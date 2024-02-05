local minutesAfterMidnight = 700

while true do
	game.Lighting:SetMinutesAfterMidnight(minutesAfterMidnight)
	minutesAfterMidnight = minutesAfterMidnight + 3
	task.wait(0.5)
end