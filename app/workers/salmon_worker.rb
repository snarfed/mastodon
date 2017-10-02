# frozen_string_literal: true

class SalmonWorker
  include Sidekiq::Worker

  sidekiq_options backtrace: true

  def perform(account_id, body)
    Rails.logger.debug "Perform"
    ProcessInteractionService.new.call(body, Account.find(account_id))
  rescue Nokogiri::XML::XPath::SyntaxError, ActiveRecord::RecordNotFound
    Rails.logger.debug "No perform"
    true
  end
end
