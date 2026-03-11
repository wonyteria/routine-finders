target_names = [ 'namji21', 'Allstory', '자영사업', '쿼카워니' ]
attribution_date = Date.current.last_week.end_of_week

target_names.each do |name_str|
  # Use LIKE in case of slight casing mismatch or trailing whitespace
  user = User.where("nickname LIKE ?", "%#{name_str}%").first
  if user
    member = user.routine_club_members.last
    if member
      if member.penalties.where(title: "주간 점검 경고", created_at: attribution_date.all_day).exists?
        puts "[Skipped] #{user.nickname} already has a warning for last week."
      else
        member.warn!("주간 루틴 달성률 저조 (수동 부여)", attribution_date)
        puts "[Success] Issued warning to #{user.nickname} (ID: #{user.id}) for last week."
      end
    else
      puts "[Not Found] RoutineClubMember not found for #{name_str}"
    end
  else
    puts "[Not Found] User #{name_str} not found in local DB!"
  end
end
