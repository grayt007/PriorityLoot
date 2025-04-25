local MyAddOnName,NS = ...
local addon = _G[MyAddOnName]
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT

--Runs in application namespace
setfenv(1, addon)

defaultConfig = {

    --Applies to all text
    fontName = STANDARD_TEXT_FONT, 
    fontHeight = 11, 
    fontColor = {1,1,1},
		
    -- General configuration Settings
    welcomeMessage = true,
    welcomeChat = false,
    minimap = {hide = false, },
    setFrameWidth = 1050,
    setFilterWidth = 200,

    -- My deatils
	myArmourType = 1,     -- position 1 = A, 2=B,3=C,4=D - see bottom filter settings
    myClassName = "Default",
    myGuildName = "Default",
    myGuildRealm = "Default",

    --  The settings that will be changed by the Loot Manager via messages between clients
    --  This is iterated to build the update message
        configFieldsToSend = {
        "configVersion",
        "testMode",
        "guildLootManager",
        "guildOfficerRanks",
        "guildRaidRanks",
        "guildOtherRanks",
        "numberOfPriorities",
        "refineSuicide",
        "refineItemLevel",
        "refineItemLevelRange",
        "refineGuildRank",
	},

    -- the fields themselves but they dont have to be in this poistion specifically
    configVersion = 1,
    lastConfigCheck = 0,
    testMode = true,
    guildLootManager = "Default",
    guildOfficerRanks = {0,1,2},
    officerList = {},
    guildRaidRanks = {0,1,4},
    guildOtherRanks = {5,6},-- other ranks that might end up in  raid group but they are not regulars.  e.g. Alts
    numberOfPriorities = 12,
    refineSuicide = true,
    refineItemLevel = false,
    refineItemLevelRange = 0,
    refineGuildRank = true,

    listMeFirst = true, 
    guildPriorityLootChannel = "PriorityLoot",

    -- Debugging settings
    doYouWantToDebug = true,
    doYouHaveDevTool = true,
    doYouWantDetailedDebug = false,
    doYouWantToDebugMessages = false,
    useTestData = false,

    --Processing and efficiency
    updateInterval = 0.1,

    -- GUI Defaults
    GUI = {
        nameLeftMargin = -5,
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

    LootList = {},

    guildMembers = {},
    -------------------------------------- PLAYER SELECTION DATA ---------------------------------
    -- lastUpdate = C_DateAndTime.GetServerTimeLocal()  e.g. realm time as one number in seconds
    -- I should always be number one in the array

    priorityHistory = {},
    playerSelections = {
        {
		player = "Jholy-Nagrand",
        version = 3,
        playerLoot =
		    {
            {"228861", 1},
            {"228865", 2},
            {"228875", 3},
            {"228876", 4},
            {"228852", 5},
            {"228862", 6},
            {"228858", 7},
            {"228868", 8},
            {"228839", 9},
            {"228847", 10},

  			},
		},
        {
		player = "Alpine-Barthilas",
        version = 3,
		playerLoot =
		    {
            {"228861", 6},
            {"228865", 5},
            {"228875", 4},
            {"228876", 3},
            {"228840", 2},
            {"228904", 1},
  			},
        },
		{
        player = "Hex-Nagrand",
        version = 1,
		playerLoot =
		    {
            {"228846", 1},
            {"228873", 2},
			},
        },
        {
        player = "Hazel-Nagrand",
        version = 1,
		playerLoot =
		    {
            {"228861", 1},            
            {"228847", 2},
            {"228856", 3},
            {"228846", 4},
            {"228873", 5},
            {"228840", 6},
            {"228904", 7},
            {"228900", 8},
  			},
        },
		{
        player = "Elinthos-Frostmourne",
        version = 1,
		playerLoot =
		    {
            {"228846", 4},
            {"228873", 5},
            {"228840", 6},
            {"228904", 7},
            {"228900", 8},
            {"228861", 1}, 
			},
        },

	},


    -------------------------------------- BOSS LOOT TABLES ---------------------------------
    --[[
	 last time I grabbed the data off wowhead then fed the data into copilot and it converted 
     it to xml e.g. "using this xml format convert this data"
	          bossLoot = {
                   {
	               bossId = "225822",
	               bossName = "the name",
                   lootItems=
                       {
                           {"228861"," Tune-Up Toolbelt"},
                       },
              },
    --]]
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
    

	-------------------------------------- FILTER SETUP AND MANAGEMENT ---------------------------------
	--[[
    Equipment Type for filterColumnElements
	ID="E" is "Armour"                ID="F" is "Trinkets"
	ID="G" is "Jewelery"              ID="H" is "Weapons (1H)"
    ID="I" is "Weapons (2H)"          ID="J" is "Offhand"
    ID="K" is "Ranged"
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
	
    -- A = Cloth, B = leather, C = Mail, D = Plate	
    filterArmourType = {"A","B","C","D"},
	
    filterSettings = {
	    displayGuildNames = true,
        displayMeFirst = true,
        displayOnlyMyItems = false,
        defaultRaid = 1273,
        defaultBoss = 2,	
        currentFilter = {"-","-","-","-","-","F","G","H","I","J","K","L"}, 
		},
     --[[
     Type "H" for Heading and "C" for checkbox 
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
    1	Warrior	        WARRIOR	
    2	Paladin	        PALADIN	
    3	Hunter	        HUNTER	
    4	Rogue	        ROGUE	
    5	Priest	        PRIEST	
    6	Death Knight	DEATHKNIGHT
    7	Shaman	        SHAMAN	
    8	Mage	        MAGE	
    9	Warlock	        WARLOCK	
    10	Monk	        MONK	
    11	Druid	        DRUID	
    12	Demon Hunter	DEMONHUNTER	
    13	Evoker	        EVOKER	

--]]
    classArmour = {

		{class = 1,armour="D"},
		{class = 2,armour="D"},	
        {class = 3,armour="C"},
		{class = 4,armour="B"},
		{class = 5,armour="A"},	
		{class = 6,armour="D"},		
		{class = 7,armour="C"},			
        {class = 8,armour="A"},
		{class = 9,armour="A"},
		{class = 10,armour="B"},
		{class = 11,armour="B"},
		{class = 12,armour="B"},	
		{class = 13,armour="C"},		
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



--[[
Database version migration logic.

migrationPaths = { [dbVersion] = function(config) ... end, }

dbVersion is an incremented integer.

Functions should update config in-place to update from the previous integer
version.  Updates are automatically cascaded across multiple versions when
needed.
]]--

currentDbVersion = 2
}

migrationPaths = {

	[2] = function(config)
            local guildOtherRanks as "Default"
    		table.insert(addon.PLdb.profile.config, guildOtherRanks)
            print("Config database upgrades to version 4")
    	end,
}

