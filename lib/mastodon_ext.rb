module Mastodon
  class Status
    MASTODON_REGEX = /(?<domain>[^\/]+)\/@(?<username>.+)/
    PLEROMA_REGEX = /(?<domain>[^\/]+)\/users\/(?<username>.+)/
    OTHER_REGEX = /(?<domain>[^\/]+)\/(?<username>.+)/
    MENTION_REGEX = /(<a href="https:\/\/(?<mention>[^"]+)" .*class=\"u-url mention\">@<span>[^>]+<\/span><\/a>)/
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
    def in_reply_to_account_id
      self.attributes["in_reply_to_account_id"]
    end
    def visibility
      self.attributes["visibility"]
    end
    def application
      self.attributes["application"]
    end
    def is_mention?
      text_content[0] == "@"
    end
    def is_direct?
      visibility == "direct"
    end
    def is_unlisted?
      visibility == "unlisted"
    end
    def is_private?
      visibility == "private"
    end
    def is_public?
      !(is_private? || is_unlisted? || is_direct?)
    end
    def sensitive?
      self.attributes["sensitive"]
    end
    def spoiler_text
      self.attributes["spoiler_text"]
    end
    def self.scrubber
      @@scrubber ||= Rails::Html::PermitScrubber.new
      @@scrubber.tags = ["br", "p"]
      @@scrubber
    end
    def self.html_entities
      @@html_entities ||= HTMLEntities.new
    end
    def text_content
      return @text_content if @text_content
      temp_content = content.dup
      while mention_m = temp_content.match(MENTION_REGEX)
        username_m = mention_m[:mention].match(MASTODON_REGEX) ||
          mention_m[:mention].match(PLEROMA_REGEX) ||
          mention_m[:mention].match(OTHER_REGEX)

        temp_content.gsub!(mention_m[0], "@#{username_m[:username]}@#{username_m[:domain]}")
      end
      @text_content = Loofah.fragment(temp_content).scrub!(Status.scrubber).to_s
      @text_content.gsub!("<br>", "\n")
      @text_content.gsub!("</p><p>", "\n\n")
      @text_content.gsub!(/(^<p>|<\/p>$)/, "")
      @text_content = Status.html_entities.decode(@text_content)
    end
  end
end
