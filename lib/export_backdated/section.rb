# frozen_string_literal: true

module ExportBackdated
  module Section
    private

    def story_section_ids_by(client_name)
      if client_name.eql?('LGIS')
        ['2', '16']
      elsif client_name.eql?('The Record') || client_name.start_with?('MM - ')
        ['16']
      else
        ['2']
      end
    end
  end
end
