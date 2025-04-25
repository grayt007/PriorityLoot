local MyAddOnName, thisAddon = ...

thisAddon.Utils = {}
thisAddon.filters = {}
thisAddon.frameReferences = {}
thisAddon.frameBeingDisplayed = 0
thisAddon.checkboxList = {}
thisAddon.ChannelId = 0
thisAddon.playerSelections = {}
thisAddon.priorityHistory = {}
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
local finishedInitalising = false -- there is a delay in getting guild info in the client.   The client  needs 10-15 seconds to finish fully initalising. 

version = 0.72  -- date("%m%d%H%M")
local headingsExist = false
local iAmTheLootManager = false
local iAmTheGM = false
local tableColumnContent = "S"
local currentBoss = "225822"   -- return the bossId of the first boss
local raidUnit = {}            -- the unitID in a raid is "raidN" the raid member with raidIndex N (1,2,3,...,40).
local guildUnit = {}

	
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
            if finishedInitalising then
                addon:ToggleLootWindow()
            else
                util.Print(format("%s: Please allow 15 seconds for the client to finish initialising", util.Colorize("WARNING:", "accent")))
			end

        elseif button == "RightButton" then

            if IsRightControlKeyDown() then 
                -- buildCheckRankMessage()
                util.Print(getPlayerInformation(util.unitname("player"),"228861","RP"))
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

--local UnitName,UnitIsUnit,UnitClass,UnitGUID,UnitIsFriend,UnitIsPlayer =
--        UnitName,UnitIsUnit,UnitClass,UnitGUID,UnitIsFriend,UnitIsPlayer
--local IsInGroup,GetNumGroupMembers,GetNumSubgroupMembers,GetRaidRosterInfo,GetPartyAssignment,GetRaidTargetIndex =
--IsInGroup,GetNumGroupMembers,GetNumSubgroupMembers,GetRaidRosterInfo,GetPartyAssignment,GetRaidTargetIndex

local function CreateBorder(self, barExists)
    if not lootRoll.GUI.border then return end
    if not self.borders then
        self.borders = {}
        for i=1, 4 do
            self.borders[i] = self:CreateLine(nil, "OVERLAY", nil, 0)
            local l = self.borders[i]
            l:SetThickness(1)
            l:SetColorTexture(0.1, 0.1, 0.1, 0.8)
            if i==1 then
                l:SetStartPoint("TOPLEFT")
                l:SetEndPoint("TOPRIGHT")
            elseif i==2 then
                l:SetStartPoint("TOPRIGHT")
                l:SetEndPoint("BOTTOMRIGHT")
            elseif i==3 then
                l:SetStartPoint("BOTTOMRIGHT")
                l:SetEndPoint("BOTTOMLEFT")
            else
                l:SetStartPoint("BOTTOMLEFT")
                l:SetEndPoint("TOPLEFT")
            end
        end
    end
end

---------------- SETUP FUNCTIONS------------------------------

function addon:OnInitialize()                                               -- MyAddOnName_LOADED(MyAddOnName)
 -- Code that you want to run when the addon is first loaded goes here.

    -- Can I run this addon
 --   if not util.hasValue(testTeam, util.unitname("player") then
	--    util.Print("Only the test team can use this addon at this point")
	--end



    -- get a copy of the default filter that control what items are displayed 
	local defaultSettings = {
		profile = {
			config = util.deepcopy(self.defaultConfig),
		},
	}

    -- util.Print("The dbName for settings is "..dbName)

    --  New DB  https://www.wowace.com/projects/ace3/pages/ace-db-3-0-tutorial 
   	addon.PLdb = LibStub("AceDB-3.0"):New(dbName, defaultSettings)    
    LDBIcon:Register(MyAddOnName, broker, self.PLdb.profile.minimap)       -- 3rd parameter is where to store the  hide/show + location of button 

    -- Register for actions when the profile is changed
    if not self.registered then                                         
        addon.PLdb.RegisterCallback(self, "OnProfileChanged", "FullRefresh")
        addon.PLdb.RegisterCallback(self, "OnProfileCopied", "FullRefresh")
        addon.PLdb.RegisterCallback(self, "OnProfileReset", "FullRefresh")

        self:ScheduleTimer("getGuildDetails", 15) -- delay getting the guild info because the client will return an error while it full initialises
        self:ScheduleTimer("buildCheckRankMessage", random(10,30)) -- delay sending the message to spread them out if multiple people login near the same time

        self.registered = true
    end

    util.AddDebugData(addon.PLdb.profile.config,"Default config settings")
   
    self:checkDbVersion()

    if addon.PLdb.profile.config.welcomeMessage then
        util.Print(format("Type %s or %s to open the options panel or %s for more commands.", util.Colorize("/PL", "accent"), util.Colorize("/PriorityLoot", "accent"), util.Colorize("/PL help", "accent")))
    end

    -- Define the slash commands.  This should be updated to be a sperate function and fall inline with the ACE approach.
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

    -- load up the player selections from the config.lua file
    thisAddon.playerSelections = addon.PLdb.profile.config.playerSelections
    thisAddon.priorityHistory = addon.PLdb.profile.config.priorityHistory
    
end                                                                     

function addon:OnEnable() 
-- Called when the addon is enabled

    -- some baseline debugging
    util.AddDebugData(guildUnit,"Guild list stored")
    util.AddDebugData(thisAddon.roster,"Current roster")

    -- preload the raid roster with the expected userID
    for i=1,MAX_RAID_MEMBERS do
		raidUnit[i] = ("raid%d"):format(i)
	end
    
    -- This call in turn handles changes to PriorityLoot.config and config GUI construction
	self:OnProfileChanged(nil, self.PLdb, self.PLdb:GetCurrentProfile())        

    -- register  for events
    addon:eventSetup("Register")      

    -- duplicate the object don't reference it so we don't change the default
	thisAddon.filters = util.deepcopy(addon.PLdb.profile.config.filterSettings)

    -- Grab the GUI settings
    lootRoll.GUI = addon.PLdb.profile.config.GUI

    -- Make sure my character exist otherwise who cares about loot :-)
    checkIExist()

    -- Build the main Frame for interacting
	buildMainLootWindow()      

    -- Build the main loot roll frame for he big event

    addon:createRollFrame()
    -- Load options after we have some information about the guild
    addon:Options()
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

    util.AddDebugData(theAction, "event stuff started")

    -- Intentionally using 2 IF statements
    if theAction == "Register" then
	    addon:RegisterEvent('GROUP_ROSTER_UPDATE',"eventHandler")
	    addon:RegisterEvent('GROUP_JOINED',"eventHandler")
        addon:RegisterEvent("PLAYER_ENTERING_WORLD","eventHandler")
		addon:RegisterEvent("CHAT_MSG_ADDON","eventHandler")
        addon:RegisterEvent("CHAT_MSG_SYSTEM","eventHandler")
        addon:RegisterEvent("START_LOOT_ROLL", "RollEvent")
        addon:RegisterEvent("CANCEL_LOOT_ROLL", "RollCancelEvent")
        addon:RegisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER", "UpdateEncounter")

        addon:RegisterMessage("PL_RANK_CHECK","respondToRankCheck")     -- a player has asked to check your selection.  
                                                                        -- If they are current ignore, if not send a targeted message with Data message
        addon:RegisterMessage("PL_CONFIG_UPDATE","processConfigUpdate") -- The Loot Manager has updated the configuration

        if self.PLdb.profile.config.doYouWantToDebug then
            addon:RegisterMessage("PL_TEST_EVENT1","testMessages")        -- PL_RANK_CHECK
            addon:RegisterMessage("PL_TEST_EVENT2","testMessages")        -- START_LOOT
            addon:RegisterMessage("PL_TEST_EVENT3","testMessages")        -- CANCEL_LOOT_ROLL
		end
	end
	
	if theAction == "unRegister" then
	    addon:UnregisterEvent('GROUP_ROSTER_UPDATE')
	    addon:UnregisterEvent('GROUP_JOINED')
		addon:UnRegisterEvent("PLAYER_ENTERING_WORLD")
        addon:UnRegisterEvent("CHAT_MSG_ADDON")
        addon:UnRegisterEvent("CHAT_MSG_SYSTEM")
		addon:UnRegisterEvent("START_LOOT_ROLL")
        addon:UnRegisterEvent("CANCEL_LOOT_ROLL")
        addon:UnRegisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER")
    end
