#coding:UTF-8
_erbout = +''; _erbout.<< "<div class=\"space-y-12 py-10 pb-24\">\n  <!-- 1. Hero Section: Generation Focus -->\n  <div class=\"relative px-6 text-center space-y-6\">\n    <div class=\"inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-indigo-500/10 border border-indigo-500/20\">\n      <span class=\"w-1.5 h-1.5 rounded-full bg-indigo-500 animate-pulse\"></span>\n      <span class=\"text-[10px] font-black text-indigo-400 uppercase tracking-widest\">Official Membership</span>\n    </div>\n    \n    <div class=\"space-y-2\">\n      <h1 class=\"text-4xl font-black text-white tracking-tight leading-tight\">\n        \xEB\xA3\xA8\xED\x8C\x8C\xED\x81\xB4\xEB\x9F\xBD <span class=\"text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-purple-400\">".freeze









; _erbout.<<(( @routine_club.recruiting_generation_number ).to_s); _erbout.<< "\xEA\xB8\xB0</span><br>\n        \xEB\xA9\xA4\xEB\xB2\x84\xEC\x8B\xAD \xEB\xAA\xA8\xEC\xA7\x91\n      </h1>\n      <p class=\"text-sm text-slate-400 font-bold leading-relaxed px-4\">\n        \xEC\x99\x84\xEB\xB2\xBD\xED\x95\x9C \xEB\xA3\xA8\xED\x8B\xB4 \xEC\x8B\x9C\xEC\x8A\xA4\xED\x85\x9C\xEA\xB3\xBC \xEA\xB0\x95\xEB\xA0\xA5\xED\x95\x9C \xEC\xBB\xA4\xEB\xAE\xA4\xEB\x8B\x88\xED\x8B\xB0\xEA\xB0\x80<br>\xEB\x8B\xB9\xEC\x8B\xA0\xEC\x9D\x98 \xEC\x84\xB1\xEC\x9E\xA5\xEC\x9D\x84 \xEA\xB0\x80\xEC\x86\x8D\xED\x99\x94\xED\x95\xA9\xEB\x8B\x88\xEB\x8B\xA4.\n      </p>\n    </div>\n\n".freeze







; _erbout.<< "    <!-- Period & Price Tag -->\n    <div class=\"flex justify-center gap-3\">\n      <div class=\"px-4 py-2 rounded-2xl bg-white/5 border border-white/5 space-y-0.5\">\n        <p class=\"text-[9px] font-black text-slate-500 uppercase tracking-widest\">Duration</p>\n        <p class=\"text-xs font-black text-white\">2\xEA\xB0\x9C\xEC\x9B\x94 \xEC\xA0\x95\xEA\xB7\x9C \xEA\xB8\xB0\xEC\x88\x98</p>\n      </div>\n      <div class=\"px-4 py-2 rounded-2xl bg-indigo-500/10 border border-indigo-500/20 space-y-0.5\">\n        <p class=\"text-[9px] font-black text-indigo-400 uppercase tracking-widest\">Pricing</p>\n        <p class=\"text-xs font-black text-indigo-400\">\xEC\x9D\xBC 300\xEC\x9B\x90 (\xEA\xB8\xB0\xEC\x88\x98\xEC\xA0\x9C)</p>\n      </div>\n    </div>\n  </div>\n\n".freeze












; _erbout.<< "  <!-- 2. Operating Rules: The Standard -->\n  <section class=\"space-y-6 px-6\">\n    <div class=\"space-y-1\">\n      <h2 class=\"text-xl font-black text-white px-1\">\xEB\xA3\xA8\xED\x8C\x8C \xED\x81\xB4\xEB\x9F\xBD \xEC\x9A\xB4\xEC\x98\x81 \xEA\xB7\x9C\xEC\xA0\x95</h2>\n      <p class=\"text-[10px] font-bold text-slate-600 uppercase tracking-widest px-1\">Rules & Regulations</p>\n    </div>\n\n".freeze






; _erbout.<< "    <div class=\"bg-white/5 rounded-[40px] border border-white/10 overflow-hidden\">\n      <div class=\"p-8 space-y-6\">\n        ".freeze

