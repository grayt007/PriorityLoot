local MyAddOnName,thisAddon = ...
local util = thisAddon.Utils
local addon = _G[MyAddOnName]
local classColors = thisAddon.ClassColors
local tsort = table.sort
local UnitClass,UnitIsPlayer = UnitClass,UnitIsPlayer

local hexFontColors = {
    ["main"] = "ff83b2ff",
    ["accent"] = "ff9b6ef3",
    ["value"] = "ffffe981",
    ["logo"] = "ffff7a00",
    ["blizzardFont"] = NORMAL_FONT_COLOR:GenerateHexColor(),
}


--[[
	Add messages into "DevTool" to help with development and debugging using
	self:AddDebugData(dataitem, comment string)
]]


function util.AddDebugData(theData, theString)
	if  addon.PLdb.profile.config.doYouWantToDebug then
        if addon.PLdb.profile.config.doYouHaveDevTool then
		    DevTool:AddData(theData, theString)
        else
            print("DEBUG:",theString,theData )
        end
	end
end

function util.Print(...)
    print(util.Colorize("PriorityLoot", "main") .. ":", ...)
end

function util.deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, _copy(getmetatable(object)))
    end
    return _copy(object)
end

function util.hasValue(t, value)
    for _, v in ipairs(t) do
        if v == value then return true end
    end
    for k, v in pairs(t) do
        if v == value then return true end
    end
    return false
end

function util.keys(t)
    local temp_t = {}
    for k,_ in pairs(t) do tinsert(temp_t, k) end
    return temp_t
end

function util.keyFromValue(t, value)
    for k,v in pairs(t) do
        if v == value then return k end
    end
end

function util.tableIndex(t, value)
    for idx, v in ipairs(t) do
        if v == value then return idx end
    end
end

function util.unique(t) -- arrays only
	local temp_t,i = {}
	tsort(t)
    for k,v in ipairs(t) do
    	temp_t[#temp_t+1] = i~=v and v or nil
	    i=v
    end
    return temp_t
end

function util.inverted(t)
    local temp_t = {}
    for i = 0,#t-1 do
        tinsert(temp_t, t[#t-i])
    end
    return temp_t
end

function util.tableToString(theTable)
    local result = "{"
    for k, v in pairs(theTable) do
        if type(k) == "string" then
            k = string.format("%q", k)
        end
        if type(v) == "table" then
            v = serialize(v)
        else
            v = string.format("%q", v)
        end
        result = result .. "[" .. k .. "]=" .. v .. ","
    end
    return result .. "}"
end

function util.stringToTable(theString)
    local func = load("return " .. theString)
    return func()
end

function util.extractfield(theTable,theField,flag)
-- extract one field from a table and convert it to a table or to text
-- true means a table false mean text

    local tableResult = {}
	local textResult = ""

    for i, record in ipairs(theTable) do
        if record[theField] then
            if theFlag then
                table.insert(tableResult, record[fieldName])
			else
			    textResult = textResult..textResult..","
			end
        end
    end
	
    if not theFlag then
		textResult = textResult:sub(1, -2)
        return textResult
    else
	    return tableResult
	end
end

function util.unitname(unit)
	local name, server = UnitNameUnmodified(unit,true)

    if server==nil then
        server=GetRealmName()
    end

    if server and server~="" then
        name = ("%s-%s"):format(name,server)
    end
 
	return name
end

function util.getShortName(theName)
-- what is the player name if the origional string included the server

	return string.match(theName, "^[^%-]+")

end

function util.GetIconString(icon, iconSize)
    local size = iconSize or 0
    local ltTexel = 0.08 * 256
    local rbTexel = 0.92 * 256

    if not icon then
        icon = 134400 --"?"
    end

    return format("|T%s:%d:%d:0:0:256:256:%d:%d:%d:%d|t", icon, size, size, ltTexel, rbTexel, ltTexel, rbTexel)
end

function util.Colorize(text, color , theFlag)
-- theFlag indicates if its a Class Color like "Warrior"
    if not text then return end
    local hexColor = hexFontColors[color] or hexFontColors["blizzardFont"]

	if theFlag then
        hexColor = C_ClassColor.GetClassColor(color):GenerateHexColor()
    end

    return "|c" .. hexColor .. text .. "|r"
end

function util.findItemSubType(theSubType)
    util.AddDebugData(theSubType,"Passed in")
	
    tbl = addon.PLdb.profile.config.LootItemSubType
    for _,row in ipairs(tbl) do
        if row[1] == theSubType then return row[2] end
	end
    return "NONE"
end







