local TrafficLightCreatorToolbar = plugin:CreateToolbar("TrafficLightCreatorToolbar")
local CreateTrafficLight = TrafficLightCreatorToolbar:CreateButton(
	"Traffic Light",
	"Creates a new selected traffic light",
	"rbxassetid://169612234"
)

local CreateMast = TrafficLightCreatorToolbar:CreateButton(
    "Mast",
    "Creates a new mast to hold traffic lights on",
    "rbxassetid://16834172396"
)

CreateTrafficLight.Click:Connect(function()
    
end)

CreateMast.Click:Connect(function()

end)
