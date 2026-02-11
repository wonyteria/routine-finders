module ApplicationHelper
  def auth_at_provider_path(provider:)
    "/auth/#{provider}"
  end

  def rufa_avatar_tag(user, size: :md, class_name: "")
    return "" unless user

    is_rufa = user.is_rufa_club_member?
    size_classes = {
      sm: "w-8 h-8 rounded-lg",
      md: "w-12 h-12 rounded-xl",
      lg: "w-16 h-16 rounded-2xl",
      xl: "w-24 h-24 rounded-3xl"
    }[size] || "w-12 h-12 rounded-xl"

    content_tag :div, class: "relative inline-block group #{class_name}" do
      # Glow effect for RUFA members
      glow = if is_rufa
               content_tag :div, "", class: "absolute -inset-1 bg-gradient-to-tr from-amber-400 to-orange-500 rounded-[inherit] blur-md opacity-40 group-hover:opacity-100 transition-opacity"
      end

      # Avatar image
      img = image_tag user.profile_image, class: "relative z-10 #{size_classes} object-cover border-2 #{is_rufa ? 'border-amber-400' : 'border-white/20'}"

      # Badge for RUFA members
      badge = if is_rufa
                content_tag :div, class: "absolute -top-1 -right-1 z-20 w-5 h-5 bg-amber-400 rounded-full border-2 border-slate-900 flex items-center justify-center text-[10px] shadow-lg" do
                  "🔱"
                end
      end

      (glow || "") + img + (badge || "")
    end
  end

  def user_friendly_time_zones
    iana_to_country = {}
    TZInfo::Country.all.each do |c|
      c.zone_identifiers.each { |z| iana_to_country[z] ||= c.name }
    end

    # 주요 국가 한국어 매핑
    ko_countries = {
      "South Korea" => "대한민국", "United States" => "미국", "Japan" => "일본",
      "China" => "중국", "United Kingdom" => "영국", "Vietnam" => "베트남",
      "Thailand" => "태국", "Philippines" => "필리핀", "Australia" => "호주",
      "Canada" => "캐나다", "Germany" => "독일", "France" => "프랑스",
      "Italy" => "이탈리아", "Spain" => "스페인", "Brazil" => "브라질",
      "Singapore" => "싱가포르", "Taiwan" => "대만", "Hong Kong" => "홍콩", "Indonesia" => "인도네시아"
    }

    ActiveSupport::TimeZone.all.map do |tz|
      en_country = iana_to_country[tz.tzinfo.name] || "기타"
      display_country = ko_countries[en_country] || en_country
      [ "[#{display_country}] #{tz.name} (GMT#{tz.formatted_offset})", tz.name, display_country ]
    end.sort_by { |disp, val, country| [ country, disp ] }
  end
end
