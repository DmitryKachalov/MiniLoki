# frozen_string_literal: true

class S1
  include MiniLokiC::Connect
  include MiniLokiC::Population
  include MiniLokiC::Creation

  STAGING_TABLE = 's1_staging'

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
    %(select max(district_amount) max
      from ca_report_card_teacher_salaries
      where school_year = '#{school_year}' and
            category = '#{position}';)
  end

  def story_type_table(districts)
    districts.map do |row|
      {
        'Rank' => row['rank'],
        'District' => row['district'],
        'Salary' => row['salary']
      }
    end
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
    teacher_positions = [
      ['Beginning Teacher', 'Beginning Teacher Salary'],
      ['Mid-range Teacher', 'Mid-Range Teacher Salary'],
      ['Highest paid Teacher', 'Highest Teacher Salary'],
      ['Principal (Elementary School)', 'Average Principal Salary (Elementary)'],
      ['Principal (Middle School)', 'Average Principal Salary (Middle)'],
      ['Principal (High School)', 'Average Principal Salary (High)'],
      ['Superintendent', 'Superintendent Salary']
    ]

    teacher_positions.map! do |position|
      key, value = position
      match = district_data.find { |row| row['category'].eql?(value) }
      next if match.nil?

      {
        'Position' => key,
        'Salary' => match['salary']
      }
    end

    teacher_positions.compact
  end

  # eg. school_year: 2018-19
  def population(options)
    school_year = options['school_year']
    time_frame = school_year[0..1] + school_year[-2..-1]
    db01 = Mysql.on(DB01, 'usa_raw')
    db02 = Mysql.on(DB02, 'loki_storycreator')

    query = query_max_salary_for(school_year, 'Superintendent Salary')
    high_superintendent_salary = db01.query(query).first['max']
    query = query_max_salary_for(school_year, 'Average Principal Salary (Elementary)')
    high_elementary_salary = db01.query(query).first['max']

    gen_query = districts_salaries_query(school_year)
    districts = db01.query(gen_query).to_a.ranking_new!('salary')
    story_type_table = story_type_table(districts)

    districts.each do |dist|
      dist_query = district_query(school_year, dist['district_code'])
      district_data = db01.query(dist_query).to_a

      superintendent_match = district_data.find { |row| row['category'].eql?('Superintendent Salary') }
      elementary_match = district_data.find { |row| row['category'].eql?('Average Principal Salary (Elementary)') }
      org_ids = district_data.first['pl_org_id']
      next if superintendent_match.nil? || elementary_match.nil? || org_ids.nil?

      superintendent_salary = superintendent_match['salary']
      elementary_salary = elementary_match['salary']
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
        raw['elementary_salary'] = elementary_salary
        raw['high_superintendent_salary'] = high_superintendent_salary
        raw['high_elementary_salary'] = high_elementary_salary
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
      elementary_salary = stage['elementary_salary']
      high_superintendent_salary = stage['high_superintendent_salary']
      high_elementary_salary = stage['high_elementary_salary']
      district_table = HtmlTable.common(stage['district_table'])
      story_table = HtmlTable.common(stage['story_table'])

      salary_difference = superintendent_salary - elementary_salary

      sample[:headline] = "Superintendent of #{district} school district earns #{} more than the elementary school principals during #{period} school year"
      sample[:teaser]



      samples.insert(sample)
    end
  end
end