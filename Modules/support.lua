local MyAddOnName, thisAddon = ...
local addon = _G[MyAddOnName]
local util = thisAddon.Utils

--[[
 
    Functions for getting or finding  data

]]--

---general functions ---

function addon:joinedRaid()

    if IsInRaid() then

        -- numMembers = GetNumGroupMembers([groupType])
        loadRaidMembers()

        if iAmTheLootManager and not thisAddon.priorityLootRollsActive then
		    addon:yesnoBox("Do you wish to swap the Priority Loot allocations state for this raid ?","activateLootRolls")
		end

	    if not thisAddon.priorityLootRollsActive and isPlayerInRaid(addon.PLdb.char.guildLootManager) then
            addon:buildPL_ROLL_CHECK(addon.PLdb.char.guildLootManager)  -- send a message to find out if loot rolls should be active 		
		end

	end

    -- make sure every has my latest priorities
   
end

function addon:leftRaid()
    thisAddon.priorityLootRollsActive = false
end

--- update data 

function updatePlayerItemPriority(thePlayer,theItem,thePriority)
-- If its a new priority then add it
-- encrypt the priorities history data when its stored

    local recToUpdate = 0
    local itemToUpdate = getPlayerInformation(thePlayer,theItem,"PP") 
    local numberOfPriorities = addon.PLdb.char.numberOfPriorities  --  The number of priorities I am allowed to have active
    local recUpdated,duplicatePriority,refreshFrame = false

    if thePlayer == 1 then
        recToUpdate = 1
    else
         recToUpdate = getPlayerInformation(thePlayer,"","PP")  
	end

    local priorityHistory = getPlayerInformation(thePlayer,"","PH")  

    if util.hasValue(priorityHistory,thePriority) then -- If the number is blocked then
        util.Print(   format("%s: Priority %i is blocked and will not be used or updated",util.Colorize("WARNING:", "accent",false),thePriority))
	    statusText(format("%s: Priority %i is blocked and will not be used or updated",util.Colorize("WARNING:", "accent",false),thePriority))
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

function updateGuildRecord(unitNameIn,hasAddonIn,configVersionIn)
-- update the record for guild emebers wit hthe latest config nad app versions
-- this is reported in the color of the names in the main frame


    for idx,guildMember in ipairs(thisAddon.guildUnit) do
        if guildMember.unitName == unitNameIn then   	
            thisAddon.guildUnit[idx].hasAddon = hasAddonIn
			thisAddon.guildUnit[idx].configVersion = configVersionIn
			-- thisAddon.guildUnit[idx].lastCheck = lastCheckIn
            util.AddDebugData(unitNameIn,"member guild data updated")
            return
		end
	end
end

function addon:configUpdate()
    addon.PLdb.char.configVersion = C_DateAndTime.GetServerTimeLocal()
end

function clearPriorities()
    local priorityHistory = thisAddon.playerSelections[1].priorityHistory  
    local i = 1
    util.AddDebugData(priorityHistory,"priorityHistory")

    while i < #thisAddon.playerSelections[1].playerLoot do
        --util.AddDebugData(i,"counter")
        --util.AddDebugData(thisAddon.playerSelections[1].playerLoot[i],"thisAddon.playerSelections[1].playerLoot[i]")
	    if not util.hasValue(priorityHistory,thisAddon.playerSelections[1].playerLoot[i][2]) then -- If the number is not blocked then
            table.remove(thisAddon.playerSelections[1].playerLoot, i)
        else
            i = i + 1
	    end
	end
end

---  finding data

function IsPlayerInGuild()
    return IsInGuild() and GetGuildInfo("player")
end

function isPlayerInRaid(thePlayer)

    for i=1,MAX_RAID_MEMBERS do      
        if thisAddon.raidUnit[i].unitName == thePlayer then
            return true
        end
    end
    return false
end

function isPlayerOnline(thePlayer)
    
end -- TO BE COMPLTED

function addon:getGuildDetails()
    
    if IsPlayerInGuild() then

        finishedInitalising = true 

        addon.PLdb.char.myGuildName, _ , _ , addon.PLdb.char.myGuildRealm = GetGuildInfo("player")
    
        if addon.PLdb.char.myGuildRealm == nil then
            addon.PLdb.char.myGuildRealm = GetRealmName()
        end

        util.AddDebugData(addon.PLdb.char.myGuildName,"Guild found ")

        loadGuildMembers()
        fillTableColumn()

    else
        util.AddDebugData(true,"No guild found ")
        addon.PLdb.char.myGuildName = "ERROR:  NO guild found "
    end
end

function getElementsFromRaids(whatToReturn,searchValue1,searchValue2) -- pass in"raid","boss" and a search value
-- "raid"            searchValue1={},searchValue2={}                     -- NOT USED
-- "bossList"        searchValue1={},searchValue2={}                     -- Get the list of bosses
-- "bossId"          searchValue1={position},searchValue2={}             -- Get the bossID if you know what boss it is e.g. the second boss
-- "bossname"        searchValue1={provide the bossId},searchValue2={}   -- Get the name based on the id

    local returnArray = {}
    lootTable = addon.PLdb.global.bossLoot

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

function checkIExist()                              
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
    table.insert(addon.PLdb.char.playerSelections, 1, myNewData)

    util.Print(format("Character %s added to playSelections data", util.Colorize(myName, "accent",false)))

    -- Set the default to my armour type
    local myClassName,myClass=UnitClassBase("player")

    for _,armourType in pairs(addon.PLdb.char.classArmour) do
        if myClass == armourType.class then
            addon.PLdb.char.myClassName = myClassName
            addon.PLdb.char.myArmourType = armourType.armour
            util.AddDebugData(armourType.armour," Armour type set for "..myClassName)
        end
    end
end                                     -- make sure my record exists and is current in teh playerSelections data

function getPlayerInformation(theName,theItemID,theFlag)     -- return details from the player priority date on the player and selected items
    local recordName,myNameIn = ""
	local playerRollList = {}
    local itemFound = false

    -- theFlag = "PP" then return the Players Position in the data.  theItem not required
	-- theFlag = "A" then return the All the player details and selections.  theItem not required
    -- theFlag = "P" then return the Priority of the selected item   
    -- theFlag = "N" then return the Number of the selected item. 
    -- theFlag = "AP" does AnyPlayer have this item selected
    -- theFlag = "RP" Does the player have top or equal top roll priority pass in util.unitname(unit) the item ID
    -- theFlag = "PH" Return the player priority history. Item not required.
    
	-- util.AddDebugData(theName,"Looking for stuff for  ")
	for recCounter,playerList in ipairs(addon.PLdb.char.playerSelections) do

        --util.AddDebugData(theName," inspecting player agaisnt ")

        recordName = playerList.player
        -- myNameIn = theName

        if theFlag == "PH" then
            return playerList.priorityHistory
        end
		
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
					    return item[2]
					end
                    if theFlag == "P" then 
                        return item[2]
					end
					if theFlag == "N" then
					    return  itemCount
					end
                    if theFlag == "RP" then
                        local newEntry = {recordName,item[2]} -- create a newEntry incase they are going to be included
                        util.AddDebugData(item,"check")

                        itemFound = true

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
            if theFlag == "P" then return 0 end
			if theFlag ~= "AP" and theFlag ~= "RP" then return -1 end    -- Item not found for this player but if we are checking all ignore

        end
    end


    if theFlag == "RP" then
        if itemFound then
            util.AddDebugData(playerRollList,"Added to roll table")
            for _,rollRecord in ipairs(playerRollList) do
		        if rollRecord[1] == theName then
			        return true
			    end
            end
		    return false
		else
		    return true -- if the item is not found then defalt to normal rolls whatever that is
		end
	end

    if theFlag == "PH" then return {} end
	
    return 0 -- player not found and the item not found for any player
end                            -- based on the flag sent find player selection information

function getItemSubType(itemEquipLoc,flag)
    for _, itemLocation in ipairs(addon.PLdb.global.LootItemSubType) do
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
    for idx,guildMember in ipairs(thisAddon.guildUnit) do
        if guildMember.unitName == theName then   	
            returnRecord.hasAddon = guildMember.hasAddon
			returnRecord.configVersion = guildMember.configVersion
			returnRecord.lastCheck = guildMember.lastCheck
            return true,returnRecord,idx
		end
	end
    return false,{},0
end

--- text functions

function addon:trimText(text)
    if addon.PLdb.profile.GUI.trimText then
        if #text > addon.PLdb.profile.GUI.maxTextAmount then
            return text:sub(1, self.PLdb.profile.GUI.maxTextAmount).."..."
        else
            return text
        end
    else
        return text
    end
end

function statusText(theMessage)
    thisAddon.MainLootFrame:SetStatusText(theMessage)
end

function addon:yesnoBox(msg, callback)                          -- Yes No conformation window
    -- https://wowpedia.fandom.com/wiki/Creating_simple_pop-up_dialog_boxes
    
    StaticPopupDialogs[MyAddOnName.."_YESNOBOX"] = {
        text = msg,
        button1 = "Yes",
        button2 = "No",
        OnButton1 = function(self, data, data2)
            addon:activateLootRolls() -- callback()
        end,
        --OnButton2 = function(self, data, data2)
        --    addon:activateLootRolls(false) -- callback()
        --end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = STATICPOPUP_NUMDIALOGS,
    }

    StaticPopup_Show (MyAddOnName.."_YESNOBOX")
end

--- profile database functions

function addon:checkDbVersion()

        -- rewrite this for three databases
--    -- my current database
--    self.config = self.PLdb.profile.config

--	if self.config then
--        util.AddDebugData(self.config.currentDbVersion,"My current version")
--		--Unversioned databases are set to v. 1
--		if self.config.currentDbVersion == nil then self.config.currentDbVersion = 1 end

--		--Handle database version checking and upgrading if necessary
--		local startVersion = self.config.currentDbVersion
--        util.AddDebugData(self.config.currentDbVersion,"self.config.currentDbVersion")
--		self:upgradeDatabase(self.config)
--		if startVersion ~= self.config.currentDbVersion then
--			print(("%s configuration database upgraded from v.%s to v.%s"):format(MyAddOnName,startVersion,self.config.currentDbVersion))
--		end

--	end
end -- TO BE COMPELTED

function addon:upgradeDatabase(config)

    -- if the default database I am loading >= what I have now 
--	if config.currentDbVersion >= addon.PLdb.profile.currentDbVersion then 
--		return config
--	else
--        -- upgrade my existing database
--		local nextVersion = config.currentDbVersion + 1
--        util.AddDebugData(self.config.currentDbVersion,"Upgrade config dbVersion")
--		local migrationCall = self.migrationPaths[nextVersion]

--		if migrationCall then migrationCall(config) end

--		config.currentDbVersion = nextVersion
--		return self:upgradeDatabase(config)
--	end

end    -- TO BE COMPELTED

