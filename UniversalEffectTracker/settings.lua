UniversalTracker = UniversalTracker or {}

local settings = nil
local settingPages = {
	mainMenu = {},
	setupList = {},
	newSetup = {},
	trackedList = {},
	newTracker = {},
	utilities = {},
}
local currentPageIndex = 2
local editIndex = -1
local isCharacterSettings = false

-- New/updated tracker settings. Local until "save"
-- These are default values for a new tracker.
local newTracker = {
	id = -1,
	control = {
		object = nil,
		key = nil,
	},
	animation = {
		object = nil,
		key = nil,
	},
	name = "",
	type = "Compact",
	targetType = "Player",
	listSettings = {
		columns = 1,
		horizontalOffsetScale = 1,
		verticalOffsetScale = 1,
	},
	textSettings = {
		duration = {
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
		abilityLabel = {
			color = {
				r = 1,
				g = 1,
				b = 1,
				a = 1,
			},
			textScale = 1,
			x = 5,
			y = 0,
			hidden = false,
		},
		unitLabel = {
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
			accountName = true,
		},
	},
	abilityIDs = { --abilityIDs are values. indexes increase by 1 from 1. Each setting gets an index.
		[1] = "",
	},
	hashedAbilityIDs = { --abilityIDs are keys

	},
	overrideTexturePath = "",
	x = 0,
	y = 0,
	scale = 1,
	hidden = false,
}

local newSetup = {
	name = "New Setup",
	id = -1,
	trackerIDList = {

	}
}

local function createHashedIDList(settingAbilityIDs)
	local hashedAbilityIDs = {}
	for k, v in pairs(settingAbilityIDs) do
		if tonumber(v) ~= nil then
			hashedAbilityIDs[tonumber(v)] = true
		end
	end
	return hashedAbilityIDs
end

local function loadMenu(menu, jumpToIndex)
	if settings then
		settings:RemoveAllSettings()
		settings:AddSettings(menu, nil, true)
		if IsConsoleUI() and jumpToIndex and jumpToIndex >= 1 and jumpToIndex <= #settings.settings then
			LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(jumpToIndex)
		end
	end
end

local function temporarilyShowControl(index) 
    --Hide control 5 seconds after most recent change.
	--This function is safe to call when no controls exist.

	local control
	local controlHead
	if not isCharacterSettings and UniversalTracker.savedVariables.trackerList[index] then
		control = UniversalTracker.savedVariables.trackerList[index].control.object
		controlHead = UniversalTracker.savedVariables.trackerList[index].control.head
	elseif UniversalTracker.characterSavedVariables.trackerList[index] then
		control = UniversalTracker.characterSavedVariables.trackerList[index].control.object
		controlHead = UniversalTracker.characterSavedVariables.trackerList[index].control.head
	end
	if control then
		control:SetHidden(false)
		EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.." move "..control:GetName(), 5000, function()
			if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN then
				control:SetHidden(true)
			end
			EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.." move "..control:GetName())
		end)
	elseif controlHead and controlHead.value.control then
		local curNode = controlHead
		while curNode do
			curNode.value.control:SetHidden(false)
			curNode = curNode.next
		end
		EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.." move "..UniversalTracker.savedVariables.trackerList[index].id, 5000, function()
			if SCENE_MANAGER:GetScene("hud"):GetState() == SCENE_HIDDEN then
				curNode = controlHead
				while curNode do
					curNode.value.control:SetHidden(true)
					curNode = curNode.next
				end
			end
			EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.." move "..UniversalTracker.savedVariables.trackerList[index].id)
		end)
	end
end

local function copySetup(source, dest)
	dest = {}

	dest.name = source.name
	dest.id = source.id
	dest.trackerIDList = {}
	for k, v in pairs(source.trackerIDList) do
		dest.trackerIDList[k] = v
	end
end

local function copyTracker(source, dest, nullifyControls)
	dest = {}

	-- Removing usage of ZO_DeepTableCopy in fear that it is the reason that this addon is corrupting save files.

	dest.id = source.id
	dest.name = source.name
	dest.type = source.type
	dest.targetType = source.targetType
	dest.listSettings = {}
	dest.listSettings.columns = source.listSettings.columns
	dest.listSettings.horizontalOffsetScale = source.listSettings.horizontalOffsetScale
	dest.listSettings.verticalOffsetScale = source.listSettings.verticalOffsetScale
	dest.textSettings = {}
	dest.textSettings.duration = {}
	dest.textSettings.duration.color = {}
	dest.textSettings.duration.color.r = source.textSettings.duration.color.r
	dest.textSettings.duration.color.g = source.textSettings.duration.color.g
	dest.textSettings.duration.color.b = source.textSettings.duration.color.b
	dest.textSettings.duration.color.a = source.textSettings.duration.color.a
	dest.textSettings.duration.textScale = source.textSettings.duration.textScale
	dest.textSettings.duration.x = source.textSettings.duration.x
	dest.textSettings.duration.y = source.textSettings.duration.y
	dest.textSettings.duration.hidden = source.textSettings.duration.hidden
	dest.textSettings.stacks = {}
	dest.textSettings.stacks.color = {}
	dest.textSettings.stacks.color.r = source.textSettings.stacks.color.r
	dest.textSettings.stacks.color.g = source.textSettings.stacks.color.g
	dest.textSettings.stacks.color.b = source.textSettings.stacks.color.b
	dest.textSettings.stacks.color.a = source.textSettings.stacks.color.a
	dest.textSettings.stacks.textScale = source.textSettings.stacks.textScale
	dest.textSettings.stacks.x = source.textSettings.stacks.x
	dest.textSettings.stacks.y = source.textSettings.stacks.y
	dest.textSettings.stacks.hidden = source.textSettings.stacks.hidden
	dest.textSettings.abilityLabel = {}
	dest.textSettings.abilityLabel.color = {}
	dest.textSettings.abilityLabel.color.r = source.textSettings.abilityLabel.color.r
	dest.textSettings.abilityLabel.color.g = source.textSettings.abilityLabel.color.g
	dest.textSettings.abilityLabel.color.b = source.textSettings.abilityLabel.color.b
	dest.textSettings.abilityLabel.color.a = source.textSettings.abilityLabel.color.a
	dest.textSettings.abilityLabel.textScale = source.textSettings.abilityLabel.textScale
	dest.textSettings.abilityLabel.x = source.textSettings.abilityLabel.x
	dest.textSettings.abilityLabel.y = source.textSettings.abilityLabel.y
	dest.textSettings.abilityLabel.hidden = source.textSettings.abilityLabel.hidden
	dest.textSettings.unitLabel = {}
	dest.textSettings.unitLabel.color = {}
	dest.textSettings.unitLabel.color.r = source.textSettings.unitLabel.color.r
	dest.textSettings.unitLabel.color.g = source.textSettings.unitLabel.color.g
	dest.textSettings.unitLabel.color.b = source.textSettings.unitLabel.color.b
	dest.textSettings.unitLabel.color.a = source.textSettings.unitLabel.color.a
	dest.textSettings.unitLabel.textScale = source.textSettings.unitLabel.textScale
	dest.textSettings.unitLabel.x = source.textSettings.unitLabel.x
	dest.textSettings.unitLabel.y = source.textSettings.unitLabel.y
	dest.textSettings.unitLabel.hidden = source.textSettings.unitLabel.hidden
	dest.textSettings.unitLabel.accountName = source.textSettings.unitLabel.accountName
	dest.abilityIDs = {}
	for k, v in pairs(source.abilityIDs) do
		dest.abilityIDs[k] = v
	end
	dest.hashedAbilityIDs = {}
	for k, v in pairs(source.hashedAbilityIDs) do
		dest.hashedAbilityIDs[k] = v
	end
	dest.overrideTexturePath = source.overrideTexturePath
	dest.x = source.x
	dest.y = source.y
	dest.scale = source.scale
	dest.hidden = source.hidden

	dest.control = {}
	dest.animation = {}
	if source.control.head then
		if nullifyControls then
			dest.control.head = nil
			dest.control.tail = nil
			dest.animation.head = nil
			dest.animation.tail = nil
		else
			local cur_source = source.control.head
			dest.control = {
				head = {next = cur_source.next, prev = cur_source.prev, 
					value = {control = cur_source.value.control, key = cur_source.value.key, unitTag = cur_source.value.unitTag}}, 
				tail = nil
			}
			local cur_dest = dest.control.head
			cur_source = cur_source.next
			cur_dest = cur_dest.next
			while cur_source do
				cur_dest.next = {next = cur_source.next, prev = cur_source.prev, 
					value = {control = cur_source.value.control, key = cur_source.value.key, unitTag = cur_source.value.unitTag}}
				cur_source = cur_source.next
				if not cur_source then
					dest.control.tail = cur_dest
				end
			end

			if source.animation and source.animation.head then
				cur_source = source.animation.head
				dest.animation = {
					head = {next = cur_source.next, prev = cur_source.prev, 
						value = {animation = cur_source.value.animation, key = cur_source.value.key}}, 
					tail = nil
				}
				cur_dest = dest.animation.head
				cur_source = cur_source.next
				cur_dest = cur_dest.next
				while cur_source do
					cur_dest.next = {next = cur_source.next, prev = cur_source.prev, 
						value = {animation = cur_source.value.animation, key = cur_source.value.key}}
					cur_source = cur_source.next
					if not cur_source then
						dest.animation.tail = cur_dest
					end
				end
			end
		end
	else
		if nullifyControls then
			dest.control.object = nil
			dest.control.key = nil
			dest.animation.object = nil
			dest.animation.key = nil
		else
			dest.control.object = source.control.object
			dest.control.key = source.control.key
			dest.animation.object = source.animation.object
			dest.animation.key = source.animation.key
		end
	end

	-- Remove abilityIDs marked for deletion.
	local index = 1
	while dest.abilityIDs[index] do
		if tonumber(dest.abilityIDs[index]) then
			index = index + 1
		else
			table.remove(dest.abilityIDs, index)
		end
	end
end

local function getNextAvailableIndex(charSettings, isSetup)
	local index = 1
	if isSetup then
		if not charSettings then
			while UniversalTracker.savedVariables.setupList[index] do
				index = index + 1
			end
		else
			while UniversalTracker.characterSavedVariables.setupList[index] do
				index = index + 1
			end
		end
	else
		if not charSettings then
			while UniversalTracker.savedVariables.trackerList[index] do
				index = index + 1
			end
		else
			while UniversalTracker.characterSavedVariables.trackerList[index] do
				index = index + 1
			end
		end
	end
	return index
end

function UniversalTracker.loadSetup(id)
	local idList = nil
	for k, v in pairs(UniversalTracker.savedVariables.setupList) do
		if v.id == id then
			idList = v.trackerIDList
			break
		end
	end
	if not idList then
		for k, v in pairs(UniversalTracker.characterSavedVariables.setupList) do
			if v.id == id then
				idList = v.trackerIDList
			end
		end
	end

	if idList == nil then 
		UniversalTracker.chat:Print("Could not locate setup with id "..tostring(id))
		return
	end

	for k, v in pairs(UniversalTracker.savedVariables.trackerList) do
		if v and v.name and v.id then
			v.hidden = not idList[v.id]
			if v.control and v.control.object then
				v.control.object:SetHidden(v.hidden)
			elseif v.control and v.control.head and v.control.head.value.control then
				UniversalTracker.refreshList(v, string.gsub(v.control.head.value.unitTag, "%d+", ""))
			end
		end
	end
	for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
		if v and v.name and v.id then
			v.hidden = not idList[v.id]
			if v.control and v.control.object then
				v.control.object:SetHidden(v.hidden)
			elseif v.control and v.control.head and v.control.head.value.control then
				UniversalTracker.refreshList(v, string.gsub(v.control.head.value.unitTag, "%d+", ""))
			end
		end
	end

end

function UniversalTracker.InitSettings()
	settings = LibHarvensAddonSettings:AddAddon("Universal Effect Tracker")

	-----------------------------------------------------------
	---		Early Declarations for Self/Cross References	---
	-----------------------------------------------------------
	
	local setNewAbilityID = nil
	local add1AbilityID = nil
	local deleteTracker = nil
	local deleteSetup = nil
	local loadSetup = nil
	local copyTrackerToAccount, copyTrackerToCharacter = nil, nil
	local copySetupToAccount, copySetupToCharacter = nil, nil
	local setNewTrackerSaveType = nil
	local columnCount, horizontalSpacing, verticalSpacing = nil, nil, nil
	local hideStacks, stackFontColor, stackFontScale, stackXOffset, stackYOffset = nil, nil, nil, nil, nil
	local hideAbilityLabel, abilityLabelFontColor, abilityLabelFontScale, abilityLabelXOffset, abilityLabelYOffset  = nil, nil, nil, nil, nil
	local hideunitLabel, preferPlayerName, unitLabelFontColor, unitLabelFontScale, unitLabelXOffset, unitLabelYOffset  = nil, nil, nil, nil, nil, nil

	---------------------------------------
	---				Labels				---
	---------------------------------------

	local setupLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Setups",}
	local trackerLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Trackers",}
	local otherLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Other",}
	local navLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Navigation",}

	local accountTrackersLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Account Trackers",}
	local characterTrackersLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Character Trackers",}

	local editSetupLabel = { type = LibHarvensAddonSettings.ST_SECTION, label = "Edit Setup",}
	local accountSetupsLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Account Setups",}
	local characterSetupsLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Character Setups",}

	local newTrackerMenuLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Edit Tracker",}
	local abilityIDListLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Tracked abilityIDs",}
	local positionLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Position",}
	local listSettingsLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "List Settings",}
	local textSettingsLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Text",}
	local durationLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Duration",}
	local stacksLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Stacks",}
	local abilityNameLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Ability Name",}
	local unitNameLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Unit Name",}

	local printLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Print",}
	local presetLabel = {type = LibHarvensAddonSettings.ST_SECTION, label = "Presets"}

	
	---------------------------------------
	---			Navigation Buttons		---
	---------------------------------------

	local setupListMenuButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "SETUP LIST",
		buttonText = "SETUPS",
		tooltip = "Load, View, Edit, and delete from your list of setups.\n\
					A setup is a collection of trackers. Loading a setup enables all trackers in the collection and disables all other trackers.",
		clickHandler = function(control)
			loadMenu(settingPages.setupList, 2)
			currentPageIndex = 2

			for k, v in pairs(UniversalTracker.savedVariables.setupList) do
				if v and v.name then
					settings:AddSetting({
						type = LibHarvensAddonSettings.ST_BUTTON,
						label = UniversalTracker.savedVariables.setupList[k].name, 
						buttonText = UniversalTracker.savedVariables.setupList[k].name, 
						tooltip = "Load or Edit this setup.",
						clickHandler = function(control)
							editIndex = k
							isCharacterSettings = false
							copySetup(UniversalTracker.savedVariables.setupList[editIndex], newSetup)
							loadMenu(settingPages.newSetup, 2)

							--Remove the save destination
							settings:RemoveSettings(6, 1, false)

							--Add the trackers to toggle for the setup.
							for k, v in pairs(UniversalTracker.savedVariables.trackerList) do
								if v and v.id and v.name then
									settings:AddSetting({
										type = LibHarvensAddonSettings.ST_CHECKBOX,
										label = v.name,
										tooltip = "Choose whether to include this tracker with the setup.",
										getFunction = function() if newSetup.trackerIDList[v.id] then return true else return false end end,
										setFunction = function(value)
											if value == true then
												newSetup.trackerIDList[v.id] = true
											else
												newSetup.trackerIDList[v.id] = nil
											end						
										end,
										default = false
									}, 4, false)
								end
							end

							for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
								if v and v.id and v.name then
									settings:AddSetting({
										type = LibHarvensAddonSettings.ST_CHECKBOX,
										label = v.name,
										tooltip = "Choose whether to include this tracker with the setup.",
										getFunction = function() if newSetup.trackerIDList[v.id] then return true else return false end end,
										setFunction = function(value)
											if value == true then
												newSetup.trackerIDList[v.id] = true
											else
												newSetup.trackerIDList[v.id] = nil
											end						
										end,
										default = false
									}, #settings.settings - 2, false)
								end
							end

							settings:AddSetting(loadSetup, 3, false)

							settings:AddSettings({deleteSetup, copySetupToCharacter, copySetupToAccount}, #settings.settings - 1, false)

						end
					}, #settings.settings - 2, false)
				end
			end

			for k, v in pairs(UniversalTracker.characterSavedVariables.setupList) do
				if v and v.name then
					settings:AddSetting({
						type = LibHarvensAddonSettings.ST_BUTTON,
						label = UniversalTracker.characterSavedVariables.setupList[k].name, 
						buttonText = UniversalTracker.characterSavedVariables.setupList[k].name, 
						tooltip = "Load or Edit this setup.",
						clickHandler = function(control)
							editIndex = k
							isCharacterSettings = true
							copySetup(UniversalTracker.characterSavedVariables.setupList[editIndex], newSetup)
							loadMenu(settingPages.newSetup, 2)

							--Remove the save destination
							settings:RemoveSettings(6, 1, false)

							--Add the trackers to toggle for the setup.
							for k, v in pairs(UniversalTracker.savedVariables.trackerList) do
								if v and v.id and v.name then
									settings:AddSetting({
										type = LibHarvensAddonSettings.ST_CHECKBOX,
										label = v.name,
										tooltip = "Choose whether to include this tracker with the setup.",
										getFunction = function() if newSetup.trackerIDList[v.id] then return true else return false end end,
										setFunction = function(value)
											if value == true then
												newSetup.trackerIDList[v.id] = true
											else
												newSetup.trackerIDList[v.id] = nil
											end						
										end,
										default = false
									}, 4, false)
								end
							end

							for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
								if v and v.id and v.name then
									settings:AddSetting({
										type = LibHarvensAddonSettings.ST_CHECKBOX,
										label = v.name,
										tooltip = "Choose whether to include this tracker with the setup.",
										getFunction = function() if newSetup.trackerIDList[v.id] then return true else return false end end,
										setFunction = function(value)
											if value == true then
												newSetup.trackerIDList[v.id] = true
											else
												newSetup.trackerIDList[v.id] = nil
											end						
										end,
										default = false
									}, #settings.settings - 2, false)
								end
							end

							settings:AddSetting(loadSetup, 3, false)

							settings:AddSettings({deleteSetup, copySetupToCharacter, copySetupToAccount}, #settings.settings - 1, false)

						end
					}, #settings.settings - 1, false)
				end
			end

			LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
		end
	}
	local addNewSetupButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "NEW SETUP",
		buttonText = "ADD NEW",
		tooltip = "Create a new setup.\n\
					A setup is a collection of trackers. Loading a setup enables all trackers in the collection and disables all other trackers.",
		clickHandler = function(control)
			--reset local variables
			newSetup = {
				name = "New Setup",
				id = -1,
				trackerIDList = {

				}
			}

			loadMenu(settingPages.newSetup, 2)
			isCharacterSettings = false

			
			for k, v in pairs(UniversalTracker.savedVariables.trackerList) do
				if v and v.id and v.name then
					settings:AddSetting({
						type = LibHarvensAddonSettings.ST_CHECKBOX,
						label = v.name,
						tooltip = "Choose whether to include this tracker with the setup.",
						getFunction = function() if newSetup.trackerIDList[v.id] then return true else return false end end,
						setFunction = function(value)
							if value == true then
								newSetup.trackerIDList[v.id] = true
							else
								newSetup.trackerIDList[v.id] = nil
							end						
						end,
						default = false
					}, 4, false)
				end
			end

			for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
				if v and v.id and v.name then
					settings:AddSetting({
						type = LibHarvensAddonSettings.ST_CHECKBOX,
						label = v.name,
						tooltip = "Choose whether to include this tracker with the setup.",
						getFunction = function() if newSetup.trackerIDList[v.id] then return true else return false end end,
						setFunction = function(value)
							if value == true then
								newSetup.trackerIDList[v.id] = true
							else
								newSetup.trackerIDList[v.id] = nil
							end						
						end,
						default = false
					}, #settings.settings - 3, false)
				end
			end

			currentPageIndex = 3
			editIndex = -1
		end
	}

	local trackedListMenuButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "TRACKER LIST",
		buttonText = "TRACKERS",
		tooltip = "View, Edit, and delete from your list of tracked effects.",
		clickHandler = function(control)
			loadMenu(settingPages.trackedList, 2)
			currentPageIndex = 5

			--Account trackers
			for k, v in pairs(UniversalTracker.savedVariables.trackerList) do
				if v.name then --avoids creating blank entries in the list.
					settings:AddSetting({
						type = LibHarvensAddonSettings.ST_BUTTON,
						label = UniversalTracker.savedVariables.trackerList[k].name, 
						buttonText = UniversalTracker.savedVariables.trackerList[k].name, 
						tooltip = "Edit this tracker.",
						clickHandler = function(control)
							editIndex = k
							isCharacterSettings = false
							newTracker = copyTracker(UniversalTracker.savedVariables.trackerList[editIndex])
							loadMenu(settingPages.newTracker, 2)

							--remove the base ability ID
							settings:RemoveSettings(8, 1, false)

							--dynamically add the extra ability IDs
							for i = 1, (#UniversalTracker.savedVariables.trackerList[editIndex].abilityIDs) do
								local newIndex = 7 + i
								settings:AddSetting({
									type = setNewAbilityID.type,
									label = setNewAbilityID.label,
									tooltip = setNewAbilityID.tooltip,
									textType = setNewAbilityID.textType,
									maxChars = setNewAbilityID.maxChars,
									getFunction = function() return newTracker.abilityIDs[i] end,
									setFunction = function(value) 
										newTracker.abilityIDs[i] = value
										if value == "0" then
											-- This set function gets executed twice (same millisecond) but we only want to run this once.
											EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.." delete ability at index "..newIndex, 20, function()
												settings:RemoveSettings(LibHarvensAddonSettings.scrollList.lists.Main.selectedIndex, 1, false)
												newTracker.abilityIDs[newIndex - 7] = "MARKED FOR REMOVAL" --removal requires shifting, wait until page gets unloaded.
												EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.." delete ability at index "..newIndex)
											end)
										end
									end,
									default = newTracker.abilityIDs[i]
								}, newIndex, false)
							end

							--Modify settings as needed to fit tracker type
							if newTracker.type == "Bar" then
								local stacksIndex = settings:GetIndexOf(stacksLabel, true)
								if stacksIndex then
									settings:RemoveSettings(stacksIndex, 6, false)
									settings:AddSettings({abilityNameLabel, hideAbilityLabel, abilityLabelFontColor, abilityLabelFontScale, abilityLabelXOffset, abilityLabelYOffset}, 
															stacksIndex, false)
								end
							else
								local nameIndex = settings:GetIndexOf(abilityNameLabel, true)
								if nameIndex then
									settings:RemoveSettings(nameIndex, 6, false)
									settings:AddSettings({stacksLabel, hideStacks, stackFontColor, stackFontScale, stackXOffset, stackYOffset}, nameIndex, false)				
								end
							end

							-- Modify settings as needed to fit target type
							local listSettingIndex = settings:GetIndexOf(listSettingsLabel, true)
							if newTracker.targetType == "Boss" or newTracker.targetType =="Group" then
								-- Add list settings if needed
								local textIndex = settings:GetIndexOf(textSettingsLabel, true)
								if not listSettingIndex and textIndex then
									settings:AddSettings({listSettingsLabel, columnCount, horizontalSpacing, verticalSpacing}, textIndex, false)	
								end
							end

							--Add the remove and copy buttons
							settings:AddSettings({deleteTracker, copyTrackerToCharacter, copyTrackerToAccount}, #settings.settings - 1, false)

						end
					}, #settings.settings - 2, false)
				end
			end

			--Character trackers
			for k, v in pairs(UniversalTracker.characterSavedVariables.trackerList) do
				if v.name then
					settings:AddSetting({
						type = LibHarvensAddonSettings.ST_BUTTON,
						label = UniversalTracker.characterSavedVariables.trackerList[k].name, 
						buttonText = UniversalTracker.characterSavedVariables.trackerList[k].name, 
						tooltip = "Edit this tracker.",
						clickHandler = function(control)
							editIndex = k
							isCharacterSettings = true
							newTracker = copyTracker(UniversalTracker.characterSavedVariables.trackerList[editIndex])
							loadMenu(settingPages.newTracker, 2)

							--remove the base ability ID
							settings:RemoveSettings(8, 1, false)

							--dynamically add the extra ability IDs
							for i = 1, (#UniversalTracker.characterSavedVariables.trackerList[editIndex].abilityIDs) do
								local newIndex = 7 + i
								settings:AddSetting({
									type = setNewAbilityID.type,
									label = setNewAbilityID.label,
									tooltip = setNewAbilityID.tooltip,
									textType = setNewAbilityID.textType,
									maxChars = setNewAbilityID.maxChars,
									getFunction = function() return newTracker.abilityIDs[i] end,
									setFunction = function(value) 
										newTracker.abilityIDs[i] = value
										if value == "0" then
											-- This set function gets executed twice (same millisecond) but we only want to run this once.
											EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.." delete ability at index "..newIndex, 20, function()
												settings:RemoveSettings(LibHarvensAddonSettings.scrollList.lists.Main.selectedIndex, 1, false)
												newTracker.abilityIDs[newIndex - 7] = "MARKED FOR REMOVAL" --removal requires shifting, wait until page gets unloaded.
												EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.." delete ability at index "..newIndex)
											end)
										end
									end,
									default = newTracker.abilityIDs[i]
								}, newIndex, false)
							end

							--Modify settings as needed to fit tracker type
							if newTracker.type == "Bar" then
								local stacksIndex = settings:GetIndexOf(stacksLabel, true)
								if stacksIndex then
									settings:RemoveSettings(stacksIndex, 6, false)
									settings:AddSettings({abilityNameLabel, hideAbilityLabel, abilityLabelFontColor, abilityLabelFontScale, abilityLabelXOffset, abilityLabelYOffset}, 
															stacksIndex, false)
								end
							else
								local nameIndex = settings:GetIndexOf(abilityNameLabel, true)
								if nameIndex then
									settings:RemoveSettings(nameIndex, 6, false)
									settings:AddSettings({stacksLabel, hideStacks, stackFontColor, stackFontScale, stackXOffset, stackYOffset}, nameIndex, false)				
								end
							end

							--Add the remove button
							settings:AddSettings({deleteTracker, copyTrackerToCharacter, copyTrackerToAccount}, #settings.settings - 1, false)

						end
					}, #settings.settings - 1, false)
				end
			end

			LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
		end
	}
	local addNewTrackerButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "NEW TRACKER",
		buttonText = "ADD NEW",
		tooltip = "Create a new effect tracker.",
		clickHandler = function(control)
			--reset local variables
			newTracker = {
				id = -1,
				control = {
					object = nil,
					key = nil,
				},
				animation = {
					object = nil,
					key = nil,
				},
				name = "",
				type = "Compact",
				targetType = "Player",
				listSettings = {
					columns = 1,
					horizontalOffsetScale = 1,
					verticalOffsetScale = 1,
				},
				textSettings = {
					duration = {
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
					abilityLabel = {
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
						textScale = 1,
						x = 5,
						y = 0,
						hidden = false,
					},
					unitLabel = {
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
						accountName = true,
					},
				},
				abilityIDs = { --abilityIDs are values
					[1] = "",
				},
				hashedAbilityIDs = { --abilityIDs are keys

				},
				overrideTexturePath = "",
				x = 0,
				y = 0,
				scale = 1,
				hidden = false,
			}

			loadMenu(settingPages.newTracker, 2)
			settings:AddSetting(setNewTrackerSaveType, #settings.settings - 1, false)
			isCharacterSettings = false

			currentPageIndex = 6
			editIndex = -1
		end
	}
	local utilityMenuButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "UTILITIES",
		buttonText = "UTILITES",
		tooltip = "Tools that will help you find the abilityIDs for certain effects.",
		clickHandler = function(control)
			loadMenu(settingPages.utilities, 2)
			currentPageIndex = 8
		end
	}
	local returnToMainMenuButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "BACK",
		buttonText = "BACK",
		tooltip = "Return to main menu.",
		clickHandler = function(control)
			loadMenu(settingPages.mainMenu, currentPageIndex)
		end
	}

	---------------------------------------
	---				Setups		  		---
	---------------------------------------

	local setNewSetupName = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Setup Name",
		tooltip = "Enter your custom name for this tracker\n",
		getFunction = function() return newSetup.name end,
		setFunction = function(value)
			newSetup.name = value
		end,
		default = "New Setup",
	}
	local setupSaveButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "SAVE",
		buttonText = "SAVE",
		tooltip = "Save Changes and Return to main menu.",
		clickHandler = function(control)
			local index
			if editIndex >= 0 then
				index = editIndex
			else
				index = getNextAvailableIndex(isCharacterSettings, true)
			end

			--Error checking
			if newSetup.name == "" then
				local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
				messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
				messageParams:SetText("You must enter a name for your setup.", "A copy was not created.")
				messageParams:SetLifespanMS(3000)
				CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
				return
			end

			if isCharacterSettings then
				copySetup(newSetup, UniversalTracker.characterSavedVariables.setupList[index])
				if editIndex < 0 then
					UniversalTracker.characterSavedVariables.setupList[index].id = UniversalTracker.savedVariables.nextSetupID
					UniversalTracker.savedVariables.nextSetupID = UniversalTracker.savedVariables.nextSetupID + 1
				end
			else
				copySetup(newSetup, UniversalTracker.savedVariables.setupList[index])
				if editIndex < 0 then
					UniversalTracker.savedVariables.setupList[index].id = UniversalTracker.savedVariables.nextSetupID
					UniversalTracker.savedVariables.nextSetupID = UniversalTracker.savedVariables.nextSetupID + 1
				end
			end
			
			loadMenu(settingPages.mainMenu, currentPageIndex)
			editIndex = -1
		end
	}
	local setupCancelButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "CANCEL",
		buttonText = "CANCEL",
		tooltip = "Discard Changes and Return to main menu.",
		clickHandler = function(control)
			loadMenu(settingPages.mainMenu, currentPageIndex)
			editIndex = -1
		end
	}

	loadSetup = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Load Setup",
		buttonText = "LOAD",
		tooltip = "Sets the hidden state of all trackers to those described by this setup.\n\
					Ignores unsaved changes.",
		clickHandler = function(control)
			local id = nil
			if isCharacterSettings then
				id = UniversalTracker.characterSavedVariables.setupList[editIndex].id
			else
				id = UniversalTracker.savedVariables.setupList[editIndex].id
			end

			if not id then return end

			UniversalTracker.loadSetup(id)

			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Setup has been loaded.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	deleteSetup = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Delete Setup",
		buttonText = "DELETE",
		tooltip = "PERMANENTLY removes this setup.\n\
					This action cannot be undone.",
		clickHandler = function(control)
			if isCharacterSettings then
				table.remove(UniversalTracker.characterSavedVariables.setupList, editIndex)
			else
				table.remove(UniversalTracker.savedVariables.setupList, editIndex)
			end

			loadMenu(settingPages.mainMenu, currentPageIndex)
		end
	}

	copySetupToAccount = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "COPY (ACCOUNT)",
		buttonText = "COPY",
		tooltip = "Creates a copy of the current setup and saves it to your account's setups.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(false, true)

			--Error checking
			if newSetup.name == "" then
				local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
				messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
				messageParams:SetText("You must enter a name for your setup.", "A copy was not created.")
				messageParams:SetLifespanMS(3000)
				CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
				return
			end

			copySetup(newSetup, UniversalTracker.savedVariables.setupList[index])
			UniversalTracker.savedVariables.setupList[index].id = UniversalTracker.savedVariables.nextSetupID
			UniversalTracker.savedVariables.nextSetupID = UniversalTracker.savedVariables.nextSetupID + 1
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("You have successfully created a new copy of this setup.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
			--Don't load a new menu.
		end
	}

	copySetupToCharacter = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "COPY (Character)",
		buttonText = "COPY",
		tooltip = "Creates a copy of the current setup and saves it to your characters's setups.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(true, true)

			--Error checking
			if newSetup.name == "" then
				local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
				messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
				messageParams:SetText("You must enter a name for your tracker.", "A copy was not created.")
				messageParams:SetLifespanMS(3000)
				CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
				return
			end
			copySetup(newSetup, UniversalTracker.characterSavedVariables.setupList[index])
			UniversalTracker.characterSavedVariables.setupList[index].id = UniversalTracker.savedVariables.nextSetupID
			UniversalTracker.savedVariables.nextSetupID = UniversalTracker.savedVariables.nextSetupID + 1
			
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("You have successfully created a new copy of this setup.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
			--Don't load a new menu.
		end
	}

	---------------------------------------
	---		Trackers (Management)  		---
	---------------------------------------
	
	setNewTrackerSaveType = {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = "Save Destination",
		tooltip = "Choose where to save this tracker.",
		items = {
			{name = "Account", data = 1},
			{name = "Character", data = 2},
		},
		getFunction = function() if isCharacterSettings then return "Character" else return "Account" end end,
		setFunction = function(control, itemName, itemData)
			if itemName == "Account" then
				isCharacterSettings = false
			elseif itemName == "Character" then
				isCharacterSettings = true
			end
		end,
		default = 1,
	}

	--Fancy back buttons.
	local trackerSaveButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "SAVE",
		buttonText = "SAVE",
		tooltip = "Save Changes and Return to main menu.",
		clickHandler = function(control)
			local index
			if editIndex >= 0 then
				index = editIndex
			else
				index = getNextAvailableIndex(isCharacterSettings)
			end
			newTracker.hashedAbilityIDs = createHashedIDList(newTracker.abilityIDs)

			--Error checking
			if newTracker.name == "" then
				local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
				messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
				messageParams:SetText("You must enter a name for your tracker.")
				messageParams:SetLifespanMS(3000)
				CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
				return
			end
			if not next(newTracker.hashedAbilityIDs) then
				local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
				messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
				messageParams:SetText("You must enter at least one ability ID for your tracker.")
				messageParams:SetLifespanMS(3000)
				CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
				return
			end

			if not isCharacterSettings then
				copyTracker(newTracker, UniversalTracker.savedVariables.trackerList[index])
				if editIndex < 0 then
					UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
					UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				end
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
				temporarilyShowControl(index)
			else
				copyTracker(newTracker, UniversalTracker.characterSavedVariables.trackerList[index])
				if editIndex < 0 then
					UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
					UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				end
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
				temporarilyShowControl(index)
			end
			
			
			loadMenu(settingPages.mainMenu, currentPageIndex)
			editIndex = -1
		end
	}
	local trackerCancelButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "CANCEL",
		buttonText = "CANCEL",
		tooltip = "Discard Changes and Return to main menu.",
		clickHandler = function(control)
			loadMenu(settingPages.mainMenu, currentPageIndex)
			if editIndex >= 0 then
				if not isCharacterSettings then
					UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[editIndex]) --Load old changes
					temporarilyShowControl(editIndex)
				else
					UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[editIndex]) --Load old changes
					temporarilyShowControl(editIndex)
				end
			end
			editIndex = -1
		end
	}

	deleteTracker = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Delete Tracker",
		buttonText = "DELETE",
		tooltip = "PERMANENTLY removes this tracker.\n\
					This action cannot be undone.",
		clickHandler = function(control)

			if newTracker.control.object then
				EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.." move "..newTracker.control.object:GetName())
				if newTracker.control.object:GetNamedChild("Stacks") then
					--compact
					UniversalTracker.compactPool:ReleaseObject(newTracker.control.key)
				else
					--bar 
					UniversalTracker.barPool:ReleaseObject(newTracker.control.key)
				end
			end
			if newTracker.animation and newTracker.animation.object then
				UniversalTracker.barAnimationPool:ReleaseObject(newTracker.animation.key)
			end

			UniversalTracker.freeLists(newTracker)

			if isCharacterSettings then
				table.remove(UniversalTracker.characterSavedVariables.trackerList, editIndex)
			else
				table.remove(UniversalTracker.savedVariables.trackerList, editIndex)
			end

			loadMenu(settingPages.mainMenu, currentPageIndex)
		end
	}

	copyTrackerToAccount = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "COPY (ACCOUNT)",
		buttonText = "COPY",
		tooltip = "Creates a copy of the current tracker and saves it to your account's trackers.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(false)
			newTracker.hashedAbilityIDs = createHashedIDList(newTracker.abilityIDs)

			--Error checking
			if newTracker.name == "" then
				local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
				messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
				messageParams:SetText("You must enter a name for your tracker.", "A copy was not created.")
				messageParams:SetLifespanMS(3000)
				CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
				return
			end
			if not next(newTracker.hashedAbilityIDs) then
				local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
				messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
				messageParams:SetText("You must enter at least one ability ID for your tracker.", "A copy was not created.")
				messageParams:SetLifespanMS(3000)
				CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
				return
			end

			copyTracker(newTracker, UniversalTracker.savedVariables.trackerList[index], true)
			UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
			UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
			UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("You have successfully created a new copy of this tracker.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
			--Don't load a new menu.
		end
	}

	copyTrackerToCharacter = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "COPY (Character)",
		buttonText = "COPY",
		tooltip = "Creates a copy of the current tracker and saves it to your character's trackers.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(true)
			newTracker.hashedAbilityIDs = createHashedIDList(newTracker.abilityIDs)

			--Error checking
			if newTracker.name == "" then
				local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
				messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
				messageParams:SetText("You must enter a name for your tracker.", "A copy was not created.")
				messageParams:SetLifespanMS(3000)
				CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
				return
			end
			if not next(newTracker.hashedAbilityIDs) then
				local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
				messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
				messageParams:SetText("You must enter at least one ability ID for your tracker.", "A copy was not created.")
				messageParams:SetLifespanMS(3000)
				CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
				return
			end

			copyTracker(newTracker, UniversalTracker.characterSavedVariables.trackerList[index], true)
			UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
			UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
			UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("You have successfully created a new copy of this tracker.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
			--Don't load a new menu.
		end
	}

	---------------------------------------
	---		Trackers (General)		    ---
	---------------------------------------

	local setNewTrackerName = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Tracker Name",
		tooltip = "Enter your custom name for this tracker\n",
		getFunction = function() return newTracker.name end,
		setFunction = function(value)
			newTracker.name = value
		end,
		default = "New Tracker",
	}

	local setNewTrackerType = {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = "Tracker Type",
		tooltip = "Choose the display type.",
		items = {
			{name = "Compact", data = 1},
			{name = "Bar", data = 2},
		},
		getFunction = function() return newTracker.type end,
		setFunction = function(control, itemName, itemData) 
			newTracker.type = itemName
			if newTracker.type == "Bar" then
				local stacksIndex = settings:GetIndexOf(stacksLabel, true)
				if stacksIndex then
					settings:RemoveSettings(stacksIndex, 6, false)
					settings:AddSettings({abilityNameLabel, hideAbilityLabel, abilityLabelFontColor, abilityLabelFontScale, abilityLabelXOffset, abilityLabelYOffset}, 
										stacksIndex, false)
				end
			else
				local nameIndex = settings:GetIndexOf(abilityNameLabel, true)
				if nameIndex then
					settings:RemoveSettings(nameIndex, 6, false)
					settings:AddSettings({stacksLabel, hideStacks, stackFontColor, stackFontScale, stackXOffset, stackYOffset}, nameIndex, false)				
				end
			end
		end,
		default = 1,
	}

	local setNewTrackerTargetType = {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = "Target Type",
		tooltip = "Choose who the tracker will focus on.",
		items = {
			{name = "Player", data = 1},
			{name = "Group", data = 2},
			{name = "Boss", data = 3},
			{name = "Reticle Target", data = 4}
		},
		getFunction = function() return newTracker.targetType end,
		setFunction = function(control, itemName, itemData) 
			newTracker.targetType = itemName
			local listSettingIndex = settings:GetIndexOf(listSettingsLabel, true)
			if itemName == "Boss" or itemName =="Group" then
				-- Add list settings if needed
				local textIndex = settings:GetIndexOf(textSettingsLabel, true)
				if not listSettingIndex and textIndex then
					settings:AddSettings({listSettingsLabel, columnCount, horizontalSpacing, verticalSpacing}, textIndex, false)	
				end
			else
				--Remove list settings if existing
				if listSettingIndex then
					settings:RemoveSettings(listSettingIndex, 4, false)
				end
			end
		end,
		default = 1
	}

	local setNewTrackerOverrideTexture = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Override Texture",
		tooltip = "The tracker will use a texture based off of the AbilityID unless you specify an overide here.",
		getFunction = function() return newTracker.overrideTexturePath end,
		setFunction = function(value) 
			newTracker.overrideTexturePath = value
			if newTracker.control.object then
				newTracker.control.object:GetNamedChild("Texture"):SetTexture(newTracker.overrideTexturePath)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = ""
	}

	local hideTracker = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Hide Tracker",
		tooltip = "Hides the tracker without deleting it.",
		getFunction = function() return newTracker.hidden end,
		setFunction = function(value) 
			newTracker.hidden = value 
			if newTracker.control.object then
				newTracker.control.object:SetHidden(value)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			if value == false then
				temporarilyShowControl(editIndex)
			end
		end,
		default = newTracker.hidden
	}

	setNewAbilityID = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Ability ID",
		tooltip = "Enter an abilityID for this tracker to track.\n\
					Multiple abilityIDs can be tracked.\n\n\
					To delete this abilityID slot, enter an ability ID of \"0\"",
		textType = TEXT_TYPE_NUMERIC,
		maxChars = 10,
		getFunction = function() return newTracker.abilityIDs[1] end,
		setFunction = function(value) 
			newTracker.abilityIDs[1] = value
			if value == "0" then
				-- This set function gets executed twice (same millisecond) but we only want to run this once.
				EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.." delete ability at index 0", 20, function()
					settings:RemoveSettings(LibHarvensAddonSettings.scrollList.lists.Main.selectedIndex, 1, false)
					newTracker.abilityIDs[LibHarvensAddonSettings.scrollList.lists.Main.selectedIndex - 7] = "MARKED FOR REMOVAL" --removal requires shifting, wait until page gets unloaded.
					EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.." delete ability at index 0")
				end)
			end
		end,
		default = newTracker.abilityIDs[1]
	}

	add1AbilityID = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Add AbilityID",
		buttonText = "ADD",
		tooltip = "Adds an ability ID that you can track.",
		clickHandler = function(control)
			local newIndex = settings:GetIndexOf(add1AbilityID, true)
			newTracker.abilityIDs[newIndex - 7] = ""
			settings:AddSetting({
				type = setNewAbilityID.type,
				label = setNewAbilityID.label,
				tooltip = setNewAbilityID.tooltip,
				textType = setNewAbilityID.textType,
				maxChars = setNewAbilityID.maxChars,
				getFunction = function() return newTracker.abilityIDs[newIndex - 7] end,
				setFunction = function(value) 
					newTracker.abilityIDs[newIndex - 7] = value
					if value == "0" then
						-- This set function gets executed twice (same millisecond) but we only want to run this once.
						EVENT_MANAGER:RegisterForUpdate(UniversalTracker.name.." delete ability at index "..newIndex, 20, function()
							settings:RemoveSettings(LibHarvensAddonSettings.scrollList.lists.Main.selectedIndex, 1, false)
							newTracker.abilityIDs[newIndex - 7] = "MARKED FOR REMOVAL" --removal requires shifting, wait until page gets unloaded.
							EVENT_MANAGER:UnregisterForUpdate(UniversalTracker.name.." delete ability at index "..newIndex)
						end)
					end
				end,
				default = newTracker.abilityIDs[newIndex - 7]
			}, newIndex, false)
		end
	}

	local newXOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "X Offset",
		tooltip = "Modifies the X Offset.",
		min = 0,
		max = GuiRoot:GetWidth(),
		step = 5,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.x end,
		setFunction = function(value) 
			newTracker.x = value
			if newTracker.control.object then
				newTracker.control.object:ClearAnchors()
				newTracker.control.object:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, newTracker.x, newTracker.y)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.x
	}

	local newYOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Y Offset",
		tooltip = "Modifies the Y Offset.",
		min = 0,
		max = GuiRoot:GetHeight(),
		step = 5,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.y end,
		setFunction = function(value) 
			newTracker.y = value
			if newTracker.control.object then
				newTracker.control.object:ClearAnchors()
				newTracker.control.object:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, newTracker.x, newTracker.y)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.y
	}

	local newScale = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Scale",
		tooltip = "Modifies the tracker's size.\n",
		min = 0.1,
		max = 5,
		step = 0.1,
		format = "%.01f", 
		unit = "",
		getFunction = function() return newTracker.scale end,
		setFunction = function(value)
			newTracker.scale = value
			if newTracker.control.object then
				newTracker.control.object:SetScale(value)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.scale
	}


	-----------------------------------------
	---			Trackers (List)			  ---
	-----------------------------------------

	columnCount = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Columns",
		tooltip = "Modifies the number of columns when displaying a boss or group list.\n",
		min = 1,
		max = 3,
		step = 1,
		format = "%1f", 
		unit = "",
		getFunction = function() return newTracker.listSettings.columns end,
		setFunction = function(value)
			newTracker.listSettings.columns = value
			--TODO: Anchor updates
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.listSettings.columns
	}

	horizontalSpacing = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Horizontal Offset Scale",
		tooltip = "Trackers have a default horizontal offset depending on their type\n\
			You can multiply that value by a scale here.\n",
		min = 0.1,
		max = 5,
		step = 0.1,
		format = "%.1f", 
		unit = "",
		getFunction = function() return newTracker.listSettings.horizontalOffsetScale end,
		setFunction = function(value)
			newTracker.listSettings.horizontalOffsetScale = value
			--TODO: Anchor updates
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.listSettings.horizontalOffsetScale
	}

	verticalSpacing = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Vertical Offset Scale",
		tooltip = "Trackers have a default vertical offset depending on their type\n\
			You can multiply that value by a scale here.\n",
		min = 0.1,
		max = 5,
		step = 0.1,
		format = "%.1f", 
		unit = "",
		getFunction = function() return newTracker.listSettings.verticalOffsetScale end,
		setFunction = function(value)
			newTracker.listSettings.verticalOffsetScale = value
			--TODO: Anchor updates
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.listSettings.verticalOffsetScale
	}

	-----------------------------------------
	---			Trackers (Text)		      ---
	-----------------------------------------

	local hideDuration = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Hide Duration",
		tooltip = "Disables the duration countdown display.",
		getFunction = function() return newTracker.textSettings.duration.hidden end,
		setFunction = function(value) 
			newTracker.textSettings.duration.hidden = value 
			if newTracker.control.object then
				--todo bar list
				local child = newTracker.control.object:GetNamedChild("Duration")
				if not child then child = newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Duration") end
				child:SetHidden(value)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.duration.hidden
	}

	local durationFontColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = "Duration Text Color",
		tooltip = "Choose the duration's text color",
		getFunction = function() 
			return newTracker.textSettings.duration.color.r, newTracker.textSettings.duration.color.g, 
				newTracker.textSettings.duration.color.b, newTracker.textSettings.duration.color.a 
		end,
		setFunction = function(r, g, b, a) 
			newTracker.textSettings.duration.color = {r = r, g = g, b = b, a = a}
			if newTracker.control.object then
				local child = newTracker.control.object:GetNamedChild("Duration")
				if not child then child = newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Duration") end
				child:SetColor(newTracker.textSettings.duration.color.r, newTracker.textSettings.duration.color.g, newTracker.textSettings.duration.color.b, newTracker.textSettings.duration.color.a  )
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = {1, 1, 1, 1}
	}

	local durationFontScale = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Duration Text Scale",
		tooltip = "Modifies the duration's text size.\n",
		min = 0.1,
		max = 5,
		step = 0.1,
		format = "%.01f", 
		unit = "",
		getFunction = function() return newTracker.textSettings.duration.textScale end,
		setFunction = function(value)
			newTracker.textSettings.duration.textScale = value
			if newTracker.control.object then
				local child = newTracker.control.object:GetNamedChild("Duration")
				if not child then child = newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Duration") end
				child:SetScale(newTracker.textSettings.duration.textScale)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.duration.textScale
	}

	local durationXOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "X Offset",
		tooltip = "Modifies the Duration's X Offset.",
		min = -100,
		max = 100,
		step = 1,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.textSettings.duration.x end,
		setFunction = function(value) 
			newTracker.textSettings.duration.x  = value
			if newTracker.control.object then
				local child = newTracker.control.object:GetNamedChild("Duration")
				if not child then 
					child = newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Duration") 
					child:ClearAnchors()
					child:SetAnchor(RIGHT, newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Background"), RIGHT, newTracker.textSettings.duration.x, newTracker.textSettings.duration.y)
				else
					child:ClearAnchors()
					child:SetAnchor(CENTER, newTracker.control.object, CENTER, newTracker.textSettings.duration.x, newTracker.textSettings.duration.y)
				end
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.duration.x 
	}

	local durationYOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Y Offset",
		tooltip = "Modifies the duration's Y Offset.",
		min = -100,
		max = 100,
		step = 1,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.textSettings.duration.y end,
		setFunction = function(value) 
			newTracker.textSettings.duration.y = value
			if newTracker.control.object then
				local child = newTracker.control.object:GetNamedChild("Duration")
				if not child then 
					child = newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Duration") 
					child:ClearAnchors()
					child:SetAnchor(RIGHT, newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Background"), RIGHT, newTracker.textSettings.duration.x, newTracker.textSettings.duration.y)
				else
					child:ClearAnchors()
					child:SetAnchor(CENTER, newTracker.control.object, CENTER, newTracker.textSettings.duration.x, newTracker.textSettings.duration.y)
				end
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.duration.y
	}

	hideStacks = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Hide Stacks",
		tooltip = "Disables the stack count display.",
		getFunction = function() return newTracker.textSettings.duration.hidden end,
		setFunction = function(value) 
			newTracker.textSettings.stacks.hidden = value 
			if newTracker.control.object then
				newTracker.control.object:GetNamedChild("Stacks"):SetHidden(value)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.duration.hidden
	}

	stackFontColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = "Stacks Text Color",
		tooltip = "Choose the stack's text color",
		getFunction = function() 
			return newTracker.textSettings.stacks.color.r, newTracker.textSettings.stacks.color.g, 
				newTracker.textSettings.stacks.color.b, newTracker.textSettings.stacks.color.a 
		end,
		setFunction = function(r, g, b, a) 
			newTracker.textSettings.stacks.color = {r = r, g = g, b = b, a = a}
			if newTracker.control.object then
				newTracker.control.object:GetNamedChild("Stacks"):SetColor(newTracker.textSettings.stacks.color.r, newTracker.textSettings.stacks.color.g, newTracker.textSettings.stacks.color.b, newTracker.textSettings.stacks.color.a  )
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = {1, 1, 1, 1}
	}

	stackFontScale = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Stacks Text Scale",
		tooltip = "Modifies the stack's text size.\n",
		min = 0.1,
		max = 5,
		step = 0.1,
		format = "%.01f", 
		unit = "",
		getFunction = function() return newTracker.textSettings.stacks.textScale end,
		setFunction = function(value)
			newTracker.textSettings.stacks.textScale = value
			if newTracker.control.object then
				newTracker.control.object:GetNamedChild("Stacks"):SetScale(newTracker.textSettings.stacks.textScale)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.stacks.textScale
	}

	stackXOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "X Offset",
		tooltip = "Modifies the stacks's X Offset.",
		min = -100,
		max = 100,
		step = 1,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.textSettings.stacks.x end,
		setFunction = function(value) 
			newTracker.textSettings.stacks.x  = value
			if newTracker.control.object then
				newTracker.control.object:GetNamedChild("Stacks"):ClearAnchors()
				newTracker.control.object:GetNamedChild("Stacks"):SetAnchor(CENTER, newTracker.control.object, CENTER, newTracker.textSettings.stacks.x, newTracker.textSettings.stacks.y)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.stacks.x 
	}

	stackYOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Y Offset",
		tooltip = "Modifies the stacks's Y Offset.",
		min = -100,
		max = 100,
		step = 1,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.textSettings.stacks.y end,
		setFunction = function(value) 
			newTracker.textSettings.stacks.y = value
			if newTracker.contro.objectl then
				newTracker.control.object:GetNamedChild("Stacks"):ClearAnchors()
				newTracker.control.object:GetNamedChild("Stacks"):SetAnchor(CENTER, newTracker.control.object, CENTER, newTracker.textSettings.stacks.x, newTracker.textSettings.stacks.y)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.stacks.y
	}

	hideAbilityLabel = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Hide Ability Label",
		tooltip = "Disables the Ability Name label display.",
		getFunction = function() return newTracker.textSettings.abilityLabel.hidden end,
		setFunction = function(value) 
			newTracker.textSettings.abilityLabel.hidden = value 
			if newTracker.control.object then
				newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("AbilityName"):SetHidden(value)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.abilityLabel.hidden
	}

	abilityLabelFontColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = "Ability Label Text Color",
		tooltip = "Choose the ability label's text color",
		getFunction = function() 
			return newTracker.textSettings.abilityLabel.color.r, newTracker.textSettings.abilityLabel.color.g, 
				newTracker.textSettings.abilityLabel.color.b, newTracker.textSettings.abilityLabel.color.a 
		end,
		setFunction = function(r, g, b, a) 
			newTracker.textSettings.abilityLabel.color = {r = r, g = g, b = b, a = a}
			if newTracker.control and newTracker.control.object then
				newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("AbilityName"):SetColor(newTracker.textSettings.abilityLabel.color.r, newTracker.textSettings.abilityLabel.color.g, newTracker.textSettings.abilityLabel.color.b, newTracker.textSettings.abilityLabel.color.a  )
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = {1, 1, 1, 1}
	}

	abilityLabelFontScale = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Ability Label Text Scale",
		tooltip = "Modifies the label's text size.\n",
		min = 0.1,
		max = 5,
		step = 0.1,
		format = "%.01f", 
		unit = "",
		getFunction = function() return newTracker.textSettings.abilityLabel.textScale end,
		setFunction = function(value)
			newTracker.textSettings.abilityLabel.textScale = value
			if newTracker.control.object then
				newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("AbilityName"):SetScale(newTracker.textSettings.abilityLabel.textScale)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.abilityLabel.textScale
	}

	abilityLabelXOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Ability Label X Offset",
		tooltip = "Modifies the label's X Offset.",
		min = -100,
		max = 100,
		step = 1,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.textSettings.abilityLabel.x end,
		setFunction = function(value) 
			newTracker.textSettings.abilityLabel.x = value
			if newTracker.control.object then
				newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("AbilityName"):ClearAnchors()
				newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("AbilityName"):SetAnchor(LEFT, newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Background"), LEFT, newTracker.textSettings.abilityLabel.x, newTracker.textSettings.abilityLabel.y)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.abilityLabel.x 
	}

	abilityLabelYOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Ability Label Y Offset",
		tooltip = "Modifies the label's Y Offset.",
		min = -100,
		max = 100,
		step = 1,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.textSettings.abilityLabel.y end,
		setFunction = function(value) 
			newTracker.textSettings.abilityLabel.y = value
			if newTracker.control.object then
				newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("AbilityName"):ClearAnchors()
				newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("AbilityName"):SetAnchor(LEFT, newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Background"), LEFT, newTracker.textSettings.abilityLabel.x, newTracker.textSettings.abilityLabel.y)
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.abilityLabel.y
	}

	hideunitLabel = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Hide Unit Label",
		tooltip = "Disables the Unit Name label display.",
		getFunction = function() return newTracker.textSettings.unitLabel.hidden end,
		setFunction = function(value) 
			newTracker.textSettings.unitLabel.hidden = value 
			if newTracker.control.object then
				if newTracker.control.object:GetNamedChild("UnitName") then
					newTracker.control.object:GetNamedChild("UnitName"):SetHidden(value)
				else
					newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("UnitName"):SetHidden(value)
				end
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.unitLabel.hidden
	}

	preferPlayerName = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Account Name",
		tooltip = "For players, choose whether the tracker displays their character name or account name.",
		getFunction = function() return newTracker.textSettings.unitLabel.accountName end,
		setFunction = function(value) 
			newTracker.textSettings.unitLabel.accountName = value 
			if newTracker.control.object then
				if DoesUnitExist(newTracker.unitTag) then
					local child = newTracker.control.object:GetNamedChild("UnitName")
					if not child then child = newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("UnitName") end
					
					if value then
						child:SetText(zo_strformat(SI_UNIT_NAME, GetUnitDisplayName(newTracker.unitTag)))
					else
						child:SetText(zo_strformat(SI_UNIT_NAME, GetUnitName(newTracker.unitTag)))
					end
				end
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.unitLabel.accountName
	}

	unitLabelFontColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = "Unit Label Text Color",
		tooltip = "Choose the unit label's text color",
		getFunction = function() 
			return newTracker.textSettings.unitLabel.color.r, newTracker.textSettings.unitLabel.color.g, 
				newTracker.textSettings.unitLabel.color.b, newTracker.textSettings.unitLabel.color.a 
		end,
		setFunction = function(r, g, b, a) 
			newTracker.textSettings.unitLabel.color = {r = r, g = g, b = b, a = a}
			if newTracker.control.object then
				if newTracker.control.object:GetNamedChild("UnitName") then
					newTracker.control.object:GetNamedChild("UnitName"):SetColor(newTracker.textSettings.unitLabel.color.r, newTracker.textSettings.unitLabel.color.g, newTracker.textSettings.unitLabel.color.b, newTracker.textSettings.unitLabel.color.a  )
				else
					newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("UnitName"):SetColor(newTracker.textSettings.unitLabel.color.r, newTracker.textSettings.unitLabel.color.g, newTracker.textSettings.unitLabel.color.b, newTracker.textSettings.unitLabel.color.a  )
				end
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = {1, 1, 1, 1}
	}

	unitLabelFontScale = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Unit Label Text Scale",
		tooltip = "Modifies the label's text size.\n",
		min = 0.1,
		max = 5,
		step = 0.1,
		format = "%.01f", 
		unit = "",
		getFunction = function() return newTracker.textSettings.unitLabel.textScale end,
		setFunction = function(value)
			newTracker.textSettings.unitLabel.textScale = value
			if newTracker.control.object then
				if newTracker.control.object:GetNamedChild("UnitName") then
					newTracker.control.object:GetNamedChild("UnitName"):SetScale(newTracker.textSettings.unitLabel.textScale)
				else
					newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("UnitName"):SetScale(newTracker.textSettings.unitLabel.textScale)
				end
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.unitLabel.textScale
	}

	unitLabelXOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Unit Label X Offset",
		tooltip = "Modifies the label's X Offset.",
		min = -100,
		max = 100,
		step = 1,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.textSettings.unitLabel.x end,
		setFunction = function(value) 
			newTracker.textSettings.unitLabel.x  = value
			if newTracker.control.object then
				if newTracker.control.object:GetNamedChild("UnitName") then
					newTracker.control.object:GetNamedChild("UnitName"):ClearAnchors()
					newTracker.control.object:GetNamedChild("UnitName"):SetAnchor(BOTTOM, newTracker.control.object, TOP, newTracker.textSettings.unitLabel.x, newTracker.textSettings.unitLabel.y)
				else
					newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("UnitName"):ClearAnchors()
					newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("UnitName"):SetAnchor(BOTTOMLEFT, newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Background"), TOPLEFT, newTracker.textSettings.unitLabel.x, newTracker.textSettings.unitLabel.y)	
				end
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.unitLabel.x 
	}

	unitLabelYOffset = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Unit Label Y Offset",
		tooltip = "Modifies the label's Y Offset.",
		min = -100,
		max = 100,
		step = 1,
		format = "%.0f",  -- No decimal places
		unit = "",
		getFunction = function() return newTracker.textSettings.unitLabel.y end,
		setFunction = function(value) 
			newTracker.textSettings.unitLabel.y = value
			if newTracker.control.object then
				if newTracker.control.object:GetNamedChild("UnitName") then
					newTracker.control.object:GetNamedChild("UnitName"):ClearAnchors()
					newTracker.control.object:GetNamedChild("UnitName"):SetAnchor(BOTTOM, newTracker.control.object, TOP, newTracker.textSettings.unitLabel.x, newTracker.textSettings.unitLabel.y)
				else
					newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("UnitName"):ClearAnchors()
					newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("UnitName"):SetAnchor(BOTTOMLEFT, newTracker.control.object:GetNamedChild("Bar"):GetNamedChild("Background"), TOPLEFT, newTracker.textSettings.unitLabel.x, newTracker.textSettings.unitLabel.y)	
				end
			elseif newTracker.control.head and newTracker.control.head.value.control then
				UniversalTracker.refreshList(newTracker, string.gsub(newTracker.control.head.value.unitTag, "%d+", ""))
			end
			temporarilyShowControl(editIndex)
		end,
		default = newTracker.textSettings.unitLabel.y
	}

	---------------------------------------
	---		Utilities (Print)			---
	---------------------------------------
	
	local printCurrentEffects = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "PLAYER",
		buttonText = "PRINT EFFECTS",
		tooltip = "Prints information about your active effects.",
		clickHandler = function(control)
			for i = 1, GetNumBuffs("player") do
				local buffName, _, _, _, _, iconFilename, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo("player", i) 
				UniversalTracker.chat:Print(buffName.." (ID:"..abilityId..") ".."Texture="..iconFilename)
			end
		end
	}

	local printTargetEffects = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "TARGET",
		buttonText = "PRINT EFFECTS",
		tooltip = "Prints information about a target's effects.\n\
					Exit the menu and look at a target within 3 seconds to get their information.",
		clickHandler = function(control)
			zo_callLater(function() 
					if not DoesUnitExist("reticleover") then
					UniversalTracker.chat:Print("Player isn't looking at a unit.")
					return
				end
				for i = 1, GetNumBuffs("reticleover") do
					local buffName, _, _, _, _, iconFilename, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo("reticleover", i) 
					UniversalTracker.chat:Print(buffName.." (ID:"..abilityId..") ".."Texture="..iconFilename)
				end
			end, 3000)
		end
	}

	local printBossEffects = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "BOSS",
		buttonText = "PRINT EFFECTS",
		tooltip = "Prints effect information about nearby bosses.",
		clickHandler = function(control)
			for x = 1, 12 do
				if DoesUnitExist("boss"..x) then
					UniversalTracker.chat:Print(zo_strformat(SI_UNIT_NAME, GetUnitName("boss"..x)))
					for i = 1, GetNumBuffs("boss"..x) do
						local buffName, _, _, _, _, iconFilename, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo("boss"..x, i) 
						UniversalTracker.chat:Print(". "..buffName.." (ID:"..abilityId..") ".."Texture="..iconFilename)
					end
				end
			end
		end
	}


	---------------------------------------
	---		Utilities (Presets)			---
	---------------------------------------

	local offBalancePreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "OFF BALANCE",
		buttonText = "LOAD",
		tooltip = "Copies an off balance preset into the target save location.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)

			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.offBalance, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.offBalance, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded off balance preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	local staggerPreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "STAGGER",
		buttonText = "LOAD",
		tooltip = "Copies a stagger preset into the target save location.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)

			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.stagger, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.stagger, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded stagger preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	local relentlessPreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Relentless Focus",
		buttonText = "LOAD",
		tooltip = "Copies a relentless focus preset into the target save location.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)
			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.relentlessFocus, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.relentlessFocus, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded relentless focus preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	local mercilessPreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Merciless Resolve",
		buttonText = "LOAD",
		tooltip = "Copies a Merciless Resolve preset into the target save location.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)

			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.mercilessResolve, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.mercilessResolve, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded grim focus preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	local alkoshPreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Alkosh",
		buttonText = "LOAD",
		tooltip = "Copies an alkosh preset into the target save location.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)
			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.alkosh, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.alkosh, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded alkosh preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	local mkPreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Martial Knowledge",
		buttonText = "LOAD",
		tooltip = "Copies a martial knowledge preset into the target save location.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)
			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.mk, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.mk, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded martial Knowledge preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	local ecShockPreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "EC (Shock) Preset",
		buttonText = "LOAD",
		tooltip = "Copies a shock weakness knowledge preset into the target save location.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)
			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.ecShock, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.ecShock, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded Shock Weakness preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	local ecFlamePreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "EC (Flame) Preset",
		buttonText = "LOAD",
		tooltip = "Copies a flame weakness knowledge preset into the target save location.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)
			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.ecFire, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.ecFire, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded Fire Weakness preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	local ecIcePreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "EC (Frost) Preset",
		buttonText = "LOAD",
		tooltip = "Copies a frost weakness knowledge preset into the target save location.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)
			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.ecIce, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.ecIce, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded Frost Weakness preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	local synergyPreset = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Resource Synergy",
		buttonText = "LOAD",
		tooltip = "This tracker will show the cooldown until you can take another combustion / shard synergy.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)

			if not isCharacterSettings then
				copyTracker(UniversalTracker.presets.synergyCooldown, UniversalTracker.savedVariables.trackerList[index])
				UniversalTracker.savedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				copyTracker(UniversalTracker.presets.synergyCooldown, UniversalTracker.characterSavedVariables.trackerList[index])
				UniversalTracker.characterSavedVariables.trackerList[index].id = UniversalTracker.savedVariables.nextID
				UniversalTracker.savedVariables.nextID = UniversalTracker.savedVariables.nextID + 1
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
			end
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("Loaded resource synergy cooldown preset.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
		end
	}

	---------------------------------------
	---			Menu Groupings			---
	---------------------------------------

	settingPages.mainMenu = {setupLabel, setupListMenuButton, addNewSetupButton, trackerLabel, trackedListMenuButton, addNewTrackerButton, otherLabel, utilityMenuButton}
	settingPages.setupList = {accountSetupsLabel, characterSetupsLabel, navLabel, returnToMainMenuButton}
	settingPages.newSetup = {editSetupLabel, setNewSetupName, accountTrackersLabel, characterTrackersLabel, navLabel, setNewTrackerSaveType, setupCancelButton, setupSaveButton}
	settingPages.trackedList = {accountTrackersLabel, characterTrackersLabel, navLabel, returnToMainMenuButton}
	settingPages.newTracker = {newTrackerMenuLabel, setNewTrackerName, setNewTrackerType, setNewTrackerTargetType, setNewTrackerOverrideTexture, hideTracker,
									abilityIDListLabel, setNewAbilityID, add1AbilityID, 
									positionLabel, newScale, newXOffset, newYOffset,
									textSettingsLabel, durationLabel, hideDuration, durationFontColor, durationFontScale, durationXOffset, durationYOffset,
														stacksLabel, hideStacks, stackFontColor, stackFontScale, stackXOffset, stackYOffset,
														unitNameLabel, hideunitLabel, preferPlayerName, unitLabelFontColor, unitLabelFontScale, unitLabelXOffset, unitLabelYOffset,
									navLabel, trackerCancelButton, trackerSaveButton}
	settingPages.utilities = {printLabel, printCurrentEffects, printTargetEffects, printBossEffects, 
									presetLabel, setNewTrackerSaveType, offBalancePreset, staggerPreset, relentlessPreset, mercilessPreset, alkoshPreset, mkPreset, ecFlamePreset, ecShockPreset, ecIcePreset, synergyPreset,
									navLabel, returnToMainMenuButton}

	settings:AddSettings(settingPages.mainMenu)
end