# frozen_string_literal: true

module PipelineReplica
  module Request
    # request return job or nil
    module ClientsPublicationsTags
      def get_clients_publications_tags
        @pl_replica.query(get_clients_pubs_tags_query).to_a
      end

      private

      def get_clients_pubs_tags_query
        'SELECT cc.id client_id, cc.name client_name, p.id publication_id, p.name publication_name, '\
        "group_concat(concat(t.id, '::', t.name) separator ':::') tags FROM client_companies cc "\
        'JOIN communities p ON p.client_company_id = cc.id LEFT JOIN communities_story_tags p_t '\
        'ON p.id = p_t.community_id LEFT JOIN story_tags t ON p_t.story_tag_id = t.id group by cc.id, '\
        'cc.name, p.id, p.name;'
      end
    end
  end
end
