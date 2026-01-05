
# simulate_dashboard_render.rb
begin
  # Find an admin user who is NOT a club member
  user = User.where(role: [ :super_admin, :club_admin ]).find { |u| !u.is_rufa_club_member? }
  unless user
    puts "Non-member Admin user not found, trying to find any admin..."
    user = User.where(role: [ :super_admin, :club_admin ]).first
    # Manually pretend they are not a member for the test logic?
  end

  if user
    puts "Testing with User: #{user.email}, Role: #{user.role}"
    puts "Is Club Member?: #{user.is_rufa_club_member?}"
    puts "Is Admin?: #{user.admin?}"
  else
    puts "No admin user found to test."
    exit
  end

  controller = PersonalRoutinesController.new
  controller.request = ActionDispatch::TestRequest.create
  controller.response = ActionDispatch::TestResponse.create

  # Inject current_user
  controller.define_singleton_method(:current_user) { user }
  controller.define_singleton_method(:logged_in?) { true }

  # Setup instance variables as per controller logic (mimic empty data for admin)
  controller.instance_variable_set(:@official_club, RoutineClub.official.first)
  controller.instance_variable_set(:@personal_routines, []) # Admin has no routines usually
  controller.instance_variable_set(:@current_log_rate, 0)
  controller.instance_variable_set(:@current_achievement_rate, 0)
  controller.instance_variable_set(:@total_completions, 0)
  controller.instance_variable_set(:@member_days, 0)
  controller.instance_variable_set(:@top_avg_score, 0)
  controller.instance_variable_set(:@my_score, 0)
  controller.instance_variable_set(:@rufa_rankings, []) # Admin not in ranking
  controller.instance_variable_set(:@category_stats, Hash.new(0)) # Empty stats
  controller.instance_variable_set(:@achievement_trend, [ 0, 0, 0, 0, 0, 0, 0 ])
  controller.instance_variable_set(:@rufa_activities, [])
  controller.instance_variable_set(:@routine_templates, [])
  controller.instance_variable_set(:@lifetime_rankings, [])

  # Mock helper methods likely used in view
  controller.class.helper_method :time_ago_in_words
  controller.define_singleton_method(:time_ago_in_words) { |t| "1 hour ago" }

  puts "Attempting to render partial (forcing dashboard view)..."

  # We can't easily force the 'if' condition inside the view to evaluate differently
  # via render_to_string without mocking current_user methods inside the view context.
  # But since user.admin? is true, it SHOULD go to else block.

  html = controller.render_to_string(partial: 'personal_routines/club_routines')

  puts "Render Success!"
  puts "HTML Preview (first 500 chars):"
  puts html[0..500]

  if html.include?("id=\"rufa-premium-board\"")
    puts "CHECK: Dashboard ID found. Admin successfully accessed dashboard."
  else
    puts "CHECK: Dashboard ID NOT found. Still showing promotion?"
  end

rescue => e
  puts "Render Failed: #{e.message}"
  puts e.backtrace.join("\n")
end
