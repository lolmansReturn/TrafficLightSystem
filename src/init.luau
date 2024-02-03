--!strict
-- Copyright (c) 2024 lolmansReturn

export type PhaseTypes = "Single" | "Arrow" | "SingleWithArrow"

local PatternsToSections = {
	Single = {
		R = false,
		G = true,
		GT = false,
	},
	Arrow = {
		R = true,
		G = false,
		GT = true,
	},
	SingleWithArrow = {
		R = false,
		G = true,
		GT = true,
	},
}

local YellowTime = 3
local DefaultPhaseTime = 14

local function SetSectionEnabled(section: any, enabled: boolean)
	section.Transparency = if enabled then 0 else 0.95
	section.Light.Enabled = enabled
end

-- local function SetTrafficLightEnabled()

-- 		for _, section in sectionChildren do
-- 			if not section:IsA("Part") then
-- 				continue
-- 			end

-- 			if section.Name == "R" and instruction == "Arrow" then
-- 				SetSectionEnabled(section, true)
-- 			else
-- 				SetSectionEnabled(section, false)
-- 			end

-- 			if table.find(SingleSectionsYellow, section.Name) and table.find(SingleOnly, instruction) then
-- 				SetSectionEnabled(section, true)
-- 			end

-- 			if table.find(ArrowSectionsYellow, section.Name) and table.find(ArrowOnly, instruction) then
-- 				SetSectionEnabled(section, true)
-- 			end

			
-- end

local function GetPhaseResult(phaseList: string, currentPhase: number): PhaseTypes
	if not phaseList:find(tostring(currentPhase)) then
		currentPhase = 1
	end

	if phaseList:find(`{currentPhase}A`) then
		return "Arrow"
	end
	
	if phaseList:find(`{currentPhase}B`) then
		return "SingleWithArrow"
	end
	
	return "Single"
end

local function SetIntersectionLight(lightModel: Model, enabled: boolean, currentPhase: number)
	local Sections = lightModel:FindFirstChild("Sections")
	local PhaseList = lightModel:GetAttribute("Phases")

	if Sections then
		local PhaseResult = GetPhaseResult(PhaseList, currentPhase)
		local NextPhase = GetPhaseResult(PhaseList, currentPhase + 1)
		lightModel:SetAttribute("NextInstruction", NextPhase)

		if enabled then
			for name, enabled in PatternsToSections[PhaseResult] do
				local Child = Sections:FindFirstChild(name)
				if Child and Child.Name == name then
					SetSectionEnabled(Child, enabled)
				end
			end
		else
			local SectionChildren = Sections:GetChildren()

			if PatternsToSections[NextPhase][] == true then
				return
			end

			local Red = Sections:FindFirstChild("R")
			for _, light in SectionChildren do
				if light.Name == "Y" then
					SetSectionEnabled(light, true)
					task.delay(YellowTime, function()
						SetSectionEnabled(light, false)
						if Red then
							SetSectionEnabled(Red, true)
						end
					end)
				else
					SetSectionEnabled(light, false)
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
			local RedSection = lightModel:FindFirstChild("Sections"):FindFirstChild("R")
			for phaseNumber in string.gmatch(PhaseList, "%d+") do
				local ActualNumber = tonumber(phaseNumber) :: number

				if not CachedPhases[ActualNumber] then
					table.insert(CachedPhases, ActualNumber, {
						PhaseTime = if phaseTimes then phaseTimes[ActualNumber] else DefaultPhaseTime,
						Objects = {},
					})
				end

				SetSectionEnabled(RedSection, true)
				table.insert(CachedPhases[ActualNumber].Objects, lightModel)
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
					SetIntersectionLight(object :: Model, false, CurrentPhase)
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