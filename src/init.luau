local Phases = require(script.Phases)
local Defaults = require(script.Defaults)

local YellowLightNames = {"YT", "Y"}

local function SetIntersectionLight(lightModel: Model, enabled: boolean, currentPhase: number, inNextPhase: boolean?)
	local Sections = lightModel:FindFirstChild("Sections")
	local PhaseList = lightModel:GetAttribute("Phases")

	if Sections then
		local PhaseResult = Phases.GetPhaseResult(PhaseList, currentPhase)
		lightModel:SetAttribute("NextInstruction", Phases.GetPhaseResult(PhaseList, Phases.GetNextPhaseNumber(PhaseList, currentPhase)))

		if not enabled and inNextPhase and lightModel:GetAttribute("NextInstruction"):find(PhaseResult) then
			return
		end

		if enabled then
			Phases.PlayPhase("G", Sections, PhaseResult)
		else
			for _, section in Sections:GetChildren() do
				Phases.PlayPhase("R", section, PhaseResult, lightModel:GetAttribute("NextInstruction"))
				if not table.find(YellowLightNames, section.Name) then
					if section.Name == "R" and PhaseResult == "Arrow" then
						continue
					end
					Phases.SetSectionEnabled(section, false)
				end
			end
		end
	end
end

local function RegisterIntersection(intersection: Folder, phaseTimes: {number}?)
	if not intersection:HasTag("Intersection") then
		warn("Intersection must have tag 'Intersection'")
		return
	end
	local CachedPhases = {}

	for _, lightModel in intersection:GetChildren() do
		if lightModel:HasTag("IntersectionTrafficLight") then
			local PhaseList = lightModel:GetAttribute("Phases")
			local RedSection = lightModel:WaitForChild("Sections"):FindFirstChild("R")

			for phaseNumber in string.gmatch(PhaseList, "%d+") do
				local ActualNumber = tonumber(phaseNumber) :: number

				if not CachedPhases[ActualNumber] then
					CachedPhases[ActualNumber] = {
						PhaseTime = if phaseTimes then phaseTimes[ActualNumber] else Defaults.PhaseTime,
						Objects = {},
					}
				end

				Phases.SetSectionEnabled(RedSection, true)
				table.insert(CachedPhases[ActualNumber].Objects, lightModel)
				lightModel:SetAttribute("NextInstruction", Phases.GetPhaseResult(PhaseList, 1))
			end
		end
	end

	local CurrentPhase = 1
	task.defer(function()
		while true do
			local PhaseData = CachedPhases[CurrentPhase]

			if PhaseData then
				for _, object in PhaseData.Objects do
					SetIntersectionLight(object :: Model, true, CurrentPhase)
				end

				task.wait(PhaseData.PhaseTime)

				for _, object in PhaseData.Objects do
					local NextPhase = false
					local ObjectTableNext = CachedPhases[CurrentPhase + 1]

					if not ObjectTableNext then
						ObjectTableNext = CachedPhases[1]
					end
					
					if table.find(ObjectTableNext.Objects, object) then
						NextPhase = true
					end
					
					SetIntersectionLight(object :: Model, false, CurrentPhase, NextPhase)
				end

				task.wait(4.5)
			end

			if CurrentPhase == #CachedPhases then
				CurrentPhase = 1
			else
				CurrentPhase += 1
			end
		end
	end)
end

return {
	RegisterIntersection = RegisterIntersection
}