end

function addon:eventHandler(theEvent, ...)
    
        -- util.AddDebugData(theEvent, "eventHandler started")

        local thePrefix,theMessage,theChannel,theSender,theTarget = ...

        if theSender == util.unitname('player') then
            return
        end 
		
    	if theEvent == "GROUP_ROSTER_UPDATE" then  
		    --  we only need to worry about the roster if someone open the addon to look at stuff while we are looking at it
			
        elseif theEvent == "GROUP_JOINED" then
             addon:joinedRaid()
			
        elseif theEvent == "PLAYER_ENTERING_WORLD" then
		    self.instanceType = select(2, IsInInstance())
            local isLogin, isReload = ...
            if isLogin or isReload then
			    C_ChatInfo.RegisterAddonMessagePrefix(MyAddOnName)
		    end
            if isLogin then
                addon:buildLoginMessage()
			end

		elseif theEvent == "CHAT_MSG_SYSTEM" then
            local theMessageIn = ...
            addon:chatMsgFilter(theMessageIn)

		elseif theEvent == "CHAT_MSG_ADDON" then

            if thePrefix == MyAddOnName then 
                -- decompress, decrypt and de anything else to the inbound message
				local newMessage = addon:processMessage(theMessage)                     
                addon:messageInUpdateRank(newMessage)
			end
		end
end                           -- Actions assigned to events

function addon:testMessages(theEvent,theMessageIn,...)
    util.AddDebugData(theEvent, "Test message Received: Event")
    util.AddDebugData(theMessageIn, "Test message Received: Message")

    util.AddDebugData(self.PLdb.profile.config.GUI.border,"GUI config data")
     
   if theEvent == "PL_TEST_EVENT1" then -- "PL_RANK_CHECK" 
		addon:respondToRankCheck(theEvent,theMessageIn,...)
    end

    if theEvent == "PL_TEST_EVENT2" then -- "START_LOOT"
		addon:RollEvent()
	end

    if theEvent == "PL_TEST_EVENT3" then -- "CANCEL_LOOT_ROLL"  
		addon:RollEvent()
	end

end

----------- ROSTER AND PROFILE RELATED FUNCTIONS -----------------------
function addon:OnNewProfile(eventName, db, profile)

	--Set the dbVersion to the most recent, as defaults for the new profile should be up-to-date
	-- self.PLdb.profile.config.dbVersion = self.currentDbVersion

end 

function addon:OnProfileChanged(eventName, db, newProfile)

	self:checkDbVersion()

end   

function loadGuildRoster()
-- Build the list of guild members
-- based on their rank.  Store then in the DB by adding or deleting as required along with the addon version details if any
--

-- rankName = GuildControlGetRankName(index)

    local numTotalGuildMembers, numOnlineGuildMembers, _ = GetNumGuildMembers()
    local memberCounter = #addon.PLdb.profile.config.guildMembers
    local memberRecord = {}
    local memberFound = False
    local memberNames = {} --  check the current guild members and delete others

    thisAddon.roster = {} 

    -- guild unit is the list of all current guild members + extra data about the addon based on rank
    guildUnit = addon.PLdb.profile.config.guildMembers

    for gmc=1,numTotalGuildMembers do
        local memberName, _, memberRankIndex, _, _, _, _, _, memberIsOnline, _, _, _, _, _, _, _, memberGUID = GetGuildRosterInfo(gmc)
        local itsMe = false
		
        -- Is the member I am looking at me ?
		if (util.unitname(UnitName("player")) == memberName) then
            itsMe = true
            util.AddDebugData(itsMe,memberName..": is me")
        end       -- UnitIsUnit()

        -- if they have the rank of an officer and are not in the officers list then insert them
        if util.hasValue(addon.PLdb.profile.config.guildOfficerRanks,memberRankIndex) and
            not util.hasValue(addon.PLdb.profile.config.officerList,memberName) then
            table.insert(addon.PLdb.profile.config.officerList,memberName)
			end

        -- if they do not the rank of an officer and are  in the officers list then remove them
        if not util.hasValue(addon.PLdb.profile.config.guildOfficerRanks,memberRankIndex) and
            util.hasValue(addon.PLdb.profile.config.officerList,memberName) then
            position = keyFromValue(addon.PLdb.profile.config.officerList,memberName)
            table.remove(addon.PLdb.profile.config.officerList,position)
		end

        -- get whatever current record we have for this person if any in the guildUnit table
        memberFound, memberRecord = getGuildMember(memberName)

        -- util.AddDebugData(memberFound,memberName.." found in the existing table")

        -- If I am the GM then lets flag that
        if memberRankIndex == 0 then 
            iAmTheGM = true
		else
            iAmTheGM = false 
		end

        -- If I am the loot manager then lets flag that
        if addon.PLdb.profile.config.nameLootManager == util.unitname(UnitName("player")) and
            (util.hasValue(addon.PLdb.profile.config.guildOfficerRanks,memberRankIndex) or iAmTheGM ) then -- include GM incase some numpty removes GM from officerranks
            iAmTheLootManager = true
		else
            iAmTheLootManager = false 
		end

        -- If its a valid raiding rank or its me then add me to the list
        if util.hasValue(addon.PLdb.profile.config.guildRaidRanks,memberRankIndex) or itsMe then
		       
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
                       memberRecord.lastCheck = addon.PLdb.profile.config.lastConfigCheck                         
	                   memberRecord.configVersion = addon.PLdb.profile.config.configVersion
                       table.insert(addon.PLdb.profile.config.guildMembers,1,memberRecord) -- insert into position 1
			       else
                       memberRecord.hasAddon = 0        
                       memberRecord.configVersion = 0   
                       memberRecord.lastCheck = 0
                       table.insert(addon.PLdb.profile.config.guildMembers,2,memberRecord)
			       end 

               else
                   util.AddDebugData(memberFound,"Found in existing DB "..memberName)
                   -- We don't need to add them to the config file
			   end
		 else
                -- util.AddDebugData(memberRankIndex,"Not a raiding rank")
		 end
    end

    util.AddDebugData(memberNames,"Members that we found to validate")

    local i = 1
    while i < #guildUnit do
	    if not util.hasValue(memberNames,guildUnit[i].unitName) then
            util.AddDebugData(guildUnit[i].unitName,"Record removed from guild data")
            table.remove(guildUnit,i) -- remove from the record of raiders in the database to capture and changes
        else
            util.AddDebugData(guildUnit[i].unitName,"Record NOT removed from guild data")
            i = i + 1
		end
	end
	    
    -- util.AddDebugData(guildUnit,"Should be the correct guild list after changes")
end

