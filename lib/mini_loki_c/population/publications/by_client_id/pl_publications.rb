# frozen_string_literal: true

module MiniLokiC
  module Population
    module Publications
      class Pipeline_shapes
        include HTTParty
        base_uri 'https://pipeline-shapes.locallabs.com/shapes'

        def initialize(*args)
          @access_key = read_ini['pipeline']['access_key']
          @options = {headers: {'Authorization' => 'Token app', 'Content-Type' => 'application/json', 'X-Force-Update' => 'true' } }
          if args.first && args.first.is_a?(Hash)
            @options[:headers] = args.first['headers'] ? @options[:headers].merge(args.first['headers']) : @options[:headers]
            @options[:debug_output] = $stdout unless args[0]['log_details'] === false
          else
            @options[:debug_output] = $stdout
          end
        end

        def get_shapes(lat, lon)
          try_count = 15
          try_number = 0
          errors = []
          begin
            # p "Try #{try_number + 1}/#{try_count} ..."
            response = self.class.get("/contains_coordinate?lat=#{lat}&lon=#{lon}", @options)
            # p response
            if (502..504).include? response.code
              raise response.code.to_s
            end
          rescue => e
            errors << e
            if try_number + 1 < try_count
              sleep 1.2 ** try_number
              # sleep 1
              try_number += 1
              retry
            else
              msg = "Pipeline_shapes exceed errors limit.\nErrors:\n#{errors.join("\n")}"
              Slack.chat_postMessage(channel: 'UA9SJH2Q5', text: msg, as_user: true)
              raise e
            end
          end
          response
        end

      end

      class Pl_pubs
        include Configuration
        attr_accessor :pubs
        def initialize(lat, lon, client_array=['all'])
          @lat = lat
          @lon = lon
          shapes = Pipeline_shapes.new
          pl_shapes_results = shapes.get_shapes(@lat, @lon)
          pl_shapes = organize_pl_shapes_by_type(pl_shapes_results)
          projects_array = get_projects(pl_shapes)
          projects_data_array_of_hashes = get_projects_data(projects_array, client_array)
          puts projects_data_array_of_hashes
          @pubs = projects_data_array_of_hashes
          @pubs #like this: [{"project_id"=>"1605", "project_name"=>"Southern Illinois News", "client"=>"LGIS"}]
        end

        def organize_pl_shapes_by_type(pl_shapes_results)
          shapes_by_type = {}
          pl_shapes_results.each do |result_hash|
            shapes_by_type[result_hash['type']] = {'label' => result_hash['label'], 'id' => result_hash['id']}
          end
          shapes_by_type
        end

        def plural(type_name)
          type_plural = type_name.sub(/y$/, 'ies')
          type_plural = type_plural + 's' unless /s$/.match(type_plural)
          type_plural
        end

        def get_projects(pl_shapes_by_type)
          query =  ''
          #cong distr
          qu = "select pg.project_id from project_geographies pg inner join congressional_districts geo on (pg.geography_type = 'CongressionalDistrict' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['congressional_district']['id']}" if pl_shapes_by_type['congressional_district']
          cong_districts_qu = " (#{qu}) " if pl_shapes_by_type['congressional_district']
          query = query +  cong_districts_qu if pl_shapes_by_type['congressional_district']

          #unified_school
          qu = "select pg.project_id from project_geographies pg inner join unified_schools geo on (pg.geography_type = 'UnifiedSchool' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['unified_school']['id']}" if pl_shapes_by_type['unified_school']
          unified_schools_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['unified_school']
          query = query + unified_schools_qu if pl_shapes_by_type['unified_school']

          #city
          qu = "select pg.project_id from project_geographies pg inner join cities geo on (pg.geography_type = 'City' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['city']['id']}" if pl_shapes_by_type['city']
          city_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['city']
          query = query + city_qu if pl_shapes_by_type['city']

          #state
          qu = "select pg.project_id from project_geographies pg inner join states geo on (pg.geography_type = 'State' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['state']['id']}" if pl_shapes_by_type['state']
          state_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['state']
          query = query + state_qu if pl_shapes_by_type['state']

          #county
          qu = "select pg.project_id from project_geographies pg inner join counties geo on (pg.geography_type = 'County' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['county']['id']}" if pl_shapes_by_type['county']
          county_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['county']
          query = query + county_qu if pl_shapes_by_type['county']

          #postal_code
          qu = "select pg.project_id from project_geographies pg inner join postal_codes geo on (pg.geography_type = 'PostalCode' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['postal_code']['id']}" if pl_shapes_by_type['postal_code']
          postal_code_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['postal_code']
          query = query + postal_code_qu if pl_shapes_by_type['postal_code']

          #project_zone
          qu = "select pg.project_id from project_geographies pg inner join project_zones geo on (pg.geography_type = 'ProjectZone' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['project_zone']['id']}" if pl_shapes_by_type['project_zone']
          project_zone_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['project_zone']
          query = query + project_zone_qu if pl_shapes_by_type['project_zone']

          #township
          qu = "select pg.project_id from project_geographies pg inner join townships geo on (pg.geography_type = 'Township' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['township']['id']}" if pl_shapes_by_type['township']
          township_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['township']
          query = query + township_qu if pl_shapes_by_type['township']

          #elementary_school
          qu = "select pg.project_id from project_geographies pg inner join elementary_schools geo on (pg.geography_type = 'ElementarySchool' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['elementary_school']['id']}" if pl_shapes_by_type['elementary_school']
          elementary_school_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['elementary_school']
          query = query + elementary_school_qu if pl_shapes_by_type['elementary_school']

          #secondary_school
          qu = "select pg.project_id from project_geographies pg inner join secondary_schools geo on (pg.geography_type = 'SecondarySchool' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['secondary_school']['id']}" if pl_shapes_by_type['secondary_school']
          secondary_school_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['secondary_school']
          query = query + secondary_school_qu if pl_shapes_by_type['secondary_school']

          #subdivision
          qu = "select pg.project_id from project_geographies pg inner join subdivisions geo on (pg.geography_type = 'Subdivision' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['subdivision']['id']}" if pl_shapes_by_type['subdivision']
          subdivision_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['subdivision']
          query = query + subdivision_qu if pl_shapes_by_type['subdivision']

          #election_precinct
          qu = "select pg.project_id from project_geographies pg inner join election_precincts geo on (pg.geography_type = 'ElectionPrecinct' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['election_precinct']['id']}" if pl_shapes_by_type['election_precinct']
          election_precinct_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " +" (#{qu}) " if pl_shapes_by_type['election_precinct']
          query = query + election_precinct_qu if pl_shapes_by_type['election_precinct']

          #neighborhood
          qu = "select pg.project_id from project_geographies pg inner join neighborhoods geo on (pg.geography_type = 'Neighborhood' and pg.geography_id = geo.id) where geo.shape_id = #{pl_shapes_by_type['neighborhood']['id']}" if pl_shapes_by_type['neighborhood']
          neighborhood_qu = "#{/select/i.match(query) ? "UNION DISTINCT" : ''} " + " (#{qu}) " if pl_shapes_by_type['neighborhood']
          query = query + neighborhood_qu if pl_shapes_by_type['neighborhood']

          puts query
          project_results = []
          project_results = query_pl(query) if /select/.match(query)
          projects_array = []
          project_results.each do |result|
            projects_array << result['project_id']
          end
          projects_array
        end

        def get_projects_data(projects_array, client_array)
          projects_data_array = []
          client_string = client_array.include?('all') ? '' : "and cc.name in ('#{client_array.join("','")}')"
          projects_array.each do |project_id|
            temp = {'project_id' => project_id.to_s}
            project_data = query_pl("select c.name as project_name, cc.name as client, cc.id as client_id from communities c join client_companies cc on cc.id = c.client_company_id where c.id = #{project_id} #{client_string}")
            next if project_data.count.zero?

            temp['project_name'] = project_data.first['project_name']
            temp['client'] = project_data.first['client']
            temp['client_id'] = project_data.first['client_id']
            projects_data_array << temp
          end
          projects_data_array
        end

      end

      class Get_cov_areas
        attr_accessor :pub_list
        def initialize(pl_org_id, client_array=['all'])
          lat_lon_array = get_lats_lons_from(pl_org_id)
          full_pub_list = []
          lat_lon_array.each do |lat_lon_pair|
            lat = lat_lon_pair[0]
            lon = lat_lon_pair[1]
            pl_pubs_object = Pl_pubs.new(lat, lon, client_array)  #like this: [{"project_id"=>"1605", "project_name"=>"Southern Illinois News", "client"=>"LGIS"}]
            pubs = pl_pubs_object.pubs
            pubs.each do |pub_element|
              full_pub_list << pub_element
            end
          end
          @pub_list = full_pub_list.uniq
        end

        def get_lats_lons_from(pl_org_id)
          quer = "select lat, lon from organization_addresses where organization_id = #{pl_org_id}"
          results = query_pl(quer)
          lat_lon_array = []
          results.each do |result|
            ary = [result['lat'], result['lon']]
            lat_lon_array << ary
          end
          lat_lon_array
        end
      end

    end
  end
end