local MyAddOnName, thisAddon = ...

thisAddon.Utils = {}
thisAddon.filters = {}
thisAddon.frameReferences = {}
thisAddon.frameBeingDisplayed = 0
thisAddon.checkboxList = {}
-- thisAddon.ChannelId = 0
thisAddon.playerSelections = {}
thisAddon.roster = {} 

lootRoll = {}
-- Module references
local util = thisAddon.Utils

--Ace3 addon application object & Libraries
local addon = LibStub("AceAddon-3.0"):NewAddon(MyAddOnName, "AceConsole-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceEvent-3.0", "AceTimer-3.0")
local ACD = LibStub("AceConfigDialog-3.0")      -- Add an option table into the Blizzard Interface Options panel.
local AceGUI = LibStub("AceGUI-3.0")  
local ACR = LibStub("AceConfigRegistry-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local LSM = LibStub("LibSharedMedia-3.0")
--local LibCompress = LibStub:GetLibrary("LibCompress")
--local LibEncoder = LibCompress:GetAddonEncodeTable()


-- Addon globals
_G[MyAddOnName] = addon
addon.LibRange = LibRange
addon.Prefix = 'pl.bT'
local dbName = ("%sDb"):format(MyAddOnName)
finishedInitalising = false -- there is a delay in getting guild info in the client.   The client  needs 10-15 seconds to finish fully initalising. 
thisAddon.priorityLootRollsActive = false -- Has the loot manager activated the addon for this raid.

version = 0.73  -- date("%m%d%H%M")
local headingsExist = false
iAmTheLootManager = false
iAmTheGM = false
local tableColumnContent = "S"
local currentBoss = "225822"   -- return the bossId of the first boss
local raidUnit = {}            -- the unitID in a raid is "raidN" the raid member with raidIndex N (1,2,3,...,40).
thisAddon.guildUnit = {}

	
-- Minimap button functionality
local broker = LDB:NewDataObject(MyAddOnName, {
    type = "launcher",
    text = MyAddOnName,
    label = "PriorityLoot",
    suffix = "",
    tooltip = GameTooltip,
    value = version,
    icon = "Interface\\AddOns\\PriorityLoot\\Media\\Textures\\logo",
    OnTooltipShow = function(tooltip)
        tooltip:AddDoubleLine(util.Colorize(MyAddOnName, "main",false), util.Colorize(version, "accent",false))
        tooltip:AddLine(" ")
        if finishedInitalising then
            tooltip:AddLine(format("%s to toggle options window.", util.Colorize("Right-click")), 1, 1, 1, false)
            tooltip:AddLine(format("%s Open Loot window.", util.Colorize("Left-click")), 1, 1, 1, false)
        else
            tooltip:AddLine(format("%s allow 15 seconds for client to initialise.", util.Colorize("WARNING:")), 1, 1, 1, false)
        end
    end,
    OnEnter = function(self)
        GameTooltip:SetOwner(self, "ANCHOR_NONE")
        GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
        GameTooltip:ClearLines()
        self.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    end,
    OnClick = function(self, button)
        if not finishedInitalising then
                util.Print(format("%s: Please allow 15 seconds for the Warcraft client to finish initialising", util.Colorize("WARNING:", "accent")))
        elseif button == "LeftButton" then
                addon:ToggleLootWindow()
        elseif button == "RightButton" then

            if IsRightControlKeyDown() then 
                -- buildPL_RANK_CHECK()
                addon:yesnoBox("Do you wish to swap the Priority Loot allocations state for this raid ?","activateLootRolls")
            end

            if IsShiftKeyDown() then
                addon:ToggleMinimapIcon()
                if addon.PLdb.profile.minimap.hide then
                    util.Print(format("Minimap icon is now hidden. Type %s %s to show it again.", util.Colorize("/auga", "accent"), util.Colorize("minimap", "accent")))
                end
                ACR:NotifyChange(MyAddOnName)
            else
                addon:ToggleOptions()
            end
        end
    end,
    OnLeave = function()
        GameTooltip:Hide()
    end,
})

---------------- SETUP FUNCTIONS------------------------------

function addon:OnInitialize()                                               -- MyAddOnName_LOADED(MyAddOnName)
 -- Code that you want to run when the addon is first loaded goes here.
    
    -- get a copy of the default filter that control what items are displayed 
	local defaultSettings = {
		char = util.deepcopy(self.charConfig),
		profile = util.deepcopy(self.profileConfig),
		global = util.deepcopy(self.globalConfig),
	}

    -- util.Print("The dbName for settings is "..dbName)

    --  New DB  https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial 
   	addon.PLdb = LibStub("AceDB-3.0"):New(dbName, defaultSettings)    
    LDBIcon:Register(MyAddOnName, broker, self.PLdb.profile.minimap)       -- 3rd parameter is where to store the  hide/show + location of button 
   
    util.AddDebugData(defaultSettings,"Default Settings")
    util.AddDebugData(addon.PLdb,"Settings")

    -- Register for actions when the profile is changed
    if not self.registered then                                         
        addon.PLdb.RegisterCallback(self, "OnProfileChanged", "FullRefresh")
        addon.PLdb.RegisterCallback(self, "OnProfileCopied", "FullRefresh")
        addon.PLdb.RegisterCallback(self, "OnProfileReset", "FullRefresh")

        addon:ScheduleTimer("getGuildDetails", 15)                 -- delay getting the guild info because the client will return an error while it full initialises
        addon:ScheduleTimer("buildPL_CONFIG_CHECK", random(15,30)) -- delay sending the message to spread them out if multiple people login near the same time
        addon:ScheduleTimer("buildPL_RANK_CHECK", random(30,45))   -- delay sending the message to spread them out if multiple people login near the same time

        addon:displayWelcomeImage()

        self.registered = true
    end

    -- util.AddDebugData(addon.PLdb.profile.config,"Default config settings")
   
    self:checkDbVersion()

    if addon.PLdb.profile.welcomeMessage then
        util.Print(format("Type %s or %s to open the options panel or %s for more commands.", util.Colorize("/PL", "accent"), util.Colorize("/PriorityLoot", "accent"), util.Colorize("/PL help", "accent")))
    end

    addon:RegisterChatCommand("PL", "processSlashCommnands")
    addon:RegisterChatCommand("PriorityLoot", "processSlashCommnands")

    -- load up the player selections from the config.lua file
    thisAddon.playerSelections = addon.PLdb.char.playerSelections
    util.AddDebugData( thisAddon.playerSelections,"Player selections")
    util.AddDebugData(true,"End OnInitialize()  ")
end                                                                     

function addon:OnEnable() 
-- Called when the addon is enabled

    util.AddDebugData(true,"Start OnEnable()  ")
    -- some baseline debugging
    -- util.AddDebugData(thisAddon.guildUnit,"Guild list stored")
    -- util.AddDebugData(thisAddon.roster,"Current roster")

    -- preload the raid roster with the expected userID
    for i=1,MAX_RAID_MEMBERS do
		raidUnit[i] = ("raid%d"):format(i)
	end
    
    -- This call in turn handles changes to PriorityLoot.config and config GUI construction
	self:OnProfileChanged(nil, self.PLdb, self.PLdb:GetCurrentProfile())        

    -- register  for events
    addon:eventSetup("Register")      
    util.AddDebugData(true,"event Setup done ")

    -- duplicate the object don't reference it so we don't change the default
	thisAddon.filters = util.deepcopy(addon.PLdb.profile.filterSettings)
    util.AddDebugData(true,"config duplicated ")

    -- Grab the GUI settings
    lootRoll.GUI = addon.PLdb.profile.GUI

    -- Make sure my character exist otherwise who cares about loot :-)
    checkIExist()
    util.AddDebugData(true,"checkIExist() done ")

    -- Build the main Frame for interacting
	buildMainLootWindow()      
    util.AddDebugData(true,"buildMainLootWinbdow done ")

    -- Build the main loot roll frame for he big event

    addon:createRollFrame()
    util.AddDebugData(true,"createRollFrame() done ")
    -- Load options after we have some information about the guild

    addon:Options()
    util.AddDebugData(true,"Options() done  ")
