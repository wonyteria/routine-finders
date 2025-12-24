class GatheringsController < ApplicationController
  def index
    @challenges = Challenge.offline_gatherings.order(created_at: :desc)
    @title = "오프라인 모임"
    @description = "직접 만나서 시너지를 내는 오프라인 벙개"
    render "challenges/index"
  end
end
