# frozen_string_literal: true

class AppSerializer < Blueprinter::Base
  # Reusable method for attachment URL fields
  def self.add_attachment_url_field(attachment_name, url_method = :attachment_url)
    field "#{attachment_name}_url" do |obj|
      attachment = obj.send(attachment_name)
      if attachment.attached?
        if url_method == :attachment_url
          obj.attachment_url(attachment)
        else
          begin
            attachment.url
          rescue NoMethodError, ArgumentError
            begin
              obj.attachment_url(attachment)
            rescue NoMethodError, ArgumentError
              nil
            end
          end
        end
      else
        nil
      end
    rescue ArgumentError
      nil
    end
  end

  # Reusable method for content body display
  def self.add_content_field(field_name, content_attr = field_name, format: :html, truncate: nil)
    field field_name do |obj|
      content = obj.send(content_attr)
      if content&.body
        text = case format
        when :html
          content.body.to_html
        when :plain
          content.body.to_plain_text
        end
        truncate ? text.truncate(truncate) : text
      else
        nil
      end
    end
  end
end
