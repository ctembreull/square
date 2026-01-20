namespace :users do
  desc "Create admin user from environment variables (ADMIN_NAME, ADMIN_EMAIL, ADMIN_PASSWORD)"
  task create_admin: :environment do
    name = ENV.fetch("ADMIN_NAME") { abort "ADMIN_NAME environment variable is required" }
    email = ENV.fetch("ADMIN_EMAIL") { abort "ADMIN_EMAIL environment variable is required" }
    password = ENV.fetch("ADMIN_PASSWORD") { abort "ADMIN_PASSWORD environment variable is required" }

    user = User.find_or_initialize_by(email: email)
    user.name = name
    user.password = password
    user.password_confirmation = password
    user.admin = true

    if user.save
      puts "Admin user #{email} (#{name}) created/updated successfully"
    else
      abort "Failed to create admin user: #{user.errors.full_messages.join(', ')}"
    end
  end
end
