# frozen_string_literal: true

class Scheduler::CleanupScheduler
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed, retry: 0

  def perform
    Cleanup.new.call
  end
end
