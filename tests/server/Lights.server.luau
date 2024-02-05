local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local CanContinueMorningChecks = true
local CanContinueNightChecks = false

while true do
	task.wait(1.25)
	if Lighting:GetMinutesAfterMidnight() > 6.15 * 60 and CanContinueMorningChecks then 
		for _, lightPart in CollectionService:GetTagged("Light") do
			lightPart:SetAttribute("Enabled", false)
			lightPart.SpotLight.Enabled = false

			lightPart.Material = Enum.Material.Glass
			lightPart.Color = Color3.fromRGB(68, 65, 67)
			lightPart.Transparency = 0.35
		end
		
		CanContinueMorningChecks = false
		CanContinueNightChecks = true
	end
	
	if Lighting:GetMinutesAfterMidnight() > 17.75 * 60 and CanContinueNightChecks then
		for _, lightPart in CollectionService:GetTagged("Light") do
			local LightColor = nil
			if lightPart:GetAttribute("OrangeLight") then
				LightColor = Color3.fromRGB(255, 137, 53)
			else
				LightColor = Color3.fromRGB(230, 230, 230)
			end

			lightPart:SetAttribute("Enabled", true)
			lightPart.SpotLight.Color = LightColor
			lightPart.SpotLight.Enabled = true

			lightPart.Material = Enum.Material.Neon
			lightPart.Color = LightColor
			lightPart.Transparency = 0
		end
		
		CanContinueNightChecks = false
		CanContinueMorningChecks = true
	end
end