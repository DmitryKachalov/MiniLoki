# frozen_string_literal: true

module ExportBackdated
  module ExportParameters
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

    def published_at(date)
      datetime_to_f = lambda do |dt, pos|
        Time.parse("#{dt} #{TIMES_BY_WEEKDAY[dt.wday][pos]} EST").to_f
      end

      start = datetime_to_f.call(date, 0)
      finish = datetime_to_f.call(date, 1)
      publish_on = (finish - start) * rand + start

      Time.at(publish_on).strftime('%Y-%m-%dT%H:%M:%S%:z')
    end
  end
end