;  [
          { icon: "🚫", title: "3-Strike 자동 제명", desc: "주간 달성률 70% 미만 시 경고가 부여되며, <span class='text-rose-400 font-black'>3회 누적</span>될 경우 시스템에 의해 즉시 자동 제명 처리됩니다." },
          { icon: "⚖️", title: "환불 불가 원칙", desc: "기수제 정액 운영 특성상, 결제 완료 후에는 개인 변심이나 제명 처분을 포함한 <span class='text-white font-black'>그 어떠한 사유로도 환불이 절대 불가</span>합니다." },
          { icon: "🏅", title: "제명 처리 및 재가입 제한", desc: "제명 처리되면 해당 기수의 모든 권한이 즉시 박탈되며, 다음 기수 참여가 제한될 수 있습니다. (재도전을 원할 경우 별도 심사 필요)" },
          { icon: "🤝", title: "커뮤니티 매너 준수", desc: "분위기를 저해하거나 타 멤버에게 불쾌감을 주는 행위 적발 시 호스트 판단 하에 즉시 활동 정지 및 퇴출이 가능합니다." },
          { icon: "🎟️", title: "휴식권/세이브권의 전략적 사용", desc: "매월 제공되는 3장의 휴식권과 세이브권은 실패를 방어하는 유일한 수단입니다. 휴식권은 미리, 세이브권은 사후에 전략적으로 사용하세요." }
        ].each do |rule| ; _erbout.<< "\n".freeze
; _erbout.<< "          <div class=\"flex gap-4\">\n            <div class=\"text-xl shrink-0 mt-0.5\">".freeze
; _erbout.<<(( rule[:icon] ).to_s); _erbout.<< "</div>\n            <div class=\"space-y-1\">\n              <h4 class=\"text-sm font-black text-indigo-400\">".freeze

; _erbout.<<(( rule[:title] ).to_s); _erbout.<< "</h4>\n              <p class=\"text-xs font-bold text-slate-500 leading-relaxed break-keep\">".freeze
; _erbout.<<(( rule[:desc].html_safe ).to_s); _erbout.<< "</p>\n            </div>\n          </div>\n        ".freeze


;  end ; _erbout.<< "\n".freeze
; _erbout.<< "      </div>\n\n".freeze

; _erbout.<< "      <div class=\"px-8 py-5 bg-rose-500/10 border-t border-white/5\">\n        <p class=\"text-[10px] font-black text-rose-400 leading-relaxed\">\n          \xE2\x80\xBB \xEB\xAA\xA8\xEB\x93\xA0 \xEC\x8B\xA0\xEC\xB2\xAD\xEC\x9E\x90\xEB\x8A\x94 \xEC\x9C\x84 \xEA\xB7\x9C\xEC\xA0\x95\xEC\x9D\x84 \xEC\xB6\xA9\xEB\xB6\x84\xED\x9E\x88 \xEC\x88\x99\xEC\xA7\x80\xED\x95\x98\xEA\xB3\xA0 \xEB\x8F\x99\xEC\x9D\x98\xED\x95\x9C \xEA\xB2\x83\xEC\x9C\xBC\xEB\xA1\x9C \xEA\xB0\x84\xEC\xA3\xBC\xED\x95\xA9\xEB\x8B\x88\xEB\x8B\xA4. \xEC\x8B\xA0\xEC\xA4\x91\xED\x95\x9C \xEC\x8B\xA0\xEC\xB2\xAD \xEB\xB6\x80\xED\x83\x81\xEB\x93\x9C\xEB\xA6\xBD\xEB\x8B\x88\xEB\x8B\xA4.\n        </p>\n      </div>\n    </div>\n  </section>\n\n".freeze







; _erbout.<< "  <!-- 4. Join Application Section -->\n  <div id=\"join-section\" class=\"px-4\">\n    ".freeze

;  
      is_recruiting = @routine_club.recruitment_open?
      recruitment_start = RoutineClub.recruitment_start_date
    ; _erbout.<< "\n".freeze
; _erbout.<< "    \n    <!-- Recruitment Status Notice (Only shown when closed) -->\n    ".freeze