end

function addon:OnDisable()

    addon:eventSetup("deRegister")
	
	if self.repeatingTimer then self:CancelTimer(self.repeatingTimer) end

	if LibRange and LibRange.UnregisterCallback then
		LibRange.UnregisterCallback(self,"CHECKERS_CHANGED")
	end

	ACR:NotifyChange(MyAddOnName)
end

---------------- EVENT HANDLERS ----------------------------------

function addon:eventSetup(theAction)

    -- util.AddDebugData(theAction, "event stuff started")

    -- Intentionally using multiple IF statements
    if theAction == "Register" then
	    addon:RegisterEvent('GROUP_ROSTER_UPDATE',"eventHandler")
	    addon:RegisterEvent('GROUP_JOINED',"eventHandler")
        addon:RegisterEvent('GROUP_LEFT',"eventHandler")
        addon:RegisterEvent("PLAYER_ENTERING_WORLD","eventHandler")

	end
	
	if theAction == "unRegister" then
	    addon:UnregisterEvent('GROUP_ROSTER_UPDATE')
	    addon:UnregisterEvent('GROUP_JOINED')
        addon:UnregisterEvent('GROUP_LEFT')
		addon:UnRegisterEvent("PLAYER_ENTERING_WORLD")
    end

    -- activate loot rolls
    if theAction == "LootRoll" then
		if thisAddon.priorityLootRollsActive then
	        addon:RegisterEvent("START_LOOT_ROLL", "RollEvent")
            addon:RegisterEvent("CANCEL_LOOT_ROLL", "RollCancelEvent")
            addon:RegisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER", "UpdateEncounter")
        else
            addon:UnregisterEvent("START_LOOT_ROLL")
            addon:UnregisterEvent("CANCEL_LOOT_ROLL")
            addon:UnregisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER")
	    end
	end

    if theAction == "MessageON" or theAction == "Register" then
    	addon:RegisterEvent("CHAT_MSG_ADDON","eventHandler")            -- 
        addon:RegisterEvent("CHAT_MSG_SYSTEM","eventHandler")           -- 

        addon:RegisterComm("PL_RANK_CHECK","inPL_RANK_CHECK")        -- a player has asked to check your selection. - activated on delay after login  
                                                                     -- If they are current ignore, if not send a targeted message with Data message
        addon:RegisterComm("PL_RANK_UPDATE","inPL_RANK_UPDATE")      -- Process a message to update a players details if PL_RANK_CHECK promted a response from anophter player
        addon:RegisterComm("PL_CONFIG_UPDATE","inPL_CONFIG_UPDATE")  -- The Loot Manager has updated the configuration - activated by Loot Manager
        addon:RegisterComm("PL_ADDON_ACTIVE","inPL_ADDON_ACTIVE")    -- The Loot Manager has updated the configuration - activated by loot manager
        addon:RegisterComm("PL_ROLL_CHECK","inPL_ROLL_CHECK")        -- Asking the loot manager if Loot Rolls are active
        addon:RegisterComm("PL_CONFIG_CHECK","inPL_CONFIG_CHECK")    -- Check the configuration with the loot manager
    end

    if theAction == "MessageON" or theAction == "unRegister" then
	    addon:UnRegisterEvent("CHAT_MSG_ADDON")
        addon:UnRegisterEvent("CHAT_MSG_SYSTEM")
	end 


end

function addon:eventHandler(theEvent, ...)


        -- util.AddDebugData(theEvent, "eventHandler started")

        local thePrefix,theMessage,theChannel,theSender,theTarget = ...

        if theSender == util.unitname('player') then
            return
        end 
		
    	if theEvent == "GROUP_ROSTER_UPDATE" then  
		    --  if a new person joins then reload raidUnit
            -- check what triggers this as well so we only get it on joining a raid not on rearranging groups
			
        elseif theEvent == "GROUP_JOINED" then
             addon:joinedRaid()

		elseif theEvent == "GROUP_LEFT" then
             addon:leftRaid()	

        elseif theEvent == "PLAYER_ENTERING_WORLD" then
		    self.instanceType = select(2, IsInInstance())
            local isLogin, isReload = ...
            if isLogin or isReload then
			    C_ChatInfo.RegisterAddonMessagePrefix(MyAddOnName)
		    end
            if isLogin then
                -- 
			end

		elseif theEvent == "CHAT_MSG_SYSTEM" then
            local theMessageIn = ...
            addon:inCHAT_MSG_SYSTEM(theMessageIn) -- a guild member logged in

		elseif theEvent == "CHAT_MSG_ADDON" then

            if thePrefix == MyAddOnName then 
  				local newMessage = addon:processMessage(theMessage)                     
                -- and then do stuff
			end
		end
end                           -- Actions assigned to events

----------- PROFILE RELATED FUNCTIONS -----------------------
function addon:OnNewProfile(eventName, db, profile)

	--Set the dbVersion to the most recent, as defaults for the new profile should be up-to-date

end 

function addon:OnProfileChanged(eventName, db, newProfile)

	self:checkDbVersion()

end   

function addon:FullRefresh()
    UpdateMinimapIcon()
end                            -- TO BE COMPLETED - Do we still need this as a function.  Include anything that happens after a profile update

----------- ROSTER RELATED FUNCTIONS -----------------------

function loadGuildMembers()
-- Build the list of guild members
-- based on their rank.  Store then in the DB by adding or deleting as required along with the addon version details if any
--

-- rankName = GuildControlGetRankName(index)

    local numTotalGuildMembers, numOnlineGuildMembers, _ = GetNumGuildMembers()
    local memberCounter = #addon.PLdb.char.guildMembers
    local memberRecord = {}
    local memberFound = False
    local memberNames = {} --  check the current guild members and delete others

    thisAddon.roster = {} 

    -- guild unit is the list of all current guild members + extra data about the addon based on rank
    thisAddon.guildUnit = addon.PLdb.char.guildMembers

    for gmc=1,numTotalGuildMembers do
        local memberName, _, memberRankIndex, _, _, _, _, _, memberIsOnline, _, _, _, _, _, _, _, memberGUID = GetGuildRosterInfo(gmc)
        local itsMe = false

