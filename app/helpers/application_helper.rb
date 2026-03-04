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
    major_zones = {
      "Seoul" => "대한민국",
      "Tokyo" => "일본",
      "Beijing" => "중국",
      "Hong Kong" => "홍콩",
      "Taipei" => "대만",
      "Singapore" => "싱가포르",
      "Bangkok" => "태국",
      "Hanoi" => "베트남",
      "Jakarta" => "인도네시아",
      "Kuala Lumpur" => "말레이시아",
      "London" => "영국",
      "Paris" => "프랑스",
      "Berlin" => "독일",
      "Sydney" => "호주",
      "Eastern Time (US & Canada)" => "미국/캐나다(동부)",
      "Central Time (US & Canada)" => "미국/캐나다(중부)",
      "Pacific Time (US & Canada)" => "미국/캐나다(서부)",
      "Hawaii" => "미국(하와이)",
      "UTC" => "세계 표준시"
    }

    ActiveSupport::TimeZone.all.select { |tz| major_zones.key?(tz.name) }.map do |tz|
      country = major_zones[tz.name]
      [ "[#{country}] #{tz.name} (GMT#{tz.formatted_offset})", tz.name, country ]
    end.sort_by { |disp, val, country| [ country == "대한민국" ? 0 : 1, country ] }
  end

  def linkify_urls(text)
    return text if text.blank?

    # Escape the entire text first to prevent XSS
    escaped_text = h(text)

    # Find all URLs and replace them with link_to tags
    urls = URI.extract(text, [ "http", "https" ]).uniq
    urls.each do |url|
      escaped_url = h(url)
      # Replace globally in the escaped text
      link_html = link_to(escaped_url, url, target: "_blank", class: "text-indigo-600 hover:underline break-all")
      escaped_text = escaped_text.gsub(escaped_url, link_html)
    end

    escaped_text.html_safe
  end
end
