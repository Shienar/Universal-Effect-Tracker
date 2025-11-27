UniversalTracker = UniversalTracker or {}
UniversalTracker.name = "UniversalEffectTracker"

UniversalTracker.defaults = {
	trackerList = {

	}
}

UniversalTracker.unitIDs = {
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
	unitNameControl:SetText(GetUnitName(unitTag))

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
					EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name..control:GetName(), 100, function()
						local duration = (endTime-GetGameTimeMilliseconds())/1000
						if duration < 0 then
							--Effect Expired
							EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
							if settingsTable.overrideTexturePath == "" then
								textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
							else
								textureControl:SetTexture(settingsTable.overrideTexture)
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
			if GetUnitName(unitTag) ~= "" then unitNameControl:SetText(GetUnitName(unitTag)) end
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
							EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name..control:GetName(), 100, function()
								local duration = (endTime-GetGameTimeMilliseconds())/1000
								if duration < 0 then
									--Effect Expired
									EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
									if settingsTable.overrideTexturePath == "" then
										textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
									else
										textureControl:SetTexture(settingsTable.overrideTexture)
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
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
				else
					textureControl:SetTexture(settingsTable.overrideTexture)
				end
				durationControl:SetText("")
				stackControl:SetText("")
			end
		end)
	else
		-- Track internal effects. (Thanks code65536 for making me aware of these)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..control:GetName(), EVENT_COMBAT_EVENT, function( _, result, _, _, _, _, _, _, _, _, hitValue, _, _, _, _, unitID, abilityID, _)
			if unitTag == UniversalTracker.unitIDs[unitID] and settingsTable.hashedAbilityIDs[abilityID] then
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
						textureControl:SetTexture(settingsTable.overrideTexture)
					end

					local endTime = GetGameTimeMilliseconds() + hitValue
					EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name..control:GetName(), 100, function()
						local duration = (endTime-GetGameTimeMilliseconds())/1000
						if duration < 0 then
							--Effect Expired
							EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
							if settingsTable.overrideTexturePath == "" then
								textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
							else
								textureControl:SetTexture(settingsTable.overrideTexture)
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
				elseif result == ACTION_RESULT_EFFECT_FADED then
					-- Check again to ensure that no tracked buffs are in use.
					-- Off balance + immunity will bug out otherwise since immunity starts before off balance ends
					for i = 1, GetNumBuffs(unitTag) do
						local _, _, _, _, _, _, _, _, _, _, buffID, _, _ = GetUnitBuffInfo(unitTag, i) 
						if settingsTable.hashedAbilityIDs[buffID] then return end
					end

					EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
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
				textureControl:SetTexture(settingsTable.overrideTexture)
			end
			if changeType ~= EFFECT_RESULT_FADED and not IsAbilityPermanent(abilityID) then
				endTime = endTime * 1000
				EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name..control:GetName(), 100, function()
					local duration = (endTime-GetGameTimeMilliseconds())/1000
					if duration < 0 then
						--Effect Expired
						EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
						if settingsTable.overrideTexturePath == "" then
							textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
						else
							textureControl:SetTexture(settingsTable.overrideTexture)
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
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
				else
					textureControl:SetTexture(settingsTable.overrideTexture)
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
	abilityNameControl:SetText(GetAbilityName(settingsTable.abilityIDs[0]))

	unitNameControl:SetHidden(settingsTable.textSettings.unitLabel.hidden)
	unitNameControl:SetColor(settingsTable.textSettings.unitLabel.color.r, settingsTable.textSettings.unitLabel.color.g, settingsTable.textSettings.unitLabel.color.b, settingsTable.textSettings.unitLabel.color.a)
	unitNameControl:SetScale(settingsTable.textSettings.unitLabel.textScale)
	unitNameControl:ClearAnchors()
	unitNameControl:SetAnchor(BOTTOMLEFT, barControl:GetNamedChild("Background"), TOPLEFT, settingsTable.textSettings.unitLabel.x, settingsTable.textSettings.unitLabel.y)
	unitNameControl:SetText(GetUnitName(unitTag))


	barControl:SetValue(0)
	durationControl:SetText("0")


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
				if settingsTable.overrideTexturePath == "" then
					textureControl:SetTexture(GetAbilityIcon(abilityId))
				else
					textureControl:SetTexture(settingsTable.overrideTexture)
				end
				abilityNameControl:SetText(GetAbilityName(abilityId))
				unitNameControl:SetText(GetUnitName(unitTag))
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
							textureControl:SetTexture(settingsTable.overrideTexture)
						end
						abilityNameControl:SetText(GetAbilityName(abilityId))
						unitNameControl:SetText(GetUnitName(unitTag))
						for j = 1, animation:GetNumAnimations() do 
							animation:GetAnimation(j):SetDuration((endTime - startTime)*1000)
						end
						animation:PlayFromStart(GetGameTimeMilliseconds()-startTime*1000)
						return
					end
				end

				--New target doesn't have the effect.
				if settingsTable.overrideTexturePath == "" then
					textureControl:SetTexture(GetAbilityIcon(settingsTable.abilityIDs[0]))
				else
					textureControl:SetTexture(settingsTable.overrideTexture)
				end
				abilityNameControl:SetText(GetAbilityName(settingsTable.abilityIDs[0]))
				unitNameControl:SetText(GetUnitName(unitTag))
				animation:PlayInstantlyToEnd()
			end
		end)
	else
		-- Track internal effects. (Thanks code65536 for making me aware of these)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..control:GetName(), EVENT_COMBAT_EVENT, function( _, result, _, _, _, _, _, _, _, _, hitValue, _, _, _, _, unitID, abilityID, _)
			if unitTag == UniversalTracker.unitIDs[unitID] and settingsTable.hashedAbilityIDs[abilityID] then
				-- Only track effects not affected by event_effect_changed
				for i = 1, GetNumBuffs(unitTag) do
					local _, _, _, _, _, _, _, _, _, _, buffID, _, _ = GetUnitBuffInfo(unitTag, i) 
					if abilityID == buffID then return end
				end

				if result == ACTION_RESULT_EFFECT_GAINED or result == ACTION_RESULT_EFFECT_GAINED_DURATION then
					if settingsTable.overrideTexturePath == "" then
						textureControl:SetTexture(GetAbilityIcon(abilityID))
					else
						textureControl:SetTexture(settingsTable.overrideTexture)
					end
					abilityNameControl:SetText(GetAbilityName(abilityID))
					unitNameControl:SetText(GetUnitName(unitTag))
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
				textureControl:SetTexture(settingsTable.overrideTexture)
			end
			abilityNameControl:SetText(GetAbilityName(abilityID))
			unitNameControl:SetText(GetUnitName(unitTag))
			for i = 1, animation:GetNumAnimations() do 
				animation:GetAnimation(i):SetDuration((endTime - startTime)*1000)
			end
			animation:PlayFromStart(GetGameTimeMilliseconds()-startTime*1000)
		end
	end)
	EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name.. control:GetName(), EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, unitTag)

