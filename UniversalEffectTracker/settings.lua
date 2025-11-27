UniversalTracker = UniversalTracker or {}

UniversalTracker.nextID = 0

local settings = nil
local settingPages = {
	mainMenu = {},
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

local function copyTracker(source, nullifyControls)
	local dest = {}
	if source.control.head then
		-- Exclude the 2-directional linked list from the deep copy.
		-- The deep copy function will never stop running otherwise.
		local tempControlList = source.control
		local tempAnimationList = source.animation
		source.control = nil
		source.animation = nil
		ZO_DeepTableCopy(source, dest)
		source.control = tempControlList
		source.animation = tempAnimationList

		if not nullifyControls then
			-- Copy over the linked list ourselves
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

			if source.	animation and source.animation.head then
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
		else
			dest.control = {head = nil, tail = nil}
			dest.animation = {head = nil, tail = nil}
		end
	else
		ZO_DeepTableCopy(source, dest)
		if nullifyControls then
			dest.control = { object = nil, key = nil,}
			dest.animation = { object = nil, key = nil,}
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

	return dest
end

local function getNextAvailableIndex(charSettings)
	local index
	if not charSettings then
		-- If index 2 is removed from 1, 2, 3, 4, 5... we will want to recover and maintain an order for table.remove by inserting the next tracker at index 2
		index = 1
		while UniversalTracker.savedVariables.trackerList[index] do
			index = index + 1
		end
	else
		index = 1
		while UniversalTracker.characterSavedVariables.trackerList[index] do
			index = index + 1
		end
	end
	return index
end

function UniversalTracker.InitSettings()
	settings = LibHarvensAddonSettings:AddAddon("Universal Effect Tracker")


	-----------------------------------------------------------
	---		Early Declarations for Self/Cross References	---
	-----------------------------------------------------------
	
	local setNewAbilityID = nil
	local add1AbilityID = nil
	local deleteTracker = nil
	local copyToAccount, copyToCharacter = nil, nil
	local setNewTrackerSaveType = nil
	local columnCount, horizontalSpacing, verticalSpacing = nil, nil, nil
	local hideStacks, stackFontColor, stackFontScale, stackXOffset, stackYOffset = nil, nil, nil, nil, nil
	local hideAbilityLabel, abilityLabelFontColor, abilityLabelFontScale, abilityLabelXOffset, abilityLabelYOffset  = nil, nil, nil, nil, nil
	local hideunitLabel, unitLabelFontColor, unitLabelFontScale, unitLabelXOffset, unitLabelYOffset  = nil, nil, nil, nil, nil

	---------------------------------------
	---				Labels				---
	---------------------------------------

	local mainMenuLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Main Menu",}
	local navLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Navigation",}

	local accountTrackersLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Account Trackers",}
	local characterTrackersLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Character Trackers",}

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

	local trackedListMenuButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "TRACKERS",
		buttonText = "TRACKERS",
		tooltip = "View, Edit, and delete from your list of tracked effects.",
		clickHandler = function(control)
			loadMenu(settingPages.trackedList, 2)
			currentPageIndex = 2

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
							currentPageIndex = 2 + editIndex
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
							settings:AddSettings({deleteTracker, copyToCharacter, copyToAccount}, #settings.settings - 1, false)

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
							currentPageIndex = 2 + editIndex
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
							settings:AddSettings({deleteTracker, copyToCharacter, copyToAccount}, #settings.settings - 1, false)

						end
					}, #settings.settings - 1, false)
				end
			end

			LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(2)
		end
	}
	local addNewTrackerButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "ADD NEW",
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

			currentPageIndex = 3
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
			currentPageIndex = 4
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
	---			Tracker List			---
	---------------------------------------
	--- This also reuses settings from "Add new Tracker"
	
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

	copyToAccount = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "COPY (ACCOUNT)",
		buttonText = "COPY",
		tooltip = "Creates a copy of the current tracker and saves it to your account's trackers.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)
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

			UniversalTracker.savedVariables.trackerList[index] = copyTracker(newTracker, true)
			UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			
			
			local messageParams = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.COLLECTIBLE_UNLOCKED)
			messageParams:SetCSAType(CENTER_SCREEN_ANNOUNCE_TYPE_COLLECTIBLES_UPDATED)
			messageParams:SetText("You have successfully created a new copy of this tracker.")
			messageParams:SetLifespanMS(1500)
			CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(messageParams)
			--Don't load a new menu.
		end
	}

	copyToCharacter = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "COPY (Character)",
		buttonText = "COPY",
		tooltip = "Creates a copy of the current tracker and saves it to your account's trackers.",
		clickHandler = function(control)
			local index = getNextAvailableIndex(isCharacterSettings)
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

			UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(newTracker, true)
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
	---			Add New Tracker		    ---
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
	---			Add New Tracker (List)    ---
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
	---			Add New Tracker (Text)    ---
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

-------------------------------------------------------------------------------------------

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
	local saveButton = {
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(newTracker)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
				temporarilyShowControl(index)
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(newTracker)
				UniversalTracker.InitSingleDisplay(UniversalTracker.characterSavedVariables.trackerList[index]) --Load new changes.
				temporarilyShowControl(index)
			end
			
			
			loadMenu(settingPages.mainMenu, currentPageIndex)
			editIndex = -1
		end
	}
	local cancelButton = {
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
		tooltip = "Prints information about a target's nearby effects.\n\
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
					UniversalTracker.chat:Print(zo_strformat(GetUnitName("boss"..x)))
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.offBalance)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.offBalance)
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.stagger)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.stagger)
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.relentlessFocus)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.relentlessFocus)
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.mercilessResolve)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.mercilessResolve)
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.alkosh)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.alkosh)
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.mk)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.mk)
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.ecShock)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.ecShock)
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.ecFire)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.ecFire)
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.ecIce)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.ecIce)
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
				UniversalTracker.savedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.synergyCooldown)
				UniversalTracker.InitSingleDisplay(UniversalTracker.savedVariables.trackerList[index]) --Load new changes.
			else
				UniversalTracker.characterSavedVariables.trackerList[index] = copyTracker(UniversalTracker.presets.synergyCooldown)
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

	settingPages.mainMenu = {mainMenuLabel, trackedListMenuButton, addNewTrackerButton, utilityMenuButton}
	settingPages.trackedList = {accountTrackersLabel, characterTrackersLabel, navLabel, returnToMainMenuButton}
	settingPages.newTracker = {newTrackerMenuLabel, setNewTrackerName, setNewTrackerType, setNewTrackerTargetType, setNewTrackerOverrideTexture, hideTracker,
									abilityIDListLabel, setNewAbilityID, add1AbilityID, 
									positionLabel, newScale, newXOffset, newYOffset,
									textSettingsLabel, durationLabel, hideDuration, durationFontColor, durationFontScale, durationXOffset, durationYOffset,
														stacksLabel, hideStacks, stackFontColor, stackFontScale, stackXOffset, stackYOffset,
														unitNameLabel, hideunitLabel, unitLabelFontColor, unitLabelFontScale, unitLabelXOffset, unitLabelYOffset,
									navLabel, cancelButton, saveButton}
	settingPages.utilities = {printLabel, printCurrentEffects, printTargetEffects, printBossEffects, 
									presetLabel, setNewTrackerSaveType, offBalancePreset, staggerPreset, relentlessPreset, mercilessPreset, alkoshPreset, mkPreset, ecFlamePreset, ecShockPreset, ecIcePreset, synergyPreset,
									navLabel, returnToMainMenuButton}

	settings:AddSettings(settingPages.mainMenu)
end