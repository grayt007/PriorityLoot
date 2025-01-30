local MyAddOnName, thisAddon = ...

thisAddon.Utils = {}
thisAddon.Auto = {}
thisAddon.ClassColors = {}
thisAddon.filters = {}
thisAddon.frameReferences = {}
thisAddon.frameBeingDisplayed = 0

local classColors = thisAddon.ClassColors
local util = thisAddon.Utils

--Ace3 addon application object & Libraries
local AceConfigDialog = LibStub("AceConfigDialog-3.0")      -- Add an option table into the Blizzard Interface Options panel.
local AceGUI = LibStub("AceGUI-3.0")  

-- Load up ready for the action
local addon = LibStub("AceAddon-3.0"):NewAddon(MyAddOnName, "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0", "AceTimer-3.0")
local AceRegistry = LibStub("AceConfigRegistry-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

_G[MyAddOnName] = addon
addon.LibRange = LibRange
addon.Prefix = 'aa.bT'

local version = 0.5

-- Make this pick up the top raid and fill it out on startup so we have a default choice 
local currentRaid = {
        raidId = "1273",
        raidName = "Nerub-ar Palace",
		currentBoss = {bossId = "2607",bossName="Ulgrax the Devourer"},
        raidBosses = 
            {
            {bossId = "*",bossName="All"},
            {bossId = "2607",bossName="Ulgrax the Devourer"},
            {bossId = "2611",bossName="The Bloodbound Horror"}, 
            {bossId = "2599",bossName="Sikran, Captain of the Sureki"},
            {bossId = "2609",bossName="Rasha'nan"},
            {bossId = "2612",bossName="Broodtwister Ovi'nax"},
            {bossId = "2601",bossName="Nexus-Princess Ky'veza"},
            {bossId = "2608",bossName="The Silken Court"},
            {bossId = "2602",bossName="Queen Ansurek"},
			},
		}

-- Minimap buttoin functionality
local broker = LDB:NewDataObject(MyAddOnName, {
    type = "launcher",
    text = MyAddOnName,
    label = "PriorityLoot",
    suffix = "",
    tooltip = GameTooltip,
    value = version,
    icon = "Interface\\AddOns\\PriorityLoot\\Media\\Textures\\logo",
    OnTooltipShow = function(tooltip)
        tooltip:AddDoubleLine(util.Colorize(MyAddOnName, "main"), util.Colorize(version, "accent"))
        tooltip:AddLine(" ")
        tooltip:AddLine(format("%s to toggle options window.", util.Colorize("Right-click")), 1, 1, 1, false)
        tooltip:AddLine(format("%s Open Loot window.", util.Colorize("Left-click")), 1, 1, 1, false)
        -- tooltip:AddLine(format("%s to toggle the minimap icon.", util.Colorize("Shift+Right-click")), 1, 1, 1, false)
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
        GameTooltip:ClearLines()
        self.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if button == "LeftButton" then
            addon:ToggleLootWindow()
        elseif button == "RightButton" then

            --if IsRightControlKeyDown() and addon.config.doYouWantToDebug then -- included for easy debug actions that wont by accidently triggered - change as per need
            --    wipe(addon.PLdb.profile.priorityPlayers)
            --    print("DEBUGGING ACTION:  Priority players wiped")
            --end

            if IsShiftKeyDown() then
                addon:ToggleMinimapIcon()
                if addon.PLdb.profile.minimap.hide then
                    util.Print(format("Minimap icon is now hidden. Type %s %s to show it again.", util.Colorize("/auga", "accent"), util.Colorize("minimap", "accent")))
                end
                AceRegistry:NotifyChange(MyAddonName)
            
            else
                addon:ToggleOptions()
            end
        end
    end,
    OnLeave = function()
        GameTooltip:Hide()
    end,
})

local debugHold, debugHold2, debugHold3 = false,false,false
local RAID_CLASS_COLORS

local dbName = ("%sDb"):format(MyAddOnName)
local ctxMenuName = ("%sContextMenu"):format(MyAddOnName)

 --   Build out the default ID for  raids so we have a list of the current people
local playerSelections = {}
local raidUnit = {}
	for i=1,MAX_RAID_MEMBERS do
		raidUnit[i] = ("raid%d"):format(i)
	end

--upvalues
--local ipairs,pairs,unpack,floor,format,tostring,tinsert,tremove,wipe,tsort =
--ipairs,pairs,unpack,floor,format,tostring,tinsert,tremove,wipe,table.sort

local UnitName,UnitIsUnit,UnitClass,UnitGUID,UnitIsFriend,UnitIsPlayer =
        UnitName,UnitIsUnit,UnitClass,UnitGUID,UnitIsFriend,UnitIsPlayer

local IsInGroup,GetNumGroupMembers,GetNumSubgroupMembers,GetRaidRosterInfo,GetPartyAssignment,GetRaidTargetIndex =
IsInGroup,GetNumGroupMembers,GetNumSubgroupMembers,GetRaidRosterInfo,GetPartyAssignment,GetRaidTargetIndex

---------------- LOCAL FUNCTIONS------------------------------

local function ShouldShow()                         -- Support the options to choose when the addon will open
    local instanceType = addon.instanceType

    if addon.config.neverShow
    or instanceType == "none" and not addon.config.showInWorld
    or instanceType == "raid" and not addon.config.showInRaid
    then
        return false
    end

    return true
end

local function UpdateMinimapIcon()                  -- Show or hide the minimap icon
    if addon.PLdb.profile.minimap.hide then
        LDBIcon:Hide(MyAddOnName)
    else
        LDBIcon:Show(MyAddOnName)
    end
end

---------------- SETUP FUNCTIONS------------------------------

function addon:OnInitialize()                                               -- MyAddOnName_LOADED(MyAddOnName)

	--Addon wide data structures
	thisAddon.roster = {} 
	self.postCombatCalls = {}                                                -- validate the requirement and approach
    self.numGroupMembers = GetNumGroupMembers()
    thisAddon.MainLootFrame = AceGUI:Create("Frame")
    
	local defaultSettings = {
		profile = {
			config = util.deepcopy(self.defaultConfig),
		},
	}

   	self.PLdb = LibStub("AceDB-3.0"):New(dbName, defaultSettings, true)    --  New DB  https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial 

    LDBIcon:Register(MyAddOnName, broker, self.PLdb.profile.minimap)       -- 3rd parameter is where to store the  hide/show + location of button 

    if not self.registered then                                         
        self.PLdb.RegisterCallback(self, "OnProfileChanged", "FullRefresh")
        self.PLdb.RegisterCallback(self, "OnProfileCopied", "FullRefresh")
        self.PLdb.RegisterCallback(self, "OnProfileReset", "FullRefresh")

        self:Options()
        self:createMainLootWindow()
        self.registered = true
    end

    if self.PLdb.profile.config.welcomeMessage then
        util.Print(format("Type %s or %s to open the options panel or %s for more commands.", util.Colorize("/PL", "accent"), util.Colorize("/PriorityLoot", "accent"), util.Colorize("/PL help", "accent")))
    end


    -- https://wowwiki-archive.fandom.com/wiki/Creating_a_slash_command
    SLASH_auga1 = "/PL"
    SLASH_auga2 = "/PriorityLoot"
    function SlashCmdList.PL(msg)
        if msg == "help" or msg == "?" then
             util.Print("Command List")
             print(format("%s or %s: Toggles the options panel.", util.Colorize("/PriorityLoot", "accent"), util.Colorize("/PL", "accent")))
             print(format("%s %s: Resets current profile to default settings. This does not remove any custom auras.", util.Colorize("/PL", "accent"), util.Colorize("reset", "value")))
             print(format("%s %s: Toggles the minimap icon.", util.Colorize("/PL", "accent"), util.Colorize("minimap", "value")))
        elseif msg == "reset" or msg == "default" then
             self.PLdb:ResetProfile()
        elseif msg == "minimap" then
             self:ToggleMinimapIcon()
        else
             self:ToggleOptions()
        end
    end

end

function addon:OnEnable() -- PLAYER_LOGIN
	--Register us as receivers of our AceComm messages - use this when we implement functionality for the addon to talk to otherpeopl;e using the same addon
	-- self:RegisterComm(self.Prefix, 'targetReceiver')
	
	--If SharedMedia is loaded, share our media
	--if C_AddOns.IsAddOnLoaded("LibSharedMedia-3.0")  then
	--	local lib = LibStub("LibSharedMedia-3.0") 
	--	lib:Register(lib.MediaType.STATUSBAR, barName, ([=[Interface\Addons\%s\media\barTex]=]):format(MyAddOnName))
	--end

	RAID_CLASS_COLORS = CUSTOM_CLASS_COLORS or _G.RAID_CLASS_COLORS

	if not next(classColors) then
		for k,v in pairs(RAID_CLASS_COLORS) do
			classColors[k]=v
		end
		classColors["UNKNOWN"] = {r=0.8,g=0.8,b=0.8,colorStr="ffcccccc"}
	end

	-- This call in turn handles changes to PriorityLoot.config and config GUI construction
	self:OnProfileChanged(nil, self.PLdb, self.PLdb:GetCurrentProfile())

	-- Event registration - MOve this to a function so enable and disables are all together
	self:RegisterEvent('GROUP_ROSTER_UPDATE')
	self:RegisterEvent('GROUP_JOINED')
    self:RegisterEvent("PLAYER_ENTERING_WORLD")

	-- Setup the user interface, and fire events which don't on their own at log in

	self:buildUI()

end

function addon:OnDisable()
	self:UnregisterEvent('UNIT_PET')
	self:UnregisterEvent('GROUP_JOINED')
	self:UnregisterEvent('GROUP_ROSTER_UPDATE')
	if self.repeatingTimer then self:CancelTimer(self.repeatingTimer) end

	if LibRange and LibRange.UnregisterCallback then
		LibRange.UnregisterCallback(self,"CHECKERS_CHANGED")
	end

	AceRegistry:NotifyChange(MyAddOnName)
end

function addon:buildUI()

	if self.optionsBaseFrame then return end
    self.contextMenu = CreateFrame("Frame", ctxMenuName, UIParent, "UIDropDownMenuTemplate")
    
    if self.PLdb.profile.welcomeMessage2 then 
        print("Here")
        self.welcomeImage = CreateFrame("Frame", 'welcomeImageFrame' , UIParent) 
        self.welcomeImage:SetPoint("CENTER")
        -- self.welcomeImage:SetAllPoints()
        self.welcomeImage:SetSize(512,512)

        local bg = self.welcomeImage:CreateTexture()
        bg:SetAllPoints(self.welcomeImage)
        bg:SetTexture("Interface\\AddOns\\PriorityLoot\\Media\\Textures\\WelcomePicture")
        -- bg:SetTexCoord(0, 1, 0, 1)
        bg:Show()

        local btn = CreateFrame("Button", nil, self.welcomeImage, "UIPanelButtonTemplate")
        btn:SetText("Close")
        btn.Text:SetTextColor(1, 1, 1)
        btn:SetWidth(100)
        btn:SetHeight(30)
        btn:SetPoint("BOTTOM", 190, 23)
        btn.Left:SetDesaturated(true)
        btn.Right:SetDesaturated(true)
        btn.Middle:SetDesaturated(true)
        btn:SetScript("OnClick", function()
            self.welcomeImage:Hide()
        end)
        self.welcomeImage:Show()
        self.PLdb.profile.welcomeMessage2 = false
    end

end

function addon:OnProfileChanged(eventName, db, newProfile)

	self.config = self.PLdb.profile.config

	if self.config then

		--Unversioned databases are set to v. 1
		if self.config.dbVersion == nil then self.config.dbVersion = 1 end

		--Handle database version checking and upgrading if necessary
		local startVersion = self.config.dbVersion
		-- self:upgradeDatabase(self.config)
		--if startVersion ~= self.config.dbVersion then
		--	print(("%s configuration database upgraded from v.%s to v.%s"):format(MyAddOnName,startVersion,self.config.dbVersion))
		--end

	end

	self:updateRoster()

end

----------- ROSTER AND PROFILE RELATED FUNCTIONS -----------------------

function addon:updateRoster()

	wipe(thisAddon.roster) 

	--local playerName = util.unitname('player')
	--local playerGUID = UnitGUID('player')
	--if self.config.includePlayer then
	--	self.roster[playerName] = 'player'
	--end
 
    if IsInGroup() then
        for i=1,GetNumGroupMembers() do                                                     -- for all the members of the party or raid
            local unitID = raidUnit[i]
            -- local notMe = not UnitIsUnit('player',unitID)
            local unitName = util.unitname(unitID)
            --local guid = UnitGUID(unitID)
            --local role, assignedRole

            if unitName and not util.hasValue(thisAddon.roster,unitID) then                  -- if the unit does not already exist
                -- if notMe then 
                    thisAddon.roster[unitName] = unitID 
                -- end                                                                       -- Add the unit to the roster
            end
        end
    end
end

function addon:FullRefresh()
    UpdateMinimapIcon()
end

function addon:onUpdate() -- THE MAIN REALTIME UPDATE FUNCTION  -- DO WE NEED THIS ??
	if not InCombatLockdown() then
        -- stuff
		if not self.enabled then self:Disable() end
	end

	if not self.enabled then return end

end

function addon:registerPostCombatCall(call) tinsert(self.postCombatCalls, call) end

function addon:OnNewProfile(eventName, db, profile)

	--Set the dbVersion to the most recent, as defaults for the new profile should be up-to-date
	self.PLdb.profile.config.dbVersion = self.currentDbVersion

end

------------- FUNCTIONS TO SUPPORT MINIMAP BUTTON ACTIONS --------------------

function addon:clearAll()
	util.AddDebugData(0, "Clear All Function")
    -- INSERT ACTION HERE

end

function addon:OpenOptions()
    AceConfigDialog:Open(MyAddOnName)
    local dialog = AceConfigDialog.OpenFrames[MyAddOnName]

	util.AddDebugData(dialog, "Dialog status")

    if dialog then
        dialog:EnableResize(false)
    end
end

-- FRAME RELATED FUCTIONS ---------------------------------------

function addon:createMainLootWindow()
    local count = 1
	thisAddon.filters = addon.PLdb.profile.config.filterSettings

    -- Create Main Loot Form
    thisAddon.MainLootFrame:SetTitle("Priority Loot")
    thisAddon.MainLootFrame:SetStatusText("Priority Loot Review Window")
    thisAddon.MainLootFrame:SetWidth(1000)
    thisAddon.MainLootFrame:SetHeight(600)
    thisAddon.MainLootFrame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
    thisAddon.MainLootFrame:SetLayout("Flow")

    -- Create the horizontal group to hold the columns
    local horizontalGroup = AceGUI:Create("SimpleGroup")
    horizontalGroup:SetFullWidth(true)
    horizontalGroup:SetLayout("Flow")

    buildFilterColumnTop()
    buildFilterColumnBottom()
    horizontalGroup:AddChild(thisAddon.filterColumn)

    -- Spacer between columns
    local spacer = AceGUI:Create("SimpleGroup") 
	spacer:SetWidth(20) 
	spacer:SetLayout("Flow")
    horizontalGroup:AddChild(spacer)

    buildTableColumn()
    horizontalGroup:AddChild(thisAddon.tableColumn)

    -- Add the horizontal group to the frame
    thisAddon.MainLootFrame:AddChild(horizontalGroup)

    addDataToTable()

end

function buildFilterColumnTop()

	-- filterColumn - Create the first column group

    --util.AddDebugData(thisAddon.filters,"Filters check #2 V1")

    thisAddon.filterColumn = AceGUI:Create("SimpleGroup")
    -- filterColumn:SetTitle("Filters")
    thisAddon.filterColumn:SetWidth(200)
    thisAddon.filterColumn:SetHeight(550)
    thisAddon.filterColumn:SetLayout("Flow")

     -- filterColumn - Player Heading
    local sourceHeading = AceGUI:Create("Heading")
    sourceHeading:SetText("Player Display")
    sourceHeading:SetFullWidth(true)
    thisAddon.filterColumn:AddChild(sourceHeading)

    local raidRadio = AceGUI:Create("CheckBox")
    local guildRadio = AceGUI:Create("CheckBox")

    raidRadio:SetLabel("Show players from Raid")
    raidRadio:SetCallback("OnValueChanged", function(widget, event, selected) 
            if selected then 
			    thisAddon.filters.displayGuildNames = false 
                guildRadio:ToggleChecked()
		    end
	    end)
    
    guildRadio:SetLabel("Show players from Guild")
    guildRadio:SetValue(thisAddon.filters.displayGuildNames)
    guildRadio:SetCallback("OnValueChanged", function(widget, event, selected) 
            if selected then 
			    thisAddon.filters.displayGuildNames = selected 
                raidRadio:ToggleChecked()
		    end
		end)
    thisAddon.filterColumn:AddChild(guildRadio)
    thisAddon.filterColumn:AddChild(raidRadio)

      -- filterColumn - Checkbox for My Loot
    local checkboxMyLoot = AceGUI:Create("CheckBox")
    checkboxMyLoot:SetLabel("Display my choices only")
    checkboxMyLoot:SetType("checkbox")
    checkboxMyLoot:SetCallback("OnValueChanged", function(widget, event, key) 
        print ("Value changed me first") end)
    thisAddon.filterColumn:AddChild(checkboxMyLoot)  
    
    -- filterColumn - Source Heading
    local sourceHeading = AceGUI:Create("Heading")
    sourceHeading:SetText("Choose Raid and Boss")
    sourceHeading:SetFullWidth(true)
    thisAddon.filterColumn:AddChild(sourceHeading)
 
     -- filterColumn - Create the raid dropdownRaid widget
    local dropdownRaid = AceGUI:Create("Dropdown")
    local dropdownBoss = AceGUI:Create("Dropdown")

    -- thisAddon.filterColumn - dropdownRaid
    -- dropdownRaid:SetLabel("Selected Raid")
    dropdownRaid:SetList(getElementsFromRaids("raid","","",""))
    dropdownRaid:SetValue(1)
    dropdownRaid:SetWidth(150)
    dropdownRaid:SetCallback("OnValueChanged", function(widget, event, key) 
        local itemSelected = dropdownRaid:GetValue()
        util.AddDebugData(itemSelected,"Raid selected")
		setCurrentRaid(itemSelected) 
        dropdownBoss:SetList(getElementsFromRaids("bosslist",currentRaid.raidId,"",""))          --update the boss list
        currentRaid.currentBoss = addon.PLdb.profile.config.raids[itemSelected].raidBosses[2]    -- Set the default to the first boss
        dropdownBoss:SetValue(2)
	    end)
    thisAddon.filterColumn:AddChild(dropdownRaid) 
    -- util.AddDebugData(currentRaid.raidName,"Raid dropdown added")

    -- filterColumn - dropdownBoss
    -- dropdownBoss:SetLabel("Selected Boss")
    dropdownBoss:SetList(getElementsFromRaids("bosslist",currentRaid.raidId,"",""))
    dropdownBoss:SetValue(2)
    dropdownBoss:SetWidth(150)
    dropdownBoss:SetCallback("OnValueChanged", function(widget, event, key) 
        local whatBoss = dropdownBoss:GetValue()
        local whatRaid = dropdownRaid:GetValue()
        -- util.AddDebugData(currentRaid,"Current raid")
		currentRaid.currentBoss.bossId = currentRaid.raidBosses[whatBoss].bossId
		currentRaid.currentBoss.bossName = currentRaid.raidBosses[whatBoss].bossName
		-- print("Selected option:", dropdownBoss:GetValue())  end)
        -- util.AddDebugData(dropdownBoss:GetValue(),currentRaid.currentBoss.bossName,"Boss selected")
		end)
    thisAddon.filterColumn:AddChild(dropdownBoss)     
    -- util.AddDebugData(currentRaid.currentBoss.bossName,"Boss dropdown added")
 
