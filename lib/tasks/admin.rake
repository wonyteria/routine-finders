# frozen_string_literal: true

namespace :admin do
  desc "Set user as super admin by email"
  task :set_super_admin, [ :email ] => :environment do |_t, args|
    email = args[:email] || ENV["ADMIN_EMAIL"]

    unless email
      puts "Error: Please provide an email address"
      puts "Usage: rake admin:set_super_admin[email@example.com]"
      puts "   or: ADMIN_EMAIL=email@example.com rake admin:set_super_admin"
      exit 1
    end

    user = User.find_by(email: email)

    unless user
      puts "Error: User with email '#{email}' not found"
      exit 1
    end

    if user.super_admin?
      puts "User '#{user.nickname}' (#{user.email}) is already a super admin"
    else
      user.super_admin!
      puts "✓ Successfully set '#{user.nickname}' (#{user.email}) as super admin"
    end
  end

  desc "Set user as super admin by ID"
  task :set_super_admin_by_id, [ :user_id ] => :environment do |_t, args|
    user_id = args[:user_id] || ENV["ADMIN_USER_ID"]

    unless user_id
      puts "Error: Please provide a user ID"
      puts "Usage: rake admin:set_super_admin_by_id[145]"
      puts "   or: ADMIN_USER_ID=145 rake admin:set_super_admin_by_id"
      exit 1
    end

    user = User.find_by(id: user_id)

    unless user
      puts "Error: User with ID '#{user_id}' not found"
      exit 1
    end

    if user.super_admin?
      puts "User '#{user.nickname}' (#{user.email}) is already a super admin"
    else
      user.super_admin!
      puts "✓ Successfully set '#{user.nickname}' (#{user.email}) as super admin"
    end
  end

  desc "List all super admins"
  task list_super_admins: :environment do
    admins = User.where(role: :super_admin)

    if admins.empty?
      puts "No super admins found"
    else
      puts "Super Admins (#{admins.count}):"
      admins.each do |admin|
        puts "  - ID: #{admin.id}, Nickname: #{admin.nickname}, Email: #{admin.email}"
      end
    end
  end
end
