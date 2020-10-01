# frozen_string_literal: true

module ExportBackdated
  module JobItem
    private

    def job_item_id(exp_config)
      return exp_config['job_item_id'] if exp_config['job_item_id']

      job = @pl_replica_client.get_job(exp_config['pl_publication_id'])
      job_id = job ? job['id'] : create_job(exp_config)

      job_item = @pl_replica_client.get_job_item(job_id, exp_config['story_type_name'], exp_config['publication_name'])
      job_item_id = job_item ? job_item['id'] : create_job_item(job_id, exp_config)

      update_exp_config(exp_config['id'], job_item_id)

      job_item_id
    end

    def create_job(exp_config)
      response = @pl_client.post_job(
        name: "#{exp_config['publication_name']} - HLE",
        project_id: exp_config['pl_publication_id']
      )

      JSON.parse(response.body)['id']
    end

    def create_job_item(job_id, exp_config)
      response = @pl_client.post_job_item(
        job_id: job_id,
        name: "#{exp_config['publication_name']} - #{exp_config['story_type_name']} HLE",
        content_type: 'hle',
        bucket_ids: [exp_config['p_bucket_id']],
        twitter_disabled: true,
        org_required: false
      )

      JSON.parse(response.body)['id']
    end

    def update_exp_config(exp_config_id, job_item_id)
      query = update_exp_config_query(exp_config_id, job_item_id)
      @lokic_db_client.query(query)
    end
  end
end
