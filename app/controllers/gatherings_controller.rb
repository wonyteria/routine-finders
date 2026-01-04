class GatheringsController < ApplicationController
  before_action :require_login, only: [ :new, :create ]

  def index
    # Base query: only offline mode challenges (gatherings)
    @gatherings = Challenge.where(mode: :offline).order(created_at: :desc)

    # Filter by meeting type (online/offline within gatherings context)
    # Note: This is different from Challenge.mode - here we might want to filter by location type
    if params[:location_type].present?
      case params[:location_type]
      when "online"
        @gatherings = @gatherings.where.not(online_meeting_link: nil)
      when "offline"
        @gatherings = @gatherings.joins(:meeting_info)
      end
    end

    # Filter by category
    @gatherings = @gatherings.where(category: params[:category]) if params[:category].present?

    # Filter by status
    case params[:status]
    when "recruiting"
      @gatherings = @gatherings.where(status: :upcoming)
                               .where("recruitment_end_date IS NULL OR recruitment_end_date >= ?", Date.current)
    when "upcoming"
      @gatherings = @gatherings.where(status: :upcoming)
    when "ended"
      @gatherings = @gatherings.where(status: :ended)
    end

    # Search by keyword
    if params[:keyword].present?
      @gatherings = @gatherings.where("title LIKE ? OR summary LIKE ?", "%#{params[:keyword]}%", "%#{params[:keyword]}%")
    end

    # Get user's joined gathering IDs for badges
    @joined_gathering_ids = current_user&.participations&.pluck(:challenge_id) || []

    @title = "모임 탐색"
    @description = "함께 성장하는 온·오프라인 모임"
    @is_gathering_page = true
  end

  def new
    @gathering = Challenge.new(mode: :offline)
    @gathering.meeting_type = :single # Default to single event
    @gathering.build_meeting_info
  end

  def create
    @gathering = Challenge.new(gathering_params)
    @gathering.host = current_user
    @gathering.mode = :offline # Force offline mode for gatherings

    if @gathering.save
      redirect_to challenge_path(@gathering), notice: "모임이 성공적으로 개설되었습니다!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def gathering_params
    params.require(:challenge).permit(
      :title, :category, :summary, :description, :thumbnail_image,
      :start_date, :end_date, :recruitment_end_date,
      :admission_type, :max_participants, :min_participants,
      :cost_type, :participation_fee, :amount,
      :host_bank, :host_account, :host_account_holder,
      :meeting_type, :meeting_frequency, :duration_minutes,
      :preparation_items, :online_meeting_link, :chat_link, :refund_policy,
      meeting_info_attributes: [ :place_name, :address, :description ]
    )
  end
end
