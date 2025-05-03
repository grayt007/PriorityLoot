local MyAddOnName, thisAddon = ...
local addon = _G[MyAddOnName]
local util = thisAddon.Utils

local LibCompress = LibStub:GetLibrary("LibCompress")
local LibEncoder = LibCompress:GetAddonEncodeTable()



--[[----------- INTER ADDON MESSAGING FUNCTIONS ----------------------------------
 
 https://www.wowace.com/projects/ace3/pages/api/ace-serializer-3-0
 https://www.wowace.com/projects/libcompress#c1

    CHAT_MSG_SYSTEM:  Friends and guild member login messages
	                  chatMsgFilter
					  
    wowACE Comm Messaging:
        PL_RANK_UPDATE:  Look at the PL_RANK_CHECK message and send my details if their data is old
		                 Sent automatically if required as part of the final steps in PLL_RANK_CHECK
		                
        PL_RANK_CHECK:   Use the AceMessage to send out a message with the versions of data I have for everyone
                         when each person sees this they check their personal record and see if the version I have matches theirs
                         if it does they ignore it
                         if it does not they send a WHISPER message back to me directly with they new datarespondToRankCheck
						 
        PL_ADDON_CHECK:  To be determined.  Currently activated on login
		
        PL_CONFIG_UPDATE: Update the config file

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
local ONLINE = ERR_FRIEND_ONLINE_SS:gsub("%%s", "(.-)"):gsub("[%[%]]", "%%%1")
-- local ONLINE = ERR_FRIEND_ONLINE_SS:gsub("|Hplayer:%%s|h%[%%s%]|h", "|Hplayer:.+|h%%[.+%%]|h")

	local _, name = strmatch(theMessageIn, ONLINE)

	if name then
        for _,guildMember in ipairs(thisAddon.guildUnit) do
            util.AddDebugData(theMessageIn,"Guild member has come online")
            return
        end
	else
		return
	end
end


function addon:inPL_CONFIG_UPDATE(theEvent,theMessageIn,...)
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
        -- util.AddDebugData(newSetting[2], newSetting[1].." has been updated")
	end

    ACR:NotifyChange(MyAddOnName)

end 

function addon:buildPL_CONFIG_UPDATE()  -- TO BE COMPLETED NEEDS TO BE ACTIVATED
    -- General configuration Settings
    -- config version will be GetServerTime()
    local updateTable = {}
    
    -- look in the database to see what fields we will send to other people
    for idx,configField in ipairs(addon.PLdb.profile.config.configFieldsToSend) do
	    table.insert(updateTable,addon.PLdb.profile.config[configField])
	end

    -- send the message
    sendMessage("PL_CONFIG_UPDATE",updateTable,"ALL")
    
end


function addon:inPL_RANK_CHECK(theEvent,theMessageIn,...)
    -- Loop through the list of players and version to find my name and the version in their message
    -- Check the version they have.  Its if current ignore it
    -- if it is older then send new priorities
       
    util.AddDebugData(theMessage, "inPL_RANK_CHECK message: Started") 

    local theMessage = addon:processMessage(theMessageIn)
    local myPlayerRecord = addon.PLdb.profile.config.playerSelections[1]

    -- util.AddDebugData(myPlayerRecord.player, "inPL_RANK_CHECK: Looking for my records.  My name is") 

    -- update the senders guild data with what they send.  Does not matter if its better or worse just make it the same
    updateGuildRecord(theMessage.unitName,theMessage.hasAddon,theMessage.lastCheck,theMessage.configVersion)

    for idx,playerRecord in ipairs(theMessage) do
        -- util.AddDebugData(playerRecord.p, "inPL_RANK_CHECK: Checking player")

        -- Get the person sending - the first person is always the sender
        if idx == 1 then 
			theTarget=playerRecord.p
            -- util.AddDebugData(theTarget, "inPL_RANK_CHECK: The target set to")
		end                       -- the first person is always the sender

        if myPlayerRecord.player == playerRecord.p then                     -- find the correct player
            -- util.AddDebugData(playerRecord.p, "inPL_RANK_CHECK: Found my data")
            if myPlayerRecord.version == playerRecord.v then                -- check the data version
	            return                                                      --  Ignore the message
            elseif myPlayerRecord.version < playerRecord.v then
                -- Check if I want to update my data, maybe I reinstalled the addon (to be done)
                util.AddDebugData(theEvent, "inPL_RANK_CHECK: Player data version for me was higher than my own") 
                return
	        else
                util.AddDebugData(theEvent, "inPL_RANK_CHECK: Send my updated data") 
                mySendMessage("PL_RANK_UPDATE",myPlayerRecord,theTarget)                -- Send the new data
                return
	        end
		end
	end
    -- util.AddDebugData(myPlayerRecord, "inPL_RANK_CHECK: Send updated data because they dont have it") 
    -- util.AddDebugData(theTarget, "inPL_RANK_CHECK: Sent to") 
    mySendMessage("PL_RANK_UPDATE",myPlayerRecord,theTarget)                      -- If I was not listed then have them add me
end

function addon:buildPL_RANK_CHECK()
    --
    -- build a smaller array of players and the version of their data I have to send out.
    -- everyone will get this and they will check their version and ignore or send data back
    -- this message goes out and the faster smaller ACE Event message type
    --
    local thePlayerRecords = addon.PLdb.profile.config.playerSelections
	local theMessageOut = ""
	local recordOut = {}

    -- the first person must always be me which it should be by default
    for key,playerDetails in ipairs(thePlayerRecords) do
        if key==1 and addon.PLdb.profile.config.doYouWantToDebugMessages then  -- include my record if debugging
            recordOut[key] = {util.unitname(UnitName("player")),1}
        end
	    if key>1 then                      -- skip my record which is number 1 because I am checking everyone else versions
		    recordOut[key] = {playerDetails.player,playerDetails.version}
		end
    end 

    recordOut.unitName = addon.PLdb.profile.config.playerSelections[1].player
    recordOut.hasAddon = version                            
    recordOut.lastCheck = addon.PLdb.profile.config.lastConfigCheck                         
	recordOut.configVersion = addon.PLdb.profile.config.configVersion
    
    theMessageOut = recordOut

    util.AddDebugData(recordOut,"buildPL_RANK_CHECK: sent")
    mySendMessage("PL_RANK_CHECK",theMessageOut,"ALL")
end


function addon:buildPL_ADDON_CHECK()
    return
end

function addon:inPL_ROLL_CHECK(theEvent,theMessageIn,_,messageFrom)

    local function toBoolean(value) return value == "true" end

    local rollState = toBoolean(addon:processMessage(theMessageIn))

    if iAmTheLootManager then
	    if rollState ~= thisAddon.priorityLootRollsActive then
	        addon:buildPL_ROLL_CHECK(messageFrom)
	    end
	else
	    thisAddon.priorityLootRollsActive = rollState 
	end
end

function addon:buildPL_ROLL_CHECK(theTarget)
    
    sendMessage("PL_ROLL_CHECK",thisAddon.priorityLootRollsActive,theTarget)
    util.AddDebugData(true,"PL_ROLL_CHECK sent")

end
