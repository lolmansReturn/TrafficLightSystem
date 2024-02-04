--!strict
-- Copyright (c) 2024 lolmansReturn

export type PhaseTypes = "Single" | "Arrow" | "SingleWithArrow"

local Packages = game:GetService("ReplicatedStorage").Packages
local Clock = require(Packages.Clock)

local PhaseResults = {
	A = "Arrow",
	B = "SingleWithArrow",
	C = "Blink",
}

local PatternsToSections = {
	Single = {
		R = false,
		G = true,
		GP = true,
		GT = false,
	},
	Arrow = {
		R = true,
		GT = true,
	},
	SingleWithArrow = {
		R = false,
		G = true,
		GT = true,
	},
	Blink = {
		R = false,
		G = false,
		YB = true,
	}
}

local SectionsToBlink = {}

local YellowTime = 3
local DefaultPhaseTime = 5

local function SetSectionEnabled(section: any, enabled: boolean, blink: boolean?)
	if blink then
		if enabled then
			table.insert(SectionsToBlink, section)
		else
			table.remove(
				SectionsToBlink, table.find(SectionsToBlink, section)
			)
		end
	end

	section.Transparency = if enabled then 0 else 0.95
	section.Light.Enabled = enabled
end

local function GetPhaseResult(phaseList: string, currentPhase: number): PhaseTypes
	if not phaseList:find(tostring(currentPhase)) then
		currentPhase = 1
	end

	for formatter, result in PhaseResults :: any do
		if phaseList:find(`{currentPhase}{formatter}`) then
			return result
		end
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
					SetSectionEnabled(Child, enabled, if Child.Name == "YB" then true else false)
				end
			end
		else
			local SectionChildren = Sections:GetChildren()

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

Clock(1, function()
	for _, section in SectionsToBlink :: {any} do
		local Enabled = section.Light.Enabled
		section.Transparency = if Enabled then 0 else 0.95
		section.Light.Enabled = not Enabled
	end
end)

return {
	RegisterIntersection = RegisterIntersection
}