function updateRosterToGuild()

	wipe(thisAddon.roster) 
    local rosterCount = 1   
	
    for idx,guildMember in ipairs(guildUnit) do
	
        --if util.hasValue(addon.PLdb.profile.config.guildRaidRanks,guildMember.unitRank) then

            -- The first unit is me becuase wee forced that when loading guildUnit
	        local notMe = not UnitIsUnit('player',guildMember.unitName) 

            util.AddDebugData(util.getShortName(guildMember.unitName),"Guild member added to headings")

            thisAddon.roster[rosterCount] = {}
            thisAddon.roster[rosterCount].unitID = rosterCount                                  -- does not really matter for the guild roster     
            thisAddon.roster[rosterCount].unitName = util.getShortName(guildMember.unitName)    -- set to my name

            if notMe then 
                thisAddon.roster[rosterCount].hasAddon = guildMember.hasAddon                       -- has or does not have the PL addon
                thisAddon.roster[rosterCount].configVersion = guildMember.configVersion
                thisAddon.roster[rosterCount].lastCheck = guildMember.lastCheck                     -- we want to check some basics once and only once
                -- util.AddDebugData(util.getShortName(guildMember.unitName),"Guild member added to headings")
            else
	            thisAddon.roster[1].hasAddon = version                            
                thisAddon.roster[1].lastCheck = addon.PLdb.profile.config.lastConfigCheck                         
	            thisAddon.roster[1].configVersion = addon.PLdb.profile.config.configVersion
		    end	
            rosterCount = rosterCount + 1
		--end			
	end
end

function addon:updateRosterToRaid()
 -- make sure I am number 1 in the roster

	wipe(thisAddon.roster) 

	local playerName = util.unitname('player')
    local rosterCount, rosterCountHold = 2              -- I am position 1 so always start at 2

    if IsInRaid() then

        for i=1,MAX_RAID_MEMBERS do      
			--name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(raidIndex)

            local unitID = raidUnit[i]
            local unitName = GetRaidRosterInfo(i) or "none"
            local itsMe = UnitIsUnit('player',unitID)

            -- util.AddDebugData(unitName,"Unitname in raid roster")

            if unitName ~= "none" then
                local guildName, _, _, guildrealm = GetGuildInfo(unitID)
            
                if guildRealm == nil then                   -- if its my server then the realm will be "nil" so set it to the correct name
			        guildRealm = GetRealmName()
                end

                -- its the same guild name on the same realm
                if guildName == addon.PLdb.profile.config.myGuildName and guildRealm == addon.PLdb.profile.config.myGuildRealm then

                    util.AddDebugData(unitName,"Found a guild member in the raid")

                    -- if its me force it into roster position 1
                    if unitName and itsMe then 
                        rosterCountHold = rosterCount
                        rosterCount = 1
			        end

                    if unitName and not util.hasValue(thisAddon.roster,unitID) then                -- if the unit does not already exist and its not me
                        util.AddDebugData(rosterCount,"Raid member added to position")
				        thisAddon.roster[rosterCount] = {}
                        thisAddon.roster[rosterCount].unitID = unitID     
                        thisAddon.roster[rosterCount].unitName = unitName 

                        local memberRecord = getGuildMember(unitName)

                        if memberRecord then
                            thisAddon.roster[rosterCount].hasAddon = memberRecord[1]            
                            thisAddon.roster[rosterCount].lastCheck = memberRecord[2]              
                            thisAddon.roster[rosterCount].configVersion = memberRecord[3]   
                        end
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
    
end                           

function updateRosterToTestData()

end

function addon:FullRefresh()
    UpdateMinimapIcon()
end                            -- TO BE COMPLETED - Do we still need this as a function

------------- FUNCTIONS TO SUPPORT MINIMAP BUTTON ACTIONS --------------------

function addon:OpenOptions()
    ACD:Open(MyAddOnName)
    local dialog = ACD.OpenFrames[MyAddOnName]
    util.AddDebugData(dialog,"Options Dialog")

    if dialog then
        dialog:EnableResize(false)
    end
end                            -- Open the options panel - Do we still need this as a function

------------- FRAME SETUP FUCTIONS ---------------------------------------

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
    thisAddon.MainLootFrame:SetWidth(addon.PLdb.profile.config.setFrameWidth)
    thisAddon.MainLootFrame:SetHeight(600)
    thisAddon.MainLootFrame:SetLayout("Flow")
        util.AddDebugData(thisAddon.MainLootFrame,"Main Frame")

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
    thisAddon.filterColumn:SetWidth(addon.PLdb.profile.config.setFilterWidth)
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
        util.AddDebugData(whatBoss,"What Boss choosen from dropdown")
        util.AddDebugData(currentBoss,"Current Boss found")
		-- print("Selected option:", dropdownBoss:GetValue())  end)
        -- util.AddDebugData(dropdownBoss:GetValue(),currentRaid.currentBoss.bossName,"Boss selected")
		end)
    thisAddon.filterColumn:AddChild(dropdownBoss)     
    -- util.AddDebugData(currentRaid.currentBoss.bossName,"Boss dropdown added")
 
end

function buildFilterColumnBottom()
   
    util.AddDebugData(thisAddon.filters,"Filters check active")
    util.AddDebugData(addon.PLdb.profile.config.filterSettings.currentFilter,"Filters check defaults")

    thisAddon.checkboxList = {}
    for key,filterList in ipairs (addon.PLdb.profile.config.filterColumnElements) do

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
            -- filterColumn Checkbox
            local theCheckbox = AceGUI:Create("CheckBox")
            thisAddon.checkboxList[filterList.position] = theCheckbox
            theCheckbox:SetLabel(filterList.name)
            theCheckbox:SetType("checkbox")
            theCheckbox:SetWidth(100)
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
            tableColumnContent = "E"        -- (E)nter Priorities
		    fillTableColumn()      
            statusText(format("Enter your priorities for currently filtered items.  %i will remove a priority.",util.Colorize("0", "accent")))
	end)
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
    local theType = addon.PLdb.profile.config.myArmourType

    -- Loop through the 4 armour types resetting them to match the filters and default armour types
    for counter,filterSetting in pairs(addon.PLdb.profile.config.filterArmourType) do
	    if filterSetting == theType then      -- found my default type
		    -- addon.PLdb.profile.config.filterSettings.currentFilter[counter]=filterSetting
            thisAddon.filters.currentFilter[counter]=filterSetting
            thisAddon.checkboxList[counter]:SetValue(true)
        else
		    -- addon.PLdb.profile.config.filterSettings.currentFilter[counter]="-"
            thisAddon.filters.currentFilter[counter]="-"
            thisAddon.checkboxList[counter]:SetValue(false)
	    end
	end

end

function buildTableColumn()
    local headerLabels = {}
    --                              width of the MainFrame           -       width of filter frame              - spacer - AceWow shit
    local tableColumnWidth = addon.PLdb.profile.config.setFrameWidth - addon.PLdb.profile.config.setFilterWidth - 20 - 40

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

function addTableColumnHeadings()
    if tableColumnContent == "S" then
	    playerPriorityHeadings()
	elseif tableColumnContent == "E" then
	    enterPriorityHeadings()
    elseif tableColumnContent == "L" then
	    lootHistoryHeadings()
    end
end                          -- Add headings based on what is being displayed

