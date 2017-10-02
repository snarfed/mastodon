# frozen_string_literal: true

module AuthorExtractor
  def author_from_xml(xml, update_profile = true)
    return nil if xml.nil?

    # Try <email> for acct
    acct = xml.at_xpath('./xmlns:author/xmlns:email', xmlns: OStatus::TagManager::XMLNS)&.content

    # Try <name> + <uri>
    if acct.blank?
      username = xml.at_xpath('./xmlns:author/xmlns:name', xmlns: OStatus::TagManager::XMLNS)&.content
      uri      = xml.at_xpath('./xmlns:author/xmlns:uri', xmlns: OStatus::TagManager::XMLNS)&.content

      Rails.logger.debug "WebFinger found username #{username} uri #{uri}"
      return nil if username.blank? || uri.blank?

      domain = Addressable::URI.parse(uri).normalized_host
      acct   = "#{username}@#{domain}"
    end

    Rails.logger.debug "WebFinger found acct #{acct}"
    ResolveRemoteAccountService.new.call(acct, update_profile)
  end
end
