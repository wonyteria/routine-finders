namespace :routine_club do
  desc "Close the previous generation and award badges (runs daily, only acts on 1st day of quarter)"
  task close_generation: :environment do
    RoutineClub::GenerationClosingService.run_daily!
  end

  desc "Manually close a specific generation (e.g. rake routine_club:manual_close[2026-01-01])"
  task :manual_close, [ :date ] => :environment do |t, args|
    date = args[:date] ? Date.parse(args[:date]) : Date.current
    RoutineClub::GenerationClosingService.close_previous_generation!(date)
  end
end
