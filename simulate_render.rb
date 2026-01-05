
# simulate_render.rb
begin
  user = User.where(role: [ :super_admin, :club_admin ]).order(role: :desc).first
  unless user
    puts "Admin user not found, using first user"
    user = User.first
  end
  puts "User: #{user.email}, Role: #{user.role}"
  puts "Is Club Member?: #{user.is_rufa_club_member?}"

  controller = PersonalRoutinesController.new
  controller.request = ActionDispatch::TestRequest.create
  controller.response = ActionDispatch::TestResponse.create

  # Inject current_user
  controller.define_singleton_method(:current_user) { user }
  controller.define_singleton_method(:logged_in?) { true }

  # Setup instance variables minimally for non-member view
  controller.instance_variable_set(:@official_club, RoutineClub.official.first)

  # If member (unexpectedly), we need more vars to avoid crash
  if user.is_rufa_club_member?
    controller.instance_variable_set(:@personal_routines, user.personal_routines)
    controller.instance_variable_set(:@current_log_rate, 0)
    controller.instance_variable_set(:@current_achievement_rate, 0)
    controller.instance_variable_set(:@total_completions, 0)
    controller.instance_variable_set(:@member_days, 0)
    controller.instance_variable_set(:@top_avg_score, 0)
    controller.instance_variable_set(:@my_score, 0)
    controller.instance_variable_set(:@rufa_rankings, [])
    controller.instance_variable_set(:@category_stats, Hash.new(0))
    controller.instance_variable_set(:@achievement_trend, [])
    controller.instance_variable_set(:@rufa_activities, [])
    controller.instance_variable_set(:@routine_templates, [])
    controller.instance_variable_set(:@lifetime_rankings, [])
  end

  puts "Attempting to render partial..."
  html = controller.render_to_string(partial: 'personal_routines/club_routines')

  puts "Render Success!"
  puts "HTML Content Sample (first 200 chars):"
  puts html[0..200]

  if html.include?("지금 루파 클럽 참여하기")
    puts "CHECK: Promotion button found."
  elsif html.include?("하루 100원")
    puts "CHECK: Fee text found."
  else
    puts "CHECK: Non-member content NOT clearly found."
  end

rescue => e
  puts "Render Failed: #{e.message}"
  puts e.backtrace.join("\n")
end
