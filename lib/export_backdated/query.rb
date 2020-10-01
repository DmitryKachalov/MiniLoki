# frozen_string_literal: true

module ExportBackdated
  module Query
    private

    def export_config_ids_query
      %(select export_configuration_id exp_conf_id
        from samples
        where backdated = 1 and
              published_at < date(current_date() - 2) and
              pl_production_id is null
        group by export_configuration_id;)
    end

    def export_config_query(id)
      %(select ec.id,
               a.name author,
               st.name story_type_name,
               c.name client_name,
               p.pl_identifier pl_publication_id,
               p.name publication_name,
               t.pl_identifier tag_id,
               pb.pl_identifier p_bucket_id,
               ec.production_job_item job_item_id
        from export_configurations ec
            join story_types st
                on ec.story_type_id = st.id
            join publications p
                on ec.publication_id = p.id
            join tags t
                on ec.tag_id = t.id
            join photo_buckets pb
                on ec.photo_bucket_id = pb.id
            join clients c
                on p.client_id = c.id
            join authors a
                on c.author_id = a.id
        where ec.id = #{id};)
    end

    def update_exp_config_query(id, job_item_id)
      %(update export_configurations
        set production_job_item = #{job_item_id}
        where id = #{id};)
    end

    def samples_to_export_query(id)
      %(select s.id,
               o.headline,
               o.teaser,
               o.body,
               s.published_at,
               s.organization_ids org_ids
        from samples s
            join outputs o
                on s.output_id = o.id
        where export_configuration_id = #{id} and
              backdated = 1 and
              published_at < date(current_date() - 2) and
              pl_production_id is null
        limit 1000;)
    end

    def update_sample_query(id, story_id)
      %(update samples
        set pl_production_id = #{story_id} where id = #{id};)
    end
  end
end


