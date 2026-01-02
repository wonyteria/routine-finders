module ApplicationHelper
  def auth_at_provider_path(provider:)
    "/auth/#{provider}"
  end
end
