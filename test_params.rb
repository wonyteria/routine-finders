out = ActionController::Parameters.new({
  challenge: {
    daily_goals: { "mon" => ["test"] },
    title: "test",
    certification_goal: ["goal"],
    reward_policy: [{"rank" => "1", "reward" => "prize"}]
  }
}).require(:challenge).permit(:title, :daily_goals, :certification_goal, :reward_policy).inspect

File.write('out.txt', out)
