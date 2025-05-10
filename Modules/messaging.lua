local MyAddOnName, thisAddon = ...
local addon = _G[MyAddOnName]
local util = thisAddon.Utils

local LibCompress = LibStub:GetLibrary("LibCompress")
local LibEncoder = LibCompress:GetAddonEncodeTable()



--[[----------- INTER ADDON MESSAGING FUNCTIONS ----------------------------------
 
 https://www.wowace.com/projects/ace3/pages/api/ace-serializer-3-0
 https://www.wowace.com/projects/libcompress#c1

    CHAT_MSG_SYSTEM:  Friends and guild member login and logout messages
	                  chatMsgFilter
					  
    wowACE Comm Messaging:
			                
        PL_RANK_CHECK:   Use the AceMessage to send out a message with the versions of data I have for everyone
                         when each person sees this they check their personal record and see if the version I have matches theirs
                         if it does they ignore it
                         if it does not they send a WHISPER message back to me directly with they new datarespondToRankCheck
						 
        PL_RANK_UPDATE:  Look at the PL_RANK_CHECK message and send my details if their data is old
		                 Sent automatically if required as part of the final steps in PLL_RANK_CHECK
						 
        PL_CONFIG_CHECK: Message to check my config with the Loot Manager.  
                         In messages are for the loot manager only.
		
        PL_CONFIG_UPDATE:Update the config file
		
		PL_ROLL_CHECK:   Is Priority Loot rolls actiove or not.  Check and or activate 
		
		PL_ADDON_ACTIVE: The LootManager turning on or off the Priority Looting

    ]]--


function mySendMessage(theEvent,theMessageIn,theTarget)

    local theMessageInText = ""      -- incase its a table
    theMessageInText = theMessageIn

    --Serialize and compress the data then send it to the target
    local stepOne = addon:Serialize(theMessageInText)
    local finalMessage = LibEncoder:Encode(stepOne)

    if theTarget == "ALL" then
        addon:SendCommMessage(theEvent, finalMessage, "GUILD")
    else
        addon:SendCommMessage(theEvent, finalMessage, "WHISPER", theTarget)
    end
	
    util.AddDebugData(theEvent, "PL sendMessage:")
end

function addon:processMessage(theMessageIn)

    util.AddDebugData(theMessageIn, "addon:processMessage:  Start")
    local stepOne = LibEncoder:Decode(theMessageIn)              -- Decode the compressed data
    local success, finalMessage = addon:Deserialize(stepOne)

    if (not success) then
        util.AddDebugData(finalMessage,"processMessage: ERROR deserializing message")
	    return
    else
        util.AddDebugData(finalMessage, "addon:processMessage:  Deserialized")
    end

    return finalMessage 
end                             -- Process and decompress the message


function addon:inCHAT_MSG_SYSTEM(theMessageIn)
-- local ONLINE = ERR_FRIEND_ONLINE_SS:gsub("|Hplayer:%%s|h%[%%s%]|h", "|Hplayer:.+|h%%[.+%%]|h")

local ONLINE = ERR_FRIEND_ONLINE_SS:gsub("%%s", "(.-)"):gsub("[%[%]]", "%%%1")
local OFFLINE = ERR_FRIEND_OFFLINE_S:gsub("%%s", "(.-)")

	local _, nameOnline = strmatch(theMessageIn, ONLINE)
    local _, nameOffline = strmatch(theMessageIn, OFFLINE)

	if nameOnline or nameOffline then
        for counter,guildMember in ipairs(thisAddon.guildUnit) do
            if nameOnline == guildMember.unitName then
                -- addon.PLdb.char.guildMember[counter].online = true
                util.AddDebugData(nameOnline,"Guildmember came online")
                return
            end
            if nameOffline == guildMember.unitName then
                -- addon.PLdb.char.guildMember[counter].online = false
                util.AddDebugData(nameOffline,"Guildmember went offline")
                return
            end        
        end
	else
		return
	end
end


function addon:inPL_RANK_CHECK(theEvent,theMessageIn,...)
    -- Loop through the list of players  to find my name and the version
    -- Check the version they have.  Its if current ignore it
    -- if it is older then send new priorities
    -- also check the first record which is their details and update it if its out of date or wring.
       
    util.AddDebugData(theMessage, "inPL_RANK_CHECK message: Started") 

    local theMessage = addon:processMessage(theMessageIn)
    local myPlayerRecord = addon.PLdb.char.playerSelections[1]

    -- util.AddDebugData(myPlayerRecord.player, "inPL_RANK_CHECK: Looking for my records.  My name is") 

    -- update the senders guild data with what they send.  Does not matter if its better or worse just make it the same
    updateGuildRecord(theMessage.unitName,theMessage.hasAddon,theMessage.configVersion)

    for idx,playerRecord in ipairs(theMessage.playerData) do
        -- util.AddDebugData(playerRecord.p, "inPL_RANK_CHECK: Checking player")

        -- Get the person sending - the first person is always the sender
  --      if idx == 1 then 
		--	theTarget=playerRecord.p
  --          -- util.AddDebugData(theTarget, "inPL_RANK_CHECK: The target set to")
		--end                       -- the first person is always the sender

        if myPlayerRecord.player == playerRecord.unitName then              -- find the correct player

            if myPlayerRecord.version == playerRecord.version then          -- check the data version
	            return                                                      --  Ignore the message
            elseif myPlayerRecord.version < playerRecord.v then
                -- Check if I want to update my data, maybe I reinstalled the addon (to be done)
                util.AddDebugData(theEvent, "inPL_RANK_CHECK: Player data version for me was higher than my own") 
                return
	        else
                util.AddDebugData(theEvent, "inPL_RANK_CHECK: Send my updated data") 
                mySendMessage("PL_RANK_UPDATE",myPlayerRecord,theMessage.unitName)                -- Send the new data
                return
	        end
		end
	end
    -- util.AddDebugData(myPlayerRecord, "inPL_RANK_CHECK: Send updated data because they dont have it") 
    -- util.AddDebugData(theTarget, "inPL_RANK_CHECK: Sent to") 
    mySendMessage("PL_RANK_UPDATE",myPlayerRecord,theMessage.unitName)                      -- If I was not listed then have them add me
end

function addon:buildPL_RANK_CHECK()
    --
    -- build a smaller array of players and the version of their data I have to send out.
    -- My data is first 
    -- everyone will get this and they will check their version and ignore or send data back
    -- this message goes out and the faster smaller ACE Event message type
    --
    local thePlayerRecords = addon.PLdb.char.playerSelections
	local theMessageOut = ""
	local recordOut = {
	            unitName = util.unitname('player'),
                hasAddon = version,
	            configVersion = addon.PLdb.char.configVersion,
                playerData = {},
	}

    for key,playerDetails in ipairs(thePlayerRecords) do
	    if key>1 then                      -- skip my record which is number 1 because I am checking everyone else versions
		    recordOut.playerData[key] = {playerDetails.player,playerDetails.version}
		end
    end 
    
    theMessageOut = recordOut

    util.AddDebugData(recordOut,"buildPL_RANK_CHECK: sent")
    mySendMessage("PL_RANK_CHECK",theMessageOut,"ALL")
end


function addon:inPL_RANK_UPDATE(theEvent,theMessageIn,_,messageFrom)
    -- Do a quick validation then
    -- update the players details
    -- dealing with changes to priorityHistory is done elsewhere so don't sweat it
       
    util.AddDebugData(theMessage, "inPL_RANK_UPDATE message: Started") 

    local theMessage = addon:processMessage(theMessageIn)

    if messageFrom == theMessage.unitName then
        playerRecord = getPlayerInformation(messageFrom,0,"PP") 
        playerSelections[playRecord] = theMessage
    end

end

function addon:buildPL_RANK_UPDATE()
    -- not used the message goes straight from in_PL_RANK_CHECK
end


function addon:inPL_CONFIG_CHECK(theEvent,theMessageIn,_,messageFrom) 
    -- Check the incoming version in the PriorityLoot rules
    -- ignore or respond
       
    util.AddDebugData(theMessage, "inPL_CONFIG_CHECK message: Started") 
	
    if iAmTheLootManager then
	    if addon.PLdb.char.configVersion > theMessage.configVersion then
            addon:buildPL_CONFIG_UPDATE(messageFrom)
        end
    else
        buildPL_CONFIG_CHECK(messageFrom)
	end

end   

function addon:buildPL_CONFIG_CHECK(messageTo) 
        local messageTo = messageTo or addon.PLdb.char.guildLootManager
		
		-- If the lootmanager wants to send a PL_CONFIG_CHECK message to someone
        if iAmTheLootManager and messageTo ~= addon.PLdb.char.guildLootManager then
		    sendMessage("PL_CONFIG_CHECK",addon.PLdb.char.configVersion,messageTo)
		end
		
		-- the loot manager in online .
	    -- and I have not checked in the last 24 hours ?
        if not iAmTheLootManager and IsPlayerOnline(addon.PLdb.char.guildLootManager) and
           addon.PLdb.char.lastConfigCheck < C_DateAndTime.GetServerTimeLocal() - 86400 then    -- 86400 is how many seconds are in 24 hours
		        sendMessage("PL_CONFIG_CHECK",addon.PLdb.char.configVersion,messageTo)
        end
end 



function addon:inPL_CONFIG_UPDATE(theEvent,theMessageIn,_,messageFrom) 
    -- Loop through the fields I have been sent and update them if the version sent is new than the version I have

    util.AddDebugData(true, "inPL_CONFIG_UPDATE: Started") 

    -- If I am the LootManager or 
    -- I get a message but the lootmanager is not online
    -- or I get a message and its not from the lootmanager then

    if iAmTheLootManager or not IsPlayerOnline(addon.PLdb.char.guildLootManager) or
        messageFrom ~= addon.PLdb.char.guildLootManager then return end

    local theMessage = addon:processMessage(theMessageIn)
    local myConfigVersion = addon.PLdb.char.configVersion

    --util.AddDebugData(addon.PLdb.char.configVersion, "processConfigUpdate: My version") 
    --util.AddDebugData(theMessage[1][2], "processConfigUpdate: Incoming version") 

    -- version must always be the first record
    if myConfigVersion == theMessage[1][2] then
	    return
	end

    for idx,newSetting in pairs(theMessage) do
        addon.PLdb.char[newSetting[1]] = newSetting[2]
        -- util.AddDebugData(newSetting[2], newSetting[1].." has been updated")
	end

    ACR:NotifyChange(MyAddOnName)

end 

function addon:buildPL_CONFIG_UPDATE(theTarget)  
    -- General configuration Settings
    -- The config version is based on GetServerTime()
    
    if not iAmTheLootManager then return end

    local updateTable = {}
    
    -- look in the database to see what fields we will send to other people
    -- The list if fields is global but the data is at a character level
    for idx,configField in ipairs(addon.PLdb.global.configFieldsToSend) do
	    table.insert(updateTable,addon.PLdb.char[configField])
	end

    -- send the message
    -- theTarget is a name or the string "All"
    sendMessage("PL_CONFIG_UPDATE",updateTable,theTarget)
    
end -- TO BE COMPLETED AND NEEDS TO BE ACTIVATED


function addon:inPL_ROLL_CHECK(theEvent,theMessageIn,_,messageFrom)

    local function toBoolean(value) return value == "true" end

    local rollState = toBoolean(addon:processMessage(theMessageIn))

    if iAmTheLootManager then
	    if rollState ~= thisAddon.priorityLootRollsActive then
	        addon:buildPL_ROLL_CHECK(messageFrom)
	    end
	else
        -- If I am in the same raid as the LootManager
        if isPlayerInRaid(addon.PLdb.char.nameLootManager) then
	        thisAddon.priorityLootRollsActive = rollState 
		end
	end
end

function addon:buildPL_ROLL_CHECK(theTarget)
    
    sendMessage("PL_ROLL_CHECK",thisAddon.priorityLootRollsActive,theTarget)
    util.AddDebugData(true,"PL_ROLL_CHECK sent")

end


function addon:inPL_ADDON_ACTIVE(theFlag)

    if thisAddon.priorityLootRollsActive then
        thisAddon.priorityLootRollsActive = false
        broker.icon = "Interface\\AddOns\\PriorityLoot\\Media\\Textures\\logo"
        util.AddDebugData(thisAddon.priorityLootRollsActive,"Loot rolls not active")
    else
        thisAddon.priorityLootRollsActive = true
        broker.icon = "Interface\\AddOns\\PriorityLoot\\Media\\Textures\\green_logo"
        util.AddDebugData(thisAddon.priorityLootRollsActive,"Loot rolls active")
	end

	addon:eventSetup("LootRoll")
    
end



