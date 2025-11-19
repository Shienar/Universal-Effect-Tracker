GET = GET or {}
GET.name = "GeneralEffectTracker"

GET.defaults = {
    trackerList = {
        {

		},
    }
}
--[[
local newTracker = {
	control = nil,
	animation = nil,
	name = "",
	type = "Simple",
	targetType = "Player",
	textSettings = {
		showStacks = true,
		showDuration = true,
		duration = {
			color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
			textScale = 1,
			x = 0,
			y = 0,
			hidden = false,
		},
		stacks = {
			color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
			textScale = 1,
			x = -5,
			y = 0,
			hidden = false,
		}
	},
	abilityIDs = {
		[0] = "",
	},
	overrideTexturePath = "",
	x = 0,
	y = 0,
	scale = 1,
}
]]

function GET.InitSingleDisplay(settingsTable)

	local unitTag = nil
	if settingsTable.targetType == "Player" then
		unitTag = "player"
	elseif settingsTable.targetType == "Reticle Target" then
		unitTag = "reticleover"
	elseif settingsTable.targetType == "Boss" then
		unitTag = {"boss1","boss2","boss3","boss4","boss5","boss6","boss7","boss8","boss9","boss10","boss11","boss12",}
	elseif settingsTable.targetType == "Group" then
		unitTag = {"group1","group2","group3","group4","group5","group6","group7","group8","group9","group10","group11","group12",}
	end

	if type(unitTag) == "string" then
		if settingsTable.type == "Simple" then
			--Create controls and assign default values

			local simpleDurationControl =settingsTable.control
			if not simpleDurationControl then
				simpleDurationControl = CreateControlFromVirtual(settingsTable.name, GuiRoot, "SingleSimpleTracker", "SingleSimple")
				settingsTable.control = simpleDurationControl
			end
			simpleDurationControl:ClearAnchors()
			simpleDurationControl:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
			simpleDurationControl:SetScale(settingsTable.scale)
			local textureControl = simpleDurationControl:GetNamedChild("Texture")
			local labelControl = simpleDurationControl:GetNamedChild("Label")
			local stackControl = simpleDurationControl:GetNamedChild("Stacks")

			labelControl:SetHidden(settingsTable.textSettings.duration.hidden)
			labelControl:SetColor(settingsTable.textSettings.duration.color.r, settingsTable.textSettings.duration.color.g, settingsTable.textSettings.duration.color.b, settingsTable.textSettings.duration.color.a)
			labelControl:SetScale(settingsTable.textSettings.duration.textScale)
			labelControl:ClearAnchors()
			labelControl:SetAnchor(CENTER, simpleDurationControl, CENTER, settingsTable.textSettings.duration.x, settingsTable.textSettings.duration.y)
			
			labelControl:SetHidden(settingsTable.textSettings.duration.hidden)
			stackControl:SetColor(settingsTable.textSettings.stacks.color.r, settingsTable.textSettings.stacks.color.g, settingsTable.textSettings.stacks.color.b, settingsTable.textSettings.stacks.color.a)
			stackControl:SetScale(settingsTable.textSettings.stacks.textScale)
			stackControl:ClearAnchors()
			stackControl:SetAnchor(TOPRIGHT, simpleDurationControl, TOPRIGHT, settingsTable.textSettings.stacks.x - 5, settingsTable.textSettings.stacks.y)

			if settingsTable.overrideTexturePath == "" then
				textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
			else
				textureControl:SetTexture(settingsTable.overrideTexture)
			end

			EVENT_MANAGER:RegisterForUpdate(GET.name..simpleDurationControl:GetName(), 100, function()
				if DoesUnitExist(unitTag) then
					local buffList = {}
					for i = 1, GetNumBuffs(unitTag) do
						local _, _, endTime, _, stacks, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i) 
						buffList[tostring(abilityId)] = {endTime=endTime, stacks=stacks}
					end
					for k, v in pairs(settingsTable.abilityIDs) do
						if buffList[v] then
							local time = zo_roundToZero(((1000*buffList[v].endTime)-GetGameTimeMilliseconds())/1000)
							if time < 0 then time = "" end --permanent effects
							labelControl:SetText(time)
							stackControl:SetText(buffList[v].stacks)
							if settingsTable.overrideTexturePath == "" then
								textureControl:SetTexture(GetAbilityIcon(v))
							end
							return
						end
					end
					--No active effects
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
					labelControl:SetText("")
					stackControl:SetText("")
				end
			end)

		elseif settingsTable.type == "Bar" then
			--Status bar control
			--[[
				/script simpleBarControl = CreateControlFromVirtual("Example", GuiRoot, "SingleBarDuration", "SingleBar")
				/script animation = GetAnimationManager():CreateTimelineFromVirtual("SingleBarAnimation", simpleBarControl:GetNamedChild("Bar"))
				/script for i = 1, animation:GetNumAnimations() do animation:GetAnimation(i):SetDuration(10000) end
				/script animation:PlayFromStart()
			]]
		end
	else
		if settingsTable.type == "Simple" then

		elseif settingsTable.type == "Bar" then
			--Status bar control
		end
	end
end

function GET.Initialize()
	GET.savedVariables = ZO_SavedVars:NewAccountWide("GETSavedVariables", 1, nil, GET.defaults, GetWorldName())

    GET.InitSettings()

	for k, v in pairs(GET.savedVariables.trackerList) do
		GET.InitSingleDisplay(v)
	end

end

function GET.OnAddOnLoaded(event, addonName)
	if addonName == GET.name then
		GET.Initialize()
		EVENT_MANAGER:UnregisterForEvent(GET.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(GET.name, EVENT_ADD_ON_LOADED, GET.OnAddOnLoaded)