end

local function InitList(settingsTable, unitTag)
	settingsTable.control, settingsTable.animation = {head = nil, tail = nil}, {head = nil, tail = nil}

	-- Initialize linked list with current bosses / group members
	for i = 1, 12 do
		if DoesUnitExist(unitTag..i) and not (unitTag == "boss" and IsUnitDead(unitTag..i)) then
			local newControl, newControlKey
			local newAnimation, newAnimationKey
			if settingsTable.type == "Bar" then
				newControl, newControlKey = UniversalTracker.barPool:AcquireObject()
				newAnimation, newAnimationKey = UniversalTracker.barAnimationPool:AcquireObject()
			elseif settingsTable.type == "Compact" then
				newControl, newControlKey = UniversalTracker.compactPool:AcquireObject()
			end

			local newControlNode = {next = nil, prev = settingsTable.control.tail, value = {control = newControl, key = newControlKey, unitTag = unitTag..i}}
			if settingsTable.control.tail then
				settingsTable.control.tail.next = newControlNode
			else
				settingsTable.control.head = newControlNode
			end
			settingsTable.control.tail = newControlNode

			if settingsTable.type == "Bar" then
				local newAnimationNode = { next = nil, prev = settingsTable.animation.tail, value = { animation = newAnimation, key = newAnimationKey } }
				if settingsTable.animation.tail then
					settingsTable.animation.tail.next = newAnimationNode
				else
					settingsTable.animation.head = newAnimationNode
				end
				settingsTable.animation.tail = newAnimationNode
			end
			
		end
	end

	if settingsTable.type == "Bar" then 
		local current_control = settingsTable.control.head
		local current_animation = settingsTable.animation.head
		while current_control and current_animation do
			InitBar(settingsTable, current_control.value.unitTag, current_control.value.control, current_animation.value.animation)
			if current_control.prev then
				current_control.value.control:ClearAnchors()
				current_control.value.control:SetAnchor(TOPLEFT, current_control.prev.value.control, BOTTOMLEFT, 0, 25 * settingsTable.scale)
			end
			current_control = current_control.next
			current_animation = current_animation.next
		end
	elseif settingsTable.type == "Compact" then
		local current_control = settingsTable.control.head
		while current_control  do
			InitCompact(settingsTable, current_control.value.unitTag, current_control.value.control)
			if current_control.prev then
				current_control.value.control:ClearAnchors()
				current_control.value.control:SetAnchor(TOPLEFT, current_control.prev.value.control, BOTTOMLEFT, 0, 15 * settingsTable.scale)
			end
			current_control = current_control.next
		end
	end
