namespace :maintenance do
  desc "Extend official club end date to Gen 8 (April 30) and ensure confirmed members are active"
  task extend_official_club_to_gen8: :environment do
    official_club = RoutineClub.official.first
    if official_club.nil?
      puts "No official club found. Ensuring one..."
      official_club = RoutineClub.ensure_official_club
    end

    target_end_date = Date.new(2026, 4, 30)

    puts "Current Official Club: #{official_club.title}"
    puts "Current End Date: #{official_club.end_date}"

    if official_club.end_date < target_end_date
      official_club.update!(end_date: target_end_date, status: :active)
      puts "Updated Club end_date to #{target_end_date}"
    else
      puts "Club end_date is already #{official_club.end_date} or later. No change needed."
    end

    # Ensure all confirmed members are active and have valid dates
    confirmed_members = official_club.members.confirmed
    update_count = 0

    confirmed_members.find_each do |member|
      # Reset status to active if it was accidentally changed (e.g. kicked or left if it was automated)
      # and ensure membership_end_date covers the new cycle
      if member.status != "active" || member.membership_end_date < target_end_date
        member.update!(
          status: :active,
          membership_end_date: [ member.membership_end_date, Date.new(2099, 12, 31) ].max # Ensure it's far future
        )
        update_count += 1
      end
    end

    puts "Processed #{confirmed_members.count} confirmed members. Updated #{update_count} members."
    puts "Maintenance complete."
  end
end
