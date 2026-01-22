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
end
