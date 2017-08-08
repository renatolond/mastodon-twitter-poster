class Authorization < ApplicationRecord
  belongs_to :user, inverse_of: :authorizations, required: true

  default_scope { order('id asc') }
end