;  unless is_recruiting || @is_member ; _erbout.<< "\n".freeze
; _erbout.<< "      <div class=\"mb-6 p-6 rounded-[28px] bg-amber-500/10 border-2 border-amber-500/30 text-center space-y-3\">\n        <div class=\"text-3xl\">\xE2\x8F\xB0</div>\n        <div>\n          <p class=\"text-amber-400 font-black text-lg\">\xED\x98\x84\xEC\x9E\xAC \xEC\xA0\x95\xEA\xB8\xB0 \xEB\xAA\xA8\xEC\xA7\x91 \xEA\xB8\xB0\xEA\xB0\x84\xEC\x9D\xB4 \xEC\x95\x84\xEB\x8B\x99\xEB\x8B\x88\xEB\x8B\xA4</p>\n          <p class=\"text-amber-300/60 text-xs font-bold mt-2 leading-relaxed\">\n            \xEB\xA3\xA8\xED\x8C\x8C\xED\x81\xB4\xEB\x9F\xBD\xEC\x9D\x80 2\xEA\xB0\x9C\xEC\x9B\x94 \xEB\x8B\xA8\xEC\x9C\x84 \xEC\xA0\x95\xEA\xB8\xB0 \xEB\xAA\xA8\xEC\xA7\x91\xEC\x9C\xBC\xEB\xA1\x9C \xEC\x9A\xB4\xEC\x98\x81\xEB\x90\xA9\xEB\x8B\x88\xEB\x8B\xA4.<br/>\n            \xEC\x95\x84\xEB\x9E\x98 \xED\x98\x9C\xED\x83\x9D\xEA\xB3\xBC \xEC\x8B\x9C\xEC\x8A\xA4\xED\x85\x9C\xEC\x9D\x84 \xED\x99\x95\xEC\x9D\xB8\xED\x95\x98\xEC\x8B\x9C\xEA\xB3\xA0 \xEB\x8B\xA4\xEC\x9D\x8C \xEB\xAA\xA8\xEC\xA7\x91\xEC\x9D\x84 \xEA\xB8\xB0\xEB\x8B\xA4\xEB\xA0\xA4\xEC\xA3\xBC\xEC\x84\xB8\xEC\x9A\x94!\n          </p>\n        </div>\n        <div class=\"pt-3 border-t border-amber-500/20\">\n          <p class=\"text-[10px] font-black text-amber-400 uppercase tracking-widest mb-1\">Next Recruitment</p>\n          <p class=\"text-amber-300 font-black text-base\">".freeze










; _erbout.<<(( recruitment_start.strftime("%Y년 %m월 %d일") ).to_s); _erbout.<< " \xEC\x98\xA4\xED\x94\x88 \xEC\x98\x88\xEC\xA0\x95</p>\n        </div>\n      </div>\n    ".freeze


;  end ; _erbout.<< "\n".freeze
; _erbout.<< "    <div class=\"app-glass-card p-6 space-y-6 bg-gradient-to-b from-[#1B1A24] to-[#16151D]\">\n      <div class=\"text-center space-y-1\">\n        <h2 class=\"text-2xl font-black text-white\">".freeze

; _erbout.<<(( @routine_club.recruiting_generation_number ).to_s); _erbout.<< "\xEA\xB8\xB0 \xEB\xA9\xA4\xEB\xB2\x84\xEC\x8B\xAD \xEC\x8B\xA0\xEC\xB2\xAD</h2>\n        <p class=\"text-[10px] font-black text-indigo-400 uppercase tracking-widest\">Membership Application Form</p>\n      </div>\n\n".freeze



; _erbout.<< "      <div class=\"bg-black/40 rounded-[24px] p-6 space-y-5 border border-white/5 shadow-inner text-center\">\n        <div class=\"space-y-4\">\n          <div class=\"space-y-1\">\n            <p class=\"text-[10px] font-black text-slate-500 uppercase tracking-widest italic\">Membership Period</p>\n            <p class=\"text-base font-black text-white whitespace-nowrap\">\n              ".freeze




