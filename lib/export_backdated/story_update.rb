# frozen_string_literal: true

module ExportBackdated
  module StoryUpdate
    private

    def story_update(story_id, organization_ids)
      response = @pl_client.update_story(story_id, organization_ids: organization_ids)
      return if (response.status / 100).eql?(2)

      replica_org_ids = @pl_replica_client.get_active_organization_ids(organization_ids)
      response = @pl_client.update_story(story_id, organization_ids: replica_org_ids)

      raise "Update organizations failed. Status: #{response.status}." if (response.status / 100) != 2
    end
  end
end