end

-- number of controls, control unit tag targets, anchors, etc.
local function updateList(settingsTable, unitTag)
	--Step 1: Removed linked list elements if the unittag's entity no longer exists.
	local currentControlNode = settingsTable.control.head
	local currentAnimationNode = nil
	if settingsTable.type == "Bar" then
		currentAnimationNode = settingsTable.animation.head
	end
	while currentControlNode do
		if not DoesUnitExist(currentControlNode.value.unitTag) or (string.find(currentControlNode.value.unitTag, "boss") and IsUnitDead(currentControlNode.value.unitTag)) then
			--update anchors
			if currentControlNode.next and currentControlNode.next.value.control then
				if currentControlNode.prev and currentControlNode.prev.value.control then
					currentControlNode.next.value.control:ClearAnchors()
					if currentAnimationNode then
						currentControlNode.next.value.control:SetAnchor(TOPLEFT, currentControlNode.prev.value.control, BOTTOMLEFT, 0, 25 * settingsTable.scale)
					else
						currentControlNode.next.value.control:SetAnchor(TOPLEFT, currentControlNode.prev.value.control, BOTTOMLEFT, 0, 15 * settingsTable.scale)
					end
					
				else
					--Position new head
					currentControlNode.next.value.control:ClearAnchors()
					currentControlNode.next.value.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
				end
			end

			--free objects
			if currentAnimationNode then
				UniversalTracker.barPool:ReleaseObject(currentControlNode.value.key)
				UniversalTracker.barAnimationPool:ReleaseObject(currentAnimationNode.value.key)
			else
				UniversalTracker.compactPool:ReleaseObject(currentControlNode.value.key)
			end

			--remove from table (leave for garbage collector)
			if not currentControlNode.prev then --head
				settingsTable.control.head = currentControlNode.next
				if currentAnimationNode then
					settingsTable.animation.head = currentAnimationNode.next
				end

				if settingsTable.control.head then
					settingsTable.control.head.prev = nil
					if currentAnimationNode then
						settingsTable.animation.head.prev = nil
					end
				end
			else --not head
				currentControlNode.prev.next = currentControlNode.next
				if currentControlNode.next then
					currentControlNode.next.prev = currentControlNode.prev
				end

				if currentAnimationNode then
					currentAnimationNode.prev.next = currentAnimationNode.next
					if currentAnimationNode.next then
						currentAnimationNode.next.prev = currentAnimationNode.prev
					end
				end
			end

			if currentControlNode == settingsTable.control.tail then
				settingsTable.control.tail = currentControlNode.prev
				if currentAnimationNode then
					settingsTable.animation.tail = currentAnimationNode.prev
				end
			end
			
		end

		currentControlNode = currentControlNode.next
		if currentAnimationNode then
			currentAnimationNode = currentAnimationNode.next
		end
	end
	

	--Step 2a: If the linked lists are empty, rebuild them.
	if not settingsTable.control.head then
		InitList(settingsTable, unitTag)
	else
		-- Step 2b: Else, Insert unaccounted for unitIDs into sorted positions within the linked list
		local unusedTags = {}
		for i = 1, 12 do
			if DoesUnitExist(unitTag..i) and not (settingsTable.targetType == "Boss" and IsUnitDead(unitTag..i)) then unusedTags[i] = true end
		end

		-- remove used tags from unused list.
		-- note that an index is only in the unused list if the corresponding unit exists.
		currentControlNode = settingsTable.control.head
		while currentControlNode do
			local index = tonumber(string.gsub(currentControlNode.value.unitTag, "%D", ""))
			if  unusedTags[index] then
				unusedTags[index] = nil
			end
			currentControlNode = currentControlNode.next
		end

		currentControlNode = settingsTable.control.head
		if settingsTable.type == "Bar" then
			currentAnimationNode = settingsTable.animation.head
		end
		while currentControlNode do
			local currentTagIndex = tonumber(string.gsub(currentControlNode.value.unitTag, "%D", ""))
			for k, v in pairs(unusedTags) do
				if currentTagIndex and k < currentTagIndex then
					-- We've passed over the desired index. insert behind
					unusedTags[k] = nil
					
					--object creation
					local newControl, newControlKey 
					local newAnimation, newAnimationKey
					if currentAnimationNode then
						newControl, newControlKey = UniversalTracker.barPool:AcquireObject()
						newAnimation, newAnimationKey = UniversalTracker.barAnimationPool:AcquireObject()
						InitBar(settingsTable, unitTag..k, newControl, newAnimation)
					else
						newControl, newControlKey = UniversalTracker.compactPool:AcquireObject()
						InitCompact(settingsTable, unitTag..k, newControl)
					end

					--List updates
					if currentControlNode == settingsTable.control.head then
						settingsTable.control.head = {next = settingsTable.control.head, prev = nil, value = {control = newControl, key = newControlKey, unitTag = unitTag..k}}
						if currentAnimationNode then
							settingsTable.animation.head = {next = settingsTable.animation.head, prev = nil, value = {animation = newAnimation, key = newAnimationKey}}
						end
					else
						local newControlNode = {next = currentControlNode, prev = currentControlNode.prev, value = {control = newControl, key = newControlKey, unitTag = unitTag..k}}
						currentControlNode.prev.next = newControlNode
						currentControlNode.prev =  newControlNode
						local newAnimationNode
						if currentAnimationNode then
							newAnimationNode = {next = currentAnimationNode, prev = currentAnimationNode.prev, value = {animation = newAnimation, key = newAnimationKey}}
							currentAnimationNode.prev.next = newAnimationNode
							currentAnimationNode.prev = newAnimationNode
						end
					end
				end
			end
			currentControlNode = currentControlNode.next
			if currentAnimationNode then
				currentAnimationNode = currentAnimationNode.next
			end
		end

		--insert after tail
		-- we know that the list isn't empty at this point.
		for k, v in pairs(unusedTags) do
			--object creation
			local newControl, newControlKey, newAnimation, newAnimationKey
			if settingsTable.type == "Bar" then
				newControl, newControlKey = UniversalTracker.barPool:AcquireObject()
				newAnimation, newAnimationKey = UniversalTracker.barAnimationPool:AcquireObject()
				InitBar(settingsTable, unitTag..k, newControl, newAnimation)

				--list updates
				local newAnimationNode = {next = nil, prev = settingsTable.animation.tail, value = {animation = newAnimation, key = newAnimationKey}}
				settingsTable.animation.tail.next = newAnimationNode
				settingsTable.animation.tail = newAnimationNode
			elseif settingsTable.type == "Compact" then
				newControl, newControlKey = UniversalTracker.compactPool:AcquireObject()
				InitCompact(settingsTable, unitTag..k, newControl)
			end

			--list updates
			local newControlNode = {next = nil, prev = settingsTable.control.tail, value = {control = newControl, key = newControlKey, unitTag = unitTag..k}}
			settingsTable.control.tail.next = newControlNode
			settingsTable.control.tail = newControlNode

		end

		-- Doing all of this case's anchor updates at the end here for simplicity's sake.
		currentControlNode = settingsTable.control.head
		currentControlNode.value.control:ClearAnchors()
		currentControlNode.value.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
		currentControlNode = currentControlNode.next
		if settingsTable.type == "Bar" then	
			while currentControlNode do
				if currentControlNode.prev.value.control then
					currentControlNode.value.control:ClearAnchors()
					currentControlNode.value.control:SetAnchor(TOPLEFT, currentControlNode.prev.value.control, BOTTOMLEFT, 0, 25 * settingsTable.scale)
				end
				currentControlNode = currentControlNode.next
			end
		elseif settingsTable.type == "Compact" then
			while currentControlNode do
				if currentControlNode.prev.value.control then
					currentControlNode.value.control:ClearAnchors()
					currentControlNode.value.control:SetAnchor(TOPLEFT, currentControlNode.prev.value.control, BOTTOMLEFT, 0, 15 * settingsTable.scale)
				end
				currentControlNode = currentControlNode.next
			end
		end
	end
end

-- settings (e.g font, scale, offset, etc.)
function UniversalTracker.refreshList(settingsTable, unitTag)
	if settingsTable.type == "Bar" then 
		local current_control = settingsTable.control.head
		local current_animation = settingsTable.animation.head
		while current_control and current_control.value.control and current_animation and current_animation.value.animation do
			InitBar(settingsTable, current_control.value.unitTag, current_control.value.control, current_animation.value.animation)
			if current_control.prev then
				current_control.value.control:ClearAnchors()
				current_control.value.control:SetAnchor(TOPLEFT, current_control.prev.value.control, BOTTOMLEFT, 0, 25 * settingsTable.scale)
			end
			current_control = current_control.next
			current_animation = current_animation.next
		end
	elseif settingsTable.type == "Compact" then
		local current_control = settingsTable.control.head
		while current_control and current_control.value.control do
			InitCompact(settingsTable, current_control.value.unitTag, current_control.value.control)
			if current_control.prev then
				current_control.value.control:ClearAnchors()
				current_control.value.control:SetAnchor(TOPLEFT, current_control.prev.value.control, BOTTOMLEFT, 0, 15 * settingsTable.scale)
			end
			current_control = current_control.next
		end
	end

	--register events.
	EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED)
	EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
	EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED, function() updateList(settingsTable, unitTag) end)
	if unitTag == "boss" then
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_BOSSES_CHANGED)
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED)
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_BOSSES_CHANGED, function() updateList(settingsTable, unitTag) end)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED, function() updateList(settingsTable, unitTag) end)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED, function() updateList(settingsTable, unitTag) end)
		EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
		EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED, REGISTER_FILTER_UNIT_TAG_PREFIX, unitTag)
	elseif unitTag == "group" then
	elseif unitTag == "group" then
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_JOINED)
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_LEFT)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_JOINED, function() updateList(settingsTable, unitTag) end)
		EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_LEFT, function() updateList(settingsTable, unitTag) end)
	end
end


function UniversalTracker.freeLists(settingsTable)
	-- Don't do anything if not passed linked lists.
	if settingsTable.control.object or (settingsTable.animation and settingsTable.animation.object) then
		return
	end

	if settingsTable.id then
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_JOINED)
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_GROUP_MEMBER_LEFT)
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_BOSSES_CHANGED)
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED)
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DESTROYED)
		EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_CREATED)
		EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.." move "..settingsTable.id)
	end

	if settingsTable.control.tail and settingsTable.control.tail.value.control then
		local curNode = settingsTable.control.tail
		if string.find(curNode.value.control:GetName(), "Bar") then
			while curNode do
				UniversalTracker.barPool:ReleaseObject(curNode.value.key)
				curNode = curNode.prev
			end
		elseif string.find(curNode.value.control:GetName(), "Compact") then
			while curNode do
				UniversalTracker.compactPool:ReleaseObject(curNode.value.key)
				curNode = curNode.prev
			end
		end
	end

	settingsTable.control = { head = nil, tail = nil}

	if settingsTable.animation and settingsTable.animation.tail and settingsTable.animation.tail.value.animation then
		local curNode = settingsTable.animation.tail
		while curNode do
			UniversalTracker.barAnimationPool:ReleaseObject(curNode.value.key)
			curNode = curNode.prev
		end
	end

	settingsTable.animation = { head = nil, tail = nil}
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
			if settingsTable.control.head then --bar panel
				UniversalTracker.freeLists(settingsTable)
				settingsTable.control.object, settingsTable.control.key = UniversalTracker.compactPool:AcquireObject()
			elseif not settingsTable.control.object then
				settingsTable.control.object, settingsTable.control.key = UniversalTracker.compactPool:AcquireObject()
				settingsTable.id = UniversalTracker.nextID
				UniversalTracker.nextID = UniversalTracker.nextID + 1
			elseif string.find(settingsTable.control.object:GetName(), "Bar") then
				UniversalTracker.barAnimationPool:ReleaseObject(settingsTable.animation.key)
				UniversalTracker.barPool:ReleaseObject(settingsTable.control.key)
				settingsTable.control.object, settingsTable.control.key = UniversalTracker.compactPool:AcquireObject()
			end

			InitCompact(settingsTable, unitTag, settingsTable.control.object)
		elseif settingsTable.type == "Bar" then
			if settingsTable.control.head then --bar panel
				UniversalTracker.freeLists(settingsTable)
				settingsTable.control.object, settingsTable.control.key = UniversalTracker.barPool:AcquireObject()
				settingsTable.animation.object, settingsTable.animation.key = UniversalTracker.barAnimationPool:AcquireObject()
			elseif not settingsTable.control.object then
				settingsTable.control.object, settingsTable.control.key = UniversalTracker.barPool:AcquireObject()
				settingsTable.animation.object, settingsTable.animation.key = UniversalTracker.barAnimationPool:AcquireObject()
				settingsTable.id = UniversalTracker.nextID
				UniversalTracker.nextID = UniversalTracker.nextID + 1
			elseif string.find(settingsTable.control.object:GetName(), "Compact") then
				UniversalTracker.compactPool:ReleaseObject(settingsTable.control.key)
				settingsTable.control.object, settingsTable.control.key = UniversalTracker.barPool:AcquireObject()
				settingsTable.animation.object, settingsTable.animation.key = UniversalTracker.barAnimationPool:AcquireObject()
			end
			InitBar(settingsTable, unitTag, settingsTable.control.object, settingsTable.animation.object)
		end
	elseif unitTag == "boss" or unitTag == "group" then
		if settingsTable.control.object then
			UniversalTracker.barPool:ReleaseObject(settingsTable.control.key)
		end
		if settingsTable.animation and settingsTable.animation.object then
			UniversalTracker.barAnimationPool:ReleaseObject(settingsTable.animation.key)
		end

		if settingsTable.control.head and settingsTable.control.head.value.control then
			--Is the initialized list of appropriate type?
			if not string.find(settingsTable.control.head.value.control:GetName(), settingsTable.type) then
				UniversalTracker.freeLists(settingsTable)
				InitList(settingsTable, unitTag)
			elseif not string.find(settingsTable.control.head.value.unitTag, unitTag) then
				-- Is the initialized list of appropriate target type?
				UniversalTracker.freeLists(settingsTable)
				InitList(settingsTable, unitTag)
			else
				UniversalTracker.refreshList(settingsTable, unitTag)
			end
		else
			--initialize current.
			InitList(settingsTable, unitTag)
			settingsTable.id = UniversalTracker.nextID
			UniversalTracker.nextID = UniversalTracker.nextID + 1
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
			if v.control then
				if v.control.object then
					v.control.object:SetHidden(v.hidden)
				else
					local tempNode = v.control.head
					while tempNode do
						if tempNode.value and tempNode.value.control then 
							tempNode.value.control:SetHidden(v.hidden)
						end
						tempNode = tempNode.next
					end
				end
			end
		end
		for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
			if v.control then
				if v.control.object then
					v.control.object:SetHidden(v.hidden)
				else
					local tempNode = v.control.head
					while tempNode do
						if tempNode.value and tempNode.value.control then 
							tempNode.value.control:SetHidden(v.hidden)
						end
						tempNode = tempNode.next
					end
				end
			end
		end
	elseif newState == SCENE_FRAGMENT_HIDDEN then
		--hide everything.
		for k, v in pairs(UniversalTracker.savedVariables.trackerList) do
			if v.control then
				if v.control.object then
					v.control.object:SetHidden(true)
				else
					local tempNode = v.control.head
					while tempNode do
						if tempNode.value and tempNode.value.control then 
							tempNode.value.control:SetHidden(true)
						end
						tempNode = tempNode.next
					end
				end
			end
		end
		for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
			if v.control then
				if v.control.object then
					v.control.object:SetHidden(true)
				else
					local tempNode = v.control.head
					while tempNode do
						if tempNode.value and tempNode.value.control then 
							tempNode.value.control:SetHidden(true)
						end
						tempNode = tempNode.next
					end
				end
			end
		end
	end
end

-- TODO pool releases for group/boss bars
function UniversalTracker.Initialize()
	UniversalTracker.savedVariables = ZO_SavedVars:NewAccountWide("UniversalTrackerSavedVariables", 1, nil, UniversalTracker.defaults, GetWorldName())
	UniversalTracker.characterSavedVariables = ZO_SavedVars:NewCharacterIdSettings("UniversalTrackerSavedVariables", 1, nil, UniversalTracker.defaults, GetWorldName())

	UniversalTracker.chat = LibChatMessage("UniversalTracker", "UniversalTracker")

    UniversalTracker.barPool = ZO_ControlPool:New("SingleBarDuration", GuiRoot)
    UniversalTracker.barPool:SetResetFunction(function(control)
			control:SetHidden(true)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_EFFECT_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_COMBAT_EVENT)
			EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
	end)
	UniversalTracker.barPool:SetCustomResetBehavior(function(control)
		for k, v  in pairs(UniversalTracker.savedVariables.trackerList) do
			if v.control and v.control.object == control then
				v.control.object = nil
				v.control.key = nil
				return
			end
		end
		for k, v  in pairs(UniversalTracker.characterSavedVariables.trackerList) do
			if v.control and v.control.object == control then
				v.control.object = nil
				v.control.key = nil
				return
			end
		end
	end)

	UniversalTracker.barAnimationPool = ZO_AnimationPool:New("SingleBarAnimation")
	UniversalTracker.barAnimationPool:SetCustomResetBehavior(function(animation)
		for k, v  in pairs(UniversalTracker.savedVariables.trackerList) do
			if v.animation and v.animation.object == animation then
				v.animation.object = nil
				v.animation.key = nil
				return
			end
		end
		for k, v  in pairs(UniversalTracker.characterSavedVariables.trackerList) do
			if v.animation and v.animation.object == animation then
				v.animation.object = nil
				v.animation.key = nil
				return
			end
		end
	end)

	UniversalTracker.compactPool = ZO_ControlPool:New("SingleCompactTracker", GuiRoot)
    UniversalTracker.compactPool:SetResetFunction(function(control)
			control:SetHidden(true)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_EFFECT_CHANGED)
			EVENT_MANAGER:UnregisterForEvent(UniversalTracker.name..control:GetName(), EVENT_COMBAT_EVENT)
			EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name..control:GetName())
	end)
	UniversalTracker.compactPool:SetCustomResetBehavior(function(control)
		for k, v  in pairs(UniversalTracker.savedVariables.trackerList) do
			if v.control and v.control.object == control then
				v.control.object = nil
				v.control.key = nil
				return
			end
		end
		for k, v  in pairs(UniversalTracker.characterSavedVariables.trackerList) do
			if v.control and v.control.object == control then
				v.control.object = nil
				v.control.key = nil
				return
			end
		end
	end)

    UniversalTracker.InitSettings()

	for k, v in pairs (UniversalTracker.savedVariables.trackerList) do
		UniversalTracker.savedVariables.trackerList.control = {object = nil, key = nil}
		UniversalTracker.InitSingleDisplay(v)
	end
	for k, v in pairs (UniversalTracker.characterSavedVariables.trackerList) do
		UniversalTracker.characterSavedVariables.trackerList.control = {object = nil, key = nil}
		UniversalTracker.InitSingleDisplay(v)
	end

	HUD_FRAGMENT:RegisterCallback("StateChange", fragmentChange)

	EVENT_MANAGER:RegisterForEvent(UniversalTracker.name.."_IDScan", EVENT_EFFECT_CHANGED, function(_, changeType, effectSlot, _, tag, startTime, endTime, _, _, _, _, _, _, _, unitID, abilityID, _) 
		if tag == "player" or string.find(tag, "group") or string.find(tag, "boss") then
			UniversalTracker.unitIDs[unitID] = tag
		end
	end)

	local function resetIDList() UniversalTracker.unitIDs = {} end
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