; _erbout.<<(( @routine_club.start_date.strftime("%Y.%m.%d") ).to_s); _erbout.<< " <span class=\"text-indigo-500 mx-1\">\xE2\x80\x94</span> ".freeze; _erbout.<<(( @routine_club.start_date.year == @routine_club.end_date.year ? @routine_club.end_date.strftime("%m.%d") : @routine_club.end_date.strftime("%Y.%m.%d") ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "            </p>\n          </div>\n\n".freeze


; _erbout.<< "          <div class=\"bg-white/5 h-px w-2/3 mx-auto\"></div>\n\n".freeze

; _erbout.<< "          <div class=\"space-y-2\">\n            <p class=\"text-[10px] font-black text-slate-500 uppercase tracking-widest italic\">\n              Total Fee (".freeze

; _erbout.<<(( @routine_club.duration_in_days ).to_s); _erbout.<< " Days)\n            </p>\n            <p class=\"text-3xl font-black text-transparent bg-clip-text bg-gradient-to-r from-indigo-400 to-purple-400\">\n              \xE2\x82\xA9".freeze


; _erbout.<<(( number_with_delimiter(@routine_club.calculate_cycle_fee) ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "            </p>\n          </div>\n\n".freeze


; _erbout.<< "          <!-- Bank Account Info -->\n          <div class=\"pt-4 space-y-2\">\n            <div class=\"inline-block px-4 py-3 rounded-2xl bg-[#16151D] border border-white/10 w-full max-w-[280px]\">\n              <p class=\"text-[10px] font-bold text-slate-400 mb-1\">\n                ".freeze



; _erbout.<<(( @routine_club.bank_name ).to_s); _erbout.<< " <span class=\"text-slate-600\">|</span> ".freeze; _erbout.<<(( @routine_club.account_holder ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "              </p>\n              <div class=\"flex items-center justify-center gap-2 group cursor-pointer\" onclick=\"navigator.clipboard.writeText('".freeze
; _erbout.<<(( @routine_club.account_number ).to_s); _erbout.<< "').then(() => alert('\xEA\xB3\x84\xEC\xA2\x8C\xEB\xB2\x88\xED\x98\xB8\xEA\xB0\x80 \xEB\xB3\xB5\xEC\x82\xAC\xEB\x90\x98\xEC\x97\x88\xEC\x8A\xB5\xEB\x8B\x88\xEB\x8B\xA4!'))\">\n                <span class=\"text-lg font-black text-white tracking-wider font-mono\">".freeze
; _erbout.<<(( @routine_club.account_number ).to_s); _erbout.<< "</span>\n                <span class=\"text-indigo-500 group-hover:text-white transition-colors\">\n                  <svg class=\"w-4 h-4\" fill=\"none\" stroke=\"currentColor\" viewBox=\"0 0 24 24\"><path stroke-linecap=\"round\" stroke-linejoin=\"round\" stroke-width=\"2\" d=\"M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z\"/></svg>\n                </span>\n              </div>\n            </div>\n            <p class=\"text-[9px] font-bold text-slate-600\">\xEC\x9E\x85\xEA\xB8\x88\xEC\x9E\x90\xEB\xAA\x85\xEC\x9D\x84 \xEC\x8B\xA0\xEC\xB2\xAD\xEC\x84\x9C\xEC\x99\x80 \xEB\x8F\x99\xEC\x9D\xBC\xED\x95\x98\xEA\xB2\x8C \xEC\x9E\x85\xEB\xA0\xA5\xED\x95\xB4\xEC\xA3\xBC\xEC\x84\xB8\xEC\x9A\x94.</p>\n          </div>\n        </div>\n      </div>\n\n".freeze










; _erbout.<< "      ".freeze;  if @is_member ; _erbout.<< "\n".freeze
; _erbout.<< "         <div class=\"bg-emerald-500/10 border border-emerald-500/20 rounded-[28px] p-8 text-center space-y-3\">\n           <div class=\"text-4xl\">\xF0\x9F\x8E\x8A</div>\n           <p class=\"text-emerald-400 font-black text-base\">\xEC\x9D\xB4\xEB\xAF\xB8 ".freeze

; _erbout.<<(( @routine_club.recruiting_generation_number ).to_s); _erbout.<< "\xEA\xB8\xB0 \xEB\xA9\xA4\xEB\xB2\x84\xEC\x9E\x85\xEB\x8B\x88\xEB\x8B\xA4!</p>\n           <p class=\"text-xs font-bold text-emerald-400/60 leading-relaxed\">\xEC\xA4\x80\xEB\xB9\x84\xEB\x90\x9C \xEC\x8B\x9C\xEC\x8A\xA4\xED\x85\x9C\xEA\xB3\xBC \xED\x95\xA8\xEA\xBB\x98<br/>\xEC\xB5\x9C\xEA\xB3\xA0\xEC\x9D\x98 \xEC\x84\xB1\xEC\x9E\xA5\xEC\x9D\x84 \xEB\xA7\x8C\xEB\x93\xA4\xEC\x96\xB4\xEB\xB3\xB4\xEC\x84\xB8\xEC\x9A\x94.</p>\n           ".freeze

; _erbout.<<(( link_to "나의 대시보드 가기", prototype_home_path(tab: 'club'), class: "inline-block mt-4 px-6 py-3 bg-emerald-500 text-white rounded-xl font-black text-xs" ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "         </div>\n      ".freeze
;  elsif @is_pending ; _erbout.<< "\n".freeze
; _erbout.<< "         <div class=\"bg-indigo-500/10 border border-indigo-500/20 rounded-[28px] p-8 text-center space-y-4\">\n           <div class=\"w-16 h-16 bg-indigo-500/20 rounded-2xl flex items-center justify-center text-3xl mx-auto mb-2 animate-pulse\">\xE2\x8F\xB3</div>\n           <div class=\"space-y-1\">\n             <p class=\"text-indigo-400 font-black text-base\">\xED\x81\xB4\xEB\x9F\xBD \xEA\xB0\x80\xEC\x9E\x85 \xED\x99\x95\xEC\x9D\xB8 \xEC\xA4\x91\xEC\x9E\x85\xEB\x8B\x88\xEB\x8B\xA4</p>\n             <p class=\"text-[10px] font-bold text-indigo-400/60 uppercase tracking-widest\">Application Pending</p>\n           </div>\n           <p class=\"text-xs font-bold text-slate-500 leading-relaxed\">\n             \xED\x98\xB8\xEC\x8A\xA4\xED\x8A\xB8\xEA\xB0\x80 \xEC\x9E\x85\xEA\xB8\x88 \xEB\x82\xB4\xEC\x97\xAD\xEC\x9D\x84 \xED\x99\x95\xEC\x9D\xB8\xED\x95\x98\xEA\xB3\xA0 \xEC\x9E\x88\xEC\x8A\xB5\xEB\x8B\x88\xEB\x8B\xA4.<br/>\n             \xEC\x8A\xB9\xEC\x9D\xB8\xEC\x9D\xB4 \xEC\x99\x84\xEB\xA3\x8C\xEB\x90\x98\xEB\xA9\xB4 \xED\x91\xB8\xEC\x8B\x9C \xEC\x95\x8C\xEB\xA6\xBC\xEC\x9C\xBC\xEB\xA1\x9C \xEC\x95\x8C\xEB\xA0\xA4\xEB\x93\x9C\xEB\xA6\xB4\xEA\xB2\x8C\xEC\x9A\x94!<br/>\n             (\xEB\xB3\xB4\xED\x86\xB5 24\xEC\x8B\x9C\xEA\xB0\x84 \xEB\x82\xB4\xEC\x97\x90 \xEC\xB2\x98\xEB\xA6\xAC\xEB\x90\xA9\xEB\x8B\x88\xEB\x8B\xA4.)\n           </p>\n           ".freeze










; _erbout.<<(( link_to "안내 페이지로 돌아가기", guide_routine_clubs_path(source: 'prototype'), class: "inline-block px-6 py-3 bg-white/5 border border-white/10 text-white rounded-xl font-black text-xs" ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "         </div>\n      ".freeze
;  elsif !is_recruiting ; _erbout.<< "\n".freeze
; _erbout.<< "         <!-- Recruitment Closed: Show disabled form state -->\n         <div class=\"opacity-50 pointer-events-none space-y-6\">\n           <div class=\"space-y-2\">\n             <label class=\"text-[10px] font-black text-slate-500 uppercase tracking-wider pl-4\">\xEC\x9E\x85\xEA\xB8\x88\xEC\x9E\x90\xEC\x84\xB1\xED\x95\xA8</label>\n             <input type=\"text\" disabled placeholder=\"\xEB\xAA\xA8\xEC\xA7\x91 \xEA\xB8\xB0\xEA\xB0\x84\xEC\x97\x90 \xEC\x8B\xA0\xEC\xB2\xAD \xEA\xB0\x80\xEB\x8A\xA5\xED\x95\xA9\xEB\x8B\x88\xEB\x8B\xA4\" class=\"w-full bg-black/40 border border-white/5 rounded-2xl p-5 text-white text-sm placeholder-slate-600 font-bold\" />\n           </div>\n           <div class=\"space-y-2\">\n             <label class=\"text-[10px] font-black text-slate-500 uppercase tracking-wider pl-4\">\xEC\x97\xB0\xEB\x9D\xBD\xEC\xB2\x98</label>\n             <input type=\"text\" disabled placeholder=\"\xEB\xAA\xA8\xEC\xA7\x91 \xEA\xB8\xB0\xEA\xB0\x84\xEC\x97\x90 \xEC\x8B\xA0\xEC\xB2\xAD \xEA\xB0\x80\xEB\x8A\xA5\xED\x95\xA9\xEB\x8B\x88\xEB\x8B\xA4\" class=\"w-full bg-black/40 border border-white/5 rounded-2xl p-5 text-white text-sm placeholder-slate-600 font-bold\" />\n           </div>\n           <button disabled class=\"w-full py-6 bg-slate-700 rounded-[28px] font-black text-white text-lg cursor-not-allowed\">\n             ".freeze










; _erbout.<<(( recruitment_start.strftime("%m월 %d일") ).to_s); _erbout.<< "\xEB\xB6\x80\xED\x84\xB0 \xEC\x8B\xA0\xEC\xB2\xAD \xEA\xB0\x80\xEB\x8A\xA5\n           </button>\n         </div>\n      ".freeze


;  else ; _erbout.<< "\n".freeze
; _erbout.<< "        ".freeze;  if logged_in? ; _erbout.<< "\n".freeze
; _erbout.<< "          ".freeze; _erbout.<<(( form_with(url: join_routine_club_path(@routine_club), method: :post, 
                        data: { 
                          controller: "club-join",
                          club_join_target: "form",
                          action: "submit->club-join#review" 
                        },
                        class: "space-y-6") do |f| ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "            <div class=\"space-y-2\">\n              <label class=\"text-[10px] font-black text-slate-500 uppercase tracking-wider pl-4\">\xEC\x9E\x85\xEA\xB8\x88\xEC\x9E\x90\xEC\x84\xB1\xED\x95\xA8</label>\n              ".freeze

; _erbout.<<(( f.text_field :depositor_name, required: true, placeholder: "홍길동", 
                              data: { club_join_target: "depositorInput" },
                              class: "w-full bg-black/40 border border-white/5 rounded-2xl p-5 text-white text-sm placeholder-slate-800 focus:border-indigo-500/50 outline-none transition-all font-bold" ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "            </div>\n\n".freeze

; _erbout.<< "            <div class=\"space-y-2\">\n              <label class=\"text-[10px] font-black text-slate-500 uppercase tracking-wider pl-4\">\xEC\x97\xB0\xEB\x9D\xBD\xEC\xB2\x98 (\xEC\x98\xA4\xED\x94\x88\xEC\xB1\x84\xED\x8C\x85/\xEC\xA0\x84\xED\x99\x94\xEB\xB2\x88\xED\x98\xB8)</label>\n              ".freeze

; _erbout.<<(( f.text_field :contact_info, required: true, placeholder: "010-1234-5678", 
                              data: { club_join_target: "contactInput" },
                              class: "w-full bg-black/40 border border-white/5 rounded-2xl p-5 text-white text-sm placeholder-slate-800 focus:border-indigo-500/50 outline-none transition-all font-bold" ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "            </div>\n\n".freeze

; _erbout.<< "            <div class=\"space-y-2\">\n              <label class=\"text-[10px] font-black text-slate-500 uppercase tracking-wider pl-4\">THREADS NICKNAME (ID)</label>\n              ".freeze

; _erbout.<<(( f.text_field :threads_nickname, placeholder: "@nickname", 
                              data: { club_join_target: "threadsInput" },
                              class: "w-full bg-black/40 border border-white/5 rounded-2xl p-5 text-white text-sm placeholder-slate-800 focus:border-indigo-500/50 outline-none transition-all font-bold" ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "            </div>\n\n".freeze

; _erbout.<< "            <div class=\"space-y-2\">\n              <label class=\"text-[10px] font-black text-slate-500 uppercase tracking-wider pl-4\">\xEC\x9D\xB4\xEB\xB2\x88 \xEA\xB8\xB0\xEC\x88\x98 \xEA\xB0\x80\xEC\x9E\x85 \xED\x8F\xAC\xEB\xB6\x80</label>\n              ".freeze

; _erbout.<<(( f.text_area :goal, rows: 4, placeholder: "목표와 다짐을 적어주세요. (최소 10자)", 
                              data: { club_join_target: "goalInput" },
                              class: "w-full bg-black/40 border border-white/5 rounded-2xl p-5 text-white text-sm placeholder-slate-800 focus:border-indigo-500/50 outline-none transition-all font-bold resize-none", required: true ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "            </div>\n\n".freeze

; _erbout.<< "            <div class=\"pt-6\">\n              <button type=\"submit\" class=\"w-full py-6 bg-gradient-to-r from-indigo-600 to-purple-600 rounded-[28px] font-black text-white text-lg shadow-2xl shadow-indigo-600/40 active:scale-95 transition-all\">\n                \xEC\xB0\xB8\xEC\x97\xAC \xEC\x8B\xA0\xEC\xB2\xAD \xEB\xB0\x8F \xEC\xA0\x95\xEB\xB3\xB4 \xED\x99\x95\xEC\x9D\xB8\n              </button>\n            </div>\n\n".freeze





; _erbout.<< "            <!-- Confirmation Modal -->\n            <div data-club-join-target=\"confirmModal\" class=\"hidden fixed inset-0 z-[2000] flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm\" style=\"margin: 0;\">\n              <div class=\"relative w-[calc(100%-2rem)] max-w-[340px] mx-auto app-glass-card border-white/10 p-6 space-y-6 animate-badge-pop bg-[#16151D]\">\n                <div class=\"text-center space-y-1\">\n                  <div class=\"w-16 h-16 bg-indigo-500/20 rounded-2xl flex items-center justify-center text-3xl mx-auto mb-3\">\xF0\x9F\xA7\x90</div>\n                  <h3 class=\"text-xl font-black text-white\">\xEC\x9E\x85\xEB\xA0\xA5 \xEC\xA0\x95\xEB\xB3\xB4\xEB\xA5\xBC \xED\x99\x95\xEC\x9D\xB8\xED\x95\xB4\xEC\xA3\xBC\xEC\x84\xB8\xEC\x9A\x94</h3>\n                  <p class=\"text-[10px] font-bold text-slate-500 uppercase tracking-widest\">Please Verify Your Info</p>\n                </div>\n\n".freeze








; _erbout.<< "                <div class=\"space-y-4 py-2 border-y border-white/5\">\n                  <div class=\"flex justify-between items-start\">\n                    <span class=\"text-[10px] font-black text-slate-500 shrink-0\">\xEC\x9E\x85\xEA\xB8\x88\xEC\x9E\x90\xEB\xAA\x85</span>\n                    <span data-club-join-target=\"confirmName\" class=\"text-xs font-black text-white text-right break-all\"></span>\n                  </div>\n                  <div class=\"flex justify-between items-start\">\n                    <span class=\"text-[10px] font-black text-slate-500 shrink-0\">\xEC\x97\xB0\xEB\x9D\xBD\xEC\xB2\x98</span>\n                    <span data-club-join-target=\"confirmContact\" class=\"text-xs font-black text-white text-right truncate max-w-[160px]\"></span>\n                  </div>\n                  <div class=\"flex justify-between items-start\">\n                    <span class=\"text-[10px] font-black text-slate-500 shrink-0\">ID</span>\n                    <span data-club-join-target=\"confirmThreads\" class=\"text-xs font-black text-white text-right break-all\"></span>\n                  </div>\n                  <div class=\"space-y-1\">\n                    <span class=\"text-[10px] font-black text-slate-500\">\xEA\xB0\x80\xEC\x9E\x85 \xED\x8F\xAC\xEB\xB6\x80</span>\n                    <p data-club-join-target=\"confirmGoal\" class=\"text-[11px] font-bold text-slate-400 leading-relaxed text-left break-words line-clamp-3\"></p>\n                  </div>\n                </div>\n\n".freeze


















; _erbout.<< "                <div class=\"pt-2 space-y-3\">\n                  <button type=\"button\" data-action=\"click->club-join#submit\" class=\"w-full py-5 bg-indigo-600 text-white rounded-2xl font-black text-sm shadow-xl shadow-indigo-600/20 active:scale-95 transition-all\">\n                    \xEC\x9D\xB4 \xEB\x82\xB4\xEC\x9A\xA9\xEC\x9C\xBC\xEB\xA1\x9C \xEC\x8B\xA0\xEC\xB2\xAD \xEC\x99\x84\xEB\xA3\x8C\n                  </button>\n                  <button type=\"button\" data-action=\"click->club-join#close\" class=\"w-full py-4 text-slate-500 font-bold text-xs hover:text-white transition-colors\">\n                    \xEC\x88\x98\xEC\xA0\x95\xED\x95\xA0\xEA\xB2\x8C\xEC\x9A\x94 (\xEC\x9E\x85\xEB\xA0\xA5\xEC\xB0\xBD\xEC\x9C\xBC\xEB\xA1\x9C \xEC\x9D\xB4\xEB\x8F\x99)\n                  </button>\n                </div>\n              </div>\n            </div>\n          ".freeze









;  end ; _erbout.<< "\n".freeze
; _erbout.<< "        ".freeze;  else ; _erbout.<< "\n".freeze
; _erbout.<< "          <div class=\"space-y-6\">\n            <div class=\"p-6 bg-indigo-500/5 border border-indigo-500/10 rounded-2xl text-center\">\n              <p class=\"text-xs font-bold text-slate-400 leading-relaxed\">\xEC\x8B\xA0\xEC\xB2\xAD\xEC\x84\x9C\xEB\xA5\xBC \xEC\x9E\x91\xEC\x84\xB1\xED\x95\x98\xEC\x8B\x9C\xEB\xA0\xA4\xEB\xA9\xB4 \xEB\xA1\x9C\xEA\xB7\xB8\xEC\x9D\xB8\xEC\x9D\xB4 \xED\x95\x84\xEC\x9A\x94\xED\x95\xA9\xEB\x8B\x88\xEB\x8B\xA4.</p>\n            </div>\n            ".freeze



; _erbout.<<(( link_to prototype_login_path, class: "block w-full py-6 bg-gradient-to-r from-indigo-600 to-purple-600 rounded-[28px] font-black text-white text-lg text-center shadow-2xl shadow-indigo-600/40 active:scale-95 transition-all" do ).to_s); _erbout.<< "\n".freeze
; _erbout.<< "              \xEB\xA1\x9C\xEA\xB7\xB8\xEC\x9D\xB8\xED\x95\x98\xEA\xB3\xA0 \xEC\x8B\xA0\xEC\xB2\xAD\xED\x95\x98\xEA\xB8\xB0\n            ".freeze
;  end ; _erbout.<< "\n".freeze
; _erbout.<< "          </div>\n        ".freeze
;  end ; _erbout.<< "\n".freeze
; _erbout.<< "      ".freeze;  end ; _erbout.<< "\n".freeze
; _erbout.<< "    </div>\n  </div>\n</div>\n".freeze


; _erbout
