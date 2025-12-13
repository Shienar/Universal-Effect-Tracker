UniversalTracker = UniversalTracker or {}
UniversalTracker.name = "UniversalEffectTracker"

UniversalTracker.defaults = {
	nextID = 0,
	nextSetupID = 0,
	trackerList = {

	},
	setupList = {

	},
}

UniversalTracker.defaultsCharacter = {
	trackerList = {

	},
	setupList = {

	},
}

UniversalTracker.unitIDs = {
}
UniversalTracker.altPlayerTag = "" -- e.g. "group2" vs "player"

-- A tracker's userdata objects are stored in these tables at index [id], not in the saved variables.
UniversalTracker.Controls = {
}
UniversalTracker.Animations = {
}

local function InitCompact(settingsTable, unitTag, control)
	-- Assign values to created controls.

	control:ClearAnchors()
	control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
	control:SetScale(settingsTable.scale)
	control:SetHidden(settingsTable.hidden)
	local textureControl = control:GetNamedChild("Texture")
	local durationControl = control:GetNamedChild("Duration")
	local stackControl = control:GetNamedChild("Stacks")
	local unitNameControl = control:GetNamedChild("UnitName")

	durationControl:SetHidden(settingsTable.textSettings.duration.hidden)
	durationControl:SetColor(settingsTable.textSettings.duration.color.r, settingsTable.textSettings.duration.color.g, settingsTable.textSettings.duration.color.b, settingsTable.textSettings.duration.color.a)
	durationControl:SetScale(settingsTable.textSettings.duration.textScale)
	durationControl:ClearAnchors()
	durationControl:SetAnchor(CENTER, control, CENTER, settingsTable.textSettings.duration.x, settingsTable.textSettings.duration.y)
	durationControl:SetText("")
	
	stackControl:SetHidden(settingsTable.textSettings.stacks.hidden)
	stackControl:SetColor(settingsTable.textSettings.stacks.color.r, settingsTable.textSettings.stacks.color.g, settingsTable.textSettings.stacks.color.b, settingsTable.textSettings.stacks.color.a)
	stackControl:SetScale(settingsTable.textSettings.stacks.textScale)
	stackControl:ClearAnchors()
	stackControl:SetAnchor(TOPRIGHT, control, TOPRIGHT, settingsTable.textSettings.stacks.x - 5, settingsTable.textSettings.stacks.y)
	stackControl:SetText("")

	unitNameControl:SetHidden(settingsTable.textSettings.unitLabel.hidden)
	unitNameControl:SetColor(settingsTable.textSettings.unitLabel.color.r, settingsTable.textSettings.unitLabel.color.g, settingsTable.textSettings.unitLabel.color.b, settingsTable.textSettings.unitLabel.color.a)
	unitNameControl:SetScale(settingsTable.textSettings.unitLabel.textScale)
	unitNameControl:ClearAnchors()
	unitNameControl:SetAnchor(BOTTOM, control, TOP, settingsTable.textSettings.unitLabel.x, settingsTable.textSettings.unitLabel.y)
	if settingsTable.textSettings.unitLabel.accountName and GetUnitDisplayName(unitTag) ~= "" then
		unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitDisplayName(unitTag)))
	else
		unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag)))
	end

	if settingsTable.overrideTexturePath == "" then
		textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[1]))
	else
		textureControl:SetTexture(settingsTable.overrideTexturePath)
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
					textureControl:SetTexture(settingsTable.overrideTexturePath)
				end
				if not IsAbilityPermanent(abilityId) then
					EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name..control:GetName(), 100, function()
						local duration = (endTime-GetGameTimeMilliseconds())/1000
						if duration < 0 then
							--Effect Expired
							EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
							if settingsTable.overrideTexturePath == "" then
								textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[1]))
							else
								textureControl:SetTexture(settingsTable.overrideTexturePath)
							end
							durationControl:SetText("")
							stackControl:SetText("")
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
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED, function()
			if settingsTable.textSettings.unitLabel.accountName and GetUnitDisplayName(unitTag) ~= "" then
				unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitDisplayName(unitTag)))
			elseif GetUnitName(unitTag) ~= "" then
				unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag)))
			end
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
							textureControl:SetTexture(settingsTable.overrideTexturePath)
						end
						if not IsAbilityPermanent(abilityId) then
							EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name..control:GetName(), 100, function()
								local duration = (endTime-GetGameTimeMilliseconds())/1000
								if duration < 0 then
									--Effect Expired
									EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
									if settingsTable.overrideTexturePath == "" then
										textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[1]))
									else
										textureControl:SetTexture(settingsTable.overrideTexturePath)
									end
									durationControl:SetText("")
									stackControl:SetText("")
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
				EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
				if settingsTable.overrideTexturePath == "" then
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[1]))
				else
					textureControl:SetTexture(settingsTable.overrideTexturePath)
				end
				durationControl:SetText("")
				stackControl:SetText("")
			end
		end)
	else
		-- Track internal effects. (Thanks code65536 for making me aware of these)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..control:GetName(), EVENT_COMBAT_EVENT, function( _, result, _, _, _, _, _, _, _, _, hitValue, _, _, _, _, unitID, abilityID, _)
			if (unitTag == UniversalTracker.unitIDs[unitID] or 
				(unitTag == "player" and UniversalTracker.unitIDs[unitID] == UniversalTracker.altPlayerTag)) and
				settingsTable.hashedAbilityIDs[abilityID] then

				-- Only track effects not affected by event_effect_changed
				for i = 1, GetNumBuffs(unitTag) do
					local _, _, _, _, _, _, _, _, _, _, buffID, _, _ = GetUnitBuffInfo(unitTag, i) 
					if abilityID == buffID then return end
				end

				if result == ACTION_RESULT_EFFECT_GAINED or result == ACTION_RESULT_EFFECT_GAINED_DURATION then
					-- Can't get stack information, assume no stacks.
					stackControl:SetText("")

					if settingsTable.overrideTexturePath == "" then
						textureControl:SetTexture(GetAbilityIcon(abilityID))
					else
						textureControl:SetTexture(settingsTable.overrideTexturePath)
					end

					local endTime = GetGameTimeMilliseconds() + hitValue
					EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name..control:GetName(), 100, function()
						local duration = (endTime-GetGameTimeMilliseconds())/1000
						if duration < 0 then
							--Effect Expired
							EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
							if settingsTable.overrideTexturePath == "" then
								textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[1]))
							else
								textureControl:SetTexture(settingsTable.overrideTexturePath)
							end
							durationControl:SetText("")
							stackControl:SetText("")
						else
							if duration < 2 then
								durationControl:SetText(zo_roundToNearest(duration, 0.1))
							else
								durationControl:SetText(zo_roundToZero(duration))
							end
						end
					end)
				end	
			end
		end)
	end

	EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..control:GetName(), EVENT_EFFECT_CHANGED, function( _, changeType, _, _, tag, startTime, endTime, stackCount, _, _, _, _, _, _, _, abilityID, _)
		if settingsTable.hashedAbilityIDs[abilityID] then

			--if faded with others running then return.
			if changeType == EFFECT_RESULT_FADED then
				for i = 1, GetNumBuffs(unitTag) do
					local _, _, endTime, _, stacks, _, _, _, _, _, buffID, _, _ = GetUnitBuffInfo(unitTag, i)
					if settingsTable.hashedAbilityIDs[buffID] and abilityID ~= buffID then return end
				end
			end
			
			if stackCount == 0 or changeType == EFFECT_RESULT_FADED then stackCount = "" end --stackcount can be 1 instead of 0 after final stone giant cast for example.
			stackControl:SetText(stackCount) 
			if settingsTable.overrideTexturePath == "" then
				textureControl:SetTexture(GetAbilityIcon(abilityID))
			else
				textureControl:SetTexture(settingsTable.overrideTexturePath)
			end
			if changeType ~= EFFECT_RESULT_FADED and not IsAbilityPermanent(abilityID) then
				endTime = endTime * 1000
				EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name..control:GetName(), 100, function()
					local duration = (endTime-GetGameTimeMilliseconds())/1000
					if duration < 0 then
						--Effect Expired
						EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
						if settingsTable.overrideTexturePath == "" then
							textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[1]))
						else
							textureControl:SetTexture(settingsTable.overrideTexturePath)
						end
						durationControl:SetText("")
						stackControl:SetText("")
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
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[1]))
				else
					textureControl:SetTexture(settingsTable.overrideTexturePath)
				end
				durationControl:SetText("")
				stackControl:SetText("")
			end
		end
	end)
	EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..control:GetName(), EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, unitTag)
