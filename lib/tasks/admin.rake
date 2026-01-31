namespace :admin do
  desc "Set a user as super admin by email"
  task :set_super_admin, [ :email ] => :environment do |t, args|
    email = args[:email] || ENV["ADMIN_EMAIL"]

    if email.blank?
      puts "❌ Error: Email is required. Usage: rake admin:set_super_admin[email@example.com]"
      exit 1
    end

    user = User.find_by(email: email)

    if user.nil?
      puts "❌ Error: User with email '#{email}' not found"
      exit 1
    end

    if user.super_admin?
      puts "ℹ️  User '#{user.nickname}' (#{email}) is already a super admin"
    else
      user.update!(role: :super_admin)
      puts "✅ Successfully set '#{user.nickname}' (#{email}) as super admin"
      puts "   Previous role: #{user.role_before_last_save}"
      puts "   Current role: #{user.role}"
    end
  end

  desc "List all admin users"
  task list_admins: :environment do
    admins = User.admin.order(role: :desc, created_at: :asc)

    if admins.empty?
      puts "No admin users found"
    else
      puts "\n📋 Admin Users (#{admins.count}):"
      puts "-" * 80
      admins.each do |admin|
        role_badge = admin.super_admin? ? "🔴 SUPER ADMIN" : "🟡 CLUB ADMIN"
        puts "#{role_badge} | #{admin.nickname.ljust(20)} | #{admin.email}"
      end
      puts "-" * 80
    end
  end
end
