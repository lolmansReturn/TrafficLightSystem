local Phases = require(script.Phases)
local Defaults = require(script.Defaults)

local YellowLightNames = { "YT", "Y" }
local CachedPhases = {}

local function SetIntersectionLight(lightModel: Model, enabled: boolean, currentPhase: number, inNextPhase: boolean?)
	local Sections = lightModel:FindFirstChild("Sections")
	local PhaseList = lightModel:GetAttribute("Phases")

	if Sections then
		local PhaseResult = Phases.GetPhaseResult(PhaseList, currentPhase)
		lightModel:SetAttribute(
			"NextInstruction",
			Phases.GetPhaseResult(PhaseList, Phases.GetNextPhaseNumber(PhaseList, currentPhase))
		)

		if not enabled then
			if inNextPhase and lightModel:GetAttribute("NextInstruction"):find(PhaseResult) then
				return
			end

			if PhaseResult == "SingleWithArrow" and lightModel:GetAttribute("NextInstruction") == "Single" then
				Phases.SetSectionEnabled(Sections:WaitForChild("GT"), false)
				Phases.SetSectionEnabled(Sections:WaitForChild("YT"), true)
				task.delay(Defaults.YellowTime, function()
					Phases.SetSectionEnabled(Sections:WaitForChild("YT"), false)
				end)
				return
			end
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

local function ActivateIntersectionPhase(phase: number, intersectionName: string)
	local PhaseData = CachedPhases[intersectionName][phase]

	if PhaseData then
		for _, object in PhaseData.Objects do
			SetIntersectionLight(object :: Model, true, phase)
		end

		task.wait(PhaseData.PhaseTime)

		for _, object in PhaseData.Objects do
			local NextPhase = false
			local ObjectTableNext = CachedPhases[intersectionName][phase + 1]

			if not ObjectTableNext then
				ObjectTableNext = CachedPhases[intersectionName][1]
			end

			if table.find(ObjectTableNext.Objects, object) then
				NextPhase = true
			end

			SetIntersectionLight(object :: Model, false, phase, NextPhase)
		end

		task.wait(Defaults.YellowTime + Defaults.PhaseDelay)
	end
end

local function RegisterIntersection(intersection: Folder, phaseTimes: { number }?)
	assert(intersection:HasTag("Intersection"), "Intersection must have tag 'Intersection'")
	assert(not CachedPhases[intersection.Name], "Cannot register the same intersection namespace twice")

	CachedPhases[intersection.Name] = {}
	local CachedIntersectionPhase = CachedPhases[intersection.Name]

	for _, lightModel in intersection:GetChildren() do
		if lightModel:HasTag("IntersectionTrafficLight") then
			local PhaseList = lightModel:GetAttribute("Phases")
			local RedSection = lightModel:WaitForChild("Sections"):FindFirstChild("R")

			for phaseNumber in string.gmatch(PhaseList, "%d+") do
				local ActualNumber = tonumber(phaseNumber) :: number

				if not CachedIntersectionPhase[ActualNumber] then
					CachedIntersectionPhase[ActualNumber] = {
						PhaseTime = if phaseTimes then phaseTimes[ActualNumber] else Defaults.PhaseTime,
						Objects = {},
					}
				end

				Phases.SetSectionEnabled(RedSection, true)
				table.insert(CachedIntersectionPhase[ActualNumber].Objects, lightModel)
				lightModel:SetAttribute("NextInstruction", Phases.GetPhaseResult(PhaseList, 1))
			end
		end
	end

	local CurrentPhase = 1
	task.defer(function()
		while true do
			ActivateIntersectionPhase(CurrentPhase, intersection.Name)
			if CurrentPhase == #CachedIntersectionPhase then
				CurrentPhase = 1
			else
				CurrentPhase += 1
			end
		end
	end)
end

return {
	RegisterIntersection = RegisterIntersection,
}
