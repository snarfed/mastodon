# frozen_string_literal: true

class ActivityPub::DistributionWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'push'

  def perform(status_id)
    Rails.logger.debug "@ AP: loading status #{status_id}"
    @status  = Status.find(status_id)
    Rails.logger.debug "@ AP: loading account " + @status.account.to_s
    @account = @status.account

    Rails.logger.debug "@ AP: visibilities"
    Rails.logger.debug "  direct " + @status.direct_visibility?.to_s
    Rails.logger.debug "  private " + @status.private_visibility?.to_s
    Rails.logger.debug "  public " + @status.public_visibility?.to_s
    Rails.logger.debug "  unlisted " + @status.unlisted_visibility?.to_s
    Rails.logger.debug "  reply, local " + @status.reply?.to_s && @status.thread.account.local?.to_s

    Rails.logger.debug "@ AP: skip distribution?"
    return if skip_distribution?
    Rails.logger.debug "  ...no!"

    Rails.logger.debug "@ AP: inboxes: " + inboxes.to_s

    ActivityPub::DeliveryWorker.push_bulk(inboxes) do |inbox_url|
      [signed_payload, @account.id, inbox_url]
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.debug "@ AP: not found!"
    true
  end

  private

  def skip_distribution?
    @status.direct_visibility?
  end

  def inboxes
    @inboxes ||= @account.followers.inboxes
  end

  def signed_payload
    @signed_payload ||= Oj.dump(ActivityPub::LinkedDataSignature.new(payload).sign!(@account))
  end

  def payload
    @payload ||= ActiveModelSerializers::SerializableResource.new(
      @status,
      serializer: ActivityPub::ActivitySerializer,
      adapter: ActivityPub::Adapter
    ).as_json
  end
end