end

local function InitBar(settingsTable, unitTag, control, animation)

	control:ClearAnchors()
	control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
	control:SetScale(settingsTable.scale)
	control:SetHidden(settingsTable.hidden)

	local textureControl = control:GetNamedChild("Texture")
	local barControl = control:GetNamedChild("Bar")
	local abilityNameControl = barControl:GetNamedChild("AbilityName")
	local unitNameControl = barControl:GetNamedChild("UnitName")
	local durationControl = barControl:GetNamedChild("Duration")

	for i = 1, animation:GetNumAnimations() do
		animation:GetAnimation(i):SetAnimatedControl(barControl)
	end

	durationControl:SetHidden(settingsTable.textSettings.duration.hidden)
	durationControl:SetColor(settingsTable.textSettings.duration.color.r, settingsTable.textSettings.duration.color.g, settingsTable.textSettings.duration.color.b, settingsTable.textSettings.duration.color.a)
	durationControl:SetScale(settingsTable.textSettings.duration.textScale)
	durationControl:ClearAnchors()
	durationControl:SetAnchor(RIGHT, barControl:GetNamedChild("Background"), RIGHT, settingsTable.textSettings.duration.x, settingsTable.textSettings.duration.y)

	abilityNameControl:SetHidden(settingsTable.textSettings.abilityLabel.hidden)
	abilityNameControl:SetColor(settingsTable.textSettings.abilityLabel.color.r, settingsTable.textSettings.abilityLabel.color.g, settingsTable.textSettings.abilityLabel.color.b, settingsTable.textSettings.abilityLabel.color.a)
	abilityNameControl:SetScale(settingsTable.textSettings.abilityLabel.textScale)
	abilityNameControl:ClearAnchors()
	abilityNameControl:SetAnchor(LEFT, barControl:GetNamedChild("Background"), LEFT, settingsTable.textSettings.abilityLabel.x, settingsTable.textSettings.abilityLabel.y)
	abilityNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetAbilityName(settingsTable.abilityIDs[1])))

	unitNameControl:SetHidden(settingsTable.textSettings.unitLabel.hidden)
	unitNameControl:SetColor(settingsTable.textSettings.unitLabel.color.r, settingsTable.textSettings.unitLabel.color.g, settingsTable.textSettings.unitLabel.color.b, settingsTable.textSettings.unitLabel.color.a)
	unitNameControl:SetScale(settingsTable.textSettings.unitLabel.textScale)
	unitNameControl:ClearAnchors()
	unitNameControl:SetAnchor(BOTTOMLEFT, barControl:GetNamedChild("Background"), TOPLEFT, settingsTable.textSettings.unitLabel.x, settingsTable.textSettings.unitLabel.y)
	if settingsTable.textSettings.unitLabel.accountName and GetUnitDisplayName(unitTag) ~= "" then
		unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitDisplayName(unitTag)))
	else
		unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag)))
	end


	barControl:SetValue(0)
	durationControl:SetText("0")


	if settingsTable.overrideTexturePath == "" then
		textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[1]))
	else
		textureControl:SetTexture(settingsTable.overrideTexturePath)
	end

	-- Start the animation if event has already passed.
	if DoesUnitExist(unitTag) then
		for i = 1, GetNumBuffs(unitTag) do
			local _, startTime, endTime, _, _, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i) 
			if settingsTable.hashedAbilityIDs[abilityId] then
				if settingsTable.overrideTexturePath == "" then
					textureControl:SetTexture(GetAbilityIcon(abilityId))
				else
					textureControl:SetTexture(settingsTable.overrideTexturePath)
				end
				abilityNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetAbilityName(abilityId)))
				if settingsTable.textSettings.unitLabel.accountName and GetUnitDisplayName(unitTag) ~= "" then
					unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitDisplayName(unitTag)))
				else
					unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag)))
				end
				for j = 1, animation:GetNumAnimations() do 
					animation:GetAnimation(j):SetDuration((endTime - startTime)*1000)
				end
				animation:PlayFromStart(GetGameTimeMilliseconds()-startTime*1000)
				break
			end
		end
	end

	if unitTag == "reticleover" then
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED, function()
			if DoesUnitExist(unitTag) then
				for i = 1, GetNumBuffs(unitTag) do
					local _, startTime, endTime, _, _, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i) 
					if settingsTable.hashedAbilityIDs[abilityId] then
						if settingsTable.overrideTexturePath == "" then
							textureControl:SetTexture(GetAbilityIcon(abilityId))
						else
							textureControl:SetTexture(settingsTable.overrideTexturePath)
						end
						abilityNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetAbilityName(abilityId)))
						if settingsTable.textSettings.unitLabel.accountName and GetUnitDisplayName(unitTag) ~= "" then
							unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitDisplayName(unitTag)))
						else
							unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag)))
						end
						for j = 1, animation:GetNumAnimations() do 
							animation:GetAnimation(j):SetDuration((endTime - startTime)*1000)
						end
						animation:PlayFromStart(GetGameTimeMilliseconds()-startTime*1000)
						return
					end
				end

				--New target doesn't have the effect.
				if settingsTable.overrideTexturePath == "" then
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[1]))
				else
					textureControl:SetTexture(settingsTable.overrideTexturePath)
				end
				abilityNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetAbilityName(settingsTable.abilityIDs[1])))
				if settingsTable.textSettings.unitLabel.accountName and GetUnitDisplayName(unitTag) ~= "" then
					unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitDisplayName(unitTag)))
				else
					unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag)))
				end
				animation:PlayInstantlyToEnd()
			end
		end)
	else
		-- Track internal effects. (Thanks code65536 for making me aware of these)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..control:GetName(), EVENT_COMBAT_EVENT, function( _, result, _, _, _, _, _, _, _, _, hitValue, _, _, _, _, unitID, abilityID, _)
			if (unitTag == UniversalTracker.unitIDs[unitID] or 
				(unitTag == "player" and UniversalTracker.unitIDs[unitID] == UniversalTracker.altPlayerTag)) and
				settingsTable.hashedAbilityIDs[abilityID] then

				-- Only track effects not affected by event_effect_changed
				for i = 1, GetNumBuffs(unitTag) do
					local _, _, _, _, _, _, _, _, _, _, buffID, _, _ = GetUnitBuffInfo(unitTag, i) 
					if abilityID == buffID then return end
				end

				if result == ACTION_RESULT_EFFECT_GAINED or result == ACTION_RESULT_EFFECT_GAINED_DURATION then
					if settingsTable.overrideTexturePath == "" then
						textureControl:SetTexture(GetAbilityIcon(abilityID))
					else
						textureControl:SetTexture(settingsTable.overrideTexturePath)
					end
					abilityNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetAbilityName(abilityID)))
					if settingsTable.textSettings.unitLabel.accountName and GetUnitDisplayName(unitTag) ~= "" then
						unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitDisplayName(unitTag)))
					else
						unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag)))
					end
					for i = 1, animation:GetNumAnimations() do 
						animation:GetAnimation(i):SetDuration(hitValue)
					end
					animation:PlayFromStart()
				end
			end
		end)
	end

	EVENT_MANAGER:RegisterForEvent(UniversalTracker.name.. control:GetName(), EVENT_EFFECT_CHANGED, function(_, changeType, effectSlot, _, tag, startTime, endTime, _, _, _, _, _, _, _, _, abilityID, _) 
		if changeType ~= EFFECT_RESULT_FADED and settingsTable.hashedAbilityIDs[abilityID] then
			if settingsTable.overrideTexturePath == "" then
				textureControl:SetTexture(GetAbilityIcon(abilityID))
			else
				textureControl:SetTexture(settingsTable.overrideTexturePath)
			end
			abilityNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetAbilityName(abilityID)))
			if settingsTable.textSettings.unitLabel.accountName and GetUnitDisplayName(unitTag) ~= "" then
				unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitDisplayName(unitTag)))
			else
				unitNameControl:SetText(zo_strformat(SI_UNIT_NAME, GetUnitName(unitTag)))
			end
			for i = 1, animation:GetNumAnimations() do 
				animation:GetAnimation(i):SetDuration((endTime - startTime)*1000)
			end
			animation:PlayFromStart(GetGameTimeMilliseconds()-startTime*1000)
		end
	end)
	EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name.. control:GetName(), EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, unitTag)