--		util.AddDebugData(memberName,"My name is ")
--      util.AddDebugData(memberRankIndex,"My Rank Index ")

        -- Is the member I am looking at me ?
		if (util.unitname(UnitName("player")) == memberName) then
            itsMe = true
            -- util.AddDebugData(itsMe,memberName..": is me")
        end       -- UnitIsUnit()

        -- if they have the rank of an officer and are not in the officers list then insert them
        if util.hasValue(addon.PLdb.char.guildOfficerRanks,memberRankIndex) and
            not util.hasValue(addon.PLdb.char.officerList,memberName) then
            table.insert(addon.PLdb.char.officerList,memberName)
			end

        -- if they do not the rank of an officer and are  in the officers list then remove them
        if not util.hasValue(addon.PLdb.char.guildOfficerRanks,memberRankIndex) and
            util.hasValue(addon.PLdb.char.officerList,memberName) then
            --util.AddDebugData(addon.PLdb.char.officerList,"Officer  list")
            --util.AddDebugData(memberName,"memberName")
            position = util.keyFromValue(addon.PLdb.char.officerList,memberName)
            table.remove(addon.PLdb.char.officerList,position)
		end

        -- get whatever current record we have for this person if any in the guildUnit table
        memberFound, memberRecord, memberLocation = getGuildMember(memberName)

        -- util.AddDebugData(memberFound,memberName.." found in the existing table")

        -- If I am the GM then lets flag that
        if memberRankIndex == 0 and itsMe then 
            iAmTheGM = true
		else
            iAmTheGM = false 
		end

        
        -- If I am the loot manager then lets flag that
        if not iAmTheLootManager then
            if addon.PLdb.char.guildLootManager == util.unitname(UnitName("player")) and
                (util.hasValue(addon.PLdb.char.guildOfficerRanks,memberRankIndex) or iAmTheGM ) then -- include GM incase some numpty removes GM from officerranks
                iAmTheLootManager = true
		    else
                iAmTheLootManager = false 
		    end
		end 

        -- If its a valid raiding rank or its me then add me to the list
        if util.hasValue(addon.PLdb.char.guildRaidRanks,memberRankIndex) or itsMe then
		       
               -- insert into a list of valid guild members that we hold for checking at the end of this function
               -- This lets us delete people who were but no longer are in the list of raiders 
               table.insert(memberNames,memberName) 
                
               -- if the person does not already exist lets add them
               if not memberFound then
                   util.AddDebugData(memberName,"Guild member added to DB")

                   memberRecord.unitName = memberName
                   memberRecord.unitRank = memberRankIndex

                   if itsMe then
			   	       memberRecord.hasAddon = version                            
                       memberRecord.lastCheck = addon.PLdb.char.lastConfigCheck                         
	                   memberRecord.configVersion = addon.PLdb.char.configVersion
                       memberRecord.online = true
                       table.insert(addon.PLdb.char.guildMembers,1,memberRecord) -- insert into position 1
			       else
                       memberRecord.hasAddon = 0        
                       memberRecord.configVersion = 0   
                       memberRecord.lastCheck = 0
                       memberRecord.online = memberIsOnline
                       table.insert(addon.PLdb.char.guildMembers,2,memberRecord)
			       end 

               else
                   -- util.AddDebugData(memberFound,"Found in existing DB "..memberName)
                   -- We don't need to add them to the config file
                   thisAddon.guildUnit[memberLocation].online = memberIsOnline
			   end
		 else
                -- util.AddDebugData(memberRankIndex,"Not a raiding rank")
		 end
    end

    -- util.AddDebugData(memberNames,"Members that we found to validate")

    local i = 1
    while i < #thisAddon.guildUnit do
	    if not util.hasValue(memberNames,thisAddon.guildUnit[i].unitName) then
            -- util.AddDebugData(guildUnit[i].unitName,"Record removed from guild data")
            table.remove(thisAddon.guildUnit,i) -- remove from the record of raiders in the database to capture and changes
        else
            -- util.AddDebugData(guildUnit[i].unitName,"Record NOT removed from guild data")
            i = i + 1
		end
	end
	    
    -- util.AddDebugData(thisAddon.guildUnit,"Should be the correct guild list after changes")
end                         -- load and process the guild roster to identify roles and load data

function loadRaidMembers()
    local numMembers = GetNumGroupMembers()
	local playerName = util.unitname('player')
    local unitCount, unitCountHold = 2              -- I am position 1 so always start at 2
    for i=1,MAX_RAID_MEMBERS do      
		--name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(raidIndex)

        local unitID = thisADdon.raidUnit[i]
        local unitName = GetRaidRosterInfo(i) or "none"
        local itsMe = UnitIsUnit('player',unitID)

        -- util.AddDebugData(unitName,"Unitname in raid roster")

        if unitName ~= "none" then
            local guildName, _, _, guildrealm = GetGuildInfo(unitID)
            
            if guildRealm == nil then                   -- if its my server then the realm will be "nil" so set it to the correct name
			    guildRealm = GetRealmName()
            end

            -- its the same guild name on the same realm
            if guildName == addon.PLdb.char.myGuildName and guildRealm == addon.PLdb.char.myGuildRealm then

                -- if its me force it into roster position 1
                if unitName and itsMe then 
                    unitCountHold = unitCount
                    unitCount = 1
			    end

                if unitName and not util.hasValue(thisAddon.raidUnit,unitID) then                -- if the unit does not already exist and its not me
				    thisAddon.raidUnit[unitCount] = {}
                    thisAddon.raidUnit[unitCount].unitID = unitID     
                    thisAddon.raidUnit[unitCount].unitName = unitName 
                end

                -- if its me then put things back to normal and continue
                if unitName and itsMe then  
                    rosterCount = rosterCountHold
				else
                    rosterCount = rosterCount + 1
			    end
                    
            end
		end
    end
end

function updateRosterToGuild()

	wipe(thisAddon.roster) 
    local rosterCount = 1   
	
    for idx,guildMember in ipairs(thisAddon.guildUnit) do
	
        --if util.hasValue(addon.PLdb.char.guildRaidRanks,guildMember.unitRank) then

            -- The first unit is me becuase wee forced that when loading guildUnit
	        local notMe = not UnitIsUnit('player',guildMember.unitName) 

            -- util.AddDebugData(util.getShortName(guildMember.unitName),"Guild member added to headings")

            thisAddon.roster[rosterCount] = {}
            thisAddon.roster[rosterCount].unitID = rosterCount                                  -- does not really matter for the guild roster     
            thisAddon.roster[rosterCount].unitName = util.getShortName(guildMember.unitName)    -- set to my name

            if notMe then 
                thisAddon.roster[rosterCount].hasAddon = guildMember.hasAddon                       -- has or does not have the PL addon
                thisAddon.roster[rosterCount].configVersion = guildMember.configVersion
                thisAddon.roster[rosterCount].lastCheck = guildMember.lastCheck                     -- we want to check some basics once and only once
                thisAddon.roster[rosterCount].online = guildMember.online  
                -- util.AddDebugData(util.getShortName(guildMember.unitName),"Guild member added to headings")
            else
	            thisAddon.roster[1].hasAddon = version                            
                thisAddon.roster[1].lastCheck = addon.PLdb.char.lastConfigCheck                         
	            thisAddon.roster[1].configVersion = addon.PLdb.char.configVersion
                thisAddon.roster[1].online = true
		    end	
            rosterCount = rosterCount + 1
		--end			
	end
end                     -- change what is displayed in the table frame to guild members

function updateRosterToRaid()
 -- make sure I am number 1 in the roster

	wipe(thisAddon.roster) 

    local rosterCount = 1

    if IsInRaid() then

        for i=1,MAX_RAID_MEMBERS do      

			thisAddon.roster[i] = {}
            -- thisAddon.roster[i].unitID = unitID     
            thisAddon.roster[i].unitName = thisAddon.raidUnit[i].unitName 

            local _,memberRecord,_ = getGuildMember(thisAddon.raidUnit[i].unitName)

            if memberRecord then
                thisAddon.roster[i].hasAddon = memberRecord[1]            
                thisAddon.roster[i].lastCheck = memberRecord[2]              
                thisAddon.roster[i].configVersion = memberRecord[3]   
            end
        end
    end
end                      -- change what is displayed in the table frame to raid members  

function updateRosterToTestData()

end                  -- change what is displayed to be test data for demo mode

------------- FUNCTIONS TO SUPPORT MINIMAP BUTTON ACTIONS --------------------

function addon:OpenOptions()
    ACD:Open(MyAddOnName)
    local dialog = ACD.OpenFrames[MyAddOnName]
    -- util.AddDebugData(dialog,"Options Dialog")

    if dialog then
        dialog:EnableResize(false)
    end
end                             -- Open the options panel - Do we still need this as a function

------------- FRAME SETUP FUCTIONS ---------------------------------------

