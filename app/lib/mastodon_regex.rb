class MastodonRegex
  REGEXEN = {} # :nodoc:
  Twitter::TwitterText::Regex::REGEXEN.each do |k, v|
    REGEXEN[k] = v
  end

  REGEXEN[:valid_general_url_path_chars] = /[^\p{White_Space}<>\(\)\?]/iou
  REGEXEN[:valid_url_path_ending_chars] = /[^\p{White_Space}\(\)\?!\*"'「」<>;:=\,\.\$%\[\]~&\|@]|(?:#{REGEXEN[:valid_url_balanced_parens]})/iou
    REGEXEN[:valid_url_balanced_parens] = /
  \(
  (?:
          #{REGEXEN[:valid_general_url_path_chars]}+
   |
  # allow one nested level of balanced parentheses
  (?:
            #{REGEXEN[:valid_general_url_path_chars]}*
   \(
              #{REGEXEN[:valid_general_url_path_chars]}+
   \)
            #{REGEXEN[:valid_general_url_path_chars]}*
  )
  )
  \)
  /iox
  REGEXEN[:valid_url_path] = /(?:
                               (?:
        #{REGEXEN[:valid_general_url_path_chars]}*
                                (?:#{REGEXEN[:valid_url_balanced_parens]} #{REGEXEN[:valid_general_url_path_chars]}*)*
        #{REGEXEN[:valid_url_path_ending_chars]}
                               )|(?:#{REGEXEN[:valid_general_url_path_chars]}+\/)
                              )/iox
  REGEXEN[:valid_url] = %r{
  (                                                                                     #   $1 total match
  (#{REGEXEN[:valid_url_preceding_chars]})                                            #   $2 Preceding character
  (                                                                                   #   $3 URL
  ((https?|dat|dweb|ipfs|ipns|ssb|gopher):\/\/)?                                    #   $4 Protocol (optional)
    (#{REGEXEN[:valid_domain]})                                                       #   $5 Domain(s)
  (?::(#{REGEXEN[:valid_port_number]}))?                                            #   $6 Port number (optional)
    (/#{REGEXEN[:valid_url_path]}*)?                                                  #   $7 URL Path and anchor
    (\?#{REGEXEN[:valid_url_query_chars]}*#{REGEXEN[:valid_url_query_ending_chars]})? #   $8 Query String
  )
  )
  }iox

  # Return the regular expression for a given <tt>key</tt>. If the <tt>key</tt>
  # is not a known symbol a <tt>nil</tt> will be returned.
  def self.[](key)
    REGEXEN[key]
  end
end
