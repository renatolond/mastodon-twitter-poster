# frozen_string_literal: true

namespace :crossposter do
  desc 'Turn a user into an admin, identified by the FEDIVERSE_USERNAME environment variable'
  task make_admin: :environment do
    username = ENV.fetch('FEDIVERSE_USERNAME')
    user = User.joins(:authorizations).where(authorizations: { uid: username })

    if user.present?
      user.update(admin: true)
      puts "#{username} is now an admin."
    else
      puts "User could not be found; please make sure a user with the `#{username}` has connected their fediverse account."
    end
  end
  desc 'Remove admin privileges from user identified by the FEDIVERSE_USERNAME environment variable'
  task revoke_admin: :environment do
    username = ENV.fetch('FEDIVERSE_USERNAME')
    user = User.joins(:authorizations).where(authorizations: { uid: username })

    if user.present?
      user.update(admin: false)
      puts "#{username} is no longer admin."
    else
      puts "User could not be found; please make sure a user with the `#{username}` has connected their fediverse account."
    end
  end
end
