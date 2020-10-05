# frozen_string_literal: true

require_relative 'export_backdated/lead_story_post.rb'
require_relative 'export_backdated/query.rb'
require_relative 'export_backdated/section.rb'
require_relative 'export_backdated/error.rb'

class ExportBackdatedStories
  include ExportBackdated::Query
  include ExportBackdated::Section
  include ExportBackdated::LeadStoryPost

  def self.find_and_export!
    new.send(:export!)
  end

  private

  def initialize
    @started_at = Time.now
    @pl_client = Pipeline[:production]
    @pl_replica_client = PipelineReplica[:production]
    @lokic_db_client = MiniLokiC::Connect::Mysql.on(DB02, 'lokic')
  end

  def export!
    exported = 0
    exp_config_ids.each do |exp_config_id|
      exp_config = exp_config_by(exp_config_id)
      exp_config['section_ids'] = story_section_ids_by(exp_config['client_name'])

      samples_in_batches(exp_config_id) do |batch|
        semaphore = Mutex.new

        threads = Array.new(5) do
          Thread.new do
            thread_connections = {
              pl_replica: PipelineReplica[:production],
              lokic_db: MiniLokiC::Connect::Mysql.on(DB02, 'lokic')
            }

            loop do
              sample = semaphore.synchronize { batch.shift }
              break if sample.nil? || Time.now > (@started_at + 86_000)

              lead_story_post(sample, exp_config, thread_connections)
              exported += 1
            rescue ExportBackdated::Error => e
              message = "*Backdated export* -- #{e}\n"\
                        'Sample was skipped. *Export continued...*'

              Slack::Web::Client.new.chat_postMessage(channel: 'hle_loki_errors', text: message)
            end

          ensure
            thread_connections[:pl_replica].close
            thread_connections[:lokic_db].close
          end
        end

        threads.each(&:join)
      end

      break if Time.now > (@started_at + 86_000)
    end

    if exported > 1
      Slack::Web::Client.new.chat_postMessage(
        channel: 'hle_lokic_messages',
        text: "#{exported} backdate stories were exported during #{Date.today}."
      )
    end

  rescue StandardError => e
    Slack::Web::Client.new.chat_postMessage(
      channel: 'hle_loki_errors',
      text: "export backdated stories dropped.\nWhy? > #{e}"
    )
  ensure
    @pl_replica_client.close
    @lokic_db_client.close
  end

  def exp_config_ids
    @lokic_db_client.query(export_config_ids_query).to_a.map { |row| row['exp_conf_id'] }
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
end
