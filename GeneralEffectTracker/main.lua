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
	hashedAbilityIDs = { --abilityIDs are keys

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
	durationControl:SetText("")
	
	stackControl:SetHidden(settingsTable.textSettings.stacks.hidden)
	stackControl:SetColor(settingsTable.textSettings.stacks.color.r, settingsTable.textSettings.stacks.color.g, settingsTable.textSettings.stacks.color.b, settingsTable.textSettings.stacks.color.a)
	stackControl:SetScale(settingsTable.textSettings.stacks.textScale)
	stackControl:ClearAnchors()
	stackControl:SetAnchor(TOPRIGHT, simpleDurationControl, TOPRIGHT, settingsTable.textSettings.stacks.x - 5, settingsTable.textSettings.stacks.y)
	stackControl:SetText("")

	if settingsTable.overrideTexturePath == "" then
		textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
	else
		textureControl:SetTexture(settingsTable.overrideTexture)
	end

	--check for current active effects.
	if DoesUnitExist(unitTag) then
		for i = 1, GetNumBuffs(unitTag) do
			local _, _, endTime, _, stacks, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i)
			if settingsTable.hashedAbilityIDs[abilityId] then
				endTime = endTime*1000
				if stacks == 0 then stacks = "" end
				stackControl:SetText(stacks)
				if settingsTable.overrideTexturePath == "" then
					textureControl:SetTexture(GetAbilityIcon(abilityId))
				else
					textureControl:SetTexture(settingsTable.overrideTexture)
				end
				if not IsAbilityPermanent(abilityId) then
					EVENT_MANAGER:RegisterForUpdate(GET.name..settingsTable.control:GetName(), 100, function()
						local duration = (endTime-GetGameTimeMilliseconds())/1000
						if duration < 0 then
							--Effect Expired
							if settingsTable.overrideTexturePath == "" then
								textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
							else
								textureControl:SetTexture(settingsTable.overrideTexture)
							end
							durationControl:SetText("")
							stackControl:SetText("")
							EVENT_MANAGER:UnregisterForUpdate(GET.name..settingsTable.control:GetName())
						else
							if duration < 2 then
								durationControl:SetText(zo_roundToNearest(duration, 0.1))

							else
								durationControl:SetText(zo_roundToZero(duration))
							end
						end
					end)
				end
				break
			end
		end
	end

	if unitTag == "reticleover" then
		EVENT_MANAGER:RegisterForEvent(GET.name..settingsTable.control:GetName(), EVENT_RETICLE_TARGET_CHANGED, function()
			if DoesUnitExist(unitTag) then
				for i = 1, GetNumBuffs(unitTag) do
					local _, s, endTime, _, stacks, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i)
					if settingsTable.hashedAbilityIDs[abilityId] then
						endTime = endTime*1000
						if stacks == 0 then stacks = "" end
						stackControl:SetText(stacks)
						if settingsTable.overrideTexturePath == "" then
							textureControl:SetTexture(GetAbilityIcon(abilityId))
						else
							textureControl:SetTexture(settingsTable.overrideTexture)
						end
						if not IsAbilityPermanent(abilityId) then
							EVENT_MANAGER:RegisterForUpdate(GET.name..settingsTable.control:GetName(), 100, function()
								local duration = (endTime-GetGameTimeMilliseconds())/1000
								if duration < 0 then
									--Effect Expired
									if settingsTable.overrideTexturePath == "" then
										textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
									else
										textureControl:SetTexture(settingsTable.overrideTexture)
									end
									durationControl:SetText("")
									stackControl:SetText("")
									EVENT_MANAGER:UnregisterForUpdate(GET.name..settingsTable.control:GetName())
								else
									if duration < 2 then
										durationControl:SetText(zo_roundToNearest(duration, 0.1))

									else
										durationControl:SetText(zo_roundToZero(duration))
									end
								end
							end)
						end
						return
					end
				end
				--target doesn't have an effect.
				if settingsTable.overrideTexturePath == "" then
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
				else
					textureControl:SetTexture(settingsTable.overrideTexture)
				end
				durationControl:SetText("")
				stackControl:SetText("")
				EVENT_MANAGER:UnregisterForUpdate(GET.name..settingsTable.control:GetName())
			end
		end)
	else
		-- todo: EVENT_COMBAT_EVENT. - can't track reticleover unittag accurately for it, but I don't think it will matter much.
	end

	EVENT_MANAGER:RegisterForEvent(GET.name..settingsTable.control:GetName(), EVENT_EFFECT_CHANGED, function( _, changeType, _, _, tag, startTime, endTime, stackCount, _, _, _, _, _, _, _, abilityID, _)
		if settingsTable.hashedAbilityIDs[abilityID] then
			if stackCount == 0 then stackCount = "" end
			stackControl:SetText(stackCount)
			if settingsTable.overrideTexturePath == "" then
				textureControl:SetTexture(GetAbilityIcon(abilityID))
			else
				textureControl:SetTexture(settingsTable.overrideTexture)
			end
			if changeType ~= EFFECT_RESULT_FADED and not IsAbilityPermanent(abilityID) then
				endTime = endTime * 1000
				EVENT_MANAGER:RegisterForUpdate(GET.name..settingsTable.control:GetName(), 100, function()
					local duration = (endTime-GetGameTimeMilliseconds())/1000
					if duration < 0 then
						--Effect Expired
						if settingsTable.overrideTexturePath == "" then
							textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
						else
							textureControl:SetTexture(settingsTable.overrideTexture)
						end
						durationControl:SetText("")
						stackControl:SetText("")
						EVENT_MANAGER:UnregisterForUpdate(GET.name..settingsTable.control:GetName())
					else
						if duration < 2 then
							durationControl:SetText(zo_roundToNearest(duration, 0.1))
						else
							durationControl:SetText(zo_roundToZero(duration))
						end
					end
				end)
			elseif changeType == EFFECT_RESULT_FADED and IsAbilityPermanent(abilityID) then
				if settingsTable.overrideTexturePath == "" then
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
				else
					textureControl:SetTexture(settingsTable.overrideTexture)
				end
				durationControl:SetText("")
				stackControl:SetText("")
			end
		end
	end)
	EVENT_MANAGER:AddFilterForEvent(GET.name..settingsTable.control:GetName(), EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, unitTag)

	return settingsTable.control, settingsTable.controlKey
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

	settingsTable.control:ClearAnchors()
	settingsTable.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
	settingsTable.control:SetScale(settingsTable.scale)

	local textureControl = settingsTable.control:GetNamedChild("Texture")
	local barControl = settingsTable.control:GetNamedChild("Bar")
	local labelControl = barControl:GetNamedChild("Label")
	local durationControl = barControl:GetNamedChild("Duration")

	for i = 1, settingsTable.animation:GetNumAnimations() do
		settingsTable.animation:GetAnimation(i):SetAnimatedControl(barControl)
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
	durationControl:SetText("0")

	if settingsTable.textSettings.label.labelType == "Ability Name" or not DoesUnitExist(unitTag) then
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
	if DoesUnitExist(unitTag) then
		for i = 1, GetNumBuffs(unitTag) do
			local _, startTime, endTime, _, _, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i) 
			if settingsTable.hashedAbilityIDs[abilityId] then
				textureControl:SetTexture(GetAbilityIcon(abilityId))
				if settingsTable.textSettings.label.labelType == "Ability Name" or not DoesUnitExist(unitTag) then
					labelControl:SetText(GetAbilityName(abilityId))
				elseif settingsTable.textSettings.label.labelType == "Unit Name" then
					labelControl:SetText(GetUnitName(unitTag))
				end
				for j = 1, animation:GetNumAnimations() do 
					settingsTable.animation:GetAnimation(j):SetDuration((endTime - startTime)*1000)
				end
				settingsTable.animation:PlayFromStart(GetGameTimeMilliseconds()-startTime*1000)
				break
			end
		end
	end

	if unitTag == "reticleover" then
		EVENT_MANAGER:RegisterForEvent(GET.name..settingsTable.control:GetName(), EVENT_RETICLE_TARGET_CHANGED, function()
			if DoesUnitExist(unitTag) then
				for i = 1, GetNumBuffs(unitTag) do
					local _, startTime, endTime, _, _, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i) 
					if settingsTable.hashedAbilityIDs[abilityId] then
						textureControl:SetTexture(GetAbilityIcon(abilityId))
						if settingsTable.textSettings.label.labelType == "Ability Name" then
							labelControl:SetText(GetAbilityName(abilityId))
						elseif settingsTable.textSettings.label.labelType == "Unit Name" then
							labelControl:SetText(GetUnitName(unitTag))
						end
						for j = 1, settingsTable.animation:GetNumAnimations() do 
							settingsTable.animation:GetAnimation(j):SetDuration((endTime - startTime)*1000)
						end
						settingsTable.animation:PlayFromStart(GetGameTimeMilliseconds()-startTime*1000)
						return
					end
				end

				--New target doesn't have the effect.
				if settingsTable.overrideTexturePath == "" then
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
				else
					textureControl:SetTexture(settingsTable.overrideTexture)
				end
				if settingsTable.textSettings.label.labelType == "Ability Name" then
					labelControl:SetText(GetAbilityName(settingsTable.abilityIDs[0]))
				elseif settingsTable.textSettings.label.labelType == "Unit Name" then
					labelControl:SetText(GetUnitName(unitTag))
				end
				settingsTable.animation:PlayInstantlyToEnd()
			end
		end)
	else
		-- todo: EVENT_COMBAT_EVENT. - can't track reticleover unittag accurately for it, but I don't think it will matter much.
		-- player unitid on initialization
		-- group unitid on group changes
		-- boss unitid on boss changes
	end

	EVENT_MANAGER:RegisterForEvent(GET.name.. settingsTable.control:GetName(), EVENT_EFFECT_CHANGED, function(_, changeType, effectSlot, _, tag, startTime, endTime, _, _, _, _, _, _, _, _, abilityID, _) 
		if changeType ~= EFFECT_RESULT_FADED and settingsTable.hashedAbilityIDs[abilityID] then
			textureControl:SetTexture(GetAbilityIcon(abilityID))
			if settingsTable.textSettings.label.labelType == "Ability Name" then
				labelControl:SetText(GetAbilityName(abilityID))
			elseif settingsTable.textSettings.label.labelType == "Unit Name" then
				labelControl:SetText(GetUnitName(unitTag))
			end
			for i = 1, settingsTable.animation:GetNumAnimations() do 
				settingsTable.animation:GetAnimation(i):SetDuration((endTime - startTime)*1000)
			end
			settingsTable.animation:PlayFromStart(GetGameTimeMilliseconds()-startTime*1000)
		end
	end)
	EVENT_MANAGER:AddFilterForEvent(GET.name.. settingsTable.control:GetName(), EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, unitTag)

	return settingsTable.control, settingsTable.controlKey, settingsTable.animation, settingsTable.animationKey
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
	elseif unitTag == "boss" or unitTag == "group" then
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
			EVENT_MANAGER:AddFilterForEvent(GET.name..settingsTable.name..settingsTable.type..settingsTable.targetType, EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
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
			EVENT_MANAGER:UnregisterForEvent(GET.name..control:GetName(), EVENT_COMBAT_EVENT)
			EVENT_MANAGER:UnregisterForUpdate(GET.name..control:GetName())
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
			EVENT_MANAGER:UnregisterForEvent(GET.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(GET.name..control:GetName(), EVENT_EFFECT_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(GET.name..control:GetName(), EVENT_COMBAT_EVENT)
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