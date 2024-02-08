export type PhaseTypes = "Single" | "Arrow" | "SingleWithArrow"

local PhaseTranslation = require(script.Parent.PhaseTranslation)
local Defaults = require(script.Parent.Defaults)
local Blinker = require(script.Parent.Blinker)

local YellowLightNames = {"YT", "Y", "R"}
local UniquePhaseTypes = {
	A = "Arrow",
	SWA = "SingleWithArrow",
	B = "Blink",
}

local function SetSectionEnabled(section: any, enabled: boolean)
	if section.Name:find("B") then
		if enabled then
			table.insert(Blinker, section)
		else
			table.remove(Blinker, table.find(Blinker, section))
		end
	end

	section.Transparency = if enabled then 0 else 0.95
	section.Light.Enabled = enabled
end

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
	if CurrentPhaseIndex and OrderedPhaseList[CurrentPhaseIndex + 1] then
		return OrderedPhaseList[CurrentPhaseIndex + 1]
	else
		return 1
	end
end

local function GetPhaseResult(phaseList: string, currentPhase: number): PhaseTypes
	for formatter, result in UniquePhaseTypes :: any do
		if phaseList:find(`{currentPhase}{formatter}`) then
			return result
		end
	end
	return "Single"
end

local PlayPhaseFunctions = {
	R = function(light: Part, phaseResult: PhaseTypes, nextPhase: PhaseTypes)
		if table.find(YellowLightNames, light.Name) then
			if light.Name == "Y" and phaseResult ~= "Arrow" then
				SetSectionEnabled(light, true)
			elseif light.Name == "YT" and phaseResult:find("Arrow") then
				SetSectionEnabled(light, true)
			end
	
			task.delay(Defaults.YellowTime, function()
				SetSectionEnabled(light, false)
				if light.Name == "R" then
					SetSectionEnabled(light, true)
				end
			end)
		end
	end,

	G = function(sections: Folder, phaseResult: PhaseTypes)
		for name, enabled in PhaseTranslation[phaseResult] do
			local Child = sections:FindFirstChild(name)
			if Child and Child.Name == name then
				SetSectionEnabled(Child, enabled)
			end
		end
	end,
}

local function PlayPhase(phaseType: "R" | "G", ...: any)
	local SelectedFunction = PlayPhaseFunctions[phaseType]

	if not SelectedFunction then
		warn(phaseType, "is not a valid phase type")
		return
	end

	SelectedFunction(...)
end

return {
    GetOrderedPhases = GetOrderedPhases,
	GetNextPhaseNumber = GetNextPhaseNumber,
	GetPhaseResult = GetPhaseResult,
	SetSectionEnabled = SetSectionEnabled,
	PlayPhase = PlayPhase,
}