function addon:displayWelcomeImage()
    

    if addon.PLdb.profile.welcomeImage then 

        addon.welcomeImage = CreateFrame("Frame", 'welcomeImageFrame' , UIParent) 
        addon.welcomeImage:SetPoint("CENTER")
        -- self.welcomeImage:SetAllPoints()
        addon.welcomeImage:SetSize(768,768)

        local bg = addon.welcomeImage:CreateTexture()
        bg:SetAllPoints(addon.welcomeImage)
        bg:SetTexture("Interface\\AddOns\\PriorityLoot\\Media\\Textures\\WelcomePicture")
        -- bg:SetTexCoord(0, 1, 0, 1)
        bg:Show()

        local btn = CreateFrame("Button", nil, addon.welcomeImage, "UIPanelButtonTemplate")
        btn:SetText("Close")
        btn.Text:SetTextColor(1, 1, 1)
        btn:SetWidth(100)
        btn:SetHeight(30)
        btn:SetPoint("BOTTOM", 190, 23)
        btn.Left:SetDesaturated(true)
        btn.Right:SetDesaturated(true)
        btn.Middle:SetDesaturated(true)
        btn:SetScript("OnClick", function()
            addon.welcomeImage:Hide()
        end)
        addon.welcomeImage:Show()
        addon.PLdb.profile.welcomeImage = false
    end

end                      -- display the welcome image the first time the addon loads

function buildMainLootWindow()
--[[
    Flesh out the MainLootFrame create on initialisation
    Create a group to hold two columns
    Fill out the top and the bottom half of the filter columns.  The bottom half is programtically created
    Build the right hand side "Table" column which contains a header and a scroll area for data
]]--
   -- Create the two main frames
    thisAddon.MainLootFrame = AceGUI:Create("Frame")

    local count = 1

    -- Create Main Loot Form
    thisAddon.MainLootFrame:SetTitle("Priority Loot")
    thisAddon.MainLootFrame:SetStatusText("Priority Loot Review Window")
    thisAddon.MainLootFrame:SetWidth(addon.PLdb.profile.setFrameWidth)
    thisAddon.MainLootFrame:SetHeight(600)
    thisAddon.MainLootFrame:SetLayout("Flow")
    thisAddon.MainLootFrame:EnableResize(false)
    -- util.AddDebugData(thisAddon.MainLootFrame,"Main Frame")

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
    
    thisAddon.MainLootFrame:Hide()

end

function buildFilterColumnTop()

	-- filterColumn - Create the first column group

    thisAddon.filterColumn = AceGUI:Create("SimpleGroup")
    -- filterColumn:SetTitle("Filters")
    thisAddon.filterColumn:SetWidth(addon.PLdb.profile.setFilterWidth)
    thisAddon.filterColumn:SetHeight(550)
    thisAddon.filterColumn:SetLayout("Flow")

     -- filterColumn - Player Heading
    local sourceHeading = AceGUI:Create("Heading")
    sourceHeading:SetText("Show players from")
    sourceHeading:SetFullWidth(true)
    thisAddon.filterColumn:AddChild(sourceHeading)

    local raidRadio = AceGUI:Create("CheckBox")
    local guildRadio = AceGUI:Create("CheckBox")

    raidRadio:SetLabel("Raid")
    raidRadio:SetWidth(100)
    raidRadio:SetCallback("OnValueChanged", function(widget, event, selected) 
            if selected then 
			    thisAddon.filters.displayGuildNames = false
                thisAddon.filters.displayRaidNames = true
            else
			    thisAddon.filters.displayGuildNames = true
                thisAddon.filters.displayRaidNames = false
		    end
            guildRadio:ToggleChecked()
            fillTableColumn()
	end)
    raidRadio:SetDisabled(not IsInRaid())
    
    guildRadio:SetLabel("Guild")
    guildRadio:SetWidth(100)
    guildRadio:SetValue(thisAddon.filters.displayGuildNames)
    guildRadio:SetCallback("OnValueChanged", function(widget, event, selected) 
            if selected then 
			    thisAddon.filters.displayGuildNames = true
                thisAddon.filters.displayRaidNames = false
			else
                thisAddon.filters.displayGuildNames = false
                thisAddon.filters.displayRaidNames = true
			end
            raidRadio:ToggleChecked()
            fillTableColumn()

		end)
    thisAddon.filterColumn:AddChild(guildRadio)
    thisAddon.filterColumn:AddChild(raidRadio)
    
    -- Spacer
    local spacerTop = AceGUI:Create("Label")
    spacerTop:SetText("  ")
    spacerTop:SetFullWidth(true)
    thisAddon.filterColumn:AddChild(spacerTop)

     -- filterColumn - Player Heading
    local sourceHeading = AceGUI:Create("Heading")
    sourceHeading:SetText("Display items selected")
    sourceHeading:SetFullWidth(true)
    thisAddon.filterColumn:AddChild(sourceHeading)

      -- filterColumn - Checkbox for My Loot
    local checkboxMyPriority = AceGUI:Create("CheckBox")
    local checkboxNoPriority = AceGUI:Create("CheckBox")

    checkboxMyPriority:SetLabel("By me")
    checkboxMyPriority:SetType("checkbox")
    checkboxMyPriority:SetWidth(100)
    checkboxMyPriority:SetCallback("OnValueChanged", function(widget, event, selected) 
            if selected then 
			    thisAddon.filters.onlyMyPriority = true
                thisAddon.filters.onlyNoPriority = false
                checkboxNoPriority:SetValue(false)
			else
                thisAddon.filters.onlyMyPriority = false
			end
            fillTableColumn()
		end)
    thisAddon.filterColumn:AddChild(checkboxMyPriority)  
    
    -- filterColumn - Checkbox for My Loot
    
    checkboxNoPriority:SetLabel("By noone")
    checkboxNoPriority:SetType("checkbox")
    checkboxNoPriority:SetWidth(100)
    checkboxNoPriority:SetCallback("OnValueChanged", function(widget, event, selected) 
            if selected then 
			    thisAddon.filters.onlyNoPriority = true
                thisAddon.filters.onlyMyPriority = false
                checkboxMyPriority:SetValue(false)
			else
                thisAddon.filters.onlyNoPriority = false
			end
            fillTableColumn()
		end)
    thisAddon.filterColumn:AddChild(checkboxNoPriority)  

    -- Spacer
    local spacerTop = AceGUI:Create("Label")
    spacerTop:SetText("  ")
    spacerTop:SetFullWidth(true)
    thisAddon.filterColumn:AddChild(spacerTop)
	
	-- filterColumn - Source Heading
    local sourceHeading = AceGUI:Create("Heading")
    sourceHeading:SetText("Choose Raid Boss")
    sourceHeading:SetFullWidth(true)
    thisAddon.filterColumn:AddChild(sourceHeading)
 
    -- filterColumn - dropdownBoss
    -- dropdownBoss:SetLabel("Selected Boss")
    local dropdownBoss = AceGUI:Create("Dropdown")
    dropdownBoss:SetList(getElementsFromRaids("bosslist","",""))
    dropdownBoss:SetValue(2)
    dropdownBoss:SetWidth(200)
    dropdownBoss:SetCallback("OnValueChanged", function(widget, event, key) 
        local whatBoss = dropdownBoss:GetValue()
		currentBoss = getElementsFromRaids("bossId",whatBoss,"") 
        fillTableColumn()
        -- util.AddDebugData(whatBoss,"What Boss choosen from dropdown")
        -- util.AddDebugData(currentBoss,"Current Boss found")
		-- print("Selected option:", dropdownBoss:GetValue())  end)
        -- util.AddDebugData(dropdownBoss:GetValue(),currentRaid.currentBoss.bossName,"Boss selected")
		end)
    thisAddon.filterColumn:AddChild(dropdownBoss)     
    -- util.AddDebugData(currentRaid.currentBoss.bossName,"Boss dropdown added")
 
end

function buildFilterColumnBottom()
   
    -- util.AddDebugData(thisAddon.filters,"Filters check active")

    thisAddon.checkboxList = {}
    for key,filterList in ipairs (addon.PLdb.global.filterColumnElements) do

        -- Loop through the data and create headers, spacers or buttons
        if filterList.type == "H" then
            -- filterColumn - Player Heading
            theHeading = AceGUI:Create("Heading")
            theHeading:SetText(filterList.name)
            theHeading:SetFullWidth(true)
            thisAddon.filterColumn:AddChild(theHeading)
        elseif filterList.type == "S" then
            -- filterColumn - Player Heading
            spacer = AceGUI:Create("Label")
            spacer:SetFullWidth(true)
            spacer:SetText("  ")
            thisAddon.filterColumn:AddChild(spacer)
        else
    --[[
            The following can be excluded from rolls by the Loot Manager

	        ID="E" is "Armour"                
			ID="F" is "Trinkets"
	        ID="G" is "Jewelery"
			ID="H" is "Weapons (1H)" ID="I" is "Weapons (2H)" ID="J" is "Offhand" ID="K" is "Ranged"
    ]]--    
	        local includeArmour = addon.PLdb.char.includeArmour
            local includeTrinkets = addon.PLdb.char.includeTrinkets
            local includeJewelery = addon.PLdb.char.includeJewelery
            local includeWeapons = addon.PLdb.char.includeWeapons
            local includeTier = addon.PLdb.char.includeTier

                -- filterColumn Checkbox
            local theCheckbox = AceGUI:Create("CheckBox")
            thisAddon.checkboxList[filterList.position] = theCheckbox
            theCheckbox:SetLabel(filterList.name)
            theCheckbox:SetType("checkbox")
            theCheckbox:SetWidth(100)
			
			if ((filterList.ID == "A" or filterList.ID == "B" or filterList.ID == "C" or filterList.ID == "D" or filterList.ID == "E") and includeArmour) or 
            (filterList.ID == "F" and includeTrinkets) or
            (filterList.ID == "G" and includeJewelery) or
            (filterList.ID == "H" and includeWeapons) or
            ((filterList.ID == "I" or filterList.ID == "J" or filterList.ID == "K") and includeWeapons) or
            (filterList.ID == "L" and includeTier) then
                theCheckbox:SetDisabled(false)
            else
                theCheckbox:SetDisabled(true)
			end

            if thisAddon.filters.currentFilter[filterList.position] == "-" then
			    theCheckbox:SetValue(false)
            else
			    theCheckbox:SetValue(true)
			end

            theCheckbox:SetUserData("group",filterList.group)
			
            theCheckbox:SetCallback("OnValueChanged", function(widget, event, selected) 
                    if selected then 
                        thisAddon.filters.currentFilter[filterList.position] = filterList.ID
				    else
				        thisAddon.filters.currentFilter[filterList.position] = "-"
				    end
                    refreshDataInTable()
			    end)
            thisAddon.filterColumn:AddChild(theCheckbox)
			
		end
    end

    
    local showPriorityEntry = AceGUI:Create("Button")
    showPriorityEntry:SetText("Show All Priorities")
    showPriorityEntry:SetWidth(200)
    showPriorityEntry:SetCallback("OnClick", function()
            tableColumnContent = "S"        -- (S)how Priorities
		    fillTableColumn()       
            statusText("Showing priorities for currently filtered items and players. ")
	    end)
    thisAddon.filterColumn:AddChild(showPriorityEntry)

    local enterPriorities = AceGUI:Create("Button")
    enterPriorities:SetText("Enter My Priorities")
    enterPriorities:SetWidth(200)
    enterPriorities:SetCallback("OnClick", function()
            if addon.PLdb.char.lockPrioritiesDuringRaid and IsInRaid() then
			    statusText(format("Editing priorities is %s for your guild during raids.",util.Colorize("LOCKED", "accent")))
            else
                tableColumnContent = "E"        -- (E)nter Priorities
		        fillTableColumn()      
                statusText(format("Enter your priorities for currently filtered items.  %i will remove a priority.",util.Colorize("0", "accent")))
			end
	end)
    enterPriorities:SetDisabled(IsInRaid())
    thisAddon.filterColumn:AddChild(enterPriorities)

    local showLootHistory = AceGUI:Create("Button")
    showLootHistory:SetText("Show Loot History")
    showLootHistory:SetWidth(200)
    showLootHistory:SetCallback("OnClick", function()
            tableColumnContent = "L"        -- (L)oot HIstory
		    fillTableColumn()     
            statusText("Filter and review loot history ")
	    end)
    thisAddon.filterColumn:AddChild(showLootHistory)

     -- Set any special defaults
    local theType = addon.PLdb.char.myArmourType

    -- Loop through the 4 armour types resetting them to match the filters and default armour types
    for counter,filterSetting in pairs(addon.PLdb.global.filterArmourType) do
	    if filterSetting == theType then      -- found my default type
            thisAddon.filters.currentFilter[counter]=filterSetting
            thisAddon.checkboxList[counter]:SetValue(true)
        else
            thisAddon.filters.currentFilter[counter]="-"
            thisAddon.checkboxList[counter]:SetValue(false)
	    end
	end

end

function buildTableColumn()
    local headerLabels = {}
    --                              width of the MainFrame           -       width of filter frame              - spacer - AceWow shit
    local tableColumnWidth = addon.PLdb.profile.setFrameWidth - addon.PLdb.profile.setFilterWidth - 20 - 40

    -- thisAddon.tableColumn - Create the second column group 
    thisAddon.tableColumn = AceGUI:Create("SimpleGroup") 
    thisAddon.tableColumn:SetWidth(tableColumnWidth)
    thisAddon.tableColumn:SetPoint("TOPLEFT", "UIParent", "TOPLEFT",0,60)
    thisAddon.tableColumn:SetFullHeight(true)
    thisAddon.tableColumn:SetLayout("Flow") 

    -- Create the heading container for the user data
    thisAddon.headingContainer = AceGUI:Create("SimpleGroup")
    thisAddon.headingContainer:SetFullWidth(true)
    thisAddon.headingContainer:SetLayout("Flow") 
    thisAddon.headingContainer:SetPoint("TOPLEFT", "UIParent", "TOPLEFT",0,60)
	thisAddon.tableColumn:AddChild(thisAddon.headingContainer)

	-- Create the scroll container for the user data
    thisAddon.scrollContainer = AceGUI:Create("ScrollFrame")
    thisAddon.scrollContainer:SetWidth(tableColumnWidth)
    thisAddon.scrollContainer:SetHeight(410)
    thisAddon.scrollContainer:SetLayout("Flow") -- This Setting can cause massive delays in the addon
    
    thisAddon.tableColumn:AddChild(thisAddon.scrollContainer)

    fillTableColumn()

end

function addTableColumnHeadings()
    if tableColumnContent == "S" then
	    playerPriorityHeadings()
	elseif tableColumnContent == "E" then
	    enterPriorityHeadings()
    elseif tableColumnContent == "L" then
	    lootHistoryHeadings()
    end
end                    -- Add headings based on what is being displayed

