namespace :gamification do
  desc "Analyze user data for gamification design"
  task analyze: :environment do
    out = []
    users = User.all.to_a

    out << "========================================"
    out << "GAMIFICATION DATA ANALYSIS"
    out << "Total Platform Users: #{users.size}"

    months_to_check = [2.months.ago, 1.month.ago, Time.current]

    months_to_check.each do |time|
      date = time.to_date
      out << "=== Analysis for #{date.strftime('%Y-%m')} ==="
      
      stats = users.map do |user|
        start_date = date.beginning_of_month
        end_date = [date.end_of_month, Date.current].min
        
        routine_count = PersonalRoutineCompletion.joins(:personal_routine)
                          .where(personal_routines: { user_id: user.id })
                          .where(completed_on: start_date..end_date)
                          .count
                          
        challenge_count = VerificationLog.joins(:participant)
                            .where(participants: { user_id: user.id })
                            .where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                            .count
        
        begin
          log_rate = user.monthly_routine_log_rate(date)
          ach_rate = user.monthly_achievement_rate(date)
          score = user.rufa_club_score(date)
        rescue => _
          log_rate = 0
          ach_rate = 0
          score = 0
        end
        
        {
          id: user.id,
          routines: routine_count,
          challenges: challenge_count,
          log_rate: log_rate.to_f.round(1),
          ach_rate: ach_rate.to_f.round(1),
          score: score.to_f.round(1)
        }
      end
      
      valid_stats = stats.select { |s| s[:routines] > 0 || s[:challenges] > 0 }
      
      if valid_stats.empty?
        out << "No activity data for this month."
        next
      end
      
      avg_routines = valid_stats.sum { |s| s[:routines] }.to_f / valid_stats.size
      avg_challenges = valid_stats.sum { |s| s[:challenges] }.to_f / valid_stats.size
      avg_score = valid_stats.sum { |s| s[:score] }.to_f / valid_stats.size
      
      out << "Total Active Users: #{valid_stats.size}"
      out << "Avg Routines Completed: #{avg_routines.round(1)}"
      out << "Avg Challenges Verified: #{avg_challenges.round(1)}"
      out << "Avg Rufa Club Score: #{avg_score.round(1)}"
      
      scores = valid_stats.map { |s| s[:score] }.sort
      out << "Score Percentiles: P10: #{scores[(scores.size * 0.1).to_i]}, P50: #{scores[(scores.size * 0.5).to_i]}, P75: #{scores[(scores.size * 0.75).to_i]}, P90: #{scores[(scores.size * 0.9).to_i]}"
      
      routine_vols = valid_stats.map { |s| s[:routines] }.sort
      out << "Routines Percentiles: P10: #{routine_vols[(routine_vols.size * 0.1).to_i]}, P50: #{routine_vols[(routine_vols.size * 0.5).to_i]}, P75: #{routine_vols[(routine_vols.size * 0.75).to_i]}, P90: #{routine_vols[(routine_vols.size * 0.9).to_i]}"

      out << "Top 10 Users by Score:"
      valid_stats.sort_by { |s| -s[:score] }.first(10).each do |s|
        out << "  User #{s[:id]}: Score=#{s[:score]}, LogRate=#{s[:log_rate]}%, AchRate=#{s[:ach_rate]}%, Routines=#{s[:routines]}, Challenges=#{s[:challenges]}"
      end
      out << ""
    end

    out << "========================================"
    puts out.join("\n")
    File.write('tmp/gamification_analysis.txt', out.join("\n"))
  end
end
