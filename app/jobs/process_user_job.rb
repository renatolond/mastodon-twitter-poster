# frozen_string_literal: true

class ProcessUserJob < ApplicationJob
  queue_as :default

  def perform(id)
    u = User.find(id)
    u.locked = false
    u.save
  end
end