end

function buildFilterColumnBottom()

    util.AddDebugData(thisAddon.filters,"Filters check V2")

    for _,filterList in ipairs (addon.PLdb.profile.config.filterColumnElements) do

        if filterList.type == "H" then
            -- filterColumn - Player Heading
            theHeading = AceGUI:Create("Heading")
            theHeading:SetText(filterList.name)
            theHeading:SetFullWidth(true)
            thisAddon.filterColumn:AddChild(theHeading)
        else
            -- filterColumn Checkbox
            local theCheckbox = AceGUI:Create("CheckBox")
            theCheckbox:SetLabel(filterList.name)
            theCheckbox:SetType("checkbox")
            theCheckbox:SetWidth(75)
            theCheckbox:SetValue(true)
            theCheckbox:SetCallback("OnValueChanged", function(widget, event, selected) 
                -- print ("Value changed "..filterList.name) 
                    if selected then 
                        thisAddon.filters.currentFilter[filterList.position] = filterList.ID
				    else
				        thisAddon.filters.currentFilter[filterList.position] = "-"
				    end

                    --local filterWord = convertFiltertoWord(thisAddon.filters.currentFilter)
                    --util.AddDebugData(filterWord,"filterWord")
                    refreshDataInTable()
			    end)
            thisAddon.filterColumn:AddChild(theCheckbox)
		end
    end
