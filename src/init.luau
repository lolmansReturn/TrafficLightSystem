--!strict
-- Copyright (c) 2024 lolmansReturn

export type PhaseTypes = "Single" | "Arrow" | "SingleWithArrow"

local Packages = game:GetService("ReplicatedStorage").Packages
local Clock = require(Packages.Clock)

local YellowLightNames = {
	"YT",
	"Y",
}

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
		RB = true,
	}
}

local SectionsToBlink = {}

local YellowTime = 3
local DefaultPhaseTime = 12

local function GetOrderedPhases(phaseList: string): {number}
	local CleanedPhases = {}
	for _, phase in phaseList:split(",") do
		table.insert(CleanedPhases, tonumber(phase:gsub("%a+", ""), nil) :: number)
	end
	return CleanedPhases
end

local function GetNextPhaseNumber(phaseList: string, currentPhase: number): number
	local OrderedPhaseList = GetOrderedPhases(phaseList)
	local CurrentPhaseIndex = table.find(OrderedPhaseList, currentPhase)
	if CurrentPhaseIndex then
		return OrderedPhaseList[CurrentPhaseIndex + 1]
	else
		return 1
	end
end

local function SetSectionEnabled(section: any, enabled: boolean)
	if section.Name:find("B") then
		if enabled then
			table.insert(SectionsToBlink, section)
		else
			table.remove(SectionsToBlink, table.find(SectionsToBlink, section))
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

local function SetIntersectionLight(lightModel: Model, enabled: boolean, currentPhase: number, inNextPhase: boolean?)
	local Sections = lightModel:FindFirstChild("Sections")
	local PhaseList = lightModel:GetAttribute("Phases")

	if Sections then
		local PhaseResult = GetPhaseResult(PhaseList, currentPhase)
		lightModel:SetAttribute("NextInstruction", GetPhaseResult(PhaseList, GetNextPhaseNumber(PhaseList, currentPhase)))

		if not enabled and inNextPhase and lightModel:GetAttribute("NextInstruction"):find(PhaseResult) then
			return
		end

		if enabled then
			for name, enabled in PatternsToSections[PhaseResult] do
				local Child = Sections:FindFirstChild(name)
				if Child and Child.Name == name then
					SetSectionEnabled(Child, enabled)
				end
			end
		else
			local Red = Sections:FindFirstChild("R")
			for _, light in Sections:GetChildren() do
				if table.find(YellowLightNames, light.Name) and Red then
					if light.Name == "Y" and PhaseResult ~= "Arrow" then
						SetSectionEnabled(light, true)
					elseif light.Name == "YT" and PhaseResult:find("Arrow") then
						SetSectionEnabled(light, true)
					end
					
					task.delay(YellowTime, function()
						SetSectionEnabled(light, false)
						SetSectionEnabled(Red, true)
					end)
				else
					if light.Name == "R" and PhaseResult == "Arrow" then
						continue
					end
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
			local RedSection = lightModel:WaitForChild("Sections"):FindFirstChild("R")
			for phaseNumber in string.gmatch(PhaseList, "%d+") do
				local ActualNumber = tonumber(phaseNumber) :: number

				if not CachedPhases[ActualNumber] then
					CachedPhases[ActualNumber] = {
						PhaseTime = if phaseTimes then phaseTimes[ActualNumber] else DefaultPhaseTime,
						Objects = {},
					}
				end

				SetSectionEnabled(RedSection, true)
				table.insert(CachedPhases[ActualNumber].Objects, lightModel)
				lightModel:SetAttribute("NextInstruction", GetPhaseResult(PhaseList, 1))
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

Clock(0.5, function()
	for _, section in SectionsToBlink :: {any} do
		section.Light.Enabled = not section.Light.Enabled
		section.Transparency = if section.Light.Enabled then 0 else 0.95
	end
end)

return {
	RegisterIntersection = RegisterIntersection
}