GET = GET or {}
GET.name = "GeneralEffectTracker"

GET.defaults = {
}
--[[
local newTracker = {
	control = nil,
	controlKey = nil,
	animation = nil,
	animationKey = nil,
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

local function InitSimple(settingsTable, unitTag)
	--Create controls and assign default values

	if not settingsTable.control then
		settingsTable.control, settingsTable.controlKey = GET.simplePool:AcquireObject()
	elseif string.find(settingsTable.control:GetName(), "Bar") then
		GET.barAnimationPool:ReleaseObject(settingsTable.animationKey)
		GET.barPool:ReleaseObject(settingsTable.controlKey)
		settingsTable.control, settingsTable.controlKey = GET.simplePool:AcquireObject()
	end

	settingsTable.control:ClearAnchors()
	settingsTable.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
	settingsTable.control:SetScale(settingsTable.scale)
	local textureControl = settingsTable.control:GetNamedChild("Texture")
	local durationControl = settingsTable.control:GetNamedChild("Duration")
	local stackControl = settingsTable.control:GetNamedChild("Stacks")

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

	EVENT_MANAGER:RegisterForUpdate(GET.name..settingsTable.control:GetName(), 100, function()
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

	return settingsTable.control
end

local function InitBar(settingsTable, unitTag)
	if not settingsTable.control then
		settingsTable.control, settingsTable.controlKey = GET.barPool:AcquireObject()
		settingsTable.animation, settingsTable.animationKey = GET.barAnimationPool:AcquireObject()
	elseif string.find(settingsTable.control:GetName(), "Simple") then
		GET.simplePool:ReleaseObject(settingsTable.controlKey)
		settingsTable.control, settingsTable.controlKey = GET.barPool:AcquireObject()
		settingsTable.animation, settingsTable.animationKey = GET.barAnimationPool:AcquireObject()
	end

	local topLevelControl = settingsTable.control
	local animation = settingsTable.animation
	topLevelControl:ClearAnchors()
	topLevelControl:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
	topLevelControl:SetScale(settingsTable.scale)

	local textureControl = topLevelControl:GetNamedChild("Texture")
	local barControl = topLevelControl:GetNamedChild("Bar")
	local labelControl = barControl:GetNamedChild("Label")
	local durationControl = barControl:GetNamedChild("Duration")

	for i = 1, animation:GetNumAnimations() do
		animation:GetAnimation(i):SetAnimatedControl(barControl)
	end

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

	-- Start the animation if event has already passed.
	local buffList = {}
	for i = 1, GetNumBuffs(unitTag) do
		local _, s, e, _, _, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i) 
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
		if changeType == EFFECT_RESULT_GAINED then
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
	EVENT_MANAGER:AddFilterForEvent(GET.name.. topLevelControl:GetName(), EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, unitTag)

	return settingsTable.control
end

function GET.InitSingleDisplay(settingsTable)

	local unitTag = nil
	if settingsTable.targetType == "Player" then
		unitTag = "player"
	elseif settingsTable.targetType == "Reticle Target" then
		unitTag = "reticleover"
	elseif settingsTable.targetType == "Boss" then
		unitTag = "boss"
	elseif settingsTable.targetType == "Group" then
		unitTag = "group"
	end

	if unitTag == "player" or unitTag == "reticleover" then
		if settingsTable.type == "Simple" then
			InitSimple(settingsTable, unitTag)
		elseif settingsTable.type == "Bar" then
			InitBar(settingsTable, unitTag)
		end
	elseif unitTag == "boss" or unitTag == "group"
		if settingsTable.type == "Simple" then
			-- If a group member gets a buff, assign them an object and store the key here.
			-- e.g group4 gets object 6 -> groupTrackers[4] = 6
			local groupTrackerKeyMapping = {}

			-- Append new object keys; remove released keys. Maintain ordering and display in this order.
			local heldKeys = {}

			EVENT_MANAGER:RegisterForEvent(GET.name..settingsTable.name..settingsTable.type..settingsTable.targetType, EVENT_EFFECT_CHANGED, function()
				if changeType == EFFECT_RESULT_GAINED then
					--constructor start/end times aren't reliable.
					local buffList = {}
					for i = 1, GetNumBuffs(unitTag) do
						local _, s, e, _, _, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i) 
						buffList[tostring(abilityId)] = {endTime=e, startTime = s}
					end
					for k, v in pairs(settingsTable.abilityIDs) do
						if buffList[v] then
							--create control. settingsTable.controls becomes table I guess. Maybe create a top level control to anchor them in?
						end
					end
				elseif changeType == EFFECT_RESULT_FADED then
					--check for other effects
					--release control if not
				end
			end)
			EVENT_MANAGER:AddFilterForEvent(GET.name.. topLevelControl:GetName(), EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
		elseif settingsTable.type == "Bar" then
			
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

    GET.barPool = ZO_ControlPool:New("SingleBarDuration", GuiRoot)
    GET.barPool:SetResetFunction(function(control)
			control:SetHidden(true)
			EVENT_MANAGER:UnregisterForEvent(GET.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(GET.name..control:GetName(), EVENT_EFFECT_CHANGED)
	end)
	GET.barPool:SetCustomResetBehavior(function(control)
		for k, v  in pairs(GET.savedVariables.trackerList) do
			if v.control == control then
				v.control = nil
				v.controlKey = nil
				break
			end
		end
	end)

	GET.barAnimationPool = ZO_AnimationPool:New("SingleBarAnimation")
	GET.barAnimationPool:SetCustomResetBehavior(function(animation)
		for k, v  in pairs(GET.savedVariables.trackerList) do
			if v.animation == animation then
				v.animation = nil
				v.animationKey = nil
				break
			end
		end
	end)

	GET.simplePool = ZO_ControlPool:New("SingleSimpleTracker", GuiRoot)
    GET.simplePool:SetResetFunction(function(control)
			control:SetHidden(true)
			EVENT_MANAGER:UnregisterForUpdate(GET.name..control:GetName())
	end)
	GET.simplePool:SetCustomResetBehavior(function(control)
		for k, v  in pairs(GET.savedVariables.trackerList) do
			if v.control == control then
				v.control = nil
				v.controlKey = nil
				break
			end
		end
	end)


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