end

function buildTableColumn()
    local headerLabels = {}

    -- thisAddon.tableColumn - Create the second column group 
    thisAddon.tableColumn = AceGUI:Create("InlineGroup") 
    thisAddon.tableColumn:SetWidth(600)
    --thisAddon.tableColumn:SetFullWidth(true)
    -- thisAddon.tableColumn:SetFullHeight(true)
    thisAddon.tableColumn:SetLayout("Flow") 
    
    addTableColumnHeadings()

    -- tableColumn -Create the scroll container for the table rows
    thisAddon.scrollContainer = AceGUI:Create("ScrollFrame")
    thisAddon.scrollContainer:SetFullWidth(true)
    thisAddon.scrollContainer:SetHeight(450)
    thisAddon.scrollContainer:SetLayout("Flow") -- This Setting can cause massive delays in the addon

    -- tableColumn - Add the scroll container to the second column
    thisAddon.tableColumn:AddChild(thisAddon.scrollContainer)
end

function addTableColumnHeadings()

        -- tableColumn - Create the header group for the table
    local header = AceGUI:Create("SimpleGroup")
    header:SetFullWidth(true)
    header:SetLayout("Flow")

    -- tableColumn -  Test Headings
    headerLabels = getListOfRaidMembers()

    -- tableColumn - Add header labels to the header group
    for _, nameText in pairs(headerLabels) do
        local label = AceGUI:Create("Label")
        label:SetText(nameText)
        label:SetWidth(40) -- Adjust the width as needed
        header:AddChild(label)
    end

    -- tableColumn - Add the header group to the second column
    thisAddon.tableColumn:AddChild(header)  
end

function addDataToTable()
    local playerChoices = {}

     -- tableColumn - Loot through the loot data for this boss and add the rows
   	tbl = addon.PLdb.profile.config.bossLoot
    util.AddDebugData(true,"Adding Rows to ScrollFrame")

     for _, bossRec in ipairs(tbl) do
        -- util.AddDebugData(bossRec.bossId,"Found a boss")
        if bossRec.bossId == currentRaid.currentBoss.bossId then
            -- util.AddDebugData(bossRec.bossId,"Found the target boss")
            for _, rowData in ipairs(bossRec.lootItems) do
                playerChoices={}
                if itemFilteredIn(rowData[1]) then
				    playerChoices = getPlayerSelections(rowData[1])  -- get the player choices based on the itemID
				    addPlayerSelectionRowsV2(thisAddon.scrollContainer, rowData[1],playerChoices) 
                else
                     util.AddDebugData(rowData[1],"Not added to scollFRame")
				end
			end
        end
	 end     

end   

function refreshDataInTable()

    thisAddon.scrollContainer:ReleaseChildren()
    for _,frameObject in ipairs(thisAddon.frameReferences) do
        frameObject:UnregisterAllEvents()
        frameObject:Hide()
	end
    addDataToTable()

end

function reuseFrame()
    local totalFrames = #thisAddon.frameReferences

    if totalFrames == nil then totalFrames = 0 end
	
    --util.AddDebugData(totalFrames,"Total Frames")
    --util.AddDebugData(thisAddon.frameBeingDisplayed,"Total Frames displayed")

    if totalFrames>0 and thisAddon.frameBeingDisplayed < totalFrames then  -- if X frames are already display but more are avilable
        thisAddon.frameBeingDisplayed = totalFrames + 1                     -- increase the number displayed
	    return thisAddon.frameBeingDisplayed                                -- and say which frame to reuse
	else
        thisAddon.frameBeingDisplayed = totalFrames + 1                     -- increase the number displayed
        return 0                                                            -- create one
	end
end

-- FILTERING FUNCTIONS ----------------------------------

function itemFilteredIn(itemID)
    -- itemEquipLocation is what slot
    -- iitemClassID is temArmourSubClass e.g.  Cloth 1, Leather	2, Mail 3,Plate	4, Others   5-11
    -- itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID
    local _, _, _, itemEquipLoc, _, itemClassId, subclassID = GetItemInfoInstant(itemID)
    local itemArmourTypeToFind = "#"
    local itemLocationToFind = "#"

    -- util.AddDebugData(itemID.."  "..itemEquipLoc.."  "..itemClassId,"filterWord")
    -- what slot does it go into - get the letter that we search for
    for _, itemLocation in ipairs(addon.PLdb.profile.config.LootItemSubType) do
	    if itemEquipLoc == itemLocation[1] then
		    itemLocationToFind = itemLocation[3]
		end
	end

    -- If its Armour then is it cloth, leather etc - get the correct letter to search for
  	if itemClassId==4 and subclassID>0 and subclassID<5 then
        itemArmourTypeToFind = addon.PLdb.profile.config.filterArmourType[subclassID]
	end
    
    local filterWord = convertFiltertoWord(thisAddon.filters.currentFilter)
    local startIndexL, endIndexL = string.find(filterWord, itemLocationToFind)
	local startIndexA, endIndexA = string.find(filterWord, itemArmourTypeToFind)

    if startIndexL == nil then startIndexL = 0 end
    if startIndexA == nil then startIndexA = 0 end

    -- util.AddDebugData(itemLocationToFind.."("..startIndexL..") - "..itemArmourTypeToFind.."("..startIndexA..")","searching for")
    
    if startIndexL==0 and startIndexA==0 then
        -- util.AddDebugData("("..startIndexL..") - ".."("..startIndexA..")","FALSE")
	    return false
	else
        -- util.AddDebugData("("..startIndexL..") - ".."("..startIndexA..")","TRUE")
	    return true
	end
end

function convertFiltertoWord(theFilter)
-- To disconnect the search from the data we do not link them explicity so its easier to change in the future but more complex to start with
-- each filter has an ID.  When you select a filter teh ID is added to the currentFilter table
-- this function convert the table to a word so that we can look at item but by saying 
-- does this ID appear in that word.  In the future we could have 30 more filters but the code will be the same (ish)
-- 
    local word = ""
    for _, letter in ipairs(theFilter) do
        word = word .. letter
    end
    return word
end

-- OTHER SUPPORT FUNCTIONS ----------------------------------

function setCurrentRaid(raidIdIn)            -- show and hide OPtions window

	util.AddDebugData(raidIdIn,"function util.setCurrentRaid(raidIdIn): Change to raid")
	tbl = addon.PLdb.profile.config.raids

    currentRaid.raidId = tbl[raidIdIn].raidId
	currentRaid.raidName = tbl[raidIdIn].raidName
	currentRaid.raidBosses = tbl[raidIdIn].raidBosses
	currentRaid.currentBoss = tbl[raidIdIn].raidBosses[2]
    util.AddDebugData(currentRaid,"function util.setCurrentRaid(raidIdIn): Current raid after update")
end

function getListOfRaidMembers()
    local returnNames = {"A","B","C"}

    util.AddDebugData(addon.PLdb.profile.config.useTestData,"Entry to getListOfRaidMembers")
    if filterColumnElementsuseTestData then
        util.AddDebugData(thisAddon.filters.displayGuildNames,"getListOfRaidMembers: disaplay guild names ?")
        if thisAddon.filters.displayGuildNames then
	        returnNames = addon.PLdb.profile.config.guildTestData
		else
            returnNames = addon.PLdb.profile.config.raidTestData
        end
    else
        if thisAddon.filters.displayGuildNames then
		    for keyPressedey,playerList in ipairs(addon.PLdb.profile.config.playerSelections) do
                returnNames[key] = util.getShortName(playerList.player)
                util.AddDebugData(playerList.player,"getListOfRaidMembers")
            end
		else
		    util.AddDebugData("Raid names","getListOfRaidMembers")
		end
	end
    util.AddDebugData(returnNames,"getListOfRaidMembers: Exit point")
    return returnNames
end

function getPlayerSelections(itemId)         
local returnRow = {}
local counter = 0
local playerSelections = addon.PLdb.profile.config.playerSelections 

    for _,playerRecord in pairs(playerSelections) do  -- <<<<<<<<< This will need to change to show only players in the current raid
	    counter = counter + 1
		returnRow[counter] = 0
        for _, theSelections in pairs(playerRecord.playerLoot) do
		    if itemId == theSelections.itemId then
			    returnRow[counter] = theSelections.rank
		    end
        end
	end
    -- util.AddDebugData(returnRow,"getPlayerSelections: return")
    return returnRow
end             -- Called from addDataToTable to build the row of player selections ranks for each item

function addPlayerSelectionRows(theScrollContainer, itemID,theSelections)   -- Called from addDataToTable 
        local row = AceGUI:Create("SimpleGroup")
        row:SetFullWidth(true)
        row:SetLayout("Flow")

        -- Pad the row to the correct height becuase I can never get that to work correctly
        local padding = AceGUI:Create("Label")
        padding:SetHeight(33)
        row:AddChild(padding)
        
        -- util.AddDebugData(itemID,"Icon Item ID")
        -- Create and display the item icon
        local itemIcon = GetItemIcon(itemID)
        local icon = row.frame:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(itemIcon)
        icon:SetSize(32, 32)
        icon:SetPoint("LEFT")
        -- util.AddDebugData(itemIcon,"Icon texture")

        for i, rank in pairs(theSelections) do
            -- Create a frame for the player selection in the correct colour
            local box = CreateFrame("Frame", nil, row.frame,BackdropTemplateMixin and "BackdropTemplate")
            box:SetSize(32,32)
            box:SetPoint("LEFT", icon, "RIGHT", (34*i)-32, 0)
            
            -- Set the background color of the box based on the theSelections
            if rank == 0 then
                box:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
                box:SetBackdropColor(1, 0, 0, 0.5) -- Light red
            else
                box:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
                box:SetBackdropColor(0, 1, 0, 0.5) -- Light green
            end

            -- Create a label for the theSelections
            if rank ~= 0 then
                -- util.AddDebugData(rank,"is there a selection")
                local boxText = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                boxText:SetPoint("CENTER", box, "CENTER")
                boxText:SetFont("Fonts\\FRIZQT__.TTF", 16)
                boxText:SetText(rank)
		    end
		end

        -- Show tooltip on mouse hover
        icon:SetScript("OnEnter", function()
            GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemID)
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Add row to table
        theScrollContainer:AddChild(row)
end          -- Called from addDataToTable to add the items and player selections to the table

function addPlayerSelectionRowsV2(theScrollContainer, itemID,theSelections)   -- Called from addDataToTable 
       local row = AceGUI:Create("SimpleGroup")
        row:SetFullWidth(true)
        row:SetLayout("Flow")

        --util.AddDebugData(thisAddon.frameBeingDisplayed.." of "..#thisAddon.frameReferences,"addPlayerSelectionRowsV2 - Frame creation check")

        -- Pad the row to the correct height becuase I can never get that to work correctly
        local padding = AceGUI:Create("Label")
        padding:SetHeight(33)
        row:AddChild(padding)
        
        -- util.AddDebugData(itemID,"Icon Item ID")
        -- Create and display the item icon
        local itemIcon = GetItemIcon(itemID)
        local backdropInfo = {      -- https://wowpedia.fandom.com/wiki/BackdropTemplate
	                bgFile = itemIcon,
                    }
        local reuseIcon = reuseFrame() -- 0 menas create and a number means use that number frame

        if reuseIcon == 0 then 
	        icon = CreateFrame("Frame", nil, row.frame,BackdropTemplateMixin and "BackdropTemplate")
            thisAddon.frameReferences[thisAddon.frameBeingDisplayed] = icon
            --util.AddDebugData(reuseIcon,"Creating a Icon Frame")
        else
            icon = thisAddon.frameReferences[reuseIcon]  --use an existing frame
            icon:Show()
            --util.AddDebugData(reuseIcon,"Reusing a Icon Frame")
		end 

        -- icon:SetTexture(itemIcon) <<< **** Is this correct for a frame ***
        icon:SetBackdrop(backdropInfo)
	    icon:SetSize(32, 32)
        icon:SetPoint("LEFT")
        
        -- util.AddDebugData(itemIcon,"Icon texture")

        for i, rank in pairs(theSelections) do
            -- Create a frame for the player selection in the correct colour
            local reuse = reuseFrame() -- 0 means create and a number means use that number frame
            if reuse == 0 then 
	            box = CreateFrame("Frame", nil, row.frame,BackdropTemplateMixin and "BackdropTemplate")
                thisAddon.frameReferences[thisAddon.frameBeingDisplayed] = box
                --util.AddDebugData(reuseIcon,"Creating a Box Frame")
            else
                box = thisAddon.frameReferences[reuse]  --use an existing frame
                box:Show()
                --util.AddDebugData(reuseIcon,"Reusing a Box Frame")
		    end 
            -- local box = CreateFrame("Frame", nil, row.frame,BackdropTemplateMixin and "BackdropTemplate")
            box:SetSize(32,32)
            box:SetPoint("LEFT", icon, "RIGHT", (34*i)-32, 0)
            
            -- Set the background color of the box based on the theSelections
            if rank == 0 then
                box:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
                box:SetBackdropColor(1, 0, 0, 0.5) -- Light red
            else
                box:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
                box:SetBackdropColor(0, 1, 0, 0.5) -- Light green
            end

            -- Create a label for the theSelections
            if rank ~= 0 then
                -- util.AddDebugData(rank,"is there a selection")
                local boxText = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                boxText:SetPoint("CENTER", box, "CENTER")
                boxText:SetFont("Fonts\\FRIZQT__.TTF", 16)
                boxText:SetText(rank)
		    end
		end

        -- Show tooltip on mouse hover
        icon:SetScript("OnEnter", function()
            GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemID)
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        -- Add row to table
        theScrollContainer:AddChild(row)
end          -- Called from addDataToTable to add the items and player selections to the table

function getElementsFromRaids(whatToReturn,searchValue1,searchValue2,searchValue3) -- pass in"raid","boss" and a search value
-- "raid"            searchValue1={},searchValue2={},searchValue3={}
-- "bossList"        searchValue1={},searchValue2={},searchValue3={}
-- "bossId"          searchValue1={provide the raid Id},searchValue2={provide the bossId},searchValue3={}
-- "raidBossLoot"    searchValue1={provide the raid Id},searchValue2={provide the bossId},searchValue3={}

    local returnArray = {}
    tbl = addon.PLdb.profile.config.raids

    if whatToReturn == "raid" then                      -- Return table of raid names
        for _, raid in ipairs(tbl) do 
		    table.insert(returnArray, raid.raidName)
			
        end
        return returnArray
    elseif whatToReturn == "bosslist" then              -- Return the list of bosses in the currently selected raid
        for _, bossList in pairs(currentRaid.raidBosses) do
            table.insert(returnArray, bossList.bossName)
            -- util.AddDebugData("Added Boss to dropdown", bossList.bossName)
		end
        return returnArray
	
    elseif whatToReturn == "bossname" then                -- Find boss Id from the Boss name
        for _, raid in pairs(tbl) do
            if raid.raidId == searchValue1 then
                for _, bossList in pairs(raid.raidBosses) do
				    if bossList.bossName == searchValue2 then
					    return bossList.bossId
					end
				end
            end	
		end
		util.AddDebugData("function: getElementsFromRaids", searchValue2.." bossID not found in raid "..searchValue1)
    else 
		util.AddDebugData("function: getElementsFromRaids", whatToReturn.." was not a suitable parameter")
	end

    return returnArray
end            -- Parse the raids data to return requested tables and data

function addon:ToggleOptions()
	util.AddDebugData("ToggleOptions()","PriorityLoot")

    if AceConfigDialog.OpenFrames[MyAddOnName] then
        AceConfigDialog:Close(MyAddOnName)
        AceConfigDialog:Close(MyAddOnName.."Dialog")
    else
		util.AddDebugData(MyAddOnName, "Calling OpenOptions()")
        self:OpenOptions()
    end
end             -- show and hide OPtions window

function addon:upgradeDatabase(config)

	if config.dbVersion == self.currentDbVersion then return config
	else
		local nextVersion = config.dbVersion + 1
		local migrationCall = self.migrationPaths[nextVersion]

		if migrationCall then migrationCall(config) end

		config.dbVersion = nextVersion
		return self:upgradeDatabase(config)
	end

end           -- upgrade the database if there have been version changes

function addon:ToggleMinimapIcon()
    util.AddDebugData(self.PLdb.profile.config.minimap.hide, "Minimap button status")

    self.PLdb.profile.config.minimap.hide = not self.PLdb.profile.config.minimap.hide
    UpdateMinimapIcon()
end         -- show and hide minimap icon

function addon:ToggleLootWindow()
    --if self.mainFrame:IsShown() then
    --    self.mainFrame:Hide()
    --else
    --    self.mainFrame:Show()
    --end
end          -- Show and hide loot window

---------------- EVENT HANDLERS ----------------------------------

function addon:GROUP_ROSTER_UPDATE() self:updateRoster() end

function addon:GROUP_JOINED() 
    self:clearAll()
    self:updateRoster() 
end

function addon:PLAYER_ENTERING_WORLD()
    self.instanceType = select(2, IsInInstance())
end

