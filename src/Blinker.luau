local Packages = game:GetService("ReplicatedStorage").Packages
local Clock = require(Packages.Clock)

local CurrentlyBlinkingObjects: {any} = {}

Clock(0.5, function()
	for _, section in CurrentlyBlinkingObjects do
		section.Light.Enabled = not section.Light.Enabled
		section.Transparency = if section.Light.Enabled then 0 else 0.95
	end
end)

return CurrentlyBlinkingObjects