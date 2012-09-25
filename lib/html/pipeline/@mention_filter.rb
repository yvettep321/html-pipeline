require 'set'

module HTML::Pipeline
  # HTML filter that replaces @user mentions with links. Mentions within <pre>,
  # <code>, and <a> elements are ignored. Mentions that reference users that do
  # not exist are ignored.
  #
  # Context options:
  #   :base_url - Used to construct links to user profile pages for each
  #               mention.
  #
  # The following keys are written to the result hash:
  #   :mentioned_users - An array of User objects that were mentioned.
  #
  class MentionFilter < Filter
    # Public: Find user @mentions in text.  See
    # MentionFilter#mention_link_filter.
    #
    #   MentionFilter.mentioned_logins_in(text) do |match, login, is_mentioned|
    #     "<a href=...>#{login}</a>"
    #   end
    #
    # text - String text to search.
    #
    # Yields the String match, the String login name, and a Boolean determining
    # if the match = "@mention[ed]".  The yield's return replaces the match in
    # the original text.
    #
    # Returns a String replaced with the return of the block.
    def self.mentioned_logins_in(text)
      text.gsub MentionPattern do |match|
        login = $1
        yield match, login, MentionLogins.include?(login.downcase)
      end
    end

    # Pattern used to extract @mentions from text.
    MentionPattern = /
      (?:^|\W)                   # beginning of string or non-word char
      @((?>[a-z0-9][a-z0-9-]*))  # @username
      (?!\/)                     # without a trailing slash
      (?=
        \.+[ \t]|                # dots followed by space
        \.+$|                    # dots at end of line
        [^0-9a-zA-Z_.]|          # non-word character except dot
        $                        # end of line
      )
    /ix

    # List of username logins that, when mentioned, link to the blog post
    # about @mentions instead of triggering a real mention.
    MentionLogins = %w(
      mention
      mentions
      mentioned
      mentioning
    )

    # Don't look for mentions in text nodes that are children of these elements
    IGNORE_PARENTS = %w(pre code a).to_set

    def call
      mentioned_users.clear
      doc.search('text()').each do |node|
        content = node.to_html
        next if !content.include?('@')
        next if has_ancestor?(node, IGNORE_PARENTS)
        html = mention_link_filter(content, base_url)
        next if html == content
        node.replace(html)
      end
      mentioned_users.uniq!
      doc
    end

    # List of User objects that were mentioned in the document. This is
    # available in the result hash as :mentioned_users.
    def mentioned_users
      result[:mentioned_users] ||= []
    end

    # Replace user @mentions in text with links to the mentioned user's
    # profile page.
    #
    # text      - String text to replace @mention usernames in.
    # base_url  - The base URL used to construct user profile URLs.
    #
    # Returns a string with @mentions replaced with links. All links have a
    # 'user-mention' class name attached for styling.
    def mention_link_filter(text, base_url='/')
      self.class.mentioned_logins_in(text) do |match, login, is_mentioned|
        link =
          if is_mentioned
            link_to_mention_info(login)
          else
            mentioned_users << login
            link_to_mentioned_user(login)
          end

        link ? match.sub("@#{login}", link) : match
      end
    end

    def link_to_mention_info(text)
      "<a href='https://github.com/blog/821' class='user-mention'>" +
      "@#{text}" +
      "</a>".html_safe
    end

    def link_to_mentioned_user(login)
      url = File.join(base_url, login)
      "<a href='#{url}' class='user-mention'>" +
      "@#{login}" +
      "</a>"
    end
  end
end
