# frozen_string_literal: true

module ExportBackdated
  module LeadStoryPost
    private

    TIMES_BY_WEEKDAY = [
      %w[7:00 10:00],   # "Sunday"
      %w[10:00 12:00],  # "Monday"
      %w[7:00 10:00],   # "Tuesday"
      %w[7:00 10:00],   # "Wednesday"
      %w[7:00 10:00],   # "Thursday"
      %w[7:00 10:00],   # "Friday"
      %w[8:30 9:30]     # "Saturday"
    ].freeze

    def lead_story_post(sample, exp_config, connections)
      lead_id = lead_post(sample, exp_config)
      story_id = story_post(lead_id, sample, exp_config, connections[:pl_replica])

      query = update_sample_query(sample['id'], lead_id, story_id)
      connections[:lokic_db].query(query)
    end

    def lead_post(sample, exp_config)
      name = "#{sample['headline']} -- [#{exp_config['id']}."\
             "#{sample['id']}::#{Date.today}.#{Time.now.to_i}]"

      params = {
        name: name,
        job_item_id: exp_config['job_item_id'],
        sub_type_id: 594,
        community_ids: [exp_config['pl_publication_id']]
      }

      response = @pl_client.post_lead_safe(params)
      if (response.status / 100) != 2
        raise ExportBackdated::LeadPostError,
              "Post lead failed. Status: #{response.status}.\n"\
              "Why > #{response.body}"
      end

      JSON.parse(response.body)['id']
    end

    def published_at(date)
      datetime_to_f = lambda do |dt, pos|
        Time.parse("#{dt} #{TIMES_BY_WEEKDAY[dt.wday][pos]} EST").to_f
      end

      start = datetime_to_f.call(date, 0)
      finish = datetime_to_f.call(date, 1)
      publish_on = (finish - start) * rand + start

      Time.at(publish_on).strftime('%Y-%m-%dT%H:%M:%S%:z')
    end

    def story_post(lead_id, sample, exp_config, pl_replica)
      published_at = published_at(sample['published_at'])

      sample_org_ids = sample['organization_ids'].delete('[ ]').split(',')
      active_org_ids = pl_replica.get_active_organization_ids(sample_org_ids)

      params = {
        community_id: exp_config['pl_publication_id'],
        lead_id: lead_id,
        organization_ids: active_org_ids,
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
        raise ExportBackdated::StoryPostError,
              "Post story failed. Status: #{response.status}.\n"\
              "Why > #{response.body}."
      end

      JSON.parse(response.body)['id']
    end
  end
end
