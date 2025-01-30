local MyAddOnName,NS = ...
local addon = _G[MyAddOnName]
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT

--Runs in application namespace
setfenv(1, addon)

defaultConfig = {

    -- General configuration options for hte options page

    --Applies to all text
        fontName = STANDARD_TEXT_FONT, 
        fontHeight = 11, 
        fontColor = {1,1,1},
		
    -- General configuration Settings
    doYouHaveDevTool = true,
    doYouWantToDebug = true,
    useTestData = true,


    welcomeMessage = true,
    welcomeMessage2 = false,
    welcomeChat = true,
    minimap = {hide = false, },

    listMeFirst = true, -- List me first in the loot window


    --Processing and efficiency
    updateInterval = 0.1,

    LootList = {},
    -- Test data
    guildTestData = {"Fire","Hex","Hazel","Leafy","Holy","Trixter","Hunter","Trippy","Tay","BigNamePlayer"},
    raidTestData = {"Raid1","Hex","Raid2","Leafy","Raid3","Trixter","Raid4","Trippy","Raid5","Raid boss"},


    -- The addon will only manage the current seasons raids
    raids = 
	{
        {
        raidId = "1273",
        raidName = "Nerub-ar Palace",
        raidBosses = 
            {
            {bossId = "*",bossName="All"},
            {bossId = "2607",bossName="Ulgrax the Devourer"},
            {bossId = "2611",bossName="The Bloodbound Horror"}, 
            {bossId = "2599",bossName="Sikran, Captain of the Sureki"},
            {bossId = "2609",bossName="Rasha'nan"},
            {bossId = "2612",bossName="Broodtwister Ovi'nax"},
            {bossId = "2601",bossName="Nexus-Princess Ky'veza"},
            {bossId = "2608",bossName="The Silken Court"},
            {bossId = "2602",bossName="Queen Ansurek"},
			},
		},
		{
		raidId = "1007",
        raidName = "The big Raid",
        raidBosses = 
            {
            {bossId = "*",bossName="All"},
            {bossId = "10071",bossName="Big Boss One"},
            {bossId = "10072",bossName="Big Boss Two"},
			{bossId = "10073",bossName="Big Boss Three"},
			{bossId = "10074",bossName="Big Boss Four"},
			},
    	},
	},              -- List of raids
	
    -- Is this needed any more its now in the raid list ??
    bosses = {
	    {"1273",
            {"2607","Ulgrax the Devourer"},
            {"2611","The Bloodbound Horror"}, 
            {"2599","Sikran, Captain of the Sureki"},
            {"2609","Rasha'nan"},
            {"2612","Broodtwister Ovi'nax"},
            {"2601","Nexus-Princess Ky'veza"},
            {"2608","The Silken Court"},
            {"2602","Queen Ansurek"},
		},
		{"1",
		    {"101","AAAA"},
			{"101","AAAA"},
			{"101","AAAA"},
		},
	},	

    -- lastUpdate = C_DateAndTime.GetServerTimeLocal()  e.g. realm time as one number in seconds
    playerSelections = {
        {
		player = "Fire-Nagrand",
        lastUpdate = 12345,
        playerLoot =
		    {
            {itemId="212386", rank=1},
            {itemId="212388", rank=2},
            {itemId="212409", rank=3},
			},
        },
        {
		player = "Pheoniix-Nagrand",
        lastUpdate = 12345,
		playerLoot =
		    {
            {itemId="212386", rank=2},
            {itemId="212388", rank=1},
            {itemId="212409", rank=0},
			},
        },
		{
        player = "Hex-Nagrand",
        lastUpdate = 12345,
		playerLoot =
		    {
            {itemId="212409", rank=1},
            {itemId="219915", rank=2},
            {itemId="212442", rank=0},
			},
        },
	},

    -- https://www.wowinterface.com/forums/showthread.php?t=53806
    -- https://warcraftdb.com/live/the-war-within/nerubar-palace/loot#raid-heroic

    bossLoot = {
        {
		bossId = "2607",
        lootItems=
            {
                {"212386","Husk of Swallowing Darkness"},
                {"212388","Ulgrax's Morsel-Masher"},
                {"212409","Venom-Etched Claw"},
                {"212419","Bile-Soaked Harness"},
                {"212423","Rebel's Drained Marrowslacks"},
                {"212424","Seasoned Earthen Boulderplates"},
                {"212425","Devourer's Taut Innards"},
                {"212426","Crunchy Intruder's Wristband"},
                {"212428","Final Meal's Horns"},
                {"212431","Undermoth-Lined Footpads"},
                {"212442","Greatbelt of the Hungerer"},
                {"212446","Royal Emblem of Nerub-ar"},
                {"219915","Foul Behemoth's Chelicera"},
            },
	    },
	    {
		bossId = "9999",
        lootItems=
            {
                {"212387","Broodtwister's Grim Catalyst"},
                {"212389","Spire of Transfused Horrors"},
                {"212391","Predator's Feasthooks"},
                {"212392","Duelist's Dancing Steel"},
                {"212394","Sovereign's Disdain"},
                {"212395","Blood-Kissed Kukri"},
                {"212397","Takazj's Entropic Edict"},
                {"212398","Bludgeons of Blistering Wind"},
                {"212399","Splintershot Silkbow"},
                {"212400","Shade-Touched Silencer"},
                {"212401","Ansurek's Final Judgment"},
                {"212404","Scepter of Manifested Miasma"},
                {"212405","Flawless Phase Blade"},
                {"212407","Anub'arash's Colossal Mandible"},
                {"212413","Honored Executioner's Perforator"},
                {"212414","Lost Watcher's Remains"},
                {"212415","Throne Defender's Bangles"},
                {"212416","Cosmic-Tinged Treads"},
                {"212417","Beyond's Dark Visage"},
                {"212418","Black Blood Injectors"},
                {"212420","Queensguard Carapace"},
                {"212421","Goresplattered Membrane"},
                {"212422","Bloodbound Horror's Legplates"},
                {"212427","Visor of the Ascended Captain"},
                {"212429","Whispering Voidlight Spaulders"},
                {"212430","Shattered Eye Cincture"},
                {"212432","Thousand-Scar Impalers"},
                {"212433","Omnivore's Venomous Camouflage"},
                {"212434","Voidspoken Sarong"},
                {"212435","Liquified Defector's Leggings"},
                {"212436","Clutches of Paranoia"},
                {"212437","Ravaged Lamplighter's Manacles"},
                {"212438","Polluted Spectre's Wraps"},
                {"212439","Beacons of the False Dawn"},
                {"212440","Devotee's Discarded Headdress"},
                {"212441","Bindings of the Starless Night"},
                {"212443","Shattershell Greaves"},
                {"212444","Frame of Felled Insurgents"},
                {"212445","Chitin-Spiked Jackboots"},
                {"212447","Key to the Unseeming"},
                {"212448","Locket of Broken Memories"},
                {"212449","Sikran's Endless Arsenal"},
                {"212450","Swarmlord's Authority"},
                {"212451","Aberrant Spellforge"},
                {"212452","Gruesome Syringe"},
                {"212453","Skyterror's Corrosive Organ"},
                {"212454","Mad Queen's Mandate"},
                {"212456","Void Reaper's Contract"},
                {"219877","Void Reaper's Warp Blade"},
                {"219917","Creeping Coagulum"},
                {"220202","Spymaster's Web"},
                {"220305","Ovi'nax's Mercurial Egg"},
                {"221023","Treacherous Transmitter"},
                {"225574","Wings of Shattered Sorrow"},
                {"225575","Silken Advisor's Favor"},
                {"225576","Writhing Ringworm"},
                {"225577","Sureki Zealot's Insignia"},
                {"225578","Seal of the Poisoned Pact"},
                {"225579","Crest of the Caustic Despot"},
                {"225580","Accelerated Ascension Coil"},
                {"225581","Ky'veza's Covert Clasps"},
                {"225582","Assimilated Eggshell Slippers"},
                {"225583","Behemoth's Eroded Cinch"},
                {"225584","Skeinspinner's Duplicitous Cuffs"},
                {"225585","Acrid Ascendant's Sash"},
                {"225586","Rasha'nan's Grotesque Talons"},
                {"225587","Devoted Offering's Irons"},
                {"225588","Sanguine Experiment's Bandages"},
                {"225589","Nether Bounty's Greatbelt"},
                {"225590","Boots of the Black Bulwark"},
                {"225591","Fleeting Massacre Footpads"},
                {"225636","Regicide"},
                {"225720","Web Acolyte's Hood"},
                {"225721","Prime Slime Slippers"},
                {"225722","Adorned Lynxborne Pauldrons"},
                {"225723","Venom Stalker's Strap"},
                {"225724","Shrillwing Hunter's Prey"},
                {"225725","Lurking Marauder's Binding"},
                {"225727","Captured Earthen's Ironhorns"},
                {"225728","Acidic Attendant's Loop"},
                {"225744","Heritage Militia's Stompers"},

		    },
	    },
    },

    -------------------------------------- FILTER SETUP AND MANAGEMENT ---------------------------------

    -- Equipment Type for filterColumnElements
	--ID="E" is "Armour"                ID="F" is "Trinkets"
	--ID="G" is "Jewelery"              ID="H" is "Weapons (1H)"
    --ID="I" is "Weapons (2H)"          ID="J" is "Offhand"
    --ID="K" is "Ranged"
    LootItemSubType = 
	{
	    {"INVTYPE_HEAD","Head","E"},
        {"INVTYPE_NECK","Neck","H"},
        {"INVTYPE_SHOULDER","Shoulder","E"},
        {"INVTYPE_CHEST","Chest","E"},
        {"INVTYPE_ROBE","Chest","E"},
        {"INVTYPE_WAIST","Waist","E"},
        {"INVTYPE_LEGS","Legs","E"},
        {"INVTYPE_FEET","Feet","E"},
        {"INVTYPE_WRIST","Wrist","E"},
        {"INVTYPE_HAND","Hands","E"},
        {"INVTYPE_FINGER","Finger","H"},
        {"INVTYPE_TRINKET","Trinket","G"},
        {"INVTYPE_CLOAK","Cloak","E"},
        {"INVTYPE_WEAPON","One-Hand","I"},
        {"INVTYPE_SHIELD","Shield","J"},
        {"INVTYPE_2HWEAPON","Two-Handed","F"},
        {"INVTYPE_WEAPONMAINHAND","Main-Hand","I"},
        {"INVTYPE_WEAPONOFFHAND","Weapon","J"},
        {"INVTYPE_HOLDABLE","Off-Hand","J"},
        {"INVTYPE_RANGED","Bows","K"},
        {"INVTYPE_THROWN","Ranged","K"},
        {"INVTYPE_RANGEDRIGHT","Ranged","K"},
        {"INVTYPE_RELIC","RangedRelic","K"},
    },
	
	
	-- Type "H" for Heading and "C" for checkbox 
	-- ID is used to filter the records so each item that is a filter needs unique character
	-- position is a future proofing sort
	-- Name is what is displayed
	
    filterArmourType = {"A","B","C","D"},
	
    filterColumnElements = {
	    {
		type="H",
		position=0,
		ID="",
		name="Armour Type",
		},
		{
		type="C",
		position=1,
		ID="A",
		name="Cloth",
		},
		{
		type="C",
		position=2,
		ID="B",
		name="Leather",
	    },
		{
        type="C",
		position=3,
		ID="C",
		name="Mail",
		},
		{
		type="C",
		position=4,
		ID="D",
		name="Plate",
		},
		{
		type="H",
		position=0,
		ID="",
		name="Equipment Type",
		},
		--{
		--type="C",
		--position=5,
		--ID="E",
		--name="Armour",
		--},
		{
		type="C",
		position=6,
		ID="F",
		name="Trinkets",
		},
		{
		type="C",
		position=7,
		ID="G",
		name="Jewelery",
		},
		{
		type="C",
		position=8,
		ID="H",
		name="Weapons (1H)",
		},
        {
		type="C",
		position=9,
		ID="I",
		name="Weapons (2H)",
		},
        {
		type="C",
		position=10,
		ID="J",
		name="Offhand",
		},
        {
		type="C",
		position=11,
		ID="K",
		name="Ranged",
		},
    },


    filterSettings = {
	    displayGuildNames = false,
        displayMeFirst = true,
        displayOnlyMyItems = false,
        defaultRaid = 1273,
        defaultBoss = 2,	
        currentFilter = {"A","B","C","D","F","G","H","I","J","K"},  -- NO "E" becuase thats arour which is covered by mail, plate etc
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
    [0] = function(config)
    		if config.fontName == "Fonts\\FRIZQT__.TTF" then config.fontName = STANDARD_TEXT_FONT end
    	end,
}

