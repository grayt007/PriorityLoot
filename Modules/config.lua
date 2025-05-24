local MyAddOnName,NS = ...
local addon = _G[MyAddOnName]
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT

--Runs in application namespace
setfenv(1, addon)

-- Determines where that data is stored for the account

charConfig = {
    -------------------------- This is set and updated by the Loot Manager ------------------------
    ------------ position 1 = A,2=B,3=C,4=D, see bottom filter settings for armour class ----------
	myArmourType = "D",           
    myClassID = 1,
    myTierGroup = 0,
    myArmourType = 0,
    myGuildName = "Default",
    myGuildRealm = "Default",
    
    lastConfigCheck = 0,
    testMode = true,
    officerList = {},
    guildOtherRanks = {5,6}, 

    -------------------------------------- PRIORITY LOOT SETTINGS ---------------------------------
    ----- This is set and updated by the Loot Manager ------
    configVersion = 1,
    guildLootManager = "Synergised-Nagrand",
    guildOfficerRanks = {0,1,2,"-","-","-","-","-","-","-","-"},
    guildRaidRanks = {0,1,2,3,4,5,6,"-","-","-"},
    numberOfPriorities = 12,
    refineSuicide = true,
    refineItemLevel = false,
    refineItemLevelRange = 0,
    refineGuildRank = true,
    refineAlts = false,
    lockPrioritiesDuringRaid = false,
    includeWeapons = true,
    includeArmour = true,
    includeTrinkets = true,
    includeJewelery = true,
    includeTier = true,


    --[[------------------------------------ GUILD MEMBER DATA ---------------------------------
            unitName = the character name
            unitRank = the guild rank
            memberClass = class
            armourType = their armour type
            tierGroup = their tier token group
	        hasAddon = the version
	        configVersion = the version of the  configuration settings
            lastCheck = last time the configuration was checked
            online = are they online or offline
    ]]--
    guildMembers = {},      
    
    --[[---------------------------------- Player Priorities ---------------------------------
            enter player selection data format here
    ]]--
    playerSelections = {
	},

    hashPH = "",
    currentDbVersion = 2,

}

profileConfig = {

    -------------------------------------- DEBUGGING ---------------------------------
    doYouWantToDebug = false,
    doYouHaveDevTool = false,
    doYouWantDetailedDebug = false,
    doYouWantToDebugMessages = false,
    useTestData = false,

    -------------------------------------- GLOBAL GUI ---------------------------------
    fontName = STANDARD_TEXT_FONT, 
    fontHeight = 11, 
    fontColor = {1,1,1},
		
    -------------------------------------- GENERAL GUI ---------------------------------
    welcomeMessage = true,
    welcomeImage = true,
    welcomeChat = false,
    minimap = { hide = false,
	            icon = "Interface\\AddOns\\PriorityLoot\\Media\\Textures\\logo",
	           },
    setFrameWidth = 1050,
    setFilterWidth = 200,


    filterSettings = {
	    displayGuildNames = true,
        displayMeFirst = true,
        displayOnlyMyItems = false,
        myClassOnly = false,
        myTierOnly = false,
        myArmourOnly = false,
        defaultRaid = 1273,
        defaultBoss = 2,	
        currentFilter = {"-","-","-","-","-","F","G","H","I","J","K","L"}, 
	},
    -------------------------------------- GUI DEFAULTS ---------------------------------
    GUI = {
        nameLeftMarginTop = -5,
        nameLeftMarginBottom = -30,
        displayMaxPlayers = 15,
        scrollPLayerNumber = 5,
        point = "CENTER",
		xPos = 0,
		yPos = 0,
        width = 500,
        height = 400,
        itemHeight = 48,
        scale = 1,
        trimText = false,
        maxTextAmount = 30,
        font = "Arial Narrow",
        fontSize = 14,
        fontFlags = "",
        iconZoom = true,
        border = true,
        protection = false,
        protectionTimer = 3,
	},


}

globalConfig = {

    -------------------------- This is set and updated by the Loot Manager ------------------------
    -- configVersion must be first
    configFieldsToSend = {
        "configVersion",
        "guildLootManager",
        "guildOfficerRanks",
        "guildRaidRanks",
        "numberOfPriorities",
        "refineSuicide",
        "refineItemLevel",
        "refineItemLevelRange",
        "refineGuildRank",
        "refineAlts",
        "lockPrioritiesDuringRaid",
        "includeWeapons",
        "includeArmour",
        "includeTrinkets",
        "includeJewelery",
        "includeTier",
	},

    -------------------------------------- BOSS LOOT TABLES ---------------------------------
    bossLoot = {
    {
        bossId = "225822",
		bossName = "Vexie and the Geargrinders",
        lootItems = {
            {"228861", "Tune-Up Toolbelt"},
            {"228865", "Pit Doctor's Petticoat"},
            {"228875", "Vandal's Skullplating"},
            {"228876", "Dragster's Last Stride"},
            {"228852", "Blazer of Glory"},
            {"228862", "Shrapnel-Ridden Sabatons"},
            {"228858", "Fullthrottle Facerig"},
            {"228868", "Revved-Up Vambraces"},
            {"228839", "Undercircuit Racing Flag"},
            {"231268", "Blastfurious Machete"},
            {"228892", "Greasemonkey's Shift-Stick"},
            {"230197", "Geargrinder's Spare Keys"},
            {"230019", "Vexie's Pit Whistle"}
        }
    },
    {
        bossId = "229181",
		bossName = "Cauldron of Carnage",
        lootItems = {
            {"228847", "Hotstep Heel-Turners"},
            {"228856", "Competitor's Battle Cord"},
            {"228846", "Galvanic Graffiti Cuffs"},
            {"228873", "Heaviestweight Title Belt"},
            {"228840", "Faded Championship Ring"},
            {"228904", "Crowd Favorite"},
            {"228900", "Tournament Arc"},
            {"228890", "Superfan's Beater-Buzzer"},
            {"230191", "Flarendo's Pilot Light"},
            {"230190", "Torq's Big Red Button"},
            {"228803", "Dreadful Bloody Gallybux"},
            {"228804", "Mystic Bloody Gallybux"},
            {"228805", "Venerated Bloody Gallybux"},
            {"228806", "Zenith Bloody Gallybux"}
        }
    },
    {
        bossId = "228652",
		bossName = "Rick Reverb",
        lootItems = {
            {"228857", "Underparty Admission Bracelet"},
            {"228869", "Killer Queen's Wristflickers"},
            {"228845", "Sash of the Fierce Diva"},
            {"228874", "Rik's Walkin' Boots"},
            {"228841", "Semi-Charmed Amulet"},
            {"228897", "Pyrotechnic Needle-Dropper"},
            {"228895", "Remixed Ignition Saber"},
            {"231311", "Frontman's Wondrous Wall"},
            {"230194", "Reverb Radio"},
            {"228815", "Dreadful Polished Gallybux"},
            {"228816", "Mystic Polished Gallybux"},
            {"228817", "Venerated Polished Gallybux"},
            {"228818", "Zenith Polished Gallybux"}
        }
    },
    {
        bossId = "230322",
		bossName = "Stix Bunkjunker",
        lootItems = {
            {"228871", "Cleanup Crew's Wastemask"},
            {"228854", "Bilgerat's Discarded Slacks"},
            {"228859", "Sanitized Scraphood"},
            {"228849", "Dumpmech Compactors"},
            {"228896", "Stix's Metal Detector"},
            {"228903", "Dumpster Diver"},
            {"230189", "Junkmaestro's Mega Magnet"},
            {"230026", "Scrapfield 9001"},
            {"228811", "Dreadful Rusty Gallybux"},
            {"228812", "Mystic Rusty Gallybux"},
            {"228813", "Venerated Rusty Gallybux"},
            {"228814", "Zenith Rusty Gallybux"}
        }
    },
    {
        bossId = "230583",
		bossName = "Sprocketmonger Lockenstock",
        lootItems = {
            {"228882", "Refiner's Conveyor Belt"},
            {"228888", "Rushed Beta Launchers"},
            {"228867", "Gravi-Gunk Handlers"},
            {"228884", "Test Subject's Clasps"},
            {"228844", "Test Pilot's Go-Pack"},
            {"228894", "GIGADEATH Chainblade"},
            {"228898", "Alphacoil Ba-Boom Stick"},
            {"230193", "Mister Lock-N-Stalk"},
            {"230186", "Mister Pick-Me-Up"},
            {"228799", "Dreadful Greased Gallybux"},
            {"228800", "Mystic Greased Gallybux"},
            {"228801", "Venerated Greased Gallybux"},
            {"228802", "Zenith Greased Gallybux"}
        }
    },
    {
        bossId = "228458",
		bossName = "The One-Armed Bandit",
        lootItems = {
            {"228850", "Bottom-Dollar Blouse"},
            {"228885", "Hustler's Ante-Uppers"},
            {"228883", "Dubious Table-Runners"},
            {"228886", "Coin-Operated Girdle"},
            {"228843", "Miniature Roulette Wheel"},
            {"231266", "Random Number Perforator"},
            {"228905", "Giga Bank-Breaker"},
            {"232526", "Best-in-Slots"},
            {"230188", "Gallagio Bottle Service"},
            {"230027", "House of Cards"},
            {"228807", "Dreadful Gilded Gallybux"},
            {"228808", "Mystic Gilded Gallybux"},
            {"228809", "Venerated Gilded Gallybux"},
            {"228810", "Zenith Gilded Gallybux"}
        }
    },
    {
        bossId = "229953",
		bossName = "Mug'Zee",
        lootItems = {
            {"228870", "Underboss's Tailored Mantle"},
            {"228879", "Cemented Murloc-Swimmers"},
            {"228863", "Enforcer's Sticky Fingers"},
            {"228880", "Hitman's Holster"},
            {"228860", "Epaulettes of Failed Enforcers"},
            {"228878", "Made Manacles"},
            {"228851", '"Bullet-Proof" Vestplate'},
            {"228853", "Hired Muscle's Legguards"},
            {"228842", "Gobfather's Gifted Bling"},
            {"232804", "Capo's Molten Knuckles"},
            {"228901", "Big Earner's Bludgeon"},
            {"228902", "Wiseguy's Refused Offer"},
            {"228893", "Tiny Pal"},
            {"230192", "Mug's Moxie Jug"},
            {"230199", "Zee's Thug Hotline"}
        }
    },
    {
        bossId = "239651",
		bossName = "Chrome King Gallywix",
        lootItems = {
            {"228881", "Illicit Bankroll Bracers"},
            {"228872", "Golden Handshakers"},
            {"228848", "Darkfuse Racketeer's Tricorne"},
            {"228864", "Streamlined Cartel Uniform"},
            {"228877", "Dealer's Covetous Chain"},
            {"228866", "Deep-Pocketed Pantaloons"},
            {"228855", "Paydirt Pauldrons"},
            {"228887", "Cutthroat Competition Stompers"},
            {"231265", "The Jastor Diamond"},
            {"228899", "Gallywix's Iron Thumb"},
            {"228891", "Capital Punisher"},
            {"228889", "Titan of Industry"},
            {"230029", "Chromebustible Bomb Suit"},
            {"230198", "Eye of Kezan"},
            {"228819", "Excessively Bejeweled Curio"}
        },
    },
},
    
    -------------------------------------- TIER TOKEN GROUPS ---------------------------------
    -- This table must be in class order e.g. warrior is class one so its first
    -- table:  className, tierTokenGroup, armourType
	classInfo = {
	   {"WARRIOR",3,"D"},
	   {"PALADIN",2,"D"},
       {"HUNTER",1,"C"},
	   {"ROGUE",3,"B"},
	   {"PRIEST",2,"A"},
	   {"DEATHKNIGHT",4,"D"},
	   {"SHAMAN",2,"C"},
	   {"MAGE",1,"A"},
	   {"WARLOCK",4,"A"},
	   {"MONK",3,"B"},
       {"DRUID",1,"B"},
	   {"DEMONHUNTER",4,"B"},
	   {"EVOKER",3,"C"},
        },

    tierGroupNames = {"Dreadful","Bloody","Mystic","Venerated","Zenith"},
	
	-- Tier token by group including the "anytoken" from the last boss
	tierTokenID = {
            {tierGroup = 1,tokenIDTable = {"228799","228804","228807","228811","228815","228819"}},
	        {tierGroup = 2,tokenIDTable = {"228800","228805","228807","228812","228816","228819"}},
            {tierGroup = 3,tokenIDTable = {"228801","228806","228808","228813","228817","228819"}},
	        {tierGroup = 4,tokenIDTable = {"228802","228807","228809","228814","228818","228819"}},
	        },
	
	--[[------------------------------------ FILTER SETUP AND MANAGEMENT ---------------------------------

    Equipment Type for filterColumnElements
	ID="E" is "Armour"                ID="F" is "Trinkets"
	ID="G" is "Jewelery"              ID="H" is "Weapons (1H)"
    ID="I" is "Weapons (2H)"          ID="J" is "Offhand"
    ID="K" is "Ranged"              

    ID="L" is Tier Tokens

    --]]

    LootItemSubType = {
	    {"INVTYPE_HEAD","Head","E"},
        {"INVTYPE_NECK","Neck","G"},
        {"INVTYPE_SHOULDER","Shoulder","E"},
        {"INVTYPE_CHEST","Chest","E"},
        {"INVTYPE_ROBE","Chest","E"},
        {"INVTYPE_WAIST","Waist","E"},
        {"INVTYPE_LEGS","Legs","E"},
        {"INVTYPE_FEET","Feet","E"},
        {"INVTYPE_WRIST","Wrist","E"},
        {"INVTYPE_HAND","Hands","E"},
        {"INVTYPE_FINGER","Finger","G"},
        {"INVTYPE_TRINKET","Trinket","F"},
        {"INVTYPE_CLOAK","Cloak","E"},
        {"INVTYPE_WEAPON","One-Hand","J"},
        {"INVTYPE_SHIELD","Shield","J"},
        {"INVTYPE_2HWEAPON","Two-Handed","I"},
        {"INVTYPE_WEAPONMAINHAND","Main-Hand","H"},
        {"INVTYPE_WEAPONOFFHAND","Weapon","J"},
        {"INVTYPE_HOLDABLE","Off-Hand","J"},
        {"INVTYPE_RANGED","Bows","K"},
        {"INVTYPE_THROWN","Ranged","K"},
        {"INVTYPE_RANGEDRIGHT","Ranged","K"},
        {"INVTYPE_RELIC","RangedRelic","K"},
        {"INVTYPE_NON_EQUIP_IGNORE","Tier Token","L"},
    },
	
    filterArmourType = {
		{"A","Cloth"},
		{"B","Leather"},
        {"C","Mail"},
        {"D","Plate"},
		},

		
     --[[
     This table allow the generation of the filter boxes.  Should probably replace with plain code in the future
	    Type: 
	    "H" for Heading and 
	    "C" for checkbox 
	    "S" for spacer
	 
	 ID is used to filter the records so each item that is a filter needs unique character
	 position allows you to refer to the checkbox from other code thisAddon.checkboxList[position]
	 Name is what is displayed
     You can set the "group" to allow one checkbox to control others regardless of the  creation order
     --]]

    filterColumnElements = {
	    
		{
        type="S",
		position=0,
		ID="",
		group="",
		name="",
		},
		{
		type="H",
		position=0,
		ID="",
        group="",
		name="Equipment Type",
		},
		{
		type="C",
		position=6,
		ID="F",
        group="",
		name="Trinkets",
		},
		{
		type="C",
		position=7,
		ID="G",
		group="",
			name="Jewelery",
		},
		{
		type="C",
		position=8,
		ID="H",
		group="",
		name="1H Weapon",
		},
        {
		type="C",
		position=9,
		ID="I",
		group="",
		name="2H Weapon",
		},
        {
		type="C",
		position=10,
		ID="J",
		group="",
		name="Offhand",
		},
        {
		type="C",
		position=11,
		ID="K",
		group="",
		name="Ranged",
		},
        {
		type="C",
		position=12,
		ID="L",
		group="",
		name="Tier Token",
		},
  --      {
		--type="C",
		--position=5,
		--ID="E",
		--group="AA",
		--name="Armour",
		--},
		{
        type="S",
		position=0,
		ID="",
		group="",
		name="",
		},
		{
        type="H",
		position=0,
		ID="",
		group="",
		name="Armour Type",
		},
		{
		type="C",
		position=1,
		ID="A",
		group="A",
		name="Cloth",
		},
		{
		type="C",
		position=2,
		ID="B",
		group="A",
		name="Leather",
	    },
		{
        type="C",
		position=3,
		ID="C",
		group="A",
		name="Mail",
		},
		{
		type="C",
		position=4,
		ID="D",
		group="A",
		name="Plate",
		},
 		{
        type="S",
		position=0,
		ID="",
		group="",
		name="",
		},

    },


--[[

GetSpecializationInfo(} - The prioritySpecsNew is class and the spec number (SPEC 1, SPEC 2, SPEC 3, SPEC 4) that we want NOT the specID (250,268 etc) as shown below.

CLASS           SPEC 1              SPEC 2              SPEC 3              SPEC 4
---------------------------------------------------------------------------------------------
DEATHKNIGHT 	250 Blood 	        251 Frost 	        252 Unholy
DEMONHUNTER 	577 Havoc 	        581 Vengeance 
DRUID           102 Balance 	    103 Feral 	        104 Guardian 	    105 Restoration
EVOKER 	        1467 Devastation 	1468 Preservation 	1473 Augmentation
HUNTER 	        253 Beast Mastery 	254 Marksmanship 	255 Survival
MAGE 	        62  Arcane 	        63 	Fire 	        64 	Frost
MONK 	        268 Brewmaster 	    270 Mistweaver 	    269 Windwalker
PALADIN 	    65 	Holy 	        66 	Protection 	    70 	Retribution
PRIEST 	        256 Discipline 	    257 Holy 	        258 Shadow
Rogue 	        259 Assassination 	260 Outlaw 	        261 Subtlety
SHAMAN 	        262 Elemental 	    263 Enhancement     264 Restoration 
WARLOCK 	    265 Affliction 	    266 Demonology 	    267 Destruction
WARRIOR 	    71 	Arms 	        72 	   Fury 	    73 	Protection 	
]]--

}

--[[
Database version migration logic.

migrationPaths = { [dbVersion] = function(config) ... end, }

dbVersion is an incremented integer.

Functions should update config in-place to update from the previous integer
version.  Updates are automatically cascaded across multiple versions when
needed.
]]--

migrationPaths = {

	[2] = function(config)
            local guildOtherRanks as "Default"
    		table.insert(addon.PLdb.profile.config, guildOtherRanks)
            print("Config database upgrades to version 4")
    	end,
}

