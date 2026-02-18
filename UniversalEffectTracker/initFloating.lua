--Rotate all floating controls at the same time to avoid recalculations.
local function RotateFloatingControls()
    -- Returns the components of a unit vector in the direction of the player's camera
    local x, y, z = GetCameraForward(SPACE_WORLD)

    --Calculate the orientation of the unit vector.
    --Negate the pitch and Rotate the yaw by 180 degrees so it faces the camera.
    local pitch = -math.asin(-y)
    local yaw = zo_atan2(x, z) - math.pi

    for k, v in pairs(UniversalTracker.FloatingControls.list) do
        for index, data in pairs(v) do
            if data and data.object and not data.object:IsHidden() then 
                data.object:GetNamedChild("Texture"):Set3DRenderSpaceOrientation(pitch, yaw, 0)
            end
        end
    end
end

local function StartMovingControl(trackerID, control, key, unitTag, yOffset)
    if not UniversalTracker.FloatingControls.list[trackerID] then
        UniversalTracker.FloatingControls.list[trackerID] = {}
    end

    table.insert(UniversalTracker.FloatingControls.list[trackerID], {key = key, object = control, unitTag = unitTag})

    UniversalTracker.FloatingControls.totalFloatingControlCount = UniversalTracker.FloatingControls.totalFloatingControlCount + 1

    if UniversalTracker.FloatingControls.totalFloatingControlCount == 1 then
        EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.."RotateFloatingObjects", 1, RotateFloatingControls)
    end

    local textureControl = control:GetNamedChild("Texture")
    EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.."MoveFloatingObject"..control:GetName(), 1, function()
        local _, x, y, z = GetUnitRawWorldPosition(unitTag)
        textureControl:Set3DRenderSpaceOrigin(WorldPositionToGuiRender3DPosition(x, y+yOffset, z))
    end)
end

function UniversalTracker.RefreshFloatingList(settingsTable, unitTagPrefix)
    UniversalTracker.ReleaseSingleDisplay(settingsTable)
    for i = 1, 12 do
        if(DoesUnitExist(unitTagPrefix..i)) then
            UniversalTracker.InitFloating(settingsTable, unitTagPrefix..i)
        end
    end
end

function UniversalTracker.InitFloating(settingsTable, unitTag)
    
    local floatingControl, floatingControlKey = UniversalTracker.floatingPool:AcquireObject()
    local textureControl = floatingControl:GetNamedChild("Texture")
    textureControl:Create3DRenderSpace()
    textureControl:Set3DRenderSpaceSystem(GUI_RENDER_3D_SPACE_SYSTEM_WORLD)
    textureControl:Set3DLocalDimensions(0.5 * settingsTable.scale, 0.5 * settingsTable.scale)

    if settingsTable.overrideTexturePath == "" then
        textureControl:SetTexture(GetAbilityIcon(next(settingsTable.hashedAbilityIDs)))
    else
        textureControl:SetTexture(settingsTable.overrideTexturePath)
    end

    StartMovingControl(settingsTable.id, floatingControl, floatingControlKey, unitTag, 200+100*settingsTable.scale)

    if DoesUnitExist(unitTag) then
        for i = 1, GetNumBuffs(unitTag) do
            local _, _, _, _, _, _, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo(unitTag, i)
            if settingsTable.hashedAbilityIDs[abilityId] then
                if settingsTable.overrideTexturePath == "" then
                    textureControl:SetTexture(GetAbilityIcon(abilityId))
                else
                    textureControl:SetTexture(settingsTable.overrideTexturePath)
                end

                if settingsTable.hideInactive then
                    if HUD_FRAGMENT.status ~= "hidden" then floatingControl:SetHidden(false) end
                elseif settingsTable.hideActive then
                    floatingControl:SetHidden(true)
                end
                break
            end
        end
        
        if settingsTable.hideInactive then
            floatingControl:SetHidden(true)
        elseif settingsTable.hideActive then
            if HUD_FRAGMENT.status ~= "hidden" then floatingControl:SetHidden(false) end
        end
    end

    EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..floatingControl:GetName(), EVENT_COMBAT_EVENT, function( _, result, _, _, _, _, _, sourceType, _, _, hitValue, _, _, _, _, unitID, abilityID, _)
		if not AreUnitsEqual(unitTag, UniversalTracker.unitIDs[unitID]) then return end

        if result == ACTION_RESULT_DIED or result == ACTION_RESULT_DIED_XP  then
            floatingControl:SetHidden(true)
        elseif settingsTable.hashedAbilityIDs[abilityID] and not (settingsTable.appliedBySelf and sourceType ~= COMBAT_UNIT_TYPE_PLAYER and sourceType ~= COMBAT_UNIT_TYPE_PLAYER_PET) then

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
				
                if settingsTable.hideInactive then
                    if HUD_FRAGMENT.status ~= "hidden" then floatingControl:SetHidden(false) end
                elseif settingsTable.hideActive then
                    floatingControl:SetHidden(true)
                end

			elseif result == ACTION_RESULT_EFFECT_FADED then
                if settingsTable.hideInactive then
                    floatingControl:SetHidden(true)
                elseif settingsTable.hideActive then
                    if HUD_FRAGMENT.status ~= "hidden" then floatingControl:SetHidden(false) end
                end
            end
        end
    end)

    EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..floatingControl:GetName(), EVENT_EFFECT_CHANGED, function( _, changeType, _, _, tag, startTime, endTime, stackCount, _, _, _, _, _, _, _, abilityID, sourceType)
		if settingsTable.hashedAbilityIDs[abilityID] and
			not (settingsTable.appliedBySelf and sourceType ~= COMBAT_UNIT_TYPE_PLAYER and sourceType ~= COMBAT_UNIT_TYPE_PLAYER_PET) then

            if changeType == EFFECT_RESULT_FADED then
			    
                --if faded with others running then return.
				for i = 1, GetNumBuffs(unitTag) do
					local _, _, _, _, _, _, _, _, _, _, buffID, _, _ = GetUnitBuffInfo(unitTag, i)
					if settingsTable.hashedAbilityIDs[buffID] and abilityID ~= buffID then return end
				end

                if settingsTable.hideInactive then
                    floatingControl:SetHidden(true)
                elseif settingsTable.hideActive then
                    if HUD_FRAGMENT.status ~= "hidden" then floatingControl:SetHidden(false) end
                end

			else
                
                if settingsTable.overrideTexturePath == "" then
                    textureControl:SetTexture(GetAbilityIcon(abilityID))
                else
                    textureControl:SetTexture(settingsTable.overrideTexturePath)
                end

                if settingsTable.hideInactive then
                    if HUD_FRAGMENT.status ~= "hidden" then floatingControl:SetHidden(false) end
                elseif settingsTable.hideActive then
                    floatingControl:SetHidden(true)
                end

            end

        end
    end)

    EVENT_MANAGER:RegisterForEvent(UniversalTracker.name..floatingControl:GetName(), EVENT_UNIT_DEATH_STATE_CHANGED, function(_, tag, isDead)
        if isDead == false then
            if settingsTable.hideInactive then
                floatingControl:SetHidden(true)
            else
                if HUD_FRAGMENT.status ~= "hidden" then floatingControl:SetHidden(false) end
            end
        end
    end)
	EVENT_MANAGER:AddFilterForEvent(UniversalTracker.name..settingsTable.id, EVENT_UNIT_DEATH_STATE_CHANGED, REGISTER_FILTER_UNIT_TAG, unitTag)
    
end