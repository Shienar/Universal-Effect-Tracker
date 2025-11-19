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
		},
		label = {
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
			labelType = "Ability Name",
		},
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

	if settingsTable.control then 
		EVENT_MANAGER:UnregisterForEvent(GET.name..settingsTable.control:GetName(), EVENT_RETICLE_TARGET_CHANGED)
		EVENT_MANAGER:UnregisterForEvent(GET.name..settingsTable.control:GetName(), EVENT_EFFECT_CHANGED)
		EVENT_MANAGER:UnregisterForUpdate(GET.name..settingsTable.control:GetName())
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
			local durationControl = simpleDurationControl:GetNamedChild("Duration")
			local stackControl = simpleDurationControl:GetNamedChild("Stacks")

			durationControl:SetHidden(settingsTable.textSettings.duration.hidden)
			durationControl:SetColor(settingsTable.textSettings.duration.color.r, settingsTable.textSettings.duration.color.g, settingsTable.textSettings.duration.color.b, settingsTable.textSettings.duration.color.a)
			durationControl:SetScale(settingsTable.textSettings.duration.textScale)
			durationControl:ClearAnchors()
			durationControl:SetAnchor(CENTER, simpleDurationControl, CENTER, settingsTable.textSettings.duration.x, settingsTable.textSettings.duration.y)
			
			stackControl:SetHidden(settingsTable.textSettings.stacks.hidden)
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
							durationControl:SetText(time)
							stackControl:SetText(buffList[v].stacks)
							if settingsTable.overrideTexturePath == "" then
								textureControl:SetTexture(GetAbilityIcon(v))
							end
							return
						end
					end
					--No active effects
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
					durationControl:SetText("")
					stackControl:SetText("")
				end
			end)

		elseif settingsTable.type == "Bar" then
			--Status bar control

			local topLevelControl = settingsTable.control
			local animation = settingsTable.animation
			if not topLevelControl then
				topLevelControl = CreateControlFromVirtual(settingsTable.name, GuiRoot, "SingleBarDuration", "SingleBar")
				settingsTable.control = topLevelControl
				animation = GetAnimationManager():CreateTimelineFromVirtual("SingleBarAnimation", topLevelControl:GetNamedChild("Bar"))
				settingsTable.animation = animation
			end
			topLevelControl:ClearAnchors()
			topLevelControl:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
			topLevelControl:SetScale(settingsTable.scale)

			local textureControl = topLevelControl:GetNamedChild("Texture")
			local barControl = topLevelControl:GetNamedChild("Bar")
			local labelControl = barControl:GetNamedChild("Label")
			local durationControl = barControl:GetNamedChild("Duration")


			durationControl:SetHidden(settingsTable.textSettings.duration.hidden)
			durationControl:SetColor(settingsTable.textSettings.duration.color.r, settingsTable.textSettings.duration.color.g, settingsTable.textSettings.duration.color.b, settingsTable.textSettings.duration.color.a)
			durationControl:SetScale(settingsTable.textSettings.duration.textScale)
			durationControl:ClearAnchors()
			durationControl:SetAnchor(RIGHT, barControl:GetNamedChild("Background"), RIGHT, settingsTable.textSettings.duration.x, settingsTable.textSettings.duration.y)

			labelControl:SetHidden(settingsTable.textSettings.label.hidden)
			labelControl:SetColor(settingsTable.textSettings.label.color.r, settingsTable.textSettings.label.color.g, settingsTable.textSettings.label.color.b, settingsTable.textSettings.label.color.a)
			labelControl:SetScale(settingsTable.textSettings.label.textScale)
			labelControl:ClearAnchors()
			labelControl:SetAnchor(LEFT, barControl:GetNamedChild("Background"), LEFT, settingsTable.textSettings.label.x, settingsTable.textSettings.label.y)

			barControl:SetValue(0)
			durationControl:SetText(0)

			if settingsTable.textSettings.label.labelType == "Ability Name" then
				labelControl:SetText(GetAbilityName(settingsTable.abilityIDs[0]))
			elseif settingsTable.textSettings.label.labelType == "Unit Name" then
				labelControl:SetText(GetUnitName(unitTag))
			end

			if settingsTable.overrideTexturePath == "" then
				textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
			else
				textureControl:SetTexture(settingsTable.overrideTexture)
			end

			if unitTag == "reticleover" then
				EVENT_MANAGER:RegisterForEvent(GET.name..topLevelControl:GetName(), EVENT_RETICLE_TARGET_CHANGED, function()
					if DoesUnitExist(unitTag) then
						local buffList = {}
						for i = 1, GetNumBuffs(unitTag) do
							local _, s, e, _, stacks, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i) 
							buffList[tostring(abilityId)] = {endTime=e, startTime = s}
						end
						for k, v in pairs(settingsTable.abilityIDs) do
							if buffList[v] then
								textureControl:SetTexture(GetAbilityIcon(v))
								if settingsTable.textSettings.label.labelType == "Ability Name" then
									labelControl:SetText(GetAbilityName(v))
								elseif settingsTable.textSettings.label.labelType == "Unit Name" then
									labelControl:SetText(GetUnitName(unitTag))
								end
								for i = 1, animation:GetNumAnimations() do 
									animation:GetAnimation(i):SetDuration((buffList[v].endTime - buffList[v].startTime)*1000)
								end
								animation:PlayFromStart(GetGameTimeMilliseconds()-buffList[v].startTime*1000)
								return
							end
						end

						
						textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
						if settingsTable.textSettings.label.labelType == "Ability Name" then
							labelControl:SetText(GetAbilityName(settingsTable.abilityIDs[0]))
						elseif settingsTable.textSettings.label.labelType == "Unit Name" then
							labelControl:SetText(GetUnitName(unitTag))
						end
						animation:PlayInstantlyToEnd()
					end
				end)
			end
			EVENT_MANAGER:RegisterForEvent(GET.name.. topLevelControl:GetName(), EVENT_EFFECT_CHANGED, function(_, changeType, effectSlot, _, tag, startTime, endTime, _, _, _, _, _, _, _, _, abilityID, _) 
				if changeType == EFFECT_RESULT_GAINED and tag == unitTag then
					--constructor start/end times aren't reliable.
					local buffList = {}
					for i = 1, GetNumBuffs(unitTag) do
						local _, s, e, _, stacks, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i) 
						buffList[tostring(abilityId)] = {endTime=e, startTime = s}
					end
					for k, v in pairs(settingsTable.abilityIDs) do
						if buffList[v] then
							textureControl:SetTexture(GetAbilityIcon(v))
							if settingsTable.textSettings.label.labelType == "Ability Name" then
								labelControl:SetText(GetAbilityName(settingsTable.abilityIDs[0]))
							elseif settingsTable.textSettings.label.labelType == "Unit Name" then
								labelControl:SetText(GetUnitName(unitTag))
							end
							for i = 1, animation:GetNumAnimations() do 
								animation:GetAnimation(i):SetDuration((buffList[v].endTime - buffList[v].startTime)*1000)
							end
							animation:PlayFromStart(GetGameTimeMilliseconds()-buffList[v].startTime*1000)
							return
						end
					end
				end
			end)
		end
	else
		if settingsTable.type == "Simple" then

		elseif settingsTable.type == "Bar" then
			--Status bar control
		end
	end
end

local function fragmentChange(oldState, newState)
	if newState == SCENE_FRAGMENT_SHOWN then
		--unhide everything.
		for k, v in pairs(GET.savedVariables.trackerList) do
			if v.control then
				v.control:SetHidden(false)
			end
		end
	elseif newState == SCENE_FRAGMENT_HIDDEN then
		--hide everything.
		for k, v in pairs(GET.savedVariables.trackerList) do
			if v.control then
				v.control:SetHidden(true)
			end
		end
	end
end

function GET.Initialize()
	GET.savedVariables = ZO_SavedVars:NewAccountWide("GETSavedVariables", 1, nil, GET.defaults, GetWorldName())

    GET.InitSettings()

	for k, v in pairs(GET.savedVariables.trackerList) do
		GET.InitSingleDisplay(v)
	end

	HUD_FRAGMENT:RegisterCallback("StateChange", fragmentChange)

end

function GET.OnAddOnLoaded(event, addonName)
	if addonName == GET.name then
		GET.Initialize()
		EVENT_MANAGER:UnregisterForEvent(GET.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(GET.name, EVENT_ADD_ON_LOADED, GET.OnAddOnLoaded)