end

-- Clears and updates all anchors in the list.
-- Assumes controls have been acquired from pools and initialized.
local function UpdateListAnchors(settingsTable)
	-- Only works on lists
	if not (UniversalTracker.Controls[settingsTable.id] and UniversalTracker.Controls[settingsTable.id][1]) then return end

	local columns = {
		[0] = {},
		[1] = {},
		[2] = {}
	}

	--populate columns with lists of controls.
	local nextColumnIndex = 0
	for i = 1, #UniversalTracker.Controls[settingsTable.id] do
		if UniversalTracker.Controls[settingsTable.id][i].object then
			columns[nextColumnIndex][#columns[nextColumnIndex] + 1] = UniversalTracker.Controls[settingsTable.id][i].object
			nextColumnIndex = (nextColumnIndex + 1)%settingsTable.listSettings.columns
		end
	end

	local horizontalOffset = settingsTable.listSettings.horizontalOffsetScale * settingsTable.scale
	local verticalOffset = settingsTable.listSettings.verticalOffsetScale * settingsTable.scale
	if settingsTable.type == "Bar" then
		horizontalOffset = horizontalOffset * 15
		verticalOffset = verticalOffset * 25
	elseif settingsTable.type == "Compact" then
		horizontalOffset = horizontalOffset * 10
		verticalOffset = verticalOffset * 15
	end

	-- Anchor column heads
	if columns[0][1] then
		columns[0][1]:ClearAnchors()
		columns[0][1]:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
	end
	if columns[1][1] then
		columns[1][1]:ClearAnchors()
		columns[1][1]:SetAnchor(LEFT, columns[0][1], RIGHT, horizontalOffset, 0)
	end
	if columns[2][1] then
		columns[2][1]:ClearAnchors()
		columns[2][1]:SetAnchor(LEFT, columns[1][1], RIGHT, horizontalOffset, 0)
	end

	-- Anchor column children
	for i = 2, #columns[0] do
		columns[0][i]:ClearAnchors()
		columns[0][i]:SetAnchor(TOPLEFT, columns[0][i-1], BOTTOMLEFT, 0, verticalOffset)
	end
	for i = 2, #columns[1] do
		columns[1][i]:ClearAnchors()
		columns[1][i]:SetAnchor(TOPLEFT, columns[1][i-1], BOTTOMLEFT, 0, verticalOffset)
	end
	for i = 2, #columns[2] do
		columns[2][i]:ClearAnchors()
		columns[2][i]:SetAnchor(TOPLEFT, columns[0][i-1], BOTTOMLEFT, 0, verticalOffset)
	end
end

local function InitList(settingsTable, unitTag)
	UniversalTracker.Controls[settingsTable.id] = {}
	UniversalTracker.Animations[settingsTable.id] = {}

	-- Initialize linked list with current group members / living bosses.
	for i = 1, 12 do
		if DoesUnitExist(unitTag..i) and not (unitTag == "boss" and IsUnitDead(unitTag..i)) then
			local newControl, newControlKey
			local newAnimation, newAnimationKey
			if settingsTable.type == "Bar" then
				newControl, newControlKey = UniversalTracker.barPool:AcquireObject()
				newAnimation, newAnimationKey = UniversalTracker.barAnimationPool:AcquireObject()
				InitBar(settingsTable, unitTag..i, newControl, newAnimation)
				
				table.insert(UniversalTracker.Animations[settingsTable.id], {object = newAnimation, key = newAnimationKey})
			elseif settingsTable.type == "Compact" then
				newControl, newControlKey = UniversalTracker.compactPool:AcquireObject()
				InitCompact(settingsTable, unitTag..i, newControl)
			end

			table.insert(UniversalTracker.Controls[settingsTable.id], {object = newControl, key = newControlKey, unitTag = unitTag..i})
		end
	end

	UpdateListAnchors(settingsTable)
end

-- number of controls, control unit tag targets, anchors, etc.
local function updateList(settingsTable, unitTag)
	local shouldUpdateAnchors = false

	--Step 1: Removed list elements if the unittag's entity no longer exists.
	for i = #UniversalTracker.Controls[settingsTable.id], 1, -1 do
		if UniversalTracker.Controls[settingsTable.id][i] and (not DoesUnitExist(UniversalTracker.Controls[settingsTable.id][i].unitTag) or 
			(string.find(UniversalTracker.Controls[settingsTable.id][i].unitTag, "boss") and IsUnitDead(UniversalTracker.Controls[settingsTable.id][i].unitTag))) then

			shouldUpdateAnchors = true

			--free objects
			if UniversalTracker.Animations[settingsTable.id][i] and UniversalTracker.Animations[settingsTable.id][i].object then
				UniversalTracker.barPool:ReleaseObject(UniversalTracker.Controls[settingsTable.id][i].key)
				UniversalTracker.barAnimationPool:ReleaseObject(UniversalTracker.Animations[settingsTable.id][i].key)
				table.remove(UniversalTracker.Animations[settingsTable.id], i)
			else
				UniversalTracker.compactPool:ReleaseObject(UniversalTracker.Controls[settingsTable.id][i].key)
			end

			table.remove(UniversalTracker.Controls[settingsTable.id], i)
		end
	end

	--Step 2a: If the linked lists are empty, rebuild them.
	if #UniversalTracker.Controls[settingsTable.id] == 0 then
		InitList(settingsTable, unitTag)
		shouldUpdateAnchors = false
	else
		-- Step 2b: Else, Insert unaccounted for unit tags into sorted positions within the linked list
		local unusedTags = {}
		for i = 1, 12 do
			if DoesUnitExist(unitTag..i) and not (settingsTable.targetType == "Boss" and IsUnitDead(unitTag..i)) then unusedTags[i] = true end
		end

		-- remove used tags from unused list.
		-- note that an index is only in the unused list if the corresponding unit exists.
		for i = 1, #UniversalTracker.Controls[settingsTable.id] do
			local index = tonumber(string.gsub(UniversalTracker.Controls[settingsTable.id][i].unitTag, "%D", ""))
			if unusedTags[index] then
				unusedTags[index] = nil
			end
		end

		--insert unused tags into the tables in sorted order based off of unit tag
		for k, v in pairs(unusedTags) do
			shouldUpdateAnchors = true

			--object creation
			local newControl, newControlKey 
			local newAnimation, newAnimationKey
			if UniversalTracker.Animations[settingsTable.id][1].object then
				newControl, newControlKey = UniversalTracker.barPool:AcquireObject()
				newAnimation, newAnimationKey = UniversalTracker.barAnimationPool:AcquireObject()
				InitBar(settingsTable, unitTag..k, newControl, newAnimation)
				table.insert(UniversalTracker.Animations[settingsTable.id], {object = newAnimation, key = newAnimationKey})
			else
				newControl, newControlKey = UniversalTracker.compactPool:AcquireObject()
				InitCompact(settingsTable, unitTag..k, newControl)
			end

			local insertIndex = 1
			local currentTag = string.gsub(UniversalTracker.Controls[settingsTable.id][insertIndex].unitTag, "%D+", "") --gsub returns 2 arguments and tonumber takes 2 arguments. not a wanted interaction
			while UniversalTracker.Controls[settingsTable.id][insertIndex] and tonumber(currentTag) < k do
				insertIndex = insertIndex + 1
				if UniversalTracker.Controls[settingsTable.id][insertIndex] then
					currentTag = string.gsub(UniversalTracker.Controls[settingsTable.id][insertIndex].unitTag, "%D+", "")
				else
					break
				end
			end
			table.insert(UniversalTracker.Controls[settingsTable.id], insertIndex, {object = newControl, key = newControlKey, unitTag = unitTag..k})
			if UniversalTracker.Animations[settingsTable.id][1].object then
				table.insert(UniversalTracker.Animations[settingsTable.id], insertIndex, {object = newAnimation, key = newAnimationKey})
			end
		end
	end

	--Step 3: Sanity check to make sure there are no duplicate unit tags in list.
	local usedTags = {}
	
	for i = #UniversalTracker.Controls[settingsTable.id], 1, -1 do
		if UniversalTracker.Controls[settingsTable.id][i] and not usedTags[UniversalTracker.Controls[settingsTable.id][i].unitTag] then
			usedTags[UniversalTracker.Controls[settingsTable.id][i].unitTag] = true
		elseif UniversalTracker.Controls[settingsTable.id][i] then
			shouldUpdateAnchors = true

			--free objects
			if UniversalTracker.Animations[settingsTable.id][i] and UniversalTracker.Animations[settingsTable.id][i].object then
				UniversalTracker.barPool:ReleaseObject(UniversalTracker.Controls[settingsTable.id][i].key)
				UniversalTracker.barAnimationPool:ReleaseObject(UniversalTracker.Animations[settingsTable.id][i].key)
				table.remove(UniversalTracker.Animations[settingsTable.id], i)
			else
				UniversalTracker.compactPool:ReleaseObject(UniversalTracker.Controls[settingsTable.id][i].key)
			end

			table.remove(UniversalTracker.Controls[settingsTable.id], i)
		end 
	end

	if shouldUpdateAnchors then
		UpdateListAnchors(settingsTable)
	end
end

-- settings (e.g font, scale, offset, etc.)
function UniversalTracker.refreshList(settingsTable, unitTag)
	if settingsTable.type == "Bar" then
		for i = 1, #UniversalTracker.Controls[settingsTable.id] do
			InitBar(settingsTable, UniversalTracker.Controls[settingsTable.id][i].unitTag, UniversalTracker.Controls[settingsTable.id][i].object, UniversalTracker.Animations[settingsTable.id][i].object)
		end
	elseif settingsTable.type == "Compact" then
		for i = 1, #UniversalTracker.Controls[settingsTable.id] do
			InitCompact(settingsTable, UniversalTracker.Controls[settingsTable.id][i].unitTag, UniversalTracker.Controls[settingsTable.id][i].object)
		end
	end

	--register events.
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_BOSSES_CHANGED)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_JOINED)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_LEFT)

	EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED, function() updateList(settingsTable, unitTag) end)
	EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
	if unitTag == "boss" then
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_BOSSES_CHANGED, function() updateList(settingsTable, unitTag) end)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED, function() updateList(settingsTable, unitTag) end)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED, function() updateList(settingsTable, unitTag) end)
		EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
		EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
	elseif unitTag == "group" then
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_JOINED, function() updateList(settingsTable, unitTag) end)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_LEFT, function() updateList(settingsTable, unitTag) end)
	end

	UpdateListAnchors(settingsTable)
end

function UniversalTracker.freeLists(settingsTable)
	-- Don't do anything if not passed lists.
	if UniversalTracker.Controls[settingsTable.id].object or (UniversalTracker.Animations[settingsTable.id] and UniversalTracker.Animations[settingsTable.id].object) then
		return
	end

	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_JOINED)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_LEFT)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_BOSSES_CHANGED)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED)
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED)
	EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.." move "..settingsTable.id)
	
	if settingsTable.type == "Bar" then
		for i = 1, #UniversalTracker.Controls[settingsTable.id] do
			UniversalTracker.barPool:ReleaseObject(UniversalTracker.Controls[settingsTable.id][i].key)
			UniversalTracker.barAnimationPool:ReleaseObject(UniversalTracker.Animations[settingsTable.id][i].key)
		end
	elseif settingsTable.type == "Compact" then
		for i = 1, #UniversalTracker.Controls[settingsTable.id] do
			UniversalTracker.compactPool:ReleaseObject(UniversalTracker.Controls[settingsTable.id][i].key)
		end
	end

	UniversalTracker.Controls[settingsTable.id] = {}
	UniversalTracker.Animations[settingsTable.id] = {}

end

function UniversalTracker.InitSingleDisplay(settingsTable)

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
		if settingsTable.type == "Compact" then
			if not UniversalTracker.Controls[settingsTable.id] then
				UniversalTracker.Controls[settingsTable.id] = {}
				UniversalTracker.Controls[settingsTable.id].object, UniversalTracker.Controls[settingsTable.id].key = UniversalTracker.compactPool:AcquireObject()
			elseif UniversalTracker.Controls[settingsTable.id][1] then --list
				UniversalTracker.freeLists(settingsTable)
				UniversalTracker.Controls[settingsTable.id] = {}
				UniversalTracker.Controls[settingsTable.id].object, UniversalTracker.Controls[settingsTable.id].key = UniversalTracker.compactPool:AcquireObject()
			elseif UniversalTracker.Controls[settingsTable.id].object and string.find(UniversalTracker.Controls[settingsTable.id].object:GetName(), "Bar") then
				UniversalTracker.barAnimationPool:ReleaseObject(UniversalTracker.Animations[settingsTable.id].key)
				UniversalTracker.barPool:ReleaseObject(UniversalTracker.Controls[settingsTable.id].key)
				UniversalTracker.Controls[settingsTable.id] = {}
				UniversalTracker.Controls[settingsTable.id].object, UniversalTracker.Controls[settingsTable.id].key = UniversalTracker.compactPool:AcquireObject()
			elseif not next(UniversalTracker.Controls[settingsTable.id]) then -- initialized but empty table (e.g. initialized boss tracker but no nearby bosses)
				UniversalTracker.Controls[settingsTable.id] = {}
				UniversalTracker.Controls[settingsTable.id].object, UniversalTracker.Controls[settingsTable.id].key = UniversalTracker.compactPool:AcquireObject()
			end

			InitCompact(settingsTable, unitTag, UniversalTracker.Controls[settingsTable.id].object)
		elseif settingsTable.type == "Bar" then
			if not UniversalTracker.Controls[settingsTable.id] then
				UniversalTracker.Controls[settingsTable.id] = {}
				UniversalTracker.Animations[settingsTable.id] = {}
				UniversalTracker.Controls[settingsTable.id].object, UniversalTracker.Controls[settingsTable.id].key = UniversalTracker.barPool:AcquireObject()
				UniversalTracker.Animations[settingsTable.id].object, UniversalTracker.Animations[settingsTable.id].key = UniversalTracker.barAnimationPool:AcquireObject()
			elseif UniversalTracker.Controls[settingsTable.id][1] then --list
				UniversalTracker.freeLists(settingsTable)
				UniversalTracker.Controls[settingsTable.id] = {}
				UniversalTracker.Animations[settingsTable.id] = {}
				UniversalTracker.Controls[settingsTable.id].object, UniversalTracker.Controls[settingsTable.id].key = UniversalTracker.barPool:AcquireObject()
				UniversalTracker.Animations[settingsTable.id].object, UniversalTracker.Animations[settingsTable.id].key = UniversalTracker.barAnimationPool:AcquireObject()
			elseif UniversalTracker.Controls[settingsTable.id].object and string.find(UniversalTracker.Controls[settingsTable.id].object:GetName(), "Compact") then
				UniversalTracker.compactPool:ReleaseObject(UniversalTracker.Controls[settingsTable.id].key)
				UniversalTracker.Controls[settingsTable.id] = {}
				UniversalTracker.Animations[settingsTable.id] = {}
				UniversalTracker.Controls[settingsTable.id].object, UniversalTracker.Controls[settingsTable.id].key = UniversalTracker.barPool:AcquireObject()
				UniversalTracker.Animations[settingsTable.id].object, UniversalTracker.Animations[settingsTable.id].key = UniversalTracker.barAnimationPool:AcquireObject()
			elseif not next(UniversalTracker.Controls[settingsTable.id]) then -- initialized but empty table (e.g. initialized boss tracker but no nearby bosses)
				UniversalTracker.Controls[settingsTable.id] = {}
				UniversalTracker.Animations[settingsTable.id] = {}
				UniversalTracker.Controls[settingsTable.id].object, UniversalTracker.Controls[settingsTable.id].key = UniversalTracker.barPool:AcquireObject()
				UniversalTracker.Animations[settingsTable.id].object, UniversalTracker.Animations[settingsTable.id].key = UniversalTracker.barAnimationPool:AcquireObject()
			end
			InitBar(settingsTable, unitTag, UniversalTracker.Controls[settingsTable.id].object, UniversalTracker.Animations[settingsTable.id].object)
		end
	elseif unitTag == "boss" or unitTag == "group" then
		if UniversalTracker.Controls[settingsTable.id] and UniversalTracker.Controls[settingsTable.id].object then
			UniversalTracker.barPool:ReleaseObject(UniversalTracker.Controls[settingsTable.id].key)
		end
		if UniversalTracker.Animations[settingsTable.id] and UniversalTracker.Animations[settingsTable.id].object then
			UniversalTracker.barAnimationPool:ReleaseObject(UniversalTracker.Animations[settingsTable.id].key)
		end

		if UniversalTracker.Controls[settingsTable.id] and UniversalTracker.Controls[settingsTable.id][1] and UniversalTracker.Controls[settingsTable.id][1].object then
			--List is initialized.
			--Is the initialized list of appropriate type?
			if not string.find(UniversalTracker.Controls[settingsTable.id][1].object:GetName(), settingsTable.type) then
				UniversalTracker.freeLists(settingsTable)
				InitList(settingsTable, unitTag)
			elseif not string.find(UniversalTracker.Controls[settingsTable.id][1].unitTag, unitTag) then
				-- Is the initialized list of appropriate target type?
				UniversalTracker.freeLists(settingsTable)
				InitList(settingsTable, unitTag)
			else
				UniversalTracker.refreshList(settingsTable, unitTag)
			end
		else
			--initialize current.
			InitList(settingsTable, unitTag)
		end

		--register events.
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED, function() updateList(settingsTable, unitTag) end)
		EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
		if unitTag == "boss" then
			EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_BOSSES_CHANGED, function() updateList(settingsTable, unitTag) end)
			EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED, function() updateList(settingsTable, unitTag) end)
			EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED, function() updateList(settingsTable, unitTag) end)
			EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
			EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
		elseif unitTag == "group" then
			EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_JOINED, function() updateList(settingsTable, unitTag) end)
			EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_LEFT, function() updateList(settingsTable, unitTag) end)
		end
	end
end

local function fragmentChange(oldState, newState)
	if newState == SCENE_FRAGMENT_SHOWN then
		--unhide everything.
		for k, v in pairs(UniversalTracker.savedVariables.trackerList) do
			if UniversalTracker.Controls[v.id] then
				if UniversalTracker.Controls[v.id].object then
					UniversalTracker.Controls[v.id].object:SetHidden(v.hidden)
				else
					for i = 1, #UniversalTracker.Controls[v.id] do
						if UniversalTracker.Controls[v.id][i].object then
							UniversalTracker.Controls[v.id][i].object:SetHidden(v.hidden)
						end
					end
				end
			end
		end
		for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
			if UniversalTracker.Controls[v.id] then
				if UniversalTracker.Controls[v.id].object then
					UniversalTracker.Controls[v.id].object:SetHidden(v.hidden)
				else
					for i = 1, #UniversalTracker.Controls[v.id] do
						if UniversalTracker.Controls[v.id][i].object then
							UniversalTracker.Controls[v.id][i].object:SetHidden(v.hidden)
						end
					end
				end
			end
		end
	elseif newState == SCENE_FRAGMENT_HIDDEN then
		--hide everything.
		for k, v in pairs(UniversalTracker.savedVariables.trackerList) do
			if UniversalTracker.Controls[v.id] then
				if UniversalTracker.Controls[v.id].object then
					UniversalTracker.Controls[v.id].object:SetHidden(true)
				else
					for i = 1, #UniversalTracker.Controls[v.id] do
						if UniversalTracker.Controls[v.id][i].object then
							UniversalTracker.Controls[v.id][i].object:SetHidden(true)
						end
					end
				end
			end
		end
		for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
			if UniversalTracker.Controls[v.id] then
				if UniversalTracker.Controls[v.id].object then
					UniversalTracker.Controls[v.id].object:SetHidden(true)
				else
					for i = 1, #UniversalTracker.Controls[v.id] do
						if UniversalTracker.Controls[v.id][i].object then
							UniversalTracker.Controls[v.id][i].object:SetHidden(v.hidden)
						end
					end
				end
			end
		end
	end
end

function UniversalTracker.Initialize()
	UniversalTracker.savedVariables = ZO_SavedVars:NewAccountWide("UniversalTrackerSavedVariables", 1, nil, UniversalTracker.defaults, GetWorldName())
	UniversalTracker.characterSavedVariables = ZO_SavedVars:NewCharacterIdSettings("UniversalTrackerSavedVariables", 1, nil, UniversalTracker.defaultsCharacter, GetWorldName())

	UniversalTracker.chat = LibChatMessage("UniversalTracker", "UniversalTracker")

    UniversalTracker.barPool = ZO_ControlPool:New("SingleBarDuration", GuiRoot)
    UniversalTracker.barPool:SetResetFunction(function(control)
			control:SetHidden(true)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_EFFECT_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_COMBAT_EVENT)
			EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
	end)

	UniversalTracker.barAnimationPool = ZO_AnimationPool:New("SingleBarAnimation")

	UniversalTracker.compactPool = ZO_ControlPool:New("SingleCompactTracker", GuiRoot)
    UniversalTracker.compactPool:SetResetFunction(function(control)
			control:SetHidden(true)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_EFFECT_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_COMBAT_EVENT)
			EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
	end)

    UniversalTracker.InitSettings()


	for k, v in pairs(UniversalTracker.savedVariables.trackerList) do
		UniversalTracker.InitSingleDisplay(v)
	end
	for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
		UniversalTracker.InitSingleDisplay(v)
	end

	LibRadialMenu:RegisterAddon(UniversalTracker.name, UniversalTracker.name)
	for k, v in pairs(UniversalTracker.savedVariables.setupList) do
		if v and v.id and v.name then
			LibRadialMenu:RegisterEntry(UniversalTracker.name, v.name, tostring(v.id), "EsoUI/Art/Notifications/notificationIcon_duel.dds", function() UniversalTracker.loadSetup(v.id) end, "Load this setup.")
		end
	end
	for k, v in pairs(UniversalTracker.characterSavedVariables.setupList) do
		if v and v.id and v.name then
			LibRadialMenu:RegisterEntry(UniversalTracker.name, v.name, tostring(v.id), "EsoUI/Art/Notifications/notificationIcon_duel.dds", function() UniversalTracker.loadSetup(v.id) end, "Load this setup.")
		end
	end

	HUD_FRAGMENT:RegisterCallback("StateChange", fragmentChange)

	EVENT_MANAGER:RegisterForEvent(UniversalTracker.name.."_IDScan", EVENT_EFFECT_CHANGED, function(_, changeType, effectSlot, _, tag, startTime, endTime, _, _, _, _, _, _, _, unitID, abilityID, _) 
		if not UniversalTracker.unitIDs[unitID] and (tag == "player" or string.find(tag, "group") or string.find(tag, "boss")) then
			UniversalTracker.unitIDs[unitID] = tag
			if tag ~= "player" and GetUnitName(tag) == GetUnitName("player") then
				UniversalTracker.altPlayerTag = tag
			end
		end  
	end)
	local function resetIDList() 
		UniversalTracker.unitIDs = {} 
		UniversalTracker.altPlayerTag = ""
	end
	EVENT_MANAGER:RegisterForEvent(UniversalTracker.name.."_IDClear", EVENT_BOSSES_CHANGED, resetIDList)
	EVENT_MANAGER:RegisterForEvent(UniversalTracker.name.."_IDClear", EVENT_GROUP_MEMBER_JOINED, resetIDList)
	EVENT_MANAGER:RegisterForEvent(UniversalTracker.name.."_IDClear", EVENT_GROUP_MEMBER_LEFT, resetIDList)

end

function UniversalTracker.OnAddOnLoaded(event, addonName)
	if addonName == UniversalTracker.name then
		UniversalTracker.Initialize()
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(UniversalTracker.name, EVENT_ADD_ON_LOADED, UniversalTracker.OnAddOnLoaded)