function playerPriorityHeadings()

        -- tableColumn - Create the header group for the table
    local header1 = AceGUI:Create("SimpleGroup")
    local header2 = AceGUI:Create("SimpleGroup")
    local widthOfIcon = 34                                      -- pixels
    local widthOfCharacter = 5.6                                -- assuming Courier 12 point
    local lastOverhang1 = addon.PLdb.profile.GUI.nameLeftMarginTop  --  True up some initial indent ot make thigns line up
    local lastOverhang2 = addon.PLdb.profile.GUI.nameLeftMarginBottom                                    -- Allow for the column of item icons for the second header row

    -- Create a custom font object
    -- local courierFont = CreateFont("Courier12")                 -- use a font that has a fixed width
    -- courierFont:SetFont("Interface\\Addons\\PriorityLoot\\media\\Fonts\\courier.ttf",10,"")           
    
    header1:SetFullWidth(true)
    header1:SetLayout("Flow")
    header2:SetFullWidth(true)
    header2:SetLayout("Flow")

    if not getListOfHeadingsToDisplay() then
	    util.AddDebugData(true,"WE HAVE A PROBLEM")
	end

    whichHeader = 1                                             -- start on the top row

    for idx,rosterRec in ipairs(thisAddon.roster) do 
        -- work out the spacer based on the heading width
        local nameText = util.getShortName(rosterRec.unitName)
		local headingLength = #nameText
		local headingWidth = 11 + (headingLength *  widthOfCharacter)      -- width of heading in pixels
        local theOverhang= ((headingWidth - widthOfIcon) / 2)      --  how much does the name overhang a standard column
        local priorOverhang = 0                                  

        if whichHeader == 1 then 
            priorOverhang = lastOverhang1
		else
            priorOverhang = lastOverhang2
		end

        -- util.AddDebugData(theOverhang, "addTableColumnHeadings:  theOverhang - "..nameText)

        spacerSize = (widthOfIcon - priorOverhang - theOverhang)    -- how many pixels wide does the spacer need to be so that the current heading is centered over the column

        local label = AceGUI:Create("Label")
        label:SetText(nameText)
        label:SetWidth(headingWidth)                            -- Adjust the width as needed
        -- label:SetFontObject(courierFont)                        -- set the font to courier
        local spacer = AceGUI:Create("Label")
        spacer:SetWidth(spacerSize)                             -- Adjust the width as needed

        local addonVersion,configVersion,playerStatus,errorCode = checkPlayerAddon(rosterRec)
        local statusText = "Offline"
        if playerStatus then
		    statusText = "Online"
		end

        if errorCode then -- and error code means something is wrong with teh data like they dont exist / dont have the addon
            label:SetColor(1, 0, 0) -- Red color (RGB: 1, 0, 0)

            label.frame:SetScript("OnEnter", function()
                GameTooltip:SetOwner(label.frame, "ANCHOR_TOPRIGHT")
                GameTooltip:AddLine("Player status:")
                GameTooltip:AddLine("Config version: "..configVersion,1,1,1)
                GameTooltip:AddLine("Addon version: "..addonVersion,1,1,1)
                if playerStatus then
                    GameTooltip:AddLine("Currently "..statusText,0,1,0)
                else
                    GameTooltip:AddLine("Currently "..statusText,1,0,0)
                end

                GameTooltip:Show()
            end)

            label.frame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        else
            label:SetColor(0, 1, 0) -- Red color (RGB: 1, 0, 0)
		end
        

        if whichHeader == 1 then
            header1:AddChild(spacer)
            header1:AddChild(label)
 			whichHeader = 2
            lastOverhang1 = theOverhang
        else
            header2:AddChild(spacer)
		    header2:AddChild(label)
			whichHeader = 1
            lastOverhang2 = theOverhang
		end
    end

    -- tableColumn - Add the header group to the second column
    thisAddon.headingContainer:AddChild(header1)  
    thisAddon.headingContainer:AddChild(header2)  
end                    -- Show the headings with player names (guild or raid)

function enterPriorityHeadings()
    -- add the button row
    enterPriorityButtons()

    -- tableColumn - Create the header group for the table
	local header1 = AceGUI:Create("SimpleGroup")
    local widthOfIcon = 34                                      -- pixels
    local widthOfCharacter = 5.6                                -- assuming Courier 12 point

    -- Create a custom font object
    --local courierFont = CreateFont("Courier12")                 -- use a font that has a fixed width
    --courierFont:SetFont("Interface\\Addons\\PriorityLoot\\media\\Fonts\\courier.ttf",12,"")           
    
    header1:SetFullWidth(true)
    header1:SetLayout("Flow")

    -- tableColumn 
    headerLabels = getListOfHeadingsToDisplay()

    -- util.AddDebugData(headerLabels,"The enter priority headings")

    for count,headingInfo in pairs(headerLabels) do

        local spacer = AceGUI:Create("Label")
        spacer:SetWidth(headingInfo[1]) 

	    local label = AceGUI:Create("Label")
        label:SetWidth(40)
        label:SetText(headingInfo[2])
        label:SetFontObject(courierFont)   
        label:SetColor(0, 1, 0) -- Red color (RGB: 1, 0, 0)

        header1:AddChild(spacer)
        header1:AddChild(label)
	end
    thisAddon.headingContainer:AddChild(header1)  
    
end                     -- change the headings to the headings when you enter priorities

function enterPriorityButtons()
	local buttonRow = AceGUI:Create("SimpleGroup")
    buttonRow:SetFullWidth(true)
    buttonRow:SetLayout("Flow")

    local clearPriority = AceGUI:Create("Button")
    clearPriority:SetText("Clear Priorities")
    clearPriority:SetWidth(200)
    clearPriority:SetCallback("OnClick", function()
            clearPriorities()
            fillTableColumn() 
            statusText("Priorities cleared and reset ")
	    end)
    buttonRow:AddChild(clearPriority)

   local clearPriority = AceGUI:Create("Button")
    clearPriority:SetText("Import Raidbots")
    clearPriority:SetWidth(200)
    clearPriority:SetCallback("OnClick", function()
            statusText("This function is not implemented yet ")
	    end)
    buttonRow:AddChild(clearPriority)

    thisAddon.headingContainer:AddChild(buttonRow)  
end                      -- Add any buttons required when entering priorities

function lootHistoryHeadings()

end                       -- change the table frame to show the loot history with the same filters

function resetCheckboxGroup(theGroup,theSetting)
    -- util.AddDebugData(theGroup,theSetting)
    -- util.AddDebugData(thisAddon.checkboxList,"checkbosList")
    for _,theCheckbox in pairs(thisAddon.checkboxList) do
        if theCheckbox:GetUserData("group") == theGroup then
		    theCheckbox:SetDisabled(not theSetting)
		end
	end
end                        -- If we have a group of checkboxes we want to disable or enable use this

function checkPlayerAddon(rosterRecIn)
    local addonVersion = "Not Loaded"
	local configVersion = "Not Loaded"
    local playerStatus = false
    local errorCode = false

    -- util.AddDebugData(rosterRecIn,"rosterRecIn")

    if tonumber(rosterRecIn.hasAddon) > 0 then 
		addonVersion = tostring(rosterRecIn.hasAddon) 
    else 
		errorCode = true
	end
    
    if tonumber(rosterRecIn.configVersion) > 0 then 
		configVersion = tostring(rosterRecIn.configVersion) 
        --util.AddDebugData(true,"Config Version A")
    else 
		errorCode = true
        --util.AddDebugData(configVersion,"Config Version B")
	end

    return addonVersion,configVersion,rosterRecIn.online, errorCode

end                                -- get the details of the player config &  addon versions = online status

function fillTableColumn()
    
    if not finishedInitalising then
	    return
	end
    
	if headingsExist then
	    thisAddon.headingContainer:ReleaseChildren()
    else
        headingsExist = true
	end

    -- add headings
    addTableColumnHeadings()

    -- add data
    refreshDataInTable()

end                                 -- Start the process for filling the user selections


------------- DATA FUCTIONS ---------------------------------------

function loadLootHistory()
    return
end                                 -- TO BE COMPLETED

function refreshDataInTable()

    thisAddon.scrollContainer:ReleaseChildren()
    for _,frameObject in ipairs(thisAddon.frameReferences) do
        frameObject:UnregisterAllEvents()
        frameObject:Hide()
	end

    addDataToTable()

