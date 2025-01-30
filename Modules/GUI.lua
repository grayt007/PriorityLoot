local MyAddOnName, thisAddon = ...
local util = thisAddon.Utils
-- local roster = NS.roster
local addon = _G[MyAddOnName]

local autoAdds = thisAddon.Auto


--------- SUPPORTING FUNCTIONS --------------

function addon:yesnoBox(msg, callback)                          -- Yes No conformation window
    
    
 
    StaticPopupDialogs[MyAddOnName.."_YESNOBOX"] = {
        text = msg,
        button1 = "Yes",
        button2 = "No",
        OnAccept = function(self, data, data2)
            callback()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = STATICPOPUP_NUMDIALOGS,
    }

    StaticPopup_Show (MyAddOnName.."_YESNOBOX")
end



