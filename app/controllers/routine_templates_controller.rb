class RoutineTemplatesController < ApplicationController
  before_action :require_login

  def apply
    @template = RoutineTemplate.find(params[:id])

    # days는 저장 시 콤마로 구분된 문자열 등으로 처리될 수 있으므로 배열화
    days_array = @template.days.split(",") rescue [ "1", "2", "3", "4", "5" ]

    routine = current_user.personal_routines.build(
      title: @template.title,
      category: @template.category,
      icon: @template.icon,
      days: days_array
    )

    if routine.save
      redirect_to personal_routines_path(tab: "free"), notice: "'#{@template.title}' 루틴이 내 루틴에 추가되었습니다!"
    else
      redirect_to personal_routines_path(tab: "club"), alert: "루틴 추가에 실패했습니다."
    end
  end
end
