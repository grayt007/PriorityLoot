local MyAddOnName, thisAddon = ...
local addon = _G[MyAddOnName]
local util = thisAddon.Utils


local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceRegistry = LibStub("AceConfigRegistry-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local LibDialog = LibStub("LibDialog-1.0")

local GetCVarBool = GetCVarBool
local SetCVar = SetCVar
local InCombatLockdown = InCombatLockdown
local CopyTable = CopyTable
local format = format
local next = next
local wipe = wipe
local pairs = pairs
local type = type
local tonumber = tonumber
local tostring = tostring
local MAX_CLASSES = MAX_CLASSES
local CLASS_SORT_ORDER = CopyTable(CLASS_SORT_ORDER)
do
    table.sort(CLASS_SORT_ORDER)
end
local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local optionsDisabled = {}
local defaultBarName = "DEFAULT"

local classIcons = {
    ["DEATHKNIGHT"] = 135771,
    ["DEMONHUNTER"] = 1260827,
    ["DRUID"] = 625999,
    ["EVOKER"] = 4574311,
    ["HUNTER"] = 626000,
    ["MAGE"] = 626001,
    ["MONK"] = 626002,
    ["PALADIN"] = 626003,
    ["PRIEST"] = 626004,
    ["ROGUE"] = 626005,
    ["SHAMAN"] = 626006,
    ["WARLOCK"] = 626007,
    ["WARRIOR"] = 626008,
}

local LOCALIZED_CLASS_NAMES_MALE = LOCALIZED_CLASS_NAMES_MALE
local optionsDisabled = {}

local function GetClasses() -- get a list of classes
    -- Get the list of classes and then cycle through those and get all the spells
    local classes = {}

    classes["MISC"] = {
        name = format("%s %s", addon.GetIconString(addon.customIcons["Cogwheel"], 15), util.Colorize(MISCELLANEOUS, "MISC")),
        order = 99,
        type = "group",
        args = GetClassCooldowns("MISC" ),
    }

    for i = 1, MAX_CLASSES do
        local className = CLASS_SORT_ORDER[i]

        classes[className] = {
            name = format("%s %s", addon:GetIconString(classIcons[className], 15), util.Colorize(LOCALIZED_CLASS_NAMES_MALE[className], className)),
            order = i,
            type = "group",
            args = GetClassCooldowns(className),
        }
    end
    return classes
end

function addon:GetIconString(icon, iconSize)
    local size = iconSize or 0
    local ltTexel = 0.08 * 256
    local rbTexel = 0.92 * 256

    if not icon then
        icon = addon.customIcons["?"]
    end

    return format("|T%s:%d:%d:0:0:256:256:%d:%d:%d:%d|t", icon, size, size, ltTexel, rbTexel, ltTexel, rbTexel)
    --            |T%s     :%d:%d:0:0:256:256:%d: %d: %d:%d|t"
--               "|T5199639: 0: 0:0:0:256:256:20:235:20:235|tPrescience"
end

function addon:AddTabsToOptions() 

    self.options.args.raids.args.settings = {
        name = SETTINGS,
        type = "group",
        order = 3,
        args = {
            space = {
                name = " ",
                type = "description",
                order = 17,
                width = "full",
            },
            h2 = {
                type = 'header',
                name = 'This is my heading',
                order = 40,
            },
        }
    }

    self.options.args.raids.args.iconsAndSpells = {
        order = 5,
        name = "Icons",
        type = "group",
        args = {
            h1 = {
                type = 'header',
                name = 'Format the buff and aura icons when they appear',
                order = 5,
            },
        }
    }
end

function addon:Options()

    -- populate the tabs with stuff
    self.options = {
        name = MyAddOnName,
        type = "group",
        plugins = { profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.PLdb) } },
        childGroups = "tab",
        args = {
            logo = {
                order = 1,
                type = "description",
                name = util.Colorize("Author")..":  The Author \n" ..util.Colorize("Addon Version")..": V0.5 \n\n",
                fontSize = "medium",
                -- "Logo" created by Marz Gallery @ https://www.flaticon.com/free-icons/nocturnal
                image = "Interface\\AddOns\\PriorityLoot\\Media\\Textures\\logo_transparent",
                imageWidth = 64,
                imageHeight = 64,
            },
            globalSettings = {
                order = 2,
                name = BASE_SETTINGS,
                type = "group",
                args = {
                    spaceSettingsA = {
                        order = 0.5,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    welcomeMessage = {
                        order = 1,
                        name = "Welcome Message",
                        type = "toggle",
                        width = 1.5,
                        desc = "Toggle showing of the welcome message in chat when you login.",
                        get = function(info) return self.PLdb.profile.config.welcomeMessage end,
                        set = function(info, val)
                            self.PLdb.profile.config.welcomeMessage = val
                        end,
                    },
                    welcomeMessage2 = {
                        order = 1.5,
                        name = "Introduction picture",
                        type = "toggle",
                        width = 1.5,
                        desc = "Showing the welcome picture with basic information and instructions at first login",
                        get = function(info) return self.PLdb.profile.config.welcomeMessage2 end,
                        set = function(info, val)
                            self.PLdb.profile.config.welcomeMessage2 = val
                        end,
                    },
                    welcomeChat = {
                        order = 3,
                        name = "Welcome chat",
                        type = "toggle",
                        width = 1.5,
                        desc = "Version and Addon name in chat at startup",
                        get = function(info) return self.PLdb.profile.config.welcomeChat end,
                        set = function(info, val)
                            self.PLdb.profile.config.welcomeChat = val
                        end,
                    },
                    minimap = {
                        order = 4,
                        name = "Minimap Icon",
                        type = "toggle",
                        width = 1.5,
                        desc = "Toggle the minimap icon.",
                        get = function() return not self.PLdb.profile.config.minimap.hide end,
                        set = function()
                            self:ToggleMinimapIcon()
                        end,
                    },
                    spaceSettingsB = {
                        order = 9,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
        

                    h3 = {
                        type = 'header',
                        name = 'Debugging and Development',
                        order = 30,
                    },

                    spaceSettings3A = {
                        order = 11,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    spaceSettings3B = {
                        order = 32,
                        name = "Settings to be used during additional development and defect resolution",
                        type = "description",
                        width = "full",
                    },
                    spaceSettings3C = {
                        order = 33,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    doYouHaveDevTool = {
                        type = 'toggle',
                        name = 'Do you want to output debugging to DevTool',
                        desc = 'You have the "DevTool" addon for debugging installed and configured and want to use it.',
                        width = 'full',
                        hidden = function() 
                                    local loaded = false
                                    loaded , _ = C_AddOns.IsAddOnLoaded("DevTool") 
                                    return not loaded
                                 end,
                        get = function() return self.config.doYouHaveDevTool end,
                        set = function(info, value) 
                                self.config.doYouHaveDevTool = value 
                              end,
                        order = 36,
                    },
                    doYouWantToDebug = {
                        type = 'toggle',
                        name = 'Do you want to show debugging output ?',
                        desc = 'You have the "DevTool" addon for debugging installed and configured.',
                        get = function() return self.config.doYouWantToDebug end,
                        set = function(info, value) self.config.doYouWantToDebug = value end,
                        width = 'full',
                        order = 37,
                    },
       
                },
            },
            raids = {
                name = "General",
                type = "group",
                childGroups = "tab",
                order = 3,
                args = {
                    space = {
                        name = " ",
                        type = "description",
                        order = 1,
                        width = "full",
                    },
                    heading1 = {
                        name =  "Update or add any missing raids, bosses or loot.",
                        type = "description",
                        order = 1.1,
                        width = "full",
                    },
                },

            },

        },
    }

    self:AddTabsToOptions()

    -- Main options dialog.
       
    AceConfig:RegisterOptionsTable(MyAddOnName, self.options ) -- , {MyAddOnName , 'PL'}
    -- AceConfig:RegisterOptionsTable(MyAddOnName.."Dialog", self.priorityListDialog)
    AceConfigDialog:SetDefaultSize(MyAddOnName, 635, 730)
    AceConfigDialog:SetDefaultSize(MyAddOnName.."Dialog", 300, 730)

    -------------------------------------------------------------------
    -- Create a simple blizzard options panel to direct users to "/auga"
    -------------------------------------------------------------------
    local panel = CreateFrame("Frame")
    panel.name = MyAddOnName

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetText(MyAddOnName)
    title:SetFont("Fonts\\FRIZQT__.TTF", 72, "OUTLINE")
    title:ClearAllPoints()
    title:SetPoint("TOP", 0, -70)

    local ver = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ver:SetText(addon.version)
    ver:SetFont("Fonts\\FRIZQT__.TTF", 48, "OUTLINE")
    ver:ClearAllPoints()
    ver:SetPoint("TOP", title, "BOTTOM", 0, -20)

    local slash = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    slash:SetText("/PL")
    slash:SetFont("Fonts\\FRIZQT__.TTF", 69, "OUTLINE")
    slash:ClearAllPoints()
    slash:SetPoint("BOTTOM", 0, 150)

    local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    btn:SetText("Open Options")
    btn.Text:SetTextColor(1, 1, 1)
    btn:SetWidth(150)
    btn:SetHeight(30)
    btn:SetPoint("BOTTOM", 0, 100)
    btn.Left:SetDesaturated(true)
    btn.Right:SetDesaturated(true)
    btn.Middle:SetDesaturated(true)
    btn:SetScript("OnClick", function()
        if not InCombatLockdown() then
            HideUIPanel(SettingsPanel)
            HideUIPanel(InterfaceOptionsFrame)
            HideUIPanel(GameMenuFrame)
        end
        addon:OpenOptions()
    end)

    local bg = panel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\AddOns\\PriorityLoot\\Media\\Textures\\logo_transparent")
    bg:SetAlpha(0.2)
    bg:SetTexCoord(0, 1, 0, 1)

    if isRetail then
        local category = Settings.RegisterCanvasLayoutCategory(panel, MyAddOnName)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
end


