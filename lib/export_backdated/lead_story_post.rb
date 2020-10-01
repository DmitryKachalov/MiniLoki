# frozen_string_literal: true

module ExportBackdated
  module LeadStoryPost
    private

    def lead_story_post(exp_config, sample)
      lead_id = lead_post(exp_config, sample)
      story_post(exp_config, lead_id, sample)
    end

    def lead_post(sample, exp_config)
      name = "#{sample['headline']} -- [#{exp_config['id']}."\
             "#{sample['id']}::#{"#{Date.today}.#{Time.now.to_i}"}]"

      params = {
        name: name,
        job_item_id: exp_config['job_item_id'],
        sub_type_id: 594,
        community_ids: [exp_config['pl_publication_id']]
      }

      response = @pl_client.post_lead_safe(params)
      raise "Post lead failed. Status: #{response.status}." if (response.status / 100) != 2

      JSON.parse(response.body)['id']
    end

    def story_post(exp_config, lead_id, sample)
      published_at = published_at(sample['published_at'])

      params = {
        community_id: exp_config['pl_publication_id'],
        lead_id: lead_id,
        organization_ids: [],
        headline: sample['headline'],
        teaser: sample['teaser'],
        body: sample['body'],
        published_at: published_at,
        author: exp_config['author'],
        story_section_ids: exp_config['section_ids'],
        story_tag_ids: [exp_config['tag_id']],
        published: true,
        bucket_id: exp_config['p_bucket_id']
      }

      response = @pl_client.post_story_safe(params)

      if (response.status / 100) != 2
        @pl_client.delete_lead(lead_id)
        raise "Post story failed. Status: #{response.status}."
      end

      JSON.parse(response.body)['id']
    end
  end
end