function playerPriorityHeadings()

        -- tableColumn - Create the header group for the table
    local header1 = AceGUI:Create("SimpleGroup")
    local header2 = AceGUI:Create("SimpleGroup")
    local widthOfIcon = 34                                      -- pixels
    local widthOfCharacter = 5.6                                -- assuming Courier 12 point
    local lastOverhang1 = addon.PLdb.profile.config.GUI.nameLeftMargin  --  True up some initial indent ot make thigns line up
    local lastOverhang2 = -30                                    -- Allow for the column of item icons for the second header row

    -- Create a custom font object
    local courierFont = CreateFont("Courier12")                 -- use a font that has a fixed width
    courierFont:SetFont("Interface\\Addons\\PriorityLoot\\media\\Fonts\\courier.ttf",12,"")           
    
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
        label:SetFontObject(courierFont)                        -- set the font to courier
        local spacer = AceGUI:Create("Label")
        spacer:SetWidth(spacerSize)                             -- Adjust the width as needed

        local addonVersion,configVersion,lastCheck,errorCode = checkPlayerAddon(rosterRec)

        if errorCode then
            label:SetColor(1, 0, 0) -- Red color (RGB: 1, 0, 0)

            label.frame:SetScript("OnEnter", function()
                GameTooltip:SetOwner(label.frame, "ANCHOR_TOPRIGHT")
                GameTooltip:AddLine("Addon Version: "..addonVersion)
                GameTooltip:AddLine("Config Version: "..configVersion)
                GameTooltip:AddLine("Last checked: "..lastCheck) 
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
end

function enterPriorityHeadings()
    -- add the button row
    enterPriorityButtons()

    -- tableColumn - Create the header group for the table
	local header1 = AceGUI:Create("SimpleGroup")
    local widthOfIcon = 34                                      -- pixels
    local widthOfCharacter = 5.6                                -- assuming Courier 12 point

    -- Create a custom font object
    local courierFont = CreateFont("Courier12")                 -- use a font that has a fixed width
    courierFont:SetFont("Interface\\Addons\\PriorityLoot\\media\\Fonts\\courier.ttf",12,"")           
    
    header1:SetFullWidth(true)
    header1:SetLayout("Flow")

    -- tableColumn -  Test Headings
    headerLabels = getListOfHeadingsToDisplay()

    util.AddDebugData(headerLabels,"The enter priority headings")

    for count,headingInfo in pairs(headerLabels) do

        local spacer = AceGUI:Create("Label")
        spacer:SetWidth(headingInfo[1]) 

	    local label = AceGUI:Create("Label")
        label:SetWidth(40)
        label:SetText(headingInfo[2])
        label:SetFontObject(courierFont)     

        header1:AddChild(spacer)
        header1:AddChild(label)
	end
    thisAddon.headingContainer:AddChild(header1)  
    
end

function enterPriorityButtons()
	local buttonRow = AceGUI:Create("SimpleGroup")
    buttonRow:SetFullWidth(true)
    buttonRow:SetLayout("Flow")

    local clearPriority = AceGUI:Create("Button")
    clearPriority:SetText("Clear Priorities")
    clearPriority:SetWidth(200)
    clearPriority:SetCallback("OnClick", function()
            addon.PLdb.profile.config.playerSelections[1].playerLoot = {}
            fillTableColumn() 
            statusText("Priorities cleared and reset ")
	    end)
    buttonRow:AddChild(clearPriority)

    thisAddon.headingContainer:AddChild(buttonRow)  
end

function lootHistoryHeadings()

end

function resetCheckboxGroup(theGroup,theSetting)
    util.AddDebugData(theGroup,theSetting)
    util.AddDebugData(thisAddon.checkboxList,"checkbosList")
    for _,theCheckbox in pairs(thisAddon.checkboxList) do
        if theCheckbox:GetUserData("group") == theGroup then
		    theCheckbox:SetDisabled(not theSetting)
		end
	end
end                              -- If we have a group of checkboxes we want to disable or enable use this

function checkPlayerAddon(rosterRecIn)
    local addonVersion = "Not Loaded"
	local configVersion = "Not Loaded"
    local lastCheck = "Not checked"
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

    if tonumber(rosterRecIn.lastCheck) > 0 then 
		lastCheck = tostring(rosterRecIn.lastCheck) 
	end

	return addonVersion,configVersion,lastCheck,errorCode
end

------------- FRAME DATA FUCTIONS ---------------------------------------

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

    util.AddDebugData(tableColumnContent,"addDataToTable started")
    if tableColumnContent == "L" then
	    loadLootHistory()
	else
         -- tableColumn - Loot through the loot data for this boss and add the rows
   	    tbl = addon.PLdb.profile.config.bossLoot
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
end                                      -- Icons are in frames.  reuse the frames rather than keep creating them to save resources.

function getRanksByPlayer(itemId)         
local returnRow = {}
local playerRecord = {}
local counter = 0

-- local currentPlayersShown = getListOfHeadingsToDisplay()

    -- Loop through the list of players being displayed
    for _,player in pairs(guildUnit) do 
        local playerNumber = 0      -- What record in the table is that player
        util.AddDebugData(player,"Player details for priorities")

	    -- Find the record that belongs to the current player if any in the stored priorities
		playerNumber = getPlayerInformation(player.unitName,0,"PP")
		
		-- Keep tracking the number of the player we are working on
        counter = counter + 1

        -- Set the default to zero meaning no data
		returnRow[counter] = 0
			
        -- If a player was found then get the priority they chose
        if playerNumber > 0 then
            returnRow[counter] = getPlayerInformation(player.unitName,itemId,"P")
            -- util.AddDebugData(returnRow[counter],"Returned from getting player details")
            if returnRow[counter] < 0  then  -- if an error was returned
			    returnRow[counter] = 0
			end
		end
    end

    -- util.AddDebugData(returnRow,"getRanksByPlayer: return")
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
                    addon.PLdb.profile.config.playerSelections[1].version = addon.PLdb.profile.config.playerSelections[1].version +1
				end
                if updateFrame then -- refresh the view
                    fillTableColumn()
				end
                util.AddDebugData(theEntry,"Priority entered for "..itemName)
                statusText(format("%s: Priority for %s has been set",util.Colorize("UPDATED:", "accent",false),itemName))
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
end                               -- Called from addDataToTable to add the items and item details to enter my Priorities

function getListOfHeadingsToDisplay()
    local returnHeadings = {"Hold"}
    local testData = addon.PLdb.profile.config.useTestData 

    if tableColumnContent == "S" then
        if testData then                                    -- Display player names
	            -- returnHeadings = thisAddon.GuildTestData
                updateRosterToTestData()
        else
		    if thisAddon.filters.displayGuildNames then
		        util.AddDebugData("Loading Guild names","getListOfHeadingsToDisplay")
                updateRosterToGuild()
		    else
		        util.AddDebugData("Loading Raid names","getListOfHeadingsToDisplay")
                addon:updateRosterToRaid()
		    end
            -- changes to use the roster for priorities
			--for idx,rosterRec in ipairs(thisAddon.roster) do   
            --        returnHeadings[idx] = rosterRec.unitName
            --end
            
	    end
        return true -- true means use roster
	elseif tableColumnContent == "E" then                   -- Enter Priorities
        --  space then text then space then text....
	    returnHeadings = {
		        {5,"Item"},
		        {5,"Type"},
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
    -- check the type (cloth) nad the class (sword) and see if they match the filter
    --

    local _, _, _, itemEquipLoc, _, itemClassId, subclassID = GetItemInfoInstant(itemID)
    local itemArmourTypeToFind = "#"
    local itemLocationToFind = "#"


    -- util.AddDebugData(itemID.."  "..itemEquipLoc.."  "..itemClassId.." "..subclassID,"Item details")
    -- what slot does it go into - get the letter that we search for
    itemLocationToFind = getItemSubType(itemEquipLoc,"Code")

    -- If its Armour then is it cloth, leather etc - get the correct letter to search for
  	if itemClassId==4 and subclassID>0 and subclassID<5 then
        itemArmourTypeToFind = addon.PLdb.profile.config.filterArmourType[subclassID]
	end
    
    local filterWord = convertFiltertoWord(thisAddon.filters.currentFilter)
    -- util.AddDebugData(itemID,"Filter word "..filterWord)
    local startIndexL, endIndexL = string.find(filterWord, itemLocationToFind)
	local startIndexA, endIndexA = string.find(filterWord, itemArmourTypeToFind)

    if startIndexL == nil then startIndexL = 0 end
    if startIndexA == nil then startIndexA = 0 end

    -- util.AddDebugData(itemLocationToFind.."("..startIndexL..") - "..itemArmourTypeToFind.."("..startIndexA..")","searching for")
    
    if startIndexL==0 and startIndexA==0 then
        -- This item does not meet the class or subclass constraints s oreject it
	    return false
	else
        -- Now we have a matching item start to ap0ply other filter elements
        if thisAddon.filters.onlyMyPriority then
            util.AddDebugData(itemID,"only my priority")
            if getPlayerInformation(util.unitname("player"),itemID,"P") >0 then
                return true
            else
                return false
            end
        end
        if thisAddon.filters.onlyNoPriority then
            if getPlayerInformation("Any",itemID,"AP") then -- does anyone have this item selected
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

function addon:joinedRaid()

    if IsInRaid() then
	
	end

        -- Check am I in a raid
        -- is it a guild raid
        -- turn on the checkbox at the top ofhte filter coluimn
        -- make sure every has my latest priorities
        -- lock my abililty to change my priorities
        -- 
        
end


------------- LOOTING AND ROLLING FUNCTIONS ----------------------------------

local encounter = 0

function addon:UpdateEncounter(event, encounterID)
    if encounter ~= encounterID then
        encounter = encounterID
        util.AddDebugData(encounterID,"Encounter updated ")
    end
end

function addon:GetQualitiy(quality) 
    if quality == 1 then
        return 1, 1, 1
    elseif quality == 2 then
        return 0.1, 1, 0.1
    elseif quality == 3 then
        return 0, 0.44, 0.87
    elseif quality == 4 then
        return 0.64, 0.21, 0.93
    elseif quality == 5 then
        return 1, 0.5, 0
    else
        return 0.6, 0.6, 0.6
    end
end

function addon:RollCancelEvent(event, rollID)
    for _, item in ipairs(lootRoll.items) do
        if item.rollID == rollID then
            addon:RemoveItem(item.frame)
        end
    end
end

function addon:RollEvent(event, rollID)
    GroupLootFrame1:Hide()
    GroupLootFrame2:Hide()
    GroupLootFrame3:Hide()
    GroupLootFrame4:Hide()
    GroupLootContainer:Hide()
    local texture, name, _, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, _, _, _, _, canTransmog = GetLootRollItemInfo(rollID)
    local itemID = select(2, GetLootRollItemInfo(rollID))
    local _, itemLink, _, itemLevel = GetItemInfo(itemID)
    -- itemData = {rollID, iconTexture, itemLevel, bop, itemName, canNeed, canGreed, canDisenchant, canTransmog}
    local itemData = {
        rollID = rollID,
        iconTexture = texture,
        itemLevel = itemLevel,
        quality = quality,
        itemName = name,
        bop = bindOnPickUp,
        canNeed = canNeed,
        canGreed = canGreed,
        canDisenchant = canDisenchant,
        canTransmog = canTransmog,
    }

    util.AddDebugData(itemData,"Item detail for Loot roll")

    if canNeed then
	    addon:AddItem(itemData)
    end

    C_Timer.After(0.5, function ()
        if #lootRoll.items ~= 0 then
            addon:OpenGUI()
        end
    end)
    
end

function addon:createRollFrame()
	local width = self.PLdb.profile.config.GUI.width or 500
    local height = self.PLdb.profile.config.GUI.height or 400

    lootRoll.frame = CreateFrame("Frame", "MyLootRollContainer", UIParent)
    lootRoll.frame:SetSize(width, height)
    lootRoll.frame:SetPoint(self.PLdb.profile.config.GUI.point, UIParent, self.PLdb.profile.config.GUI.point, self.PLdb.profile.config.GUI.xPos, self.PLdb.profile.config.GUI.yPos)
    lootRoll.frame:SetScale(self.PLdb.profile.config.GUI.scale)
    
	lootRoll.bg = lootRoll.frame:CreateTexture(nil, "BACKGROUND")
	lootRoll.bg:SetAllPoints(true)
	lootRoll.bg:SetColorTexture(0.1,0.1,0.1,0.8)
    lootRoll.bg:Hide()

    lootRoll.scrollFrame = CreateFrame("ScrollFrame", nil, lootRoll.frame, "UIPanelScrollFrameTemplate")
    lootRoll.scrollFrame:SetAllPoints(true)
	lootRoll.scrollFrame.ScrollBar:Hide()
    
    lootRoll.contentFrame = CreateFrame("Frame", nil, lootRoll.scrollFrame)
    lootRoll.contentFrame:SetSize(width, height)
    lootRoll.scrollFrame:SetScrollChild(lootRoll.contentFrame)
    
    lootRoll.items = {}
    lootRoll.nextY = 0

	lootRoll.frame:Hide()
end

local protection = false

local function getClassColoredName(playerName, className, roll)
    local classColors = RAID_CLASS_COLORS[className]
    if not classColors then
        classColors = { r = 1, g = 1, b = 1 } 
    end
    local coloredPlayerName = string.format("|cff%02x%02x%02x%s|r", 
                                            classColors.r * 255, 
                                            classColors.g * 255, 
                                            classColors.b * 255, 
                                            playerName)
    local result = string.format("%s |cffffffffRoll %d|r", coloredPlayerName, roll)
    return result
end

local function getInfos(itemData)
    --local states = {"Need", "Need", "Transmog", "Greed", "Pass", "Pass"}
    if encounter ~= 0 then
        local stateList = {0, 0, 0, 0}
        local drops = C_LootHistory.GetSortedDropsForEncounter(encounter)
        for _, drop in ipairs(drops) do
            local item = C_Item.GetItemNameByID(drop.itemHyperlink)
            if item == itemData.itemName then
                GameTooltip:AddLine(" ")
                for _, rollers in ipairs(drop.rollInfos) do
                    local playerName = rollers.playerName
                    local playerClass = rollers.playerClass
                    local roll = rollers.roll or 0
                    if rollers.state == 0 or rollers.state == 1 then
                        stateList[1] = stateList[1] + 1
                    elseif rollers.state == 2 then
                        stateList[2] = stateList[2] + 1
                    elseif rollers.state == 3 then
                        stateList[3] = stateList[3] + 1
                    elseif rollers.state == 4 or rollers.state == 5 then
                        stateList[4] = stateList[4] + 1
                    end
                    if rollers.state == 4 or rollers.state == 5 or roll == 0 then
                        return
                    end
                    local fany = getClassColoredName(playerName, playerClass, roll)
                    GameTooltip:AddLine(fany)


                end
                GameTooltip:AddLine("  ")
                GameTooltip:AddLine("Needed: "..stateList[1].." Transmog: "..stateList[2].." Greeded: "..stateList[3].." Passed: "..stateList[4])
            end
        end
    end
end

function addon:AddItem(itemData)
    local width = lootRoll.GUI.width or 500 
    local itemHeight = lootRoll.GUI.itemHeight or 48 
    local IconSize = math.min(itemHeight, 48)

    -- Create Item Frame
    local itemFrame = CreateFrame("Frame", nil, lootRoll.contentFrame)
    itemFrame:SetSize(width, itemHeight)
    itemFrame:SetPoint("TOPLEFT", lootRoll.contentFrame, "TOPLEFT", 0, -lootRoll.nextY)

    -- Create icon frame
    local iconFrame = CreateFrame("Frame", nil, itemFrame)
    iconFrame:SetSize(IconSize, IconSize)
    iconFrame:SetPoint("LEFT", itemFrame, "LEFT", 10, 0)

    if itemData.rollID then
        iconFrame:EnableMouse(true)

        iconFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetLootRollItem(itemData.rollID) 
            getInfos(itemData)
            GameTooltip:Show()
        end)

        iconFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    

    local iconTexture = iconFrame:CreateTexture(nil, "BACKGROUND")
    iconTexture:SetAllPoints(true)
    iconTexture:SetTexture(itemData.iconTexture)
    if lootRoll.GUI.zoomIcon then
        iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
    

	CreateBorder(iconFrame)
    
    -- Add item level text
    local itemLevelText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemLevelText:SetPoint("BOTTOM", iconFrame, "BOTTOM", 0, 5)
    itemLevelText:SetText(itemData.itemLevel)
    itemLevelText:SetTextColor(1, 1, 1, 1)
    PriorityLoot:ApplyFontString(itemLevelText)

    -- Add progress bar
    local duration = itemData.rollID and (C_Loot.GetLootRollDuration(itemData.rollID) or 0) / 1000 or 60
    local startTime = GetTime()
    local r,g,b = addon:GetQualitiy(itemData.quality)

	local progressBarFrameBG = CreateFrame("StatusBar", nil, itemFrame)
    progressBarFrameBG:SetSize(width - IconSize - 20, 14)
    progressBarFrameBG:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMRIGHT", 5, 0)
    progressBarFrameBG:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    progressBarFrameBG:SetMinMaxValues(0, 1)
    progressBarFrameBG:SetValue(100)
    progressBarFrameBG:SetStatusBarColor(r,g,b, 0.4)

    local progressBarFrame = CreateFrame("StatusBar", nil, itemFrame)
    progressBarFrame:SetSize(width - IconSize - 20, 14)
    progressBarFrame:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMRIGHT", 5, 0)
    progressBarFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    progressBarFrame:SetMinMaxValues(0, 1)
    progressBarFrame:SetValue(100)
    progressBarFrame:SetStatusBarColor(r,g,b, 1)

    progressBarFrame:SetScript("OnUpdate", function(self, elapsed)
        local timeLeft = duration - (GetTime() - startTime)
        self:SetValue(timeLeft / duration)
        if timeLeft <= 0 then
            addon:RemoveItem(itemFrame)
            self:SetScript("OnUpdate", nil)
        end
    end)

	CreateBorder(progressBarFrame)
    
    local sparkTexture = progressBarFrame:CreateTexture(nil, "OVERLAY")
    sparkTexture:SetSize(32, 32)
    sparkTexture:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    sparkTexture:SetBlendMode("ADD")
    
    local function UpdateSpark()
        local value = progressBarFrame:GetValue()
        local minValue, maxValue = progressBarFrame:GetMinMaxValues()
        local barWidth = progressBarFrame:GetWidth()
        local sparkPosition = ((value - minValue) / (maxValue - minValue)) * barWidth
        sparkTexture:SetPoint("CENTER", progressBarFrame, "LEFT", sparkPosition, 0)
    end

    UpdateSpark()

    progressBarFrame:SetScript("OnValueChanged", UpdateSpark)
    
    -- Add item name text
    local itemNameText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    itemNameText:SetPoint("BOTTOMLEFT", progressBarFrame, "TOPLEFT", 0, 10)
    itemNameText:SetText(self:trimText(itemData.itemName))
    itemNameText:SetTextColor(1, 1, 1, 1)
    PriorityLoot:ApplyFontString(itemNameText)

    -- Add buttons
    local buttonSize = 24
    local buttonOffsetX = -2
    local buttons = {
        {name = "Pass", texture = "Interface\\Buttons\\UI-GroupLoot-Pass-Up", rollType = 0},
        {name = "Disenchant", texture = "Interface\\Buttons\\UI-GroupLoot-DE-Up", rollType = 3, check = "canDisenchant"},
        {name = "Transmog", texture = "Interface\\Minimap\\Tracking\\Transmogrifier", rollType = 4, check = "canTransmog"},
        {name = "Greed", texture = "Interface\\Buttons\\UI-GroupLoot-Coin-Up", rollType = 2, check = "canGreed"},
        {name = "Need", texture = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", rollType = 1, check = "canNeed"},
    }

    local conditions = {
        canNeed = itemData.canNeed,
        canGreed = itemData.canGreed,
        canDisenchant = itemData.canDisenchant,
        canTransmog = itemData.canTransmog,
    }

    for i, buttonInfo in ipairs(buttons) do
        local buttonFrame = CreateFrame("Frame", nil, itemFrame)
        buttonFrame:SetSize(buttonSize, buttonSize)
        buttonFrame:SetPoint("BOTTOMRIGHT", progressBarFrame, "TOPRIGHT", buttonOffsetX, 5)
        
        local buttonTexture = buttonFrame:CreateTexture(nil, "ARTWORK")
        buttonTexture:SetAllPoints(true)
        buttonTexture:SetTexture(buttonInfo.texture)

        local canClick = conditions[buttonInfo.check] ~= false
        
        if not canClick then
            buttonTexture:SetDesaturated(true)
            buttonTexture:SetAlpha(0.1)
            buttonFrame:EnableMouse(false)
        else
            buttonFrame:EnableMouse(true)
            buttonFrame:SetScript("OnMouseDown", function()
                if buttonInfo.rollType then
                    if itemData.rollID then
                        if lootRoll.GUI.protection then
                            if protection then
                                print("PriorityLoot >> ".. L["Protection enabled, please wait a couples seconds, you can disable or reduce in options!"])
                                return
                            else
                                protection = true
                                RollOnLoot(itemData.rollID, buttonInfo.rollType)
                                addon:RemoveItem(itemFrame)
                                C_Timer.After(lootRoll.GUI.protectionTimer, function ()
                                    protection = false
                                end)
                            end
                        else
                            RollOnLoot(itemData.rollID, buttonInfo.rollType)
                            addon:RemoveItem(itemFrame)
                        end
                    end
                end
            end)
        end
        
        buttonFrame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(buttonFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(buttonInfo.name, 1, 1, 1)
            GameTooltip:Show()
        end)
        buttonFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        buttonOffsetX = buttonOffsetX - buttonSize - 10
    end

    if itemData.bop then
        local itemBoP = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        itemBoP:SetPoint("BOTTOMRIGHT", progressBarFrame, "TOPRIGHT", buttonOffsetX, 10)
        itemBoP:SetText("BoP")
        itemBoP:SetTextColor(1, 0, 0, 1)
        addon:ApplyFontString(itemBoP)
    end

    lootRoll.nextY = lootRoll.nextY + itemHeight + 4
    lootRoll.contentFrame:SetSize(width, lootRoll.nextY)

    table.insert(lootRoll.items, {frame = itemFrame, rollID = itemData.rollID})
    return itemFrame
end

function addon:RemoveItem(itemFrame)
    if itemFrame then
        itemFrame:Hide()
        itemFrame:SetParent(nil)
        
        for i, item in ipairs(lootRoll.items) do
            if item.frame == itemFrame then
                table.remove(lootRoll.items, i)
                break
            end
        end

        lootRoll.nextY = 0
        for _, item in ipairs(lootRoll.items) do
            item.frame:SetPoint("TOPLEFT", lootRoll.contentFrame, "TOPLEFT", 0, -lootRoll.nextY)
            lootRoll.nextY = lootRoll.nextY + item.frame:GetHeight() + 4
        end

        lootRoll.contentFrame:SetSize(lootRoll.contentFrame:GetWidth(), lootRoll.nextY)

        if #lootRoll.items == 0 then
            encounter = 0
            addon:HideGUI()
        end
    end
end

function addon:OpenGUI()
    if not lootRoll.frame:IsShown() then
        lootRoll.frame:Show()
    end
end

function addon:HideGUI()
    if lootRoll.frame:IsShown() then
        lootRoll.frame:Hide()
    end
end

------------- OTHER SUPPORT FUNCTIONS ----------------------------------

--- update data 

function updatePlayerItemPriority(thePlayer,theItem,thePriority)
-- If its a new priority then add it
-- encrypt the priorities history data when its stored

    local recToUpdate = 0
    local itemToUpdate = getPlayerInformation(thePlayer,theItem,"PP") 
    local numberOfPriorities = addon.PLdb.profile.config.numberOfPriorities  --  The number of priorities I am allowed to have active
    local recUpdated,duplicatePriority,refreshFrame = false

    if thePlayer == 1 then
        recToUpdate = 1
    else
         recToUpdate = getPlayerInformation(thePlayer,"","PP")  
	end

    if thisAddon.priorityHistory[thePriority] then -- If the number is blocked then
        util.Print(   format("%s: Priority %i is blocked and will not be added",util.Colorize("WARNING:", "accent",false),thePriority))
	    statusText(format("%s: Priority %i is blocked and will not be added",util.Colorize("WARNING:", "accent",false),thePriority))
        return false
	end
	
    -- make the priority change for that item
    for counter,itemLoot in ipairs(thisAddon.playerSelections[recToUpdate].playerLoot) do
	
        if itemLoot[2] == thePriority then
		    duplicatePriority = true
            util.AddDebugData(true,"Duplicate found")
		end

        if itemLoot[1] == theItem then
      
            if thePriority == 0  then
                table.remove(thisAddon.playerSelections[recToUpdate].playerLoot, counter)
                refreshFrame = true
                return true,refreshFrame -- delete the record but leave other change to the user
            end

            -- if the item priority did not change then dont update it and dont update the version
            if thisAddon.playerSelections[recToUpdate].playerLoot[counter][2] ~= thePriority then
		        thisAddon.playerSelections[recToUpdate].playerLoot[counter][2] = thePriority
                recUpdated = true -- we changed the item so now lets see what other things are required.
			else
                return false,refreshFrame -- no change required so do nothing more
			end
        end
	end
	
    -- if a duplicate was entered go through the loop and move all the other prioties after what we entered up one 
    if duplicatePriority and recUpdated then
        util.AddDebugData(true,"Duplicate found and a record was updated")
	    -- we need top start the loop again because we dont know what order the items are in
        for counter,itemLoot in ipairs(thisAddon.playerSelections[recToUpdate].playerLoot) do
            if itemLoot[2] >= thePriority and itemLoot[1] ~= theItem then
                util.AddDebugData(true,"moving a priority")
		        thisAddon.playerSelections[recToUpdate].playerLoot[counter][2] = itemLoot[2] + 1
		    end
		end
        refreshFrame = true
	end

	-- if it does not already exist then insert it because we have already made a space
    table.insert(thisAddon.playerSelections[recToUpdate].playerLoot, {theItem,thePriority})
    return true,refreshFrame
end

function addon:processConfigUpdate(theEvent,theMessageIn,...)
    -- Loop through the fields I have been sent and update them if the version sent is new than the version I have
   
    --util.AddDebugData(true, "processConfigUpdate: Started") 

    local theMessage = addon:processMessage(theMessageIn)
    local myConfigVersion = addon.PLdb.profile.config.configVersion

    --util.AddDebugData(addon.PLdb.profile.config.configVersion, "processConfigUpdate: My version") 
    --util.AddDebugData(theMessage[1][2], "processConfigUpdate: Incoming version") 

    -- version must always be the first record
    if myConfigVersion == theMessage[1][2] then
	    return
	end

    for idx,newSetting in pairs(theMessage) do
        addon.PLdb.profile.config[newSetting[1]] = newSetting[2]
        util.AddDebugData(newSetting[2], newSetting[1].." has been updated")
	end

    ACR:NotifyChange(MyAddOnName)

end 

-- getting, finding  data

function IsPlayerInGuild()
    return IsInGuild() and GetGuildInfo("player")
end

function addon:getGuildDetails()
    
    if IsPlayerInGuild() then

        finishedInitalising = true 

        addon.PLdb.profile.config.myGuildName, _ , _ , addon.PLdb.profile.config.myGuildRealm = GetGuildInfo("player")
    
        if addon.PLdb.profile.config.myGuildRealm == nil then
            addon.PLdb.profile.config.myGuildRealm = GetRealmName()
        end

        util.AddDebugData(addon.PLdb.profile.config.myGuildName,"Guild found ")

        loadGuildRoster()
        fillTableColumn()

    else
        util.AddDebugData(true,"No guild found ")
        addon.PLdb.profile.config.myGuildName = "ERROR:  NO guild found "
    end
end

function getElementsFromRaids(whatToReturn,searchValue1,searchValue2) -- pass in"raid","boss" and a search value
-- "raid"            searchValue1={},searchValue2={}                     -- NOT USED
-- "bossList"        searchValue1={},searchValue2={}                     -- Get the list of bosses
-- "bossId"          searchValue1={position},searchValue2={}             -- Get the bossID if you know what boss it is e.g. the second boss
-- "bossname"        searchValue1={provide the bossId},searchValue2={}   -- Get the name based on the id

    local returnArray = {}
    lootTable = addon.PLdb.profile.config.bossLoot

    if whatToReturn == "raid" then                     
        return false

    elseif whatToReturn == "bosslist" then     
        table.insert(returnArray, "All")
        for _, bossList in pairs(lootTable) do
            table.insert(returnArray, bossList.bossName)
            -- util.AddDebugData("Added Boss to dropdown", bossList.bossName)
		end
        return returnArray
	
    elseif whatToReturn == "bossId" then   
        if searchValue1 == 1 then -- If "All" bosses was selected then ignore this
		    return searchValue1
		else
            -- Add one place to the boss ID becuase the first item in the lookup is "All"
            util.AddDebugData(lootTable[searchValue1-1].bossId, "Find BossID from position ")
            return lootTable[searchValue1-1].bossId
        end

    elseif whatToReturn == "bossname" then                
        for _, bossList in pairs(lootTable) do
			if bossList.bossName == searchValue1 then
				return bossList.bossId
			end
		end
		util.AddDebugData("function: getElementsFromRaids", searchValue2.." bossID not found in raid "..searchValue1)

    else 
		util.AddDebugData("function: getElementsFromRaids", whatToReturn.." was not a suitable parameter")
	end

    return returnArray
end                            -- Parse the raids data to return requested tables and data

function checkIExist()                              -- makesure my record exists and is current in teh playerSelections data
    local myName = util.unitname("player")
	local playerExist = false

    -- util.AddDebugData(util.unitname("player"),"Check player 1 ")
    -- util.AddDebugData(myName,"Checking for my character Name")
	playerExist = getPlayerInformation(myName,"","PP")
    util.AddDebugData(playerExist," Player exists setting for ")

    -- util.AddDebugData(playerExist,"Adding character Name")

    if  playerExist > 0 then
	    return
	end

	-- Define the new item to be added
    local myNewData = 
		{
        player = myName,
        version = 1,
        playerLoot = {
            },
        }

    -- util.AddDebugData(myName,"Adding character Name")

    -- Insert the new item at the beginning of the table
    table.insert(addon.PLdb.profile.config.playerSelections, 1, myNewData)

    util.Print(format("Character %s added to playSelections data", util.Colorize(myName, "accent",false)))

    -- Set the default to my armour type
    local myClassName,myClass=UnitClassBase("player")

    for _,armourType in pairs(addon.PLdb.profile.config.classArmour) do
        if myClass == armourType.class then
            addon.PLdb.profile.config.myClassName = myClassName
            addon.PLdb.profile.config.myArmourType = armourType.armour
            util.AddDebugData(armourType.armour," Armour type set for "..myClassName)
        end
    end
end

function getPlayerInformation(theName,theItemID,theFlag)     -- return details from the player priority date on the player and selected items
    local recordName,myNameIn = ""
	local playerRollList = {}

    -- theFlag = "PP" then return the Players Position in the data.  theItem not required
	-- theFlag = "A" then return the All the player details and selections.  theItem not required
    -- theFlag = "P" then return the Priority of the selected item   
    -- theFlag = "N" then return the Number of the selected item. 
    -- theFlag = "AP" does AnyPlayer have this item selected
    -- theFlag = "RP" Does the player have top or equal top roll priority pass in util.unitname(unit) the item ID
    
	-- util.AddDebugData(theName,"Looking for stuff for  ")
	for recCounter,playerList in ipairs(addon.PLdb.profile.config.playerSelections) do

        --util.AddDebugData(theName," inspecting player agaisnt ")

        recordName = playerList.player
        -- myNameIn = theName

        if recordName == theName or theFlag == "AP" or theFlag == "RP" then
            -- if theFlag == "RP" then util.AddDebugData(theName,"RP flag name in") end
            if theFlag == "PP" then
                return recCounter
            end
			if theFlag == "A" then
                return playerList
            end
			
            for itemCount, item in ipairs(playerList.playerLoot) do

                if item[1] == theItemID then
					if theFlag == "AP" and item[2] > 0 then
                        util.AddDebugData(theItemID,"item has selections")
					    return true
					end
                    if theFlag == "P" then 
                        return item[2]
					end
					if theFlag == "N" then
					    return  itemCount
					end
                    if theFlag == "RP" then
                        local newEntry = {recordName,item[2]} -- create a nwEntry incase they are going to be included
                        util.AddDebugData(item,"check")

                        -- if the table is empty or the priority I have is the same as the one that is there already
                        if next(playerRollList) == nil or newEntry[2] == playerRollList[1][2] then -- If its the same priority than the first entry then 
                            table.insert(playerRollList, 1, newEntry)
                            -- util.AddDebugData(newEntry,"Added to roll table")
						end

                        if newEntry[2] < playerRollList[1][2] then -- If its a lower priority than the first entry then
                            playerRollList = newEntry
                            -- util.AddDebugData(newEntry,"All existing records replaced with")
                        end

					end
                end
            end
			if theFlag ~= "AP" and theFlag ~= "RP" then return -1 end    -- Item not found for this player but if we are checking all ignore
        end
    end

    if theFlag == "RP" then
        util.AddDebugData(playerRollList,"Added to roll table")
        for _,rollRecord in ipairs(playerRollList) do
		    if rollRecord[1] == theName then
			    return true
			end
        end
		return false
	end

    util.AddDebugData(theName,"getPlayerInformation: ERROR player not found")
    return 0 -- player not found and the item not found for any player
end                             

function getItemSubType(itemEquipLoc,flag)
    for _, itemLocation in ipairs(addon.PLdb.profile.config.LootItemSubType) do
	    if itemEquipLoc == itemLocation[1] then
            if flag=="Name" then
                return itemLocation[2]  -- return normalised name
		    else
			    return itemLocation[3]  -- return the code for the location when filtering
            end
		end
	end
end

function getGuildMember(theName)
    local returnRecord = {}
    for idx,guildMember in ipairs(guildUnit) do
        if guildMember.unitName == theName then   	
            returnRecord.hasAddon = guildMember.hasAddon
			returnRecord.configVersion = guildMember.configVersion
			returnRecord.lastCheck = guildMember.lastCheck
            return true,returnRecord
		end
	end
    return false,{}
end

function updateGuildRecord(unitNameIn,hasAddonIn,lastCheckIn,configVersionIn)
    for idx,guildMember in ipairs(guildUnit) do
        if guildMember.unitName == unitNameIn then   	
            guildUnit[idx].hasAddon = hasAddonIn
			guildUnit[idx].configVersion = configVersionIn
			guildUnit[idx].lastCheck = lastCheckIn
            util.AddDebugData(unitNameIn,"member guild data updated")
            return
		end
	end
end

--- show and hide frames
function addon:ToggleOptions()
	
    if ACD.OpenFrames[MyAddOnName] then
        ACD:Close(MyAddOnName)
        -- ACD:Close(MyAddOnName.."Dialog")
    else
		util.AddDebugData(MyAddOnName, "Calling OpenOptions()")
        self:OpenOptions()
    end
end                             -- show and hide OPtions window

function addon:ToggleMinimapIcon()
    util.AddDebugData(self.PLdb.profile.config.minimap.hide, "Minimap button status")

    self.PLdb.profile.config.minimap.hide = not self.PLdb.profile.config.minimap.hide
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
    if addon.PLdb.profile.config.minimap.hide then
        LDBIcon:Hide(MyAddOnName)
    else
        LDBIcon:Show(MyAddOnName)
    end
end                         -- Show or hide the minimap icon

--- text functions
function addon:trimText(text)
    if addon.PLdb.profile.config.GUI.trimText then
        if #text > addon.PLdb.profile.config.GUI.maxTextAmount then
            return text:sub(1, self.PLdb.profile.config.GUI.maxTextAmount).."..."
        else
            return text
        end
    else
        return text
    end
end

function addon:ApplyFontString(fontString)
    local fontName = LSM:Fetch("font", addon.PLdb.profile.config.GUI.font)
    local fontSize = addon.PLdb.profile.config.GUI.fontSize or 12
    local fontFlags = addon.PLdb.profile.config.GUI.fontFlags or ""

    fontString:SetFont(fontName, fontSize, fontFlags)
end

function statusText(theMessage)
    thisAddon.MainLootFrame:SetStatusText(theMessage)
end

--- database functions
function addon:checkDbVersion()

    -- my current database
    self.config = self.PLdb.profile.config

	if self.config then
        util.AddDebugData(self.config.currentDbVersion,"My current version")
		--Unversioned databases are set to v. 1
		if self.config.currentDbVersion == nil then self.config.currentDbVersion = 1 end

		--Handle database version checking and upgrading if necessary
		local startVersion = self.config.currentDbVersion
        util.AddDebugData(self.config.currentDbVersion,"self.config.currentDbVersion")
		self:upgradeDatabase(self.config)
		if startVersion ~= self.config.currentDbVersion then
			print(("%s configuration database upgraded from v.%s to v.%s"):format(MyAddOnName,startVersion,self.config.currentDbVersion))
		end

	end
end

function addon:upgradeDatabase(config)

    -- if the default database I am loading >= what I have now 
	if config.currentDbVersion >= addon.PLdb.profile.config.currentDbVersion then 
		return config
	else
        -- upgrade my existing database
		local nextVersion = config.currentDbVersion + 1
        util.AddDebugData(self.config.currentDbVersion,"Upgrade config dbVersion")
		local migrationCall = self.migrationPaths[nextVersion]

		if migrationCall then migrationCall(config) end

		config.currentDbVersion = nextVersion
		return self:upgradeDatabase(config)
	end

end    


