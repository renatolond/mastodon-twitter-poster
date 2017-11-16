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
    def application
      self.attributes['application']
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
    def is_public?
      !(is_private? || is_unlisted? || is_direct?)
    end
    def sensitive?
      self.attributes['sensitive']
    end
    def spoiler_text
      self.attributes['spoiler_text']
    end
    def self.scrubber
      @@scrubber ||= Rails::Html::PermitScrubber.new
      @@scrubber.tags = ['br', 'p']
      @@scrubber
    end
    def self.html_entities
      @@html_entities ||= HTMLEntities.new
    end
    def self.mention_regex
      @@mention_regex ||= /<a href="https:\/\/([^\/]+)\/@([^"]+)" class=\"u-url mention\">@<span>[^>]+<\/span><\/a>/
    end
    def text_content
      return @text_content if @text_content
      @text_content = Loofah.fragment(content.gsub(self.class.mention_regex, '@\2@\1')).scrub!(Status::scrubber).to_s
      @text_content.gsub!('<br>', "\n")
      @text_content.gsub!('</p><p>', "\n\n")
      @text_content.gsub!(/(^<p>|<\/p>$)/, '')
      @text_content = Status::html_entities.decode(@text_content)
    end
  end
  module REST
    module Media
      # XXX change this in mastodon-api instead.
      def upload_media(file, opts = {})
        file = file.is_a?(HTTP::FormData::File) ? file : HTTP::FormData::File.new(file)
        perform_request_with_object(:post, '/api/v1/media', { file: file }.merge(opts), Mastodon::Media)
      end
    end
  end
end

