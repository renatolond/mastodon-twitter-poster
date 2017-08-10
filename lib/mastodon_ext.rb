module Mastodon
  class Status
    def is_reblog?
      begin
        _ = reblog
        true
      rescue NoMethodError
        false
      end
    end
    def is_reply?
      in_reply_to_id.nil? == false
    end
    def visibility
      self.attributes['visibility']
    end
    def is_mention?
      text_content[0] == '@'
    end
    def is_direct?
      visibility == 'direct'
    end
    def is_unlisted?
      visibility == 'unlisted'
    end
    def is_private?
      visibility == 'private'
    end
    def self.scrubber
      @@scrubber ||= Rails::Html::PermitScrubber.new
      @@scrubber.tags = ['br', 'p']
      @@scrubber
    end
    def self.html_entities
      @@html_entities ||= HTMLEntities.new
    end
    def text_content
      return @text_content if @text_content
      @text_content = Loofah.fragment(content).scrub!(Status::scrubber).to_s
      @text_content.gsub!('<br>', "\n")
      @text_content.gsub!('</p><p>', "\n\n")
      @text_content.gsub!(/<\/?p>/, '')
      @text_content = Status::html_entities.decode(@text_content)
    end
  end
end

