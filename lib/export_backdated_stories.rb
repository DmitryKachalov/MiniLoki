# frozen_string_literal: true

require_relative 'export_backdated/job_item.rb'
require_relative 'export_backdated/export_parameters.rb'
require_relative 'export_backdated/lead_story_post.rb'
require_relative 'export_backdated/story_update.rb'
require_relative 'export_backdated/query.rb'
require_relative 'export_backdated/section.rb'

class ExportBackdatedStories
  include ExportBackdated::Query
  include ExportBackdated::JobItem
  include ExportBackdated::Section
  include ExportBackdated::ExportParameters
  include ExportBackdated::LeadStoryPost
  include ExportBackdated::StoryUpdate

  def self.find_and_export!
    new.export!
  end

  private

  def initialize
    @started_at = Time.now
    @pl_client = Pipeline[:production]
    @pl_replica_client = PipelineReplica[:production]
    @lokic_db_client = Mysql.on(DB02, 'lokic')
    # @job_item_key = 'production_job_item'
    # @pl_id_key = 'pl_production_id'
  end

  def export!
    exp_config_ids.each do |exp_config_id|
      exp_config = exp_config_by(exp_config_id)
      exp_config['job_item_id'] ||= job_item_id(exp_config)
      exp_config['section_ids'] = story_section_ids_by(exp_config['client_name'])
      next if failed?(exp_config)

      samples_in_batches(exp_config_id) do |batch|
        semaphore = Mutex.new

        threads = Array.new(4) do
          Thread.new do
            loop do
              sample = semaphore.synchronize { batch.shift }
              break if sample.nil? || Time.now > (@started_at + 86_000)

              story_id = lead_story_post(exp_config, sample)
              organization_ids = sample['org_ids'].delete('[ ]').split(',')
              story_update(story_id, organization_ids)

              update_sample(sample['id'], story_id)
            end
          end
        end

        threads.each(&:join)
      end

      break if Time.now > (@started_at + 86_000)
    end
  end

  def exp_config_ids
    @lokic_db_client.query(export_config_ids_query)
                    .to_a.map { |row| row['exp_conf_id'] }
  end

  def exp_config_by(id)
    query = export_config_query(id)
    @lokic_db_client.query(query).first
  end

  def samples_in_batches(exp_config_id)
    loop do
      query = samples_to_export_query(exp_config_id)
      samples_to_export = @lokic_db_client.query(query).to_a
      break if samples_to_export.empty? || Time.now > (@started_at + 86_000)

      yield(samples_to_export)
    end
  end

  def update_sample(sample_id, story_id)
    query = update_sample_query(sample_id, story_id)
    @lokic_db_client.query(query)
  end
end
