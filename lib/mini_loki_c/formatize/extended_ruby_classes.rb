# frozen_string_literal: true

class String # :nodoc:
  # Adds HTML tags to the self text according to editorial requirements to tables
  def to_table_title
    %(<div><strong style='font-size: 18px;'>#{self}</strong></div>)
  end

  # Adds anchor tag to the self text with an URL
  def to_link(link = '#')
    %(<a href='#{link}'>#{self}</a>)
  end

  # Wraps the self text to <strong>
  def to_bold
    %(<strong>#{self}</strong>)
  end

  # Wraps the self text to <em>
  def to_italic
    %(<em>#{self}</em>)
  end
end

class Array
  # Ranking an array of hashes by key
  #
  # @param base_key [Symbol, String] will ranked by this key
  # @param rank_key [Symbol, String] will contain a rank. If key doesn't exist it will be created. +'rank'+ by default
  # @param asc [Boolean] order of sort. +false+ by default
  # @note Initial data will be changed!
  # @return [Array] sorted and ranked array of hashes
  def ranking!(base_key, rank_key: 'rank', asc: false)
    sort! { |a, b| (asc ? 1 : -1) * (a[base_key].to_f - b[base_key].to_f) <=> 0 }
    map.with_index do |row, index|
      row[rank_key] = row[base_key] == self[index - 1][base_key] ? self[index - 1][rank_key] : index + 1
    end
    self
  end

  def ranking_new!(base_key, rank_key: 'rank', asc: false)
    return self if empty?

    sort_by! { |row| (asc ? 1 : -1) * row[base_key] }
    curr_value = first[base_key]
    curr_rank = 1

    to_enum.with_index(1) do |row, index|
      unless row[base_key].eql?(curr_value)
        curr_value = row[base_key]
        curr_rank = index
      end

      row[rank_key] = curr_rank
    end

    self
  end

  # Makes full deep copy of array with all nested arrays or hashes like the method deep_dup from ActiveSupport class
  def deep_copy
    Marshal.load(Marshal.dump(self))
  end

  # Counts and returns percentile of index of +self+ if +self+ is ordered by descent. When index is 0 the method
  # returns 99, when index is last it returns 1.
  #
  # @param index [Integer] wouldn't more than self.size
  # @return {Integer} the percentile of index
  def percentile(index)
    raise "The index is #{index} -- it cannot be more than #{size}" if index > size

    99 - ((index) / (count.to_f - 1) * 98).round
  end

  # Gets an array of hashes and convert it to json contains a tables with headers
  #
  # @param table_columns [Array<Hash>] contains an array of hashes, where each hash have to contain keys :heading and :column
  # @example
  #   query_result = Mysql2.client.query('select address, city, people from a_table;').to_a
  #   story_table = query_result.get_table(
  #     [{heading: 'Cities',
  #       column: 'city},
  #      {heading: 'People amount',
  #       column: 'people'}])
  # @return [JSON] prepared table
  def build_table(table_columns)
    table = []
    map do |self_row|
      table << {}
      table_columns.map { |table_cell| table.last[table_cell[:heading]] = self_row[table_cell[:column]] }
    end
    table.to_json
  end
end
