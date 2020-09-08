# frozen_string_literal: true

class S3
  include MiniLokiC::Connect
  include MiniLokiC::Population
  include MiniLokiC::Creation

  STAGING_TABLE = 's3_staging'

  def districts_salaries_query(school_year)
    %(select root.district_code,
             d_info.district,
             district_amount salary
      from ca_report_card_teacher_salaries root
          join ca_report_card_district_contact_info d_info
              on d_info.district_code = root.district_code
      where school_year = '#{school_year}' and
            category = 'Superintendent Salary' and
            district_amount is not null and
            district_amount != 0
      group by root.district_code;)
  end

  def query_max_salary_for(school_year, position)
    %(select district name,
             district_amount max
      from ca_report_card_teacher_salaries root
          join ca_report_card_district_contact_info d_info
              on root.district_code = d_info.district_code
      where district_amount = (select max(district_amount) max from ca_report_card_teacher_salaries where school_year = '#{school_year}' and category = '#{position}') and
            school_year = '#{school_year}' and
            category = '#{position}'
      group by district;)
  end

  def story_type_table(raw_districts)
    districts = raw_districts.map do |row|
      [
        row['rank'],
        row['district'],
        Formatize::Money.add_commas(row['salary'])
      ]
    end

    StoryTable.new(header: %w[Rank District Salary], content: districts).to_json
  end

  def district_query(school_year, district_code)
    %(select d_info.district,
             category,
             district_amount salary,
             d_info.pl_production_org_id,
             group_concat(distinct d_info.pl_production_org_id) pl_org_id
      from ca_report_card_teacher_salaries root
               join ca_report_card_district_contact_info d_info
                    on d_info.district_code = root.district_code
      where root.district_code = '#{district_code}' and
            school_year = '#{school_year}' and
            category not in ('Percent of Budget for Administrative Salaries', 'Percent of Budget for Teacher Salaries') and
            district_amount is not null and
            district_amount != 0
      group by root.district_code, category;)
  end

  def district_table(district_data)
    raw_teacher_positions = [
      ['Beginning Teacher', 'Beginning Teacher Salary'],
      ['Mid-range Teacher', 'Mid-Range Teacher Salary'],
      ['Highest paid Teacher', 'Highest Teacher Salary'],
      ['Principal (Elementary School)', 'Average Principal Salary (Elementary)'],
      ['Principal (Middle School)', 'Average Principal Salary (Middle)'],
      ['Principal (High School)', 'Average Principal Salary (High)'],
      ['Superintendent', 'Superintendent Salary']
    ]

    teacher_positions = raw_teacher_positions.map do |position|
      key, value = position
      match = district_data.find { |row| row['category'].eql?(value) }
      next if match.nil?

      [
        key,
        Formatize::Money.add_commas(match['salary'])
      ]
    end

    StoryTable.new(header: %w[Position Salary], content: teacher_positions.compact).to_json
  end

  # eg. school_year: 2018-19
  def population(options)
    school_year = options['school_year']
    time_frame = school_year[0..1] + school_year[-2..-1]
    db01 = Mysql.on(DB01, 'usa_raw')
    db02 = Mysql.on(DB02, 'loki_storycreator')

    query = query_max_salary_for(school_year, 'Superintendent Salary')
    high_district = db01.query(query).first
    high_superintendent_district = high_district['name']
    high_superintendent_salary = high_district['max']
    query = query_max_salary_for(school_year, 'Average Principal Salary (High)')
    higest_high_school_salary = db01.query(query).first['max']

    gen_query = districts_salaries_query(school_year)
    districts = db01.query(gen_query).to_a.ranking_new!('salary')
    story_type_table = story_type_table(districts)

    districts.each do |dist|
      dist_query = district_query(school_year, dist['district_code'])
      district_data = db01.query(dist_query).to_a

      superintendent_match = district_data.find { |row| row['category'].eql?('Superintendent Salary') }
      high_school_match = district_data.find { |row| row['category'].eql?('Average Principal Salary (High)') }
      org_ids = district_data.first['pl_org_id']
      next if superintendent_match.nil? || high_school_match.nil? || org_ids.nil?

      superintendent_salary = superintendent_match['salary']
      high_school_salary = high_school_match['salary']
      dist_table = district_table(district_data)

      publications = org_ids.split(',').map do |org_id|
        [
          Publications.by_org_client_id(org_id, [120]),
          Publications.mm_excluding_states(org_id, ['California'])
        ]
      end

      publications.flatten.uniq.each do |publication|
        raw = {}
        raw['client_id'] = publication['client_id']
        raw['client_name'] = publication['client_name']
        raw['publication_id'] = publication['id']
        raw['publication_name'] = publication['name']
        raw['organization_ids'] = org_ids

        raw['time_frame'] = time_frame
        raw['district'] = dist['district']
        raw['superintendent_salary'] = superintendent_salary
        raw['high_school_principal_salary'] = high_school_salary
        raw['high_district'] = high_superintendent_district
        raw['superintendent_salary_high'] = high_superintendent_salary
        raw['high_school_principal_salary_high'] = higest_high_school_salary
        raw['district_table'] = dist_table
        raw['story_table'] = story_type_table

        staging_insert_query = SQL.insert_on_duplicate_key(STAGING_TABLE, raw)
        db02.query(staging_insert_query)
      end
    end

    db01.close
    db02.close
    PopulationSuccess[STAGING_TABLE] unless ENV['RAILS_ENV']
  end

  def creation(options)
    samples = Samples.new(STAGING_TABLE, options)

    StagingRecords[STAGING_TABLE, options].each do |stage|
      sample = {}
      sample[:staging_row_id] = stage['id']
      sample[:publication_id] = stage['publication_id']
      sample[:organization_ids] = stage['organization_ids']
      sample[:time_frame] = stage['time_frame']

      period = "#{sample[:time_frame].to_i - 1}-#{sample[:time_frame]}"
      district = stage['district']
      superintendent_salary = stage['superintendent_salary']
      high_school_principal_salary = stage['high_school_principal_salary']
      high_district = stage['high_district']
      superintendent_salary_high = stage['superintendent_salary_high']
      high_school_principal_salary_high = stage['high_school_principal_salary_high']
      district_table = StoryTable.new.from_json(stage['district_table']).to_html
      story_table = StoryTable.new.from_json(stage['story_table']).to_html

      salary_diff = superintendent_salary - high_school_principal_salary
      percent_diff = Formatize::Percents.calculate_percent(superintendent_salary, high_school_principal_salary)
      more_less = salary_diff.positive? ? 'more' : 'less'
      superintendent_salary_txt = Formatize::Money.add_commas(superintendent_salary)
      high_school_salary_txt = Formatize::Money.add_commas(high_school_principal_salary)
      high_superintendent_salary_txt = Formatize::Money.add_commas(superintendent_salary_high)
      high_principal_salary_high_txt = Formatize::Money.add_commas(high_school_principal_salary_high)

      ca_edu_link = 'California Department of Education'.to_link('https://www.cde.ca.gov/')
      us_edu_link = 'National Education Association'.to_link('https://blogs.edweek.org/teachers/teaching_now/2019/04/which_states_have_the_highest_and_lowest_teacher_salaries.html')
      policy_inst_link = 'Learning Policy Institute'.to_link('https://learningpolicyinstitute.org/product/interactive-map-understanding-teacher-shortages-california?utm_source=LPI+Master+List&utm_campaign=d4d19cd741-LPIMC_CATeacherShortageInteractive_20191205&utm_medium=email&utm_term=0_7e60dfa1d8-d4d19cd741-42305231')

      sample[:headline] = "Superintendent of #{district} school district earns #{superintendent_salary_txt} during #{period} school year"
      sample[:teaser] = "During the #{period} school year, the superintendent of #{district} school district earned #{superintendent_salary_txt}."

      output = "During the #{period} school year, the superintendent in #{district} "\
               "earned #{superintendent_salary_txt}, according to the #{ca_edu_link}. "\
               "This was #{percent_diff} percent #{more_less} than the average "\
               "high school principal salary of #{high_school_salary_txt}.\n"

      output += 'The district that had the highest pay among its superintendents was '\
                "#{high_district}, with a salary of #{high_superintendent_salary_txt}, "\
                "while the highest compensated high school principal made #{high_principal_salary_high_txt}.\n"

      output += 'Salaries for teachers vary widely based on geographical region. '\
                "According to the #{us_edu_link}, there is roughly a $40,000 "\
                "pay difference between teachers in California and Mississippi.\n"

      output += 'While California ranks second in average salaries according to the NEA, '\
                "the #{policy_inst_link} estimates that 80 percent of its school districts "\
                'are experiencing teacher shortages. Because of these shortages, 34 percent '\
                "of newly-hired teachers have substandard teaching credentials.\n"
      output += "Pay per position in #{district} on average".to_table_title
      output += district_table
      output += "\n"
      output += 'Districts ranked by superintendent pay'.to_table_title
      output += story_table

      sample[:body] = output
      samples.insert(sample)
    end
  end
end
