GET = GET or {}

local settings = nil
local settingPages = {
	mainMenu = {},
	generalSettings = {},
	trackedList = {},
	newTracker = {},
	utilities = {},
}
local currentPageIndex = 2
local editIndex = -1

-- New/updated tracker settings. Local until "save"
-- THESE ARE DEFAULT VALUES FOR A NEW TRACKER.
local newTracker = {
	control = nil,
	animation = nil,
	name = "",
	type = "Simple",
	targetType = "Player",
	textSettings = {
		showStacks = true,
		showDuration = true,
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
		},
		hidden = false,
	},
	abilityIDs = {
		[0] = "",
	},
	overrideTexturePath = "",
	x = 0,
	y = 0,
	scale = 1,
}

local function loadMenu(menu, jumpToIndex)
	if settings then
		settings:RemoveAllSettings()
		settings:AddSettings(menu, nil, true)
		if IsConsoleUI() and jumpToIndex and jumpToIndex >= 1 and jumpToIndex <= #settings.settings then
			LibHarvensAddonSettings.list:SetSelectedIndexWithoutAnimation(jumpToIndex)
		end
	end
end

function GET.InitSettings()
	settings = LibHarvensAddonSettings:AddAddon("General Effect Tracker")


	-----------------------------------------------------------
	---		Early Declarations for Self/Cross References	---
	-----------------------------------------------------------
	
	local setNewAbilityID = nil
	local add1AbilityID, remove1AbilityID = nil, nil
	local deleteTracker = nil

	---------------------------------------
	---				Labels				---
	---------------------------------------

	local mainMenuLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Main Menu",}
	local navLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Navigation",}
	local generalMenuLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "General Settings",}
	local trackedListMenuLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Current Trackers",}
	local newTrackerMenuLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Edit Tracker",}
	local abilityIDListLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Tracked abilityIDs",}
	local positionLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Position",}
	local textSettingsLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Text",}
	local printLabel = {type = LibHarvensAddonSettings.ST_SECTION,label = "Print",}

	
	---------------------------------------
	---			Navigation Buttons		---
	---------------------------------------

	local generalMenuButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "GENERAL",
		buttonText = "GENERAL",
		tooltip = "General settings",
		clickHandler = function(control)
			loadMenu(settingPages.generalSettings, 2)
			currentPageIndex = 2
		end
	}
	local trackedListMenuButton = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "TRACKERS",
		buttonText = "TRACKERS",
		tooltip = "View, Edit, and delete from your list of tracked effects.",
		clickHandler = function(control)
			loadMenu(settingPages.trackedList, 2)
			currentPageIndex = 3

			--Tracker settings are in a table indexed from 0 to #trackers - 1
			--Create settings on setting indexes 2 to #trackers + 1
			for k, v in pairs(GET.savedVariables.trackerList) do
				settings:AddSetting({
					type = LibHarvensAddonSettings.ST_BUTTON,
					label = GET.savedVariables.trackerList[k].name, 
					buttonText = GET.savedVariables.trackerList[k].name, 
					tooltip = "Edit this tracker.",
					clickHandler = function(control)
						editIndex = k
						ZO_DeepTableCopy(GET.savedVariables.trackerList[editIndex], newTracker)
						currentPageIndex = 2 + editIndex
						loadMenu(settingPages.newTracker, 2)

						--dynamically add the extra ability IDs
						for i = 1, (#GET.savedVariables.trackerList[editIndex].abilityIDs) do
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
								end,
								default = newTracker.abilityIDs[i]
							}, newIndex, false)
						end

						--Add the remove button
						settings:AddSetting(deleteTracker, #settings.settings - 1, false)
					end
				}, #settings.settings, false)
			end
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
				control = nil,
				animation = nil,
				name = "",
				type = "Simple",
				targetType = "Player",
				textSettings = {
					showStacks = true,
					showDuration = true,
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
					},
					hidden = false,
				},
				abilityIDs = {
					[0] = "",
				},
				overrideTexturePath = "",
				x = 0,
				y = 0,
				scale = 1,
			}

			loadMenu(settingPages.newTracker, 2)
			currentPageIndex = 4
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
			currentPageIndex = 5
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
	---			General Settings		---
	---------------------------------------

	

	---------------------------------------
	---			Tracker List			---
	---------------------------------------
	
	deleteTracker = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Delete Tracker",
		buttonText = "DELETE",
		tooltip = "PERMANENTLY removes this tracker.\n\
					This action cannot be undone.",
		clickHandler = function(control)
			--table.remove isn't saving changes for some reason
			if #GET.savedVariables.trackerList < (editIndex + 1) then
				GET.savedVariables.trackerList[editIndex] = GET.savedVariables.trackerList[#GET.savedVariables.trackerList - 1]
			end
			GET.savedVariables.trackerList[#GET.savedVariables.trackerList - 1] = nil

			if newTracker.control then 
				newTracker.control:SetHidden(true) 
				EVENT_MANAGER:UnregisterForUpdate(GET.name..newTracker.control:GetName())
			end 
			loadMenu(settingPages.mainMenu, currentPageIndex)
		end
	}

	---------------------------------------
	---			Add New Tracker		---
	---------------------------------------

	local setNewTrackerName = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Tracker Name",
		tooltip = "Enter your custom name for this tracker\n\
					Names must be unique.",
		getFunction = function() return newTracker.name end,
		setFunction = function(value) 
			for k, v in pairs(GET.savedVariables.trackerList) do
				if v.name == value and k ~= editIndex then newTracker.name = "" end
			end
			newTracker.name = value
		end,
		default = "New Tracker",
		disable = function() return editIndex >= 0 end --Can't change for existing trackers.
	}

	local setNewTrackerType = {
		type = LibHarvensAddonSettings.ST_DROPDOWN,
		label = "Tracker Type",
		tooltip = "Choose the display type.",
		items = {
			{name = "Simple", data = 1},
			{name = "Bar", data = 2},
		},
		getFunction = function() return newTracker.type end,
		setFunction = function(control, itemName, itemData) newTracker.type = itemName end,
		default = 1,
		disable = function() return editIndex >= 0 end
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
		setFunction = function(control, itemName, itemData) newTracker.targetType = itemName end,
		default = 1
	}

	local setNewTrackerOverrideTexture = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Override Texture",
		tooltip = "The tracker will use a texture based off of the AbilityID unless you specify an overide here.",
		getFunction = function() return newTracker.overrideTexturePath end,
		setFunction = function(value) 
			newTracker.overrideTexturePath = value
			if newTracker.control then
				newTracker.control:GetNamedChild("Texture"):SetTexture(newTracker.overrideTexturePath)
			end
		end,
		default = ""
	}

	setNewAbilityID = {
		type = LibHarvensAddonSettings.ST_EDIT,
		label = "Ability ID",
		tooltip = "Enter an abilityID for this tracker to track.\n\
					Multiple abilityIDs can be tracked.\n\
					abilityIDs will be searched for from top to bottom until one is found.",
		textType = TEXT_TYPE_NUMERIC,
		maxChars = 10,
		getFunction = function() return newTracker.abilityIDs[0] end,
		setFunction = function(value) 
			newTracker.abilityIDs[0] = value
		end,
		default = newTracker.abilityIDs[0]
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
				end,
				default = newTracker.abilityIDs[newIndex - 7]
			}, newIndex, false)
		end
	}
	
	remove1AbilityID = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "Remove AbilityID",
		buttonText = "REMOVE",
		tooltip = "Removes the last abilityID from the list.",
		clickHandler = function(control)
			local removalIndex = settings:GetIndexOf(remove1AbilityID, true) - 2
			if removalIndex == settings:GetIndexOf(setNewAbilityID, true) then return end
			newTracker.abilityIDs[removalIndex - 7] = nil
			settings:RemoveSettings(removalIndex, 1, false)
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
			if newTracker.control then
				newTracker.control:ClearAnchors()
				newTracker.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, newTracker.x, newTracker.y)
			end
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
			if newTracker.control then
				newTracker.control:ClearAnchors()
				newTracker.control:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, newTracker.x, newTracker.y)
			end
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
		format = "%.1f", 
		unit = "",
		getFunction = function() return newTracker.scale end,
		setFunction = function(value)
			newTracker.scale = value
			if newTracker.control then
				newTracker.control:SetScale(value)
			end
		end,
		default = newTracker.scale
	}

	local hideDuration = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Hide Duration",
		tooltip = "Disables the duration countdown display.",
		getFunction = function() return newTracker.textSettings.duration.hidden end,
		setFunction = function(value) 
			newTracker.textSettings.duration.hidden = value 
			if newTracker.control then
				newTracker.control:GetNamedChild("Label"):SetHidden(value)
			end
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
			if newTracker.control then
				newTracker.control:GetNamedChild("Label"):SetColor(newTracker.textSettings.duration.color.r, newTracker.textSettings.duration.color.g, newTracker.textSettings.duration.color.b, newTracker.textSettings.duration.color.a  )
			end
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
		format = "%.1f", 
		unit = "",
		getFunction = function() return newTracker.textSettings.duration.textScale end,
		setFunction = function(value)
			newTracker.textSettings.duration.textScale = value
			if newTracker.control then
				newTracker.control:GetNamedChild("Label"):SetScale(newTracker.textSettings.duration.textScale)
			end
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
			if newTracker.control then
				newTracker.control:GetNamedChild("Label"):ClearAnchors()
				newTracker.control:GetNamedChild("Label"):SetAnchor(CENTER, newTracker.control, CENTER, newTracker.textSettings.duration.x, newTracker.textSettings.duration.y)
			end
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
			if newTracker.control then
				newTracker.control:GetNamedChild("Label"):ClearAnchors()
				newTracker.control:GetNamedChild("Label"):SetAnchor(CENTER, newTracker.control, CENTER, newTracker.textSettings.duration.x, newTracker.textSettings.duration.y)
			end
		end,
		default = newTracker.textSettings.duration.y
	}

	local hideStacks = {
		type = LibHarvensAddonSettings.ST_CHECKBOX,
		label = "Hide Stacks",
		tooltip = "Disables the stack count display.",
		getFunction = function() return newTracker.textSettings.duration.hidden end,
		setFunction = function(value) 
			newTracker.textSettings.stacks.hidden = value 
			if newTracker.control then
				newTracker.control:GetNamedChild("Stacks"):SetHidden(value)
			end
		end,
		default = newTracker.textSettings.duration.hidden
	}

	local stackFontColor = {
		type = LibHarvensAddonSettings.ST_COLOR,
		label = "Stacks Text Color",
		tooltip = "Choose the stack's text color",
		getFunction = function() 
			return newTracker.textSettings.stacks.color.r, newTracker.textSettings.stacks.color.g, 
				newTracker.textSettings.stacks.color.b, newTracker.textSettings.stacks.color.a 
		end,
		setFunction = function(r, g, b, a) 
			newTracker.textSettings.stacks.color = {r = r, g = g, b = b, a = a}
			if newTracker.control then
				newTracker.control:GetNamedChild("Stacks"):SetColor(newTracker.textSettings.stacks.color.r, newTracker.textSettings.stacks.color.g, newTracker.textSettings.stacks.color.b, newTracker.textSettings.stacks.color.a  )
			end
		end,
		default = {1, 1, 1, 1}
	}

	local stackFontScale = {
		type = LibHarvensAddonSettings.ST_SLIDER,
		label = "Stacks Text Scale",
		tooltip = "Modifies the stack's text size.\n",
		min = 0.1,
		max = 5,
		step = 0.1,
		format = "%.1f", 
		unit = "",
		getFunction = function() return newTracker.textSettings.stacks.textScale end,
		setFunction = function(value)
			newTracker.textSettings.stacks.textScale = value
			if newTracker.control then
				newTracker.control:GetNamedChild("Stacks"):SetScale(newTracker.textSettings.stacks.textScale)
			end
		end,
		default = newTracker.textSettings.stacks.textScale
	}

	local stackXOffset = {
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
			if newTracker.control then
				newTracker.control:GetNamedChild("Stacks"):ClearAnchors()
				newTracker.control:GetNamedChild("Stacks"):SetAnchor(CENTER, newTracker.control, CENTER, newTracker.textSettings.stacks.x, newTracker.textSettings.stacks.y)
			end
		end,
		default = newTracker.textSettings.stacks.x 
	}

	local stackYOffset = {
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
			if newTracker.control then
				newTracker.control:GetNamedChild("Stacks"):ClearAnchors()
				newTracker.control:GetNamedChild("Stacks"):SetAnchor(CENTER, newTracker.control, CENTER, newTracker.textSettings.stacks.x, newTracker.textSettings.stacks.y)
			end
		end,
		default = newTracker.textSettings.stacks.y
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
				index = #GET.savedVariables.trackerList
			end
			GET.savedVariables.trackerList[index] = {}
			ZO_DeepTableCopy(newTracker, GET.savedVariables.trackerList[index])
			GET.InitSingleDisplay(GET.savedVariables.trackerList[index]) --Load new changes.
			
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
				GET.InitSingleDisplay(GET.savedVariables.trackerList[editIndex]) --Load old changes
			end
			editIndex = -1
		end
	}

	---------------------------------------
	---			Utilities			---
	---------------------------------------
	
	local printCurrentEffects = {
		type = LibHarvensAddonSettings.ST_BUTTON,
		label = "PLAYER",
		buttonText = "PRINT EFFECTS",
		tooltip = "Prints information about your active effects.",
		clickHandler = function(control)
			for i = 1, GetNumBuffs("player") do
				local buffName, _, _, _, _, iconFilename, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo("player", i) 
				d(buffName.."(ID:"..abilityId..") ".."Texture="..iconFilename)
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
					d("Player isn't looking at a unit.")
					return
				end
				for i = 1, GetNumBuffs("reticleover") do
					local buffName, _, _, _, _, iconFilename, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo("reticleover", i) 
					d(buffName.."(ID:"..abilityId..") ".."Texture="..iconFilename)
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
					d(zo_strformat(GetUnitName("boss"..x)))
					for i = 1, GetNumBuffs("boss"..x) do
						local buffName, _, _, _, _, iconFilename, _, _, _, _, abilityId, _, _ = GetUnitBuffInfo("boss"..x, i) 
						d(". "..buffName.."(ID:"..abilityId..") ".."Texture="..iconFilename)
					end
				end
			end
		end
	}

	---------------------------------------
	---			Menu Groupings			---
	---------------------------------------

	settingPages.mainMenu = {mainMenuLabel, generalMenuButton, trackedListMenuButton, addNewTrackerButton, utilityMenuButton}
	settingPages.generalSettings = {generalMenuLabel, durationFontColor, durationFontScale, durationXOffset, durationYOffset,
														stackFontColor, stackFontScale, stackXOffset, stackYOffset, navLabel, returnToMainMenuButton}
	settingPages.trackedList = {trackedListMenuLabel, returnToMainMenuButton}
	settingPages.newTracker = {newTrackerMenuLabel, setNewTrackerName, setNewTrackerType, setNewTrackerTargetType, setNewTrackerOverrideTexture, 
									abilityIDListLabel, setNewAbilityID, add1AbilityID, remove1AbilityID, 
									positionLabel, newScale, newXOffset, newYOffset,
									textSettingsLabel, hideDuration, durationFontColor, durationFontScale, durationXOffset, durationYOffset,
														hideStacks, stackFontColor, stackFontScale, stackXOffset, stackYOffset,
									navLabel, cancelButton, saveButton}
	settingPages.utilities = {printLabel, printCurrentEffects, printTargetEffects, printBossEffects, navLabel, returnToMainMenuButton}

	settings:AddSettings(settingPages.mainMenu)
end