GET = GET or {}
GET.name = "GeneralEffectTracker"

--[[
	TODO LIST:
		-- Give each tracker a unique tracker ID to be used for certain event hooks.
		-- Group/Boss buff panels.
			- Simple:
				- Create a table. (new control)
					- Header row is 1 column equal to the assigned tracker name.
					- Column 1: Texture
					- Column 2: Unit Name
					- Column 3: Duration
						- Add a stack indicator if applicable (e.g. x3)
					- Row count is fixed  
			- Bars:
				- Setting to adjust distance between?
		-- Make the bar pretty
			-- Bar background color settings
			-- Bar border color settings
			-- Bar Animation Color Settings
			-- Bar width/height ratio
		-- Allow for LibCombatAlerts Positioning.
			- Only when editing existing
			- Just search for the y offsets of each type and add there.
]]

GET.defaults = {
	trackerList = {

	}
}

GET.unitIDs = {

}

local function InitSimple(settingsTable, unitTag, control)
	-- Assign values to created controls.

	control:ClearAnchors()
	control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
	control:SetScale(settingsTable.scale)
	control:SetHidden(settingsTable.hidden)
	local textureControl = control:GetNamedChild("Texture")
	local durationControl = control:GetNamedChild("Duration")
	local stackControl = control:GetNamedChild("Stacks")

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
					EVENT_MANAGER:RegisterForUpdate(GET.name..control:GetName(), 100, function()
						local duration = (endTime-GetGameTimeMilliseconds())/1000
						if duration < 0 then
							--Effect Expired
							EVENT_MANAGER:UnregisterForUpdate(GET.name..control:GetName())
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
		EVENT_MANAGER:RegisterForEvent(GET.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED, function()
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
							EVENT_MANAGER:RegisterForUpdate(GET.name..control:GetName(), 100, function()
								local duration = (endTime-GetGameTimeMilliseconds())/1000
								if duration < 0 then
									--Effect Expired
									EVENT_MANAGER:UnregisterForUpdate(GET.name..control:GetName())
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
				EVENT_MANAGER:UnregisterForUpdate(GET.name..control:GetName())
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
		EVENT_MANAGER:RegisterForEvent(GET.name..control:GetName(), EVENT_COMBAT_EVENT, function( _, result, _, _, _, _, _, _, _, _, hitValue, _, _, _, _, unitID, abilityID, _)
			if unitTag == GET.unitIDs[unitID] and settingsTable.hashedAbilityIDs[abilityID] then
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
					EVENT_MANAGER:RegisterForUpdate(GET.name..control:GetName(), 100, function()
						local duration = (endTime-GetGameTimeMilliseconds())/1000
						if duration < 0 then
							--Effect Expired
							EVENT_MANAGER:UnregisterForUpdate(GET.name..control:GetName())
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
					EVENT_MANAGER:UnregisterForUpdate(GET.name..control:GetName())
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

	EVENT_MANAGER:RegisterForEvent(GET.name..control:GetName(), EVENT_EFFECT_CHANGED, function( _, changeType, _, _, tag, startTime, endTime, stackCount, _, _, _, _, _, _, _, abilityID, _)
		if settingsTable.hashedAbilityIDs[abilityID] then
			if stackCount == 0 or changeType == EFFECT_RESULT_FADED then stackCount = "" end --stackcount can be 1 instead of 0 after final stone giant cast for example.
			stackControl:SetText(stackCount) 
			if settingsTable.overrideTexturePath == "" then
				textureControl:SetTexture(GetAbilityIcon(abilityID))
			else
				textureControl:SetTexture(settingsTable.overrideTexture)
			end
			if changeType ~= EFFECT_RESULT_FADED and not IsAbilityPermanent(abilityID) then
				endTime = endTime * 1000
				EVENT_MANAGER:RegisterForUpdate(GET.name..control:GetName(), 100, function()
					local duration = (endTime-GetGameTimeMilliseconds())/1000
					if duration < 0 then
						--Effect Expired
						EVENT_MANAGER:UnregisterForUpdate(GET.name..control:GetName())
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
	EVENT_MANAGER:AddFilterForEvent(GET.name..control:GetName(), EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, unitTag)
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
		EVENT_MANAGER:RegisterForEvent(GET.name..control:GetName(), EVENT_RETICLE_TARGET_CHANGED, function()
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
		EVENT_MANAGER:RegisterForEvent(GET.name..control:GetName(), EVENT_COMBAT_EVENT, function( _, result, _, _, _, _, _, _, _, _, hitValue, _, _, _, _, unitID, abilityID, _)
			if unitTag == GET.unitIDs[unitID] and settingsTable.hashedAbilityIDs[abilityID] then
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

	EVENT_MANAGER:RegisterForEvent(GET.name.. control:GetName(), EVENT_EFFECT_CHANGED, function(_, changeType, effectSlot, _, tag, startTime, endTime, _, _, _, _, _, _, _, _, abilityID, _) 
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
	EVENT_MANAGER:AddFilterForEvent(GET.name.. control:GetName(), EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, unitTag)

end

local function InitBarList(settingsTable, unitTag)
	settingsTable.control, settingsTable.animation = {head = nil, tail = nil}, {head = nil, tail = nil}
	-- Initialize linked list with current bosses / group members
	for i = 1, 12 do
		if DoesUnitExist(unitTag..i) then
			local newControl, newControlKey = GET.barPool:AcquireObject()
			local newAnimation, newAnimationKey = GET.barAnimationPool:AcquireObject()

			local newControlNode = {next = nil, prev = settingsTable.control.tail, value = {control = newControl, key = newControlKey, unitTag = unitTag..i}}
			if settingsTable.control.tail then
				settingsTable.control.tail.next = newControlNode
			else
				settingsTable.control.head = newControlNode
			end
			settingsTable.control.tail = newControlNode

			local newAnimationNode = { next = nil, prev = settingsTable.animation.tail, value = { animation = newAnimation, key = newAnimationKey } }
			if settingsTable.animation.tail then
				settingsTable.animation.tail.next = newAnimationNode
			else
				settingsTable.animation.head = newAnimationNode
			end
			settingsTable.animation.tail = newAnimationNode
		end
	end

	local current_control = settingsTable.control.head
	local current_animation = settingsTable.animation.head
	while current_control and current_animation do
		InitBar(settingsTable, current_control.value.unitTag, current_control.value.control, current_animation.value.animation)
		if current_control.prev then
			current_control.value.control:ClearAnchors()
			current_control.value.control:SetAnchor(TOPLEFT, current_control.prev.value.control, BOTTOMLEFT, 0, 25)
		end
		current_control = current_control.next
		current_animation = current_animation.next
	end
end

local function updateBarList(settingsTable, unitTag)
	--Step 1: Removed linked list elements if the unittag's boss no longer exists.
	local currentControlNode = settingsTable.control.head
	local currentAnimationNode = settingsTable.animation.head
	while currentControlNode do
		if not DoesUnitExist(currentControlNode.value.unitTag) then
			--update anchors
			if currentControlNode.next then
				if currentControlNode.prev then
					currentControlNode.next.value.control:ClearAnchors()
					currentControlNode.next.value.control:SetAnchor(TOPLEFT, currentControlNode.prev.value.control, BOTTOMLEFT, 0, 25)
				else
					--Position new head
					currentControlNode.next.value.control:ClearAnchors()
					currentControlNode.next.value.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
				end
			end

			--free objects
			GET.barPool:ReleaseObject(currentControlNode.value.key)
			GET.barAnimationPool:ReleaseObject(currentAnimationNode.value.key)

			--remove from table (leave for garbage collector)
			if not currentControlNode.prev then --head
				settingsTable.control.head = currentControlNode.next
				settingsTable.animation.head = currentAnimationNode.next

				if settingsTable.control.head then
					settingsTable.control.head.prev = nil
					settingsTable.animation.head.prev = nil
				end
			else --not head
				currentControlNode.prev.next = currentControlNode.next
				if currentControlNode.next then
					currentControlNode.next.prev = currentControlNode.prev
				end

				currentAnimationNode.prev.next = currentAnimationNode.next
				if currentAnimationNode.next then
					currentAnimationNode.next.prev = currentAnimationNode.prev
				end
			end

			if currentControlNode == settingsTable.control.tail then
				settingsTable.control.tail = currentControlNode.prev
				settingsTable.animation.tail = currentAnimationNode.prev
			end
			
		end
		currentControlNode = currentControlNode.next
		currentAnimationNode = currentAnimationNode.next
	end
	

	--Step 2a: If the linked lists are empty, rebuild them.
	if not settingsTable.control.head then
		InitBarList(settingsTable, unitTag)
	elseif false then
		-- Step 2b: Else, Insert unaccounted for unitIDs into sorted positions within the linked list
		local usedTags = {}
		for i = 1, 12 do
			if DoesUnitExist(unitTag..i) then usedTags[i] = true end
		end

		currentControlNode = settingsTable.control.head
		currentAnimationNode = settingsTable.animation.head
		while currentControlNode do
			local currentTagIndex = string.match(currentControlNode.value.unitTag, "%d+")
			for k, v in pairs(usedTags) do
				if currentTagIndex and k < tonumber(currentTagIndex) then
					usedTags[k] = nil
					--object creation
					local newControl, newControlKey = GET.barPool:AcquireObject()
					local newAnimation, newAnimationKey = GET.barAnimationPool:AcquireObject()
					InitBar(settingsTable, unitTag..k, newControl, newAnimation)

					--List updates
					if currentControlNode == settingsTable.control.head then
						settingsTable.control.head = {next = settingsTable.control.head, prev = nil, value = {control = newControl, key = newControlKey, unitTag = unitTag..k}}
						settingsTable.animation.head = {next = settingsTable.animation.head, prev = nil, value = {animation = newAnimation, key = newAnimationKey}}
					else
						local newControlNode = {next = currentControlNode, prev = currentControlNode.prev, value = {control = newControl, key = newControlKey, unitTag = unitTag..k}}
						local newAnimationNode = {next = currentAnimationNode, prev = currentAnimationNode.prev, value = {animation = newAnimation, key = newAnimationKey}}
						currentControlNode.prev.next = newControlNode
						currentControlNode.prev =  newControlNode
						currentAnimationNode.prev.next = newAnimationNode
						currentAnimationNode.prev = newAnimationNode
					end


					--Anchor updates
					if newControl.prev then
						newControl:ClearAnchors()
						newControl:SetAnchor(TOPLEFT, newControl.prev.value.control, BOTTOMLEFT, 0, 25)
					else
						newControl:ClearAnchors()
						newControl:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, settingsTable.x, settingsTable.y)
					end
					currentControlNode.value.control:ClearAnchors()
					currentControlNode.value.control:SetAnchor(TOPLEFT, currentControlNode.prev.value.control, BOTTOMLEFT, 0, 25)
				end
			end
			currentControlNode = currentControlNode.next
			currentAnimationNode = currentAnimationNode.next
		end

		--insert after tail
		-- we know that the list isn't empty at this point.
		for k, v in pairs(usedTags) do
			--object creation
			local newControl, newControlKey = GET.barPool:AcquireObject()
			local newAnimation, newAnimationKey = GET.barAnimationPool:AcquireObject()
			InitBar(settingsTable, unitTag..k, newControl, newAnimation)

			--list updates
			local newControlNode = {next = nil, prev = settingsTable.control.tail, value = {control = newControl, key = newControlKey, unitTag = unitTag..k}}
			local newAnimationNode = {next = nil, prev = settingsTable.animation.tail, value = {animation = newAnimation, key = newAnimationKey}}
			settingsTable.control.tail.next = newControlNode
			settingsTable.animation.tail.next = newAnimationNode
			settingsTable.control.tail = newControlNode
			settingsTable.animation.tail = newAnimationNode

			--anchor updates
			newControl:ClearAnchors()
			newControl:SetAnchor(TOPLEFT, newControlNode.prev.value.control, BOTTOMLEFT, 0, 25)
		end
		
	end
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
			if not settingsTable.control.object then
				settingsTable.control.object, settingsTable.control.key = GET.simplePool:AcquireObject()
			elseif string.find(settingsTable.control.object:GetName(), "Bar") then
				GET.barAnimationPool:ReleaseObject(settingsTable.animation.key)
				GET.barPool:ReleaseObject(settingsTable.control.key)
				settingsTable.control.object, settingsTable.control.key = GET.simplePool:AcquireObject()
			--elseif old tracker was a simple panel
			--elseif old tracker was a bar panel
			end

			InitSimple(settingsTable, unitTag, settingsTable.control.object)
		elseif settingsTable.type == "Bar" then
			if not settingsTable.control.object then
				settingsTable.control.object, settingsTable.control.key = GET.barPool:AcquireObject()
				settingsTable.animation.object, settingsTable.animation.key = GET.barAnimationPool:AcquireObject()
			elseif string.find(settingsTable.control:GetName(), "Simple") then
				GET.simplePool:ReleaseObject(settingsTable.control.key)
				settingsTable.control.object, settingsTable.control.key = GET.barPool:AcquireObject()
				settingsTable.animation.object, settingsTable.animation.key = GET.barAnimationPool:AcquireObject()
			--elseif old tracker was a simple panel
			--elseif old tracker was a bar panel
			end

			InitBar(settingsTable, unitTag, settingsTable.control.object, settingsTable.animation.object)
		end
	elseif unitTag == "boss" or unitTag == "group" then
		if settingsTable.type == "Simple" then

		elseif settingsTable.type == "Bar" then
			if  settingsTable.control.object then
				GET.barPool:ReleaseObject(settingsTable.control.key)
			end
			if settingsTable.animation.object then
				GET.barAnimationPool:ReleaseObject(settingsTable.animation.key)
			end
			
			--initialize current.
			InitBarList(settingsTable, unitTag)
			
			--register events.
			if unitTag == "boss" then
				--todo: find consistent naming scheme.
				EVENT_MANAGER:RegisterForEvent(GET.name, EVENT_BOSSES_CHANGED, function() updateBarList(settingsTable, unitTag) end)
			elseif unitTag == "group" then
				--todo: find consistent naming scheme.
				EVENT_MANAGER:RegisterForEvent(GET.name, EVENT_GROUP_MEMBER_JOINED, function() updateBarList(settingsTable, unitTag) end)
				EVENT_MANAGER:RegisterForEvent(GET.name, EVENT_GROUP_MEMBER_LEFT, function() updateBarList(settingsTable, unitTag) end)
			end

		end
	end
end

local function fragmentChange(oldState, newState)
	if newState == SCENE_FRAGMENT_SHOWN then
		--unhide everything.
		for k, v in pairs(GET.savedVariables.trackerList) do
			if v.control then
				if v.control.object then
					v.control.object:SetHidden(v.hidden)
				else
					local tempNode = v.control
					while tempNode do
						if tempNode.value and tempNode.value.control then 
							tempNode.value.control:SetHidden(v.hidden)
						end
						tempNode = tempNode.next
					end
				end
			end
		end
		for k, v in pairs(GET.characterSavedVariables.trackerList) do
			if v.control then
				if v.control.object then
					v.control.object:SetHidden(v.hidden)
				else
					local tempNode = v.control
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
		for k, v in pairs(GET.savedVariables.trackerList) do
			if v.control then
				if v.control.object then
					v.control.object:SetHidden(true)
				else
					local tempNode = v.control
					while tempNode do
						if tempNode.value and tempNode.value.control then 
							tempNode.value.control:SetHidden(true)
						end
						tempNode = tempNode.next
					end
				end
			end
		end
		for k, v in pairs(GET.characterSavedVariables.trackerList) do
			if v.control then
				if v.control.object then
					v.control.object:SetHidden(true)
				else
					local tempNode = v.control
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
function GET.Initialize()
	GET.savedVariables = ZO_SavedVars:NewAccountWide("GETSavedVariables", 1, nil, GET.defaults, GetWorldName())
	GET.characterSavedVariables = ZO_SavedVars:NewCharacterIdSettings("GETSavedVariables", 1, nil, GET.defaults, GetWorldName())

	GET.chat = LibChatMessage("GET", "GET")

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
			if v.control.object == control then
				v.control.object = nil
				v.control.key = nil
				return
			end
		end
		for k, v  in pairs(GET.characterSavedVariables.trackerList) do
			if v.control.object == control then
				v.control.object = nil
				v.control.key = nil
				return
			end
		end
	end)

	GET.barAnimationPool = ZO_AnimationPool:New("SingleBarAnimation")
	GET.barAnimationPool:SetCustomResetBehavior(function(animation)
		for k, v  in pairs(GET.savedVariables.trackerList) do
			if v.animation.object == animation then
				v.animation.object = nil
				v.animation.key = nil
				return
			end
		end
		for k, v  in pairs(GET.characterSavedVariables.trackerList) do
			if v.animation.object == animation then
				v.animation.object = nil
				v.animation.key = nil
				return
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
			if v.control.object == control then
				v.control.object = nil
				v.control.key = nil
				return
			end
		end
		for k, v  in pairs(GET.characterSavedVariables.trackerList) do
			if v.control.object == control then
				v.control.object = nil
				v.control.key = nil
				return
			end
		end
	end)

    GET.InitSettings()

	for k, v in pairs (GET.savedVariables.trackerList) do
		GET.InitSingleDisplay(v)
	end
	for k, v in pairs (GET.characterSavedVariables.trackerList) do
		GET.InitSingleDisplay(v)
	end

	HUD_FRAGMENT:RegisterCallback("StateChange", fragmentChange)

	EVENT_MANAGER:RegisterForEvent(GET.name.."_IDScan", EVENT_EFFECT_CHANGED, function(_, changeType, effectSlot, _, tag, startTime, endTime, _, _, _, _, _, _, _, unitID, abilityID, _) 
		if tag == "player" or string.find(tag, "group") or string.find(tag, "boss") then
			GET.unitIDs[unitID] = tag
		end
	end)

	local function resetIDList() GET.unitIDs = {} end
	EVENT_MANAGER:RegisterForEvent(GET.name.."_IDClear", EVENT_BOSSES_CHANGED, resetIDList)
	EVENT_MANAGER:RegisterForEvent(GET.name.."_IDClear", EVENT_GROUP_MEMBER_JOINED, resetIDList)
	EVENT_MANAGER:RegisterForEvent(GET.name.."_IDClear", EVENT_GROUP_MEMBER_LEFT, resetIDList)

end

function GET.OnAddOnLoaded(event, addonName)
	if addonName == GET.name then
		GET.Initialize()
		EVENT_MANAGER:UnregisterForEvent(GET.name, EVENT_ADD_ON_LOADED)
	end
end

EVENT_MANAGER:RegisterForEvent(GET.name, EVENT_ADD_ON_LOADED, GET.OnAddOnLoaded)