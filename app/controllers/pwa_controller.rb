class PwaController < ApplicationController
  # Skip CSRF protection for service worker and manifest
  skip_before_action :verify_authenticity_token, only: [ :service_worker, :manifest ]

  def manifest
    render file: "app/views/pwa/manifest.json.erb", content_type: "application/manifest+json"
  end

  def service_worker
    render file: "app/views/pwa/service-worker.js", content_type: "application/javascript"
  end

  def offline
    render file: "app/views/pwa/offline.html", layout: false
  end
end