end                              -- Refresh whatever table is currently displayed (Shot or enter priorities, loot history_

function addDataToTable()
    local playerChoices = {}
    local myPriorities = {}

    -- util.AddDebugData(tableColumnContent,"addDataToTable started")
    if tableColumnContent == "L" then
	    loadLootHistory()
	else
         -- tableColumn - Loot through the loot data for this boss and add the rows
   	    tbl = addon.PLdb.global.bossLoot
        -- util.AddDebugData(currentBoss,"Looking for this boss loot table")

         for _, bossRec in ipairs(tbl) do
             -- util.AddDebugData(bossRec.bossId,"Found a boss")
            if bossRec.bossId == currentBoss or currentBoss == 1 then  -- 1 means all bosses
                -- util.AddDebugData(bossRec.bossId,"Found the target boss")
                for _, rowData in ipairs(bossRec.lootItems) do
                    myPriority = 0
                    playerChoices={}
                    if itemFilteredIn(rowData[1]) then
                        if tableColumnContent == "E" then
                            -- util.AddDebugData(true,"Reached PrioritiesToTable")
                            -- myPriority = get my priority if I already have one for the item << STILL WRITING THIS
                            enterMyPriorities(thisAddon.scrollContainer,myPriority,rowData[1],rowData[2])
				        elseif tableColumnContent == "S" then   
				            playerChoices = getRanksByPlayer(rowData[1])  -- get the player choices based on the itemID
				            addPlayerSelectionRowsV2(thisAddon.scrollContainer, rowData[1],playerChoices) 
                        end
                    -- else
                            --util.AddDebugData(rowData[1],"addDataToTable: ERROR Row not added to scollFrame")
				    end
			    end
            end
		end
	 end     
end   

function reuseFrame()
--[[
    Frames are a resource so we dont create infinite numbers of them.  Once created we reuse them again and again.
]]--
    local totalFrames = #thisAddon.frameReferences

    if totalFrames == nil then totalFrames = 0 end
	
    if totalFrames>0 and thisAddon.frameBeingDisplayed < totalFrames then  -- if X frames are already display but more are avilable
        thisAddon.frameBeingDisplayed = totalFrames + 1                     -- increase the number displayed
	    return thisAddon.frameBeingDisplayed                                -- and say which frame to reuse
	else
        thisAddon.frameBeingDisplayed = totalFrames + 1                     -- increase the number displayed
        return 0                                                            -- create one
	end
end                                -- Icons are in frames.  reuse the frames rather than keep creating them to save resources.

function getRanksByPlayer(itemId)         
local returnRow = {}
local playerRecord = {}
local counter = 0


-- local currentPlayersShown = getListOfHeadingsToDisplay()

    -- Loop through the list of players being displayed
    for _,player in pairs(thisAddon.guildUnit) do 
        local playerNumber = 0      -- What record in the table is that player
        local usedSelection = {}
        -- util.AddDebugData(player,"Player details for priorities")

	    -- Find the record that belongs to the current player if any in the stored priorities
		playerNumber = getPlayerInformation(player.unitName,0,"PP")
		
		-- Keep tracking the number of the player we are working on
        counter = counter + 1

        -- Set the default to zero meaning no data
		returnRow[counter] = 0
			
        -- If a player was found then get the priority they chose
        if playerNumber > 0 then
            returnRow[counter] = getPlayerInformation(player.unitName,itemId,"P")

            --if playerNumber == 1 then
            --    util.AddDebugData(returnRow,"getRanksByPlayer: return")
            --end
            if returnRow[counter] < 0  then  -- if an error was returned
			    returnRow[counter] = 0
			end
            -- if I have a rank but I have also used it convert it to a negative rank for display only
            if returnRow[counter] > 0 then

				    local priorityHistory = getPlayerInformation(player.unitName,"","PH")
                    if  util.hasValue(priorityHistory,returnRow[counter]) then
                        returnRow[counter] = returnRow[counter] * (-1)
                    end
			end
		end
    end


    return returnRow
end                                -- Called from addDataToTable to build the row of player selections ranks for each item

function addPlayerSelectionRowsV2(theScrollContainer, itemID,theSelections)   -- Called from addDataToTable 
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
        local backdropInfo = {      -- https://wowpedia.fandom.com/wiki/BackdropTemplate
	                bgFile = itemIcon,
                    }
        local reuseIcon = reuseFrame() -- 0 means create and a number means use that number frame

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
        
        -- util.AddDebugData(theSelections,"player selction aboutto be added")

        -- Add the players
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
                box:SetBackdropColor(1, 0, 0, 0.75) -- Light red
            else
                if rank <0 then
                    box:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
                    box:SetBackdropColor(1, 1, 0, 0.5) -- 
                  else
                    box:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
                    box:SetBackdropColor(0, 1, 0, 0.75) -- Light green
                end
            end

            -- Create a label for the theSelections
            if rank ~= 0 then
                -- util.AddDebugData(rank,"is there a selection")
                local boxText = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                boxText:SetPoint("CENTER", box, "CENTER")
                boxText:SetFont("Fonts\\FRIZQT__.TTF", 16)
                if rank<0 then boxText:SetTextColor(0,0,0) end
                boxText:SetText(math.abs(rank)) -- convert to positive if negative
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
end                        -- Called from addDataToTable to add the items and player selections to the table

function enterMyPriorities(theScrollContainer, myPriority, itemID,itemName)   -- Called from addDataToTable 
        local itemType, itemSubType, itemEquipLoc = ""
	    local icon, classID, subClassID = 0
        local thePlayer = util.unitname("player")

        local row = AceGUI:Create("SimpleGroup")
        row:SetFullWidth(true)
        row:SetLayout("Flow")
  
        -- Create and display the item icon
        local itemIcon = GetItemIcon(itemID)
        local backdropInfo = {      -- https://wowpedia.fandom.com/wiki/BackdropTemplate
	                bgFile = itemIcon,
                    }
        local reuseIcon = reuseFrame() -- 0 means create and a number means use that number frame

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
        
        -- Add the item details and field to enter my Priority  << STILL WRITING THIS
        -- USEFULL INFO
        
        -- GetItemInfo
		-- Returns:  "itemName", "itemLink", itemRarity, itemLevel, itemMinLevel, "itemType", "itemSubType", itemStackCount, "itemEquipLoc", "invTexture", "itemSellPrice"
        
	    -- GetItemInfoInstant - https://warcraft.wiki.gg/wiki/API_C_Item.GetItemInfoInstant
        -- Returns: itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subClassID

	    -- C_ItemUpgrade.GetItemUpgradeItemInfo (https://warcraft.wiki.gg/wiki/API_C_ItemUpgrade.GetItemUpgradeItemInfo)
        -- 

        _ , itemType, itemSubType, itemEquipLoc, _, classID, subClassID = GetItemInfoInstant(itemID)
        -- util.AddDebugData(itemType,"enterMyPriorities: GetITemInfo "..itemName)

        -- Pad the row to the correct height becuase I can never get that to work correctly
        local padding = AceGUI:Create("Label")
        padding:SetWidth(50)    
	    padding:SetHeight(32)
        -- padding:SetPoint("LEFT")
        row:AddChild(padding)

        local theEquipLoc = AceGUI:Create("Label")
        theEquipLoc:SetWidth(100)
        theEquipLoc:SetText(getItemSubType(itemEquipLoc,"Name"))
        row:AddChild(theEquipLoc)

        local theItemName = AceGUI:Create("Label")
        theItemName:SetWidth(150)
        theItemName:SetText(itemName)
        row:AddChild(theItemName)

        local theSubType = AceGUI:Create("Label")
        theSubType:SetWidth(150)
        theSubType:SetText(itemSubType)
        row:AddChild(theSubType)

        local myPriority = AceGUI:Create("EditBox")
        myPriority:SetWidth(75)
        local theNewPriority = getPlayerInformation(thePlayer,itemID,"P")
        if tonumber(theNewPriority) > 0 then
            myPriority:SetText(tonumber(theNewPriority))
            if util.hasValue(getPlayerInformation(thePlayer,0,"PH"),theNewPriority) then
                -- util.AddDebugData(myPriority,"Priority editbox")
                myPriority:SetDisabled(true) 
			end
		end
        myPriority:SetCallback("OnEnterPressed", function()
            local theEntry = tonumber(myPriority:GetText())
            if theEntry == nil then theEntry=0 end 
            if theEntry < 0 then theEntry=0 end
            if theEntry then
                theEntry = math.floor(theEntry)
                myPriority:SetText(theEntry)

                local updateMade,updateFrame =  updatePlayerItemPriority(thePlayer,itemID,tonumber(myPriority:GetText())) 

			    if updateMade then
                    -- I know I am always player 1 
                    addon.PLdb.char.playerSelections[1].version = addon.PLdb.char.playerSelections[1].version +1
                    statusText(format("%s: Priority for %s has been set",util.Colorize("UPDATED:", "accent",false),itemName))
                else
                    statusText(format("%s: Priority for %s has NOT been set.  Check chat for warning or errors.",util.Colorize("UPDATED:", "accent",false),itemName))
				end
                if updateFrame then -- refresh the view
                    fillTableColumn()
				end
                -- util.AddDebugData(theEntry,"Priority entered for "..itemName)
   
			else
                local itemName = GetItemInfo(itemID)
                util.Print("WARNING: Priority not a number for "..itemName)
                statusText(format("%s: Priority for %s is not a number",util.Colorize("ERROR:", "accent",false),itemName))
                myPriority:SetText(0)
  			end
        end)

        row:AddChild(myPriority)


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
end                         -- Called from addDataToTable to add the items and item details to enter my Priorities

function getListOfHeadingsToDisplay()
    local returnHeadings = {"Hold"}
    local testData = addon.PLdb.profile.useTestData 

    if tableColumnContent == "S" then
        --if testData then                                    -- Display player names
	       --     -- returnHeadings = thisAddon.GuildTestData
        --        updateRosterToTestData()
        --else
		    if thisAddon.filters.displayGuildNames then
		        -- util.AddDebugData("Loading Guild names","getListOfHeadingsToDisplay")
                updateRosterToGuild()
		    else
		        -- util.AddDebugData("Loading Raid names","getListOfHeadingsToDisplay")
                updateRosterToRaid()
		    end
           
	    -- end
        return true -- true means use roster
	elseif tableColumnContent == "E" then                   -- Enter Priorities
        --  space then text then space then text....
	    returnHeadings = {
		        {50,"Type"},
		        {60,"Name"},
			    {110,"Class"},
			    {115,"Priority"},
		}
    elseif tableColumnContent == "L" then                   -- Loot History
        --  space then text then space then text....
	    returnHeadings = {
		        {1,"Date"},
		        {1,"Raid Type"},
		        {50,"Boss"},
			    {115,"Loot"},
			    {115,"Winner"},
		}
	end
    return returnHeadings
end                      -- Getthe correct heading list to put ion the table frame

function itemFilteredIn(itemID)
    -- itemEquipLocation is what slot
    -- iitemClassID is temArmourSubClass e.g.  Cloth 1, Leather	2, Mail 3,Plate	4, Others   5-11
    -- itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID
    --
    -- Get the item details for the type of item it is sword, mail, etc
    -- get the current setting (filterWord)
    -- check the type (cloth etc) and the class (sword etc) and see if they match the filter
    --

    local _, _, _, itemEquipLoc, _, itemClassId, subclassID = GetItemInfoInstant(itemID)
    local itemArmourTypeToFind = "#"
    local itemLocationToFind = "#"

    -- util.AddDebugData(itemID.."  "..itemEquipLoc.."  "..itemClassId.." "..subclassID,"Item details")
    -- what slot does it go into - get the letter that we search for
    itemLocationToFind = getItemSubType(itemEquipLoc,"Code")

    -- If its Armour then is it cloth, leather etc - get the correct letter to search for
  	if itemClassId==4 and subclassID>0 and subclassID<5 then
        itemArmourTypeToFind = addon.PLdb.global.filterArmourType[subclassID]
	end
    
    local filterWord = convertFiltertoWord(thisAddon.filters.currentFilter)
    -- util.AddDebugData(itemID,"Filter word "..filterWord)
    local startIndexL, endIndexL = string.find(filterWord, itemLocationToFind)
	local startIndexA, endIndexA = string.find(filterWord, itemArmourTypeToFind)

    if startIndexL == nil then startIndexL = 0 end
    if startIndexA == nil then startIndexA = 0 end

    -- util.AddDebugData(itemLocationToFind.."("..startIndexL..") - "..itemArmourTypeToFind.."("..startIndexA..")","searching for")
    
    if startIndexL==0 and startIndexA==0 then
        -- This item does not meet the class or subclass constraints so reject it
	    return false
	else
        -- Now we have a matching item start to apply other filter elements
        if thisAddon.filters.onlyMyPriority then
            -- util.AddDebugData(itemID,"only my priority")
            if getPlayerInformation(util.unitname("player"),itemID,"P") >0 then
                return true
            else
                return false
            end
        end
        if thisAddon.filters.onlyNoPriority then
            if getPlayerInformation("Any",itemID,"AP") > 0 then -- does anyone have this item selected
                return false
			else
			    return true
			end
        end
	    return true
	end
end                                  -- Filter the list of items based on the filters set in the frame

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

------------- VISUAL SUPPORT FUNCTIONS ----------------------------------

function addon:ToggleOptions()
	
    if ACD.OpenFrames[MyAddOnName] then
        ACD:Close(MyAddOnName)
        -- ACD:Close(MyAddOnName.."Dialog")
    else
		-- util.AddDebugData(MyAddOnName, "Calling OpenOptions()")
        self:OpenOptions()
    end
end                             -- show and hide OPtions window

function addon:ToggleMinimapIcon()
    -- util.AddDebugData(self.PLdb.profile.minimap.hide, "Minimap button status")

    self.PLdb.profile.minimap.hide = not self.PLdb.profile.minimap.hide
    UpdateMinimapIcon()
end                         -- show and hide minimap icon

function addon:ToggleLootWindow()
    if thisAddon.MainLootFrame:IsShown() then
        thisAddon.MainLootFrame:Hide()
    else
        thisAddon.MainLootFrame:Show()
    end
end                          -- Show and hide loot window

function UpdateMinimapIcon()                  
    if addon.PLdb.profile.minimap.hide then
        LDBIcon:Hide(MyAddOnName)
    else
        LDBIcon:Show(MyAddOnName)
    end
end                               -- Show or hide the minimap icon

function addon:processSlashCommnands(msg)

        if msg == "help" or msg == "?" then
                util.Print("Commands:")
                print(format("%s or %s: Toggles the options panel.", util.Colorize("/PriorityLoot", "accent"), util.Colorize("/PL", "accent")))
                print(format("%s %s: Resets current profile to default settings.", util.Colorize("/PL", "accent"), util.Colorize("reset", "value")))
                print(format("%s %s: Toggles the minimap icon.", util.Colorize("/PL", "accent"), util.Colorize("minimap", "value")))
                print(format("%s %s: Toggles the Priority Loot window", util.Colorize("/PL", "accent"), util.Colorize("window", "value")))
                print()
        elseif msg == "reset" or msg == "default" then
                self.PLdb:ResetProfile()
        elseif msg == "minimap" then
                self:ToggleMinimapIcon()
        elseif msg == "window" then
                self:ToggleLootWindow()
        else
                self:ToggleOptions()
        end
       
end

