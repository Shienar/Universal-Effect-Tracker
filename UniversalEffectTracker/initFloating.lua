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

local function StartMovingControl(trackerID, control, key, unitTag)
    table.insert(UniversalTracker.FloatingControls.list[trackerID], {key = key, object = control, unitTag = unitTag})
    UniversalTracker.FloatingControls.totalFloatingControlCount = UniversalTracker.FloatingControls.totalFloatingControlCount + 1
    if UniversalTracker.FloatingControls.totalFloatingControlCount == 1 then
        EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.."RotateFloatingObjects", 1, RotateFloatingControls)
    end

    local textureControl = control:GetNamedChild("Texture")
    EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.."MoveFloatingObject"..control:GetName(), 1, function()
        local _, x, y, z = GetUnitRawWorldPosition(unitTag)
        textureControl:Set3DRenderSpaceOrigin(WorldPositionToGuiRender3DPosition(x, y+300, z)) --TODO: Allow players to specify a height.      
    end)
end

local function StopMovingControl(trackerID, control)
    for k, v in pairs(UniversalTracker.FloatingControls.list[trackerID]) do
        if v.object:GetName() == control:GetName() then
            table.remove(UniversalTracker.FloatingControls.list[trackerID], k)
            break
        end
    end
    UniversalTracker.FloatingControls.totalFloatingControlCount = UniversalTracker.FloatingControls.totalFloatingControlCount - 1
    if UniversalTracker.FloatingControls.totalFloatingControlCount == 0 then
        EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.."RotateFloatingObjects")
    end

    EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.."MoveFloatingObject"..control:GetName())
end

function UniversalTracker.InitFloating(settingsTable, unitTag)

    --This needs to be done for each control upon effect gain.
    -- Target types: player, group, boss
    -- Events for each

    if settingsTable.targetType == "Boss" then
    elseif settingsTable.targetType == "Group" then
    elseif settingsTable.targetType == "Player" then
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

        if not UniversalTracker.FloatingControls.list[settingsTable.id] then
            UniversalTracker.FloatingControls.list[settingsTable.id] = {}
        end

        StartMovingControl(settingsTable.id, floatingControl, floatingControlKey, unitTag)
    end
    
end