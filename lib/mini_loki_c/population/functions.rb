# frozen_string_literal: true

module Functions
  def insert_rules(hash)
    puts 'insert_rules'
    rule = ''
    hold = ''
    updates = ''
    hash.each do |key, value|
      value = 'null' if value.nil?
      rule = "#{rule}, `#{key}`"
      hold = "#{hold}, #{value}"
      updates = "#{updates}, `#{key}` = VALUES(`#{key}`)"
    end
    rule = rule.sub(/^\s*,\s*/, '')
    hold = hold.sub(/^\s*,\s*/, '')
    updates = updates.sub(/^\s*,\s*/, '')
    '(' + rule + ') values(' + hold + ') on duplicate key update ' + updates
  end

  def graph_from_json(json)
    data = JSON.parse(json)
    table_headers =
      '<div style="display:table; border-style: solid; border-width: 1px;">'\
      '<div style="display:table-row; border-style: solid; border-width: 1px;">' +

      data.first.keys.map do |k|
        "<div style=\"display:table-cell; border-style: solid; border-width: 1px;\"><b><div style=\"padding:10px;text-align: center;\">#{k}</div></b></div>"
      end.join('') +
      '</div>'

    table_contents =
      data.map do |m|
        '<div style="display:table-row; border-style: solid; border-width: 1px;">' +
          m.values.map do |v|
            "<div style=\"display:table-cell; border-style: solid; border-width: 1px;\"><div style=\"padding:10px\">#{v}</div></div>"\
      end.join('') + '</div>'
      end.join('')

    table_terminus = '</div>'
    table_headers + table_contents + table_terminus
  end
end



