local MyAddOnName, thisAddon = ...
local addon = _G[MyAddOnName]
local util = thisAddon.Utils


local ACD = LibStub("AceConfigDialog-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local LibDialog = LibStub("LibDialog-1.0")

local priorityLootRollsActive = priorityLootRollsActive
local GetCVarBool = GetCVarBool
local SetCVar = SetCVar
-- local InCombatLockdown = InCombatLockdown
--local CopyTable = CopyTable
--local format = format
--local next = next
--local wipe = wipe
--local pairs = pairs
--local type = type
local tonumber = tonumber
local tostring = tostring
local version = version
local MAX_CLASSES = MAX_CLASSES
--local CLASS_SORT_ORDER = CopyTable(CLASS_SORT_ORDER)
--do
--    table.sort(CLASS_SORT_ORDER)
--end
local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

local optionsDisabled = {}

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

function addon:addBaseOptions(theOrder)
    self.options.args.base = {
                order = theOrder,
                name = "Base",
                type = "group",
                childGroups = "tab",
                args = {
                    h1 = {
                        type = 'description',
                        name = 'Use each tab to configure your base addon settings',
                        width = "full",
                        order = 1,
                    },
   
                },
	}
end

function addon:addTabsToOptionsBase() 

    self.options.args.base.args.general = {
        name = "General",
        type = "group",
        order = 50,
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
                get = function(info) return self.PLdb.profile.welcomeMessage end,
                set = function(info, val)
                    self.PLdb.profile.welcomeMessage = val
                end,
            },
            welcomeChat = {
                order = 2,
                name = "Welcome chat",
                type = "toggle",
                width = 1.5,
                desc = "Version and Addon name in chat at startup",
                get = function(info) return self.PLdb.profile.welcomeChat end,
                set = function(info, val)
                    self.PLdb.profile.welcomeChat = val
                end,
            },
            welcomeScreen = {
                order = 3,
                name = "Welcome image",
                type = "toggle",
                width = 1.5,
                desc = "Version and Addon name in chat at startup",
                get = function(info) return self.PLdb.profile.welcomeMessage2 end,
                set = function(info, val)
                    self.PLdb.profile.welcomeMessage2 = val
                end,
            },
            minimap = {
                order = 4,
                name = "Minimap Icon",
                type = "toggle",
                width = 1.5,
                desc = "Toggle the minimap icon.",
                get = function() return not self.PLdb.profile.minimap.hide end,
                set = function()
                    self:ToggleMinimapIcon()
                end,
            },
            spaceSettingsB = {
                order = 4.5,
                name = " ",
                type = "description",
                width = "full",
            },
            h1 = {
                type = 'header',
                name = 'Settings Information',
                order = 5,
            },
            myClass = {
				order = 6,
				type = "input",
                name = "My Class was identified as: ",
                width = 2,
                get = function()    
                    local className = self.PLdb.global.classInfo[self.PLdb.char.myClassID][1]
					return util.Colorize(className,className,true)
				end,
            
			},
            myArmourType = {
				order = 6.5,
				type = "input",
                name = "My armour type is set for: ",
                width = 2,
                get = function()   
                    if self.PLdb.char.myArmourType == "A" then return "CLOTH"
                    elseif self.PLdb.char.myArmourType == "B" then return "LEATHER"
                    elseif self.PLdb.char.myArmourType == "C" then return "MAIL"
                    elseif self.PLdb.char.myArmourType == "D" then return "PLATE"
                    end
				end,
			},
            myTierGroup = {
				order = 7,
				type = "input",
                name = "My Tier group is: ",
                width = 2,
                get = function()  
                    local tierText = string.upper(self.PLdb.global.tierGroupNames[self.PLdb.char.myTierGroup])
                    
					tierText = tierText .." ( "
                    for idx,classTier in ipairs(self.PLdb.global.classInfo) do
                        if classTier[2] == self.PLdb.char.myTierGroup then
						    tierText = tierText ..classTier[1]:sub(1,1):upper()..classTier[1]:sub(2):lower().." "
                        end
                    end
					tierText = tierText .." )"

					return tierText  -- self.PLdb.global.tierGroupNames[self.PLdb.char.myTierGroup]
				end,
			},
            spaceSettingsA = {
                order = 7.5,
                name = " ",
                type = "description",
                width = "full",
            },
			myGuildName = {
				order = 8,
				type = "input",
                name = "Guild is set to:",
                width = 2,
                get = function()    
					return util.Colorize(self.PLdb.char.myGuildName).." on realm "..util.Colorize(self.PLdb.char.myGuildRealm)
				end,
			},
            spaceSettingsC = {
                order = 9,
                name = " ",
                type = "description",
                width = "full",
            },
			myLootManager = {
				order = 10,
				type = "input",
                name = "My Loot manager has been set to:",
                width = 2,
                get = function() return self.PLdb.char.guildLootManager end,
			},
            spaceSettingsD = {
                order = 11,
                name = " ",
                type = "description",
                width = "full",
            },

        },
    }

    self.options.args.base.args.guild = {
        name = "Guild",
        order = 60,

        type = "group",
        args = {
            h1 = {
                type = 'header',
                name = 'Setup guild ranks and other settings',
                order = 2,
            },
            guildOfficerRanks = {
				order = 12,
				type = "multiselect",
                desc = "Choose the ranks that represent officers.  This will impact who can be a Loot Manager and other background logic.  It can be set by the GM or the Loot Manager",
                name = "Officer guild ranks ",
                hidden = function() 
                        if iAmTheGM or iAmTheLootManager or self.PLdb.char.testMode then 
							return false 
						else
                            return true
						end
						end,
                width = "1",
                values = function() 
						local rankList = {}
						for idx = 1, GuildControlGetNumRanks() do
							table.insert(rankList, GuildControlGetRankName(idx))
						end
						return rankList
					end,
                get = function(info , key)
                        -- dont forget ranks start at zero and tables start at 1
						if self.PLdb.char.guildOfficerRanks[key] ~= "-" then
                            return true   
						else
                            return false
						end
						end,
                set = function(info, key, value) 
                        -- we and looking to see if the rankindex exists so put in the number for true or "-" for false
                        -- dont forget ranks start at zero and tables start at 1
                        if iAmTheGM or iAmTheLootManager then 
                            if value then
                                self.PLdb.char.guildOfficerRanks[key] = key-1
                                addon:configUpdate()
                            else
                                self.PLdb.char.guildOfficerRanks[key] = "-"
                                addon:configUpdate()
                            end 
						end
                        end,
                },
            spaceSettingsB2 = {
                order = 13,
                name = "  ",
                type = "description",
                width = "full",
            },
			guildLMNote = {
				order = 14,
				type = "description",
                name = "The guild Loot Manager role is a guild officer who provides the guild settings for the addon.  This must be set by the Guild Master before the guild uses PriorityLoot.",
                width = "full",
                },
            guildLootManager = {
				order = 14.2,
				type = "select",
                values = addon.PLdb.char.officerList, 
                name = "Guild Loot Manager is",
                disabled = function() 
					    if not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode then
                            return true
                        end
				    end,
                width = "1.5",
                get = function() return self.PLdb.char.guildLootManager end,
                set = function(info, value) 
                        if iAmTheGM or iAmTheLootManager then 
                            self.PLdb.char.guildLootManager = value 
                            addon:configUpdate()
                        end
                        end,
			},
            spaceSettingsC = {
                order = 14.5,
                name = "  ",
                type = "description",
                width = "full",
            },

			guildRaidRanks = {
				order = 15,
				type = "multiselect",
                desc = "Choose the ranks assigned to people who raid e.g. Raiders,Raider Alts,Officers.  This will impact who is displayed on the Loot Priority screen and potentially the allocation of loot if that rule is choosen",
                name = "Guild ranks for raiders ",
                disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
                width = "1.5",
                values = function() 
						local rankList = {}
						for idx = 1, GuildControlGetNumRanks() do
							table.insert(rankList, GuildControlGetRankName(idx))
						end
                        util.AddDebugData(rankList,"Raid Guild ranks")
						return rankList
					end,
                get = function(info , key)
                        -- dont forget ranks start at zero and tables start at 1
						if self.PLdb.char.guildRaidRanks[key] ~= "-" then
                            return true   
						else
                            return false
						end
						end,
                set = function(info, key, value) 
                        -- we and looking to see if the rankindex exists so put in the number for true or "-" for false
                        -- dont forget ranks start at zero and tables start at 1
                        if iAmTheGM or iAmTheLootManager then 
                            if value then
                                self.PLdb.char.guildRaidRanks[key] = key-1
                            else
                                self.PLdb.char.guildRaidRanks[key] = "-"
                            end 
                            addon:configUpdate()
                            loadGuildMembers()
                            fillTableColumn()
						end
                        end,
                },
            h2 = {
                type = 'header',
                name = 'Loot Manager Functions',
                order = 15,
                 hidden = function() 
						    if iAmTheGM or iAmTheLootManager or self.PLdb.char.testMode then 
							    return false 
						    else
                                return true
						    end
						end,
            },
            spaceSettingsE = {
                order = 15.5,
                name = " ",
                type = "description",
                width = "full",
            },
            setLootRollStateOn = {
				order = 16,
				type = "execute",
                name = "Turn on Loot Rolls",
                width = 1,
                disabled = function ()
					        return thisAddon.priorityLootRollsActive
                        end,
                hidden = function() 
						    if iAmTheGM or iAmTheLootManager or self.PLdb.char.testMode then 
							    return false 
						    else
                                return true
						    end
						end,
                func = function()
                            if iAmTheGM or iAmTheLootManager then 
                                addon:updateLootRollStatus(true)
							end
					    end,
            },
        }
    }

    self.options.args.base.args.gui = {
        name = "GUI",
        order = 70,

        type = "group",
        args = {
             h1 = {
                type = 'header',
                name = 'General Interface Settings',
                order = 10,
            },
			nameLeftMarginTop = {
                name = 'Left margin on top header names',
                type = 'range',
                width = 1.5,
                min = -40,
                max = 20,
                step = 1,
                order = 11,
				get = function(info) return self.PLdb.profile.GUI.nameLeftMarginTop end,
                set = function(info, val)
                    self.PLdb.profile.GUI.nameLeftMarginTop = val
                    fillTableColumn()
                end,
            },
            nameLeftMarginBottom = {
                name = 'Left margin on bottom header names',
                type = 'range',
                width = 1.5,
                min = -60,
                max = 10,
                step = 1,
                order = 11,
				get = function(info) return self.PLdb.profile.GUI.nameLeftMarginBottom end,
                set = function(info, val)
                    self.PLdb.profile.GUI.nameLeftMarginBottom = val
                    fillTableColumn()
                end,
            },
             displayMaxPlayers = {
                name = 'Maximum players to display',
                type = 'range',
                width = 1.5,
                min = 15,
                max = 30,
                step = 1,
                order = 15,
				get = function(info) return self.PLdb.profile.GUI.displayMaxPlayers end,
                set = function(info, val)
                    self.PLdb.profile.GUI.displayMaxPlayers = val
                    fillTableColumn()
                end,
			 },
             playerToDisplay = {
                name = 'How many players to scroll at a time',
                type = 'range',
                width = 1.5,
                min = 2,
                max = 5,
                step = 1,
                order = 16,
				get = function(info) return self.PLdb.profile.GUI.scrollPLayerNumber end,
                set = function(info, val)
                    self.PLdb.profile.GUI.scrollPLayerNumber = val
                end,
            },
            spaceSettingsA = {
                order = 28,
                name = " ",
                type = "description",
                width = "full",
            },
            h2 = {
                type = 'header',
                name = 'Loot Roll Frame Interface',
                order = 30,
            },

       --     xPos = {
       --         order = 31,
       --         name = "Horizontal base position",
       --         type = "range",
       --         width = 1.5,
       --         min = 0,
       --         max = 2000,
       --         step = 10,
       --         desc = "Starting position base line",
			    --get = function(info) return self.PLdb.profile.GUI.xPos end,
       --         set = function(info,val)
       --             self.PLdb.profile.GUI.xPos = val
       --         end,
       --     },
       --     yPos = {
       --         order = 32,
       --         name = "Vertical base position",
       --         type = "range",
       --         width = 1.5,
       --         min = 0,
       --         max = 2000,
       --         step = 10,
       --         desc = "Starting position base line",
			    --get = function(info) return self.PLdb.profile.GUI.yPos end,
       --         set = function(info,val)
       --             self.PLdb.profile.GUI.yPos = val
       --         end,
       --     },

            width = {
                order = 35,
                name = "Width of loot window",
                type = 'range',
                width = 1.5,
                min = 300,
                max = 700,
                step = 20,
                width = 1.5,
                desc = "Width of loot window",
			    get = function(info) return self.PLdb.profile.GUI.width end,
                set = function(info, val)
                    self.PLdb.profile.GUI.width = val
                end,
            },
            height = {
                order = 36,
                name = "Height of loot window",
                type = 'range',
                width = 1.5,
                min = 300,
                max = 600,
                step = 20,
                width = 1.5,
                desc = "Height of loot window",
			    get = function(info) return self.PLdb.profile.GUI.height end,
                set = function(info, val)
                    self.PLdb.profile.GUI.height = val
                end,
            },

            itemHeight = {
                order = 37,
                name = "Item Height in loot window",
                type = 'range',
                width = 1.5,
                min = 40,
                max = 60,
                step = 1,
                width = 1.5,
                desc = "Height of items in the loot window",
			    get = function(info) return self.PLdb.profile.GUI.itemHeight end,
                set = function(info, val)
                    self.PLdb.profile.GUI.itemHeight = val
                end,
            },
            scale = {
                order = 38,
                name = "Item Scale",
                type = 'range',
                width = 1.5,
                min = 0.5,
                max = 3,
                step = 0.25,
                desc = "Scale of items in the loot window",
			    get = function(info) return self.PLdb.profile.GUI.scale end,
                set = function(info, val)
                    self.PLdb.profile.GUI.scale = val
                end,
            },

            fontSize = {
                name = 'Font size',
                type = 'range',
                width = "full",
                min = 6,
                max = 20,
                step = 1,
                order = 39,
				get = function(info) return self.PLdb.profile.GUI.fontSize end,
                set = function(info, val)
                    self.PLdb.profile.GUI.fontSize = val
                end,
            },

            trimText = {
                order = 40,
                name = "Trim text",
                type = "toggle",
                width = 1.5,
                desc = "Trim text to length",
			    get = function(info) return self.PLdb.profile.GUI.trimText end,
                set = function(info, val)
                    self.PLdb.profile.GUI.trimText = val
                end,
            },
            maxTextAmount = {
                type = 'range',
                name = 'Maximum text',
                width = 1.5,
                min = 20,
                max = 40,
                step = 1,
                order = 41,
				get = function(info) return self.PLdb.profile.maxTextAmount end,
                set = function(info, val)
                    self.PLdb.profile.maxTextAmount = val
                end,
            },

            iconZoom = {
                order = 42,
                name = "Zoom icons",
                type = "toggle",
                width = 1.5,
			    get = function(info) return self.PLdb.profile.GUI.iconZoom end,
                set = function(info, val)
                    self.PLdb.profile.GUI.iconZoom = val
                end,
            },
            border = {
                order = 43,
                name = "Border",
                type = "toggle",
                width = 1,
                desc = "Scale of items in the loot window",
			    get = function(info) return self.PLdb.profile.GUI.tribordermText end,
                set = function(info, val)
                    self.PLdb.profile.GUI.border = val
                end,
            },
        },
    }

end

function addon:addRuleOptions(theOrder)
            self.options.args.rules = {
                order = theOrder,
                name = "Loot Allocation Rules",
                type = "group",
                args = {
                    spaceSettingsA = {
                        order = 0.5,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    overview = {
                        order = 1,
                        type = "description",
                        name = "The following options are set by the Loot Manager for all raiders to distribute loot in raids.  They are provided here to help you better understand the Priority Looting system your guild has choosen.  ",
                        width = "full",
                        fontSize = "medium",
                    },    
                    numberOfPriorities = {
                        type = 'range',
                        name = 'Number of items that can be prioritised',
                        width = "full",
                        min = 2,
                        max = 18,
                        step = 1,
                        order = 12,
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
                        get = function(info) return self.PLdb.char.numberOfPriorities end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.numberOfPriorities = val
                                addon:configUpdate()
                            end
                        end,
                    },
                    h2 = {
                        type = 'header',
                        name = 'Items available to be prioritised for loot drops',
                        order = 20,
                    },
                    includeArmour = {
                        order = 21,
                        name = "Include Armour",
                        type = "toggle",
                        width = 1.5,
                        desc = "Include armour in the items that can be prioritised.",
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.includeArmour end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.includeArmour = val
                                addon:configUpdate()
                            end
                        end,
                    },
                    includeWeapons = {
                        order = 22,
                        name = "Include Weapons",
                        type = "toggle",
                        width = 1.5,
                        desc = "Include weapons in the items that can be prioritised.",
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.includeWeapons end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
							    self.PLdb.char.includeWeapons = val
                                addon:configUpdate()
                              end
                        end,
                    },
                    includeTrinkets = {
                        order = 23,
                        name = "Include Trinkets",
                        type = "toggle",
                        width = 1.5,
                        desc = "Include trinkets in the items that can be prioritised.",
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.includeTrinkets end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.includeTrinkets = val
                                addon:configUpdate()
                            end
                        end,
                    },
                    includeJewelery = {
                        order = 24,
                        name = "Include Jewelry",
                        type = "toggle",
                        width = 1.5,
                        desc = "Include rings and neck items in the items that can be prioritised.",
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.includeJewelery end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.includeJewelery = val
                                addon:configUpdate()
                            end
                        end,
                    },
                    includeTier = {
                        order = 25,
                        name = "Include Tier Tokens",
                        type = "toggle",
                        width = 1.5,
                        desc = "Include Tier Tokens items in the items that can be prioritised.",
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.includeTier end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.includeTier = val
                                addon:configUpdate()
                            end
                        end,
                    },
                    spaceSettings2A = {
                        order = 29,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    h3 = {
                        type = 'header',
                        name = 'Loot allocation rules',
                        order = 30,
                    },

                    spaceSettings3A = {
                        order = 50,
                        name = "The following rules can be applied in the order specified when two or more people have the same maximum priority to refine the allocations ",
                        type = "description",
                        width = "full",
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
                    },
         
                    spaceSettings3C = {
                        order = 51,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    refineSuicideText = {
                        order = 53,
                        type = "description",
                        name = "Suicide priorities information:  When someone wins an item that priority option is no longer available them but they can still prioritise the same number of items e,g, Player1 has prioritised items 1,2,3,4,5.  They win their second choice item.  They can now revise their priorities as 1,3,4,5,6. Priority 2 is no longer available.",
                        width = "full",
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
                    },
                    refineSuicide = {
                        order = 53.5,
                        type = 'toggle',
                        name = 'Use suicide priorities (recommended)',
                        desc = 'Lock a priority choice once the loot is won but still let them specify the same number of priorities',
                        width = "full",
                        disabled = function() return true end, -- (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.refineSuicide end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.refineSuicide = val
                                addon:configUpdate()
                            end
                        end,
                    },
                    spaceSettings5B = {
                        order = 54,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    refineItemLevel = {
                        order = 55,
                        type = 'toggle',
                        name = 'Include an item level review',
                        desc = 'If the item gap is greater than the amount specified the lower item level person will gain priority',
                        width = 1.5,
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.refineItemLevel end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.refineItemLevel = val
                                addon:configUpdate()
                            end
                        end,
                    },
                    refineItemLevelRange = {
                        type = 'range',
                        name = 'Number of items levels',
                        width = 1.5,
                        min = 2,
                        max = 50,
                        step = 1,
                        order = 55.5,
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.refineItemLevelRange end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.refineItemLevelRange = val
                                addon:configUpdate()
							end
                        end,
                    },
                    refineAlts = {
                        order = 60,
                        type = 'toggle',
                        name = 'Prioritise Raiders over Alts',
                        desc = 'Give priority to guild ranks for raiders over any Alts currently in the raid group.',
                        width = 1.5,
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.Alts end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.refineAlts = val
							end
                        end,
                    },
                    lockPrioritiesDuringRaid = {
                        order = 62,
                        type = 'toggle',
                        name = 'Stop people changing priorities during an active raid',
                        desc = 'Give priority to guild ranks for raiders over any Alts currently in the raid group.',
                        width = 2,
                        disabled = function() return (not iAmTheGM and not iAmTheLootManager and not self.PLdb.char.testMode ) end,
						get = function(info) return self.PLdb.char.lockPrioritiesDuringRaid end,
                        set = function(info, val)
                            if iAmTheGM or iAmTheLootManager then 
                                self.PLdb.char.lockPrioritiesDuringRaid = val
                                addon:configUpdate()
							end
                        end,
                    },
  
                },
            }
end

function addon:addDataOptions(theOrder)
            self.options.args.data = {
                name = "Data",
                type = "group",
                childGroups = "tab",
                order = theOrder,
                args = {
                    space = {
                        name = " ",
                        type = "description",
                        order = 1,
                        width = "full",
                    },
                    heading1 = {
                        name =  "DATA:  Manage Data (Boss / Loot table) and view message logs",
                        type = "description",
                        order = 1.1,
                        width = "full",
                    },
                },
            }
end

function addon:addTabsToOptionsData() 

    self.options.args.data.args.bosses = {
        name = "Boss names",
        type = "group",
        order = 3,
        args = {
            space = {
                name = " ",
                type = "description",
                order = 50,
                width = "full",
            },
            h2 = {
                type = 'header',
                name = 'Add bosses',
                order = 2,
            },
        }
    }

    self.options.args.data.args.lootItems = {
        name = "Boss loot table",
        order = 60,

        type = "group",
        args = {
            h1 = {
                type = 'header',
                name = 'Add loot items',
                order = 2,
            },
        }
    }

    self.options.args.data.args.messageLogs = {
        name = "Message logs",
        order = 70,

        type = "group",
        args = {
            h1 = {
                type = 'header',
                name = 'Message Logs',
                order = 2,
            },
        }
    }

end

function addon:addOtherOptions(theOrder)
            self.options.args.other = {
                name = "Other",
                type = "group",
                childGroups = "tab",
                order = theOrder,
                args = {
                    space = {
                        name = " ",
                        type = "description",
                        order = 1,
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
                    useDevToolAddon = {
                        type = 'toggle',
                        name = 'Do you want to output debugging to DevTool',
                        desc = 'You have the "DevTool" addon for debugging installed and configured and want to use it.',
                        width = 'full',
                        hidden = function() 
                                    local loaded = false
                                    loaded , _ = C_AddOns.IsAddOnLoaded("DevTool") 
                                    return not loaded
                                    end,
                        get = function() return self.PLdb.profile.useDevToolAddon end,
                        set = function(info, value) 
                                self.PLdb.profile.useDevToolAddon = value 
                                end,
                        order = 36,
                    },
                    doYouWantToDebug = {
                        type = 'toggle',
                        name = 'Do you want to show debugging output ?',
                        desc = 'You have the "DevTool" addon for debugging installed and configured.',
                        get = function() return self.PLdb.profile.doYouWantToDebug end,
                        set = function(info, value) self.PLdb.profile.doYouWantToDebug = value end,
                        width = 'full',
                        order = 37,
                    },
                    useTestData = {
                        type = 'toggle',
                        name = 'Do you want to use test data ?',
                        desc = 'Do you want to short circuit the messages for debugging and see what is happening?',
                        get = function() return self.PLdb.profile.useTestData end,
                        set = function(info, value) self.PLdb.profile.useTestData = value end,
                        width = 'full',
                        order = 37,
                    },
                    spaceSettingsd = {
                        order = 38,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    h4 = {
                    type = 'header',
                    name = 'Data Management Functions',
                    order = 40,
                    },
                    spaceSettingsE = {
                        order = 40.5,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    wipeGuild = {
				        order = 42,
				        type = "execute",
                        name = "Clear and rebuild Guild data",
                        width = 2,
                        func = function()
                            wipe(addon.PLdb.char.guildMembers) 
						    loadGuildMembers()
					    end,
                    },
                    wipeMyData = {
				        order = 42,
				        type = "execute",
                        name = "Clear all my characters data",
                        width = 2,
                        func = function()
                            table.remove(addon.PLdb.char.playerSelections, 1)
                            addon.PLdb.char.myClassID = ""
                            addon.PLdb.char.myArmourType = 0
                            addon.PLdb.char.myTierGroup = 0
                            addon.PLdb.char.myArmourType = "D"           
                            addon.PLdb.char.myGuildName = "Default"
                            addon.PLdb.char.myGuildRealm = "Default"
						    checkIExist()       
					    end,
                    },
                    h5 = {
                        type = 'header',
                        name = 'Loot Manager Functions',
                        order = 50,
                         hidden = function() 
						            if iAmTheGM or iAmTheLootManager or self.PLdb.char.testMode then 
							            return false 
						            else
                                        return true
						            end
						        end,
                    },
                    spaceSettingsE = {
                        order = 51,
                        name = " ",
                        type = "description",
                        width = "full",
                    },
                    setLootRollStateOn = {
				        order = 52,
				        type = "execute",
                        name = "Turn on Loot Rolls",
                        width = 1,
                        disabled = function ()
					                return thisAddon.priorityLootRollsActive
                                end,
                        hidden = function() 
						            if iAmTheGM or iAmTheLootManager or self.PLdb.char.testMode then 
							            return false 
						            else
                                        return true
						            end
						        end,
                        func = function()
                                    if iAmTheGM or iAmTheLootManager then 
                                        addon:updateLootRollStatus(true)
							        end
					            end,
                    },
                    setLootRollStateOff = {
				        order = 53,
				        type = "execute",
                        name = "Turn off Loot Rolls",
                        width = 1,
                        disabled = function ()
					                return not thisAddon.priorityLootRollsActive
                                end,
                        hidden = function() 
						        if iAmTheGM or iAmTheLootManager or self.PLdb.char.testMode then 
							        return false 
						        else
                                    return true
						        end
						        end,
                        func = function()
                            if iAmTheGM or iAmTheLootManager then 
                                addon:updateLootRollStatus(false)
                            end
					        end,
                    },
                    spaceSettingsE = {
                        order = 54,
                        name = " ",
                        type = "description",
                        width = "1.5",
                    },
                    sendPL_CONFIG_UPDATE = {
				        order = 55,
				        type = "execute",
                        name = "Send configuration update to all",
                        width = 2,
                        hidden = function() 
						            if iAmTheGM or iAmTheLootManager or self.PLdb.char.testMode then 
							            return false 
						            else
                                        return true
						            end
						        end,
                        func = function()
                                if iAmTheGM or iAmTheLootManager then 
                                    addon:buildPL_CONFIG_UPDATE("All")
						        end
					        end,
	                },
                },
            }
end

function addon:getLogoName()
    -- util.Colorize("Addon Version: ").."0.5 \n"..util.Colorize("Settings: ")..tostring(self.PLdb.char.configVersion).." \n" ..util.Colorize("Test mode: ")..string.upper(tostring(self.PLdb.char.testMode)).."\n",

	local appVersion = util.Colorize("Addon Version: ")..version.." \n"
    local configVersion = util.Colorize("Settings version: ")..tostring(self.PLdb.char.configVersion).."\n"
    local configMode = util.Colorize("Checkbox: ").."indicates test mode status\n"

    return appVersion..configVersion..configMode
	
end

function addon:Options()
local counter = 0

    -- populate the tabs with stuff
    self.options = {
        name = MyAddOnName,
        type = "group",
        plugins = { profiles = { profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.PLdb) } },
        childGroups = "tab",
        args = {
            logo1 = {
                order = 1,
                type = "description",
                name = "",
                fontSize = "medium",
                image = "Interface\\AddOns\\PriorityLoot\\Media\\Textures\\logo_transparent",
                imageWidth = 64,
                imageHeight = 64,
                width = 0.4,
            },
            logo2 = {
                order = 1,
                name = util.Colorize("Priority Loot"),
                type = "toggle",
                desc = addon:getLogoName(),
                descStyle = "inline",
                width = 2,
                get = function(info) return self.PLdb.char.testMode end,
                set = function(info, val)
                    self.PLdb.char.testMode = val
                    self.options.args.logo2.desc = addon:getLogoName()
                end,
            },

        },
    }

    self:addBaseOptions(100)
    self:addTabsToOptionsBase()
    self:addRuleOptions(200)
    -- self:addDataOptions(300)
    -- self:addTabsToOptionsData()

    self:addOtherOptions(400)
 

    -- Main options dialog.
    AceConfig:RegisterOptionsTable(MyAddOnName, self.options)
    ACR:RegisterOptionsTable(MyAddOnName, self.options)
    ACD:SetDefaultSize(MyAddOnName, 635, 730)


    -------------------------------------------------------------------
    -- Create a simple blizzard options panel to direct users to "/PL"
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


