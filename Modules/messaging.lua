local MyAddOnName, thisAddon = ...
local addon = _G[MyAddOnName]
local util = thisAddon.Utils

local LibCompress = LibStub:GetLibrary("LibCompress")
local LibEncoder = LibCompress:GetAddonEncodeTable()



------------- INTER ADDON MESSAGING FUNCTIONS ----------------------------------
-- 
-- Use the AceMessage to send out a message with the versions of data I have for everyone
-- when each person sees this they check their personal record and see if the version I have matches theirs
-- if it does they ignore it
-- if it does not they send a WHISPER message back to me directly with they new data
--
-- https://www.wowace.com/projects/ace3/pages/api/ace-serializer-3-0
-- https://www.wowace.com/projects/libcompress#c1


function addon:chatMsgFilter (theMessageIn)
local ONLINE = ERR_FRIEND_ONLINE_SS:gsub("%%s", "(.-)"):gsub("[%[%]]", "%%%1")
-- local ONLINE = ERR_FRIEND_ONLINE_SS:gsub("|Hplayer:%%s|h%[%%s%]|h", "|Hplayer:.+|h%%[.+%%]|h")

	local _, name = strmatch(theMessageIn, ONLINE)

	if name then
        for _,GuildMember in ipairs(guildUnit) do
            util.AddDebugData(theMessageIn,"Guild member has come online")
            return
        end
	else
		return
	end
end

function mySendMessage(theEvent,theMessageIn,theTarget)

    local theMessageInText = ""      -- incase its a table
    theMessageInText = theMessageIn

    --Serialize and compress the data then send it to the target
    local stepOne = addon:Serialize(theMessageInText)
    -- local stepTwo = LibCompress:CompressHuffman(stepOne)
    local finalMessage = LibEncoder:Encode(stepOne)

    if theEvent == "PL_RANK_UPDATE" then
        addon:SendCommMessage(MyAddOnName, finalMessage, "WHISPER", theTarget, "NORMAL")
    elseif theEvent == "PL_RANK_CHECK" or theEvent == "PL_ADDON_CHECK"  then
	    addon:SendMessage(theEvent,finalMessage)
    end
	
    util.AddDebugData(theEvent, "sendMessage:")
end

function addon:processMessage(theMessageIn)

    util.AddDebugData(theMessageIn, "addon:processMessage:  Start")
    local stepOne = LibEncoder:Decode(theMessageIn)              -- Decode the compressed data
	-- util.AddDebugData(stepOne, "addon:processMessage:  Decoded")

    --local stepTwo = LibCompress:Decompress(stepOne)   --Decompress the decoded data
    --if(not stepTwo) then
    --    util.AddDebugData(message,"processMessage: ERROR decompressing message") -- Failure returns an error message
	   -- return
    --else
	   -- util.AddDebugData(stepTwo, "addon:processMessage:  Decompressed") -- sucess return the message
    --end

    local success, finalMessage = addon:Deserialize(stepOne)
    if (not success) then
        util.AddDebugData(finalMessage,"processMessage: ERROR deserializing message")
	    return
    else
        util.AddDebugData(finalMessage, "addon:processMessage:  Deserialized")
    end

    return finalMessage 
end                             -- Process and decompress the message

function addon:messageInUpdateRank(theMessage)
-- PL-RANK_CHECK format is {p="???",v=12}  p for player and v for version to reduce the number of characters

    -- local inboundRecord = util.stringToTable(theMessage)
    util.AddDebugData(theMessage, "messageInUpdateRank: Started") 
    
    local recToUpdate = getPlayerInformation(theMessage.player,"","PP")               -- Where are they in my data
    -- util.AddDebugData(recToUpdate, "messageInUpdateRank: Array row to update") 

    if recToUpdate == 0 then
	    table.insert(addon.PLdb.profile.config.playerSelections, theMessage)
        util.AddDebugData(theMessage.player, "updateRank: Player data  INSERTED")  
	else
        addon.PLdb.profile.config.playerSelections[recToUpdate] = theMessage
        util.AddDebugData(theMessage.player, "updateRank: Player data version UPDATED")  
	end
end                              -- Update my records with the new information provided.

function addon:respondToRankCheck(theEvent,theMessageIn,...)
    -- Loop through the list of players and version to find my name and the version
    -- of my data the other person has.
    --
   
    util.AddDebugData(theMessage, "respondToRankCheck message: Started") 

    local theMessage = addon:processMessage(theMessageIn)
    local myPlayerRecord = addon.PLdb.profile.config.playerSelections[1]

    util.AddDebugData(myPlayerRecord.player, "respondToRankCheck: Looking for my records.  My name is") 

    -- update the senders guild data with what they send.  Does not matter if its better or worse just make it the same
    updateGuildRecord(theMessage.unitName,theMessage.hasAddon,theMessage.lastCheck,theMessage.configVersion)

    for idx,playerRecord in ipairs(theMessage) do
        util.AddDebugData(playerRecord.p, "respondToRankCheck: Checking player")

        -- Get the person sending - the first person is always the sender
        if idx == 1 then 
			theTarget=playerRecord.p
            util.AddDebugData(theTarget, "respondToRankCheck: The target set to")
		end                       -- the first person is always the sender

        if myPlayerRecord.player == playerRecord.p then                     -- find the correct player
            util.AddDebugData(playerRecord.p, "respondToRankCheck: Found my data")
            if myPlayerRecord.version == playerRecord.v then                -- check the data version
	            return                                                      --  Ignore the message
            elseif myPlayerRecord.version < playerRecord.v then
                -- Check if I want to update my data, maybe I reinstalled the addon (to be done)
                util.AddDebugData(theEvent, "respondToRankCheck: Player data version for me was higher than my own") 
                return
	        else
                util.AddDebugData(theEvent, "respondToRankCheck: Send my updated data") 
                mySendMessage("PL_RANK_UPDATE",myPlayerRecord,theTarget)                -- Send the new data
                return
	        end
		end
	end
    util.AddDebugData(myPlayerRecord, "respondToRankCheck: Send updated data because they dont have it") 
    util.AddDebugData(theTarget, "respondToRankCheck: Sent to") 
    mySendMessage("PL_RANK_UPDATE",myPlayerRecord,theTarget)                      -- If I was not listed then have them add me
end

function addon:buildCheckRankMessage()
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

    util.AddDebugData(recordOut,"buildCheckRankMessage: sent")
    mySendMessage("PL_RANK_CHECK",theMessageOut,"none")
end
                                                          -- process a message to update the config of the addon
function addon:buildConfigUpdate()  -- TO BE COMPLETED NEEDS TO BE ACTIVATED
    -- General configuration Settings
    -- config version will be GetServerTime()
    local updateTable = {}
    
    for idx,configField in ipairs(addon.PLdb.profile.config.configFieldsToSend) do
	    table.insert(updateTable,addon.PLdb.profile.config[configField])
	end

    sendMessageTest(PL_CONFIG_UPDATE,updateTable)
    
end

function addon:buildLoginMessage()
    return
end

