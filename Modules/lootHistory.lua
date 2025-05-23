local AceAddon = LibStub("AceAddon-3.0")
local priorityLoot = AceAddon:GetAddon("PriorityLoot")
local lootHistory = priorityLoot:GetModule("lootHistory", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")

function lootHistory:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("lootHistoryDB", {
    global ={
      ---@type table<string, table> @ A table mapping session IDS to some session Data
      sessions = {},
      ---@type table<string, table<string, table>> @ A table mapping session and encounter IDS to the encounter Data
      encounters = {},
      ---@type table<string, table<string, table<string, table>>> @ A table mapping session, encounter, and drop IDS to the drop Data
      drops = {}
    },
  })

  self.sessions = self.db.global.sessions
  self.encounters = self.db.global.encounters
  self.drops = self.db.global.drops
  self.currentSession = nil
end

function lootHistory:OnEnable()

  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  self:RegisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER")
  self:RegisterEvent("LOOT_HISTORY_UPDATE_DROP")
end

----------------------
-- Event handlers
----------------------

function lootHistory:LOOT_HISTORY_UPDATE_ENCOUNTER(_eventName, encounterID)
  -- self:Print("Loot history updated", encounterID)

  if self.currentSession == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No session, skipping")
    return
  end

  local encounter = C_LootHistory.GetInfoForEncounter(encounterID)

  if encounter == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No encounter found, skipping")
    return
  end

  self:appendEncounterToSession(encounter)
  local drops = C_LootHistory.GetSortedDropsForEncounter(encounterID)

  if drops == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No drops found, skipping")
    return
  end

  for _, drop in ipairs(drops) do
    self:appendDropToEncounter(encounter, drop)
  end
end

function lootHistory:LOOT_HISTORY_UPDATE_DROP(_eventName, encounterID, lootListID)
  -- self:Print("Loot history drop updated", encounterID, lootListID)

  if self.currentSession == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No session, skipping")
    return
  end

  local encounter = C_LootHistory.GetInfoForEncounter(encounterID)

  if encounter == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No encounter found, skipping")
    return
  end

  self:appendEncounterToSession(encounter)

  local info = C_LootHistory.GetSortedInfoForDrop(encounterID, lootListID)

  if info == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No drop found, skipping")
    return
  end

  self:appendDropToEncounter(encounter, info)
end

function lootHistory:PLAYER_ENTERING_WORLD()
  self:updateSessionIfRequired()
end

function lootHistory:ZONE_CHANGED_NEW_AREA()
  self:updateSessionIfRequired()
end

----------------------
-- Utility functions
----------------------

function lootHistory:generateSessionID()
  local playerGUID = UnitGUID("player")  -- Get the player's GUID
  local startTime = GetServerTime()      -- Get the current server time
  local instanceID = select(8, GetInstanceInfo()) or "0"  -- Get the instance ID
  local difficultyID = select(3, GetInstanceInfo()) or "0"  -- Get the difficulty ID
  local sessionID = string.format("%s-%s-%s-%s", playerGUID, startTime, instanceID, difficultyID)
  return sessionID
end

-- Getter for current session
function lootHistory:session()
  if self.currentSession == nil then
    return nil
  else
    return self.sessions[self.currentSession]
  end
end

-- End the current session
function lootHistory:endSession()
  if self.currentSession == nil then
    return
  end

  self:session().endTime = GetServerTime()
  self.currentSession = nil
end

-- Starts a new session and saves it to the data store
function lootHistory:startSession()
  local instanceName, _, difficultyID, difficultyName, _, _, _, instanceID = GetInstanceInfo()

  self.currentSession = self:generateSessionID()
  self.sessions[self.currentSession] = {
    sessionID = self.currentSession,
    instanceID = instanceID,
    instanceName = instanceName,
    difficultID = difficultyID,
    difficultName = difficultyName,
    startTime = GetServerTime(),
  }
end

function lootHistory:updateSessionIfRequired()
  local inInstance, instanceType = IsInInstance()
  local instanceID = select(8, GetInstanceInfo())

  if inInstance and instanceType == "raid" then
    if self.currentSession == nil then
      -- TODO - Settings for addon. Allow logging on
      -- self:Print("Player entering raid, starting session")
      self:startSession()
    elseif self.sessions[self.currentSession].instanceID ~= instanceID then
      -- TODO - Settings for addon. Allow logging on
      -- self:Print("Player shifted instance, starting a new session")
      self:endSession()
      self:startSession()
    end
  elseif inInstance and self.currentSession ~= nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("Player leaving raid, ending session")
    self:endSession()
  end
end

function lootHistory:appendEncounterToSession(encounter)
  if self.currentSession == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No session, skipping")
    return
  end

  local sessionEncounters = self.encounters[self.currentSession]
  if sessionEncounters == nil then
    self.encounters[self.currentSession] = {}
    sessionEncounters = self.encounters[self.currentSession]
  end


  sessionEncounters[encounter.encounterID] = encounter
end

---@param encounter EncounterLootInfo
---@param drop EncounterLootDropInfo
function lootHistory:appendDropToEncounter(encounter, drop)
  if self.currentSession == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No session, skipping")
    return
  end

  local sessionDrops = self.drops[self.currentSession]
  if sessionDrops == nil then
    self.drops[self.currentSession] = {}
    sessionDrops = self.drops[self.currentSession]
  end

  local encounterDrops = sessionDrops[encounter.encounterID]
  if encounterDrops == nil then
    sessionDrops[encounter.encounterID] = {}
    encounterDrops = sessionDrops[encounter.encounterID]
  end

  encounterDrops[drop.lootListID] = drop
end


  ----------------------
-- UI functions
----------------------

function lootHistory:Open()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Opening the UI")
  ---@type AceGUIFrame
  local frame = AceGUI:Create("Frame")
  frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
  frame:SetTitle("LootTrackr")
  frame:SetStatusText("Loot tracking time")
  frame:SetLayout("List")

  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Creating the sidebar")

  local raidEncouterSidebar = AceGUI:Create("TreeGroup")
  raidEncouterSidebar:SetFullHeight(true)
  raidEncouterSidebar:SetFullWidth(true)
  raidEncouterSidebar:SetLayout("Fill")
  raidEncouterSidebar:SetTree(self:BuildEncounterSessionTree())
  frame:AddChild(raidEncouterSidebar)

  local scrollContainer = AceGUI:Create("ScrollFrame")
  scrollContainer:SetLayout("List")
  scrollContainer:SetFullHeight(true)
  scrollContainer:SetFullWidth(true)
  raidEncouterSidebar:AddChild(scrollContainer)

  raidEncouterSidebar:SetCallback("OnGroupSelected", function(widget, event, group)
    local sessionID, encounterID = strsplit("\001", group)

    -- Only update the view if we have a session and encounter
    if sessionID == nil or encounterID == nil then
      return
    end

    scrollContainer:ReleaseChildren()

    self:BuildDropUI(scrollContainer, sessionID, encounterID)

    scrollContainer:DoLayout()
  end)
end

function lootHistory:BuildDropUI(parent, sessionID, encounterID)
  local sessionDrops = self.db.global.drops[sessionID]

  if sessionDrops == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("Missing Drops for Session")
    self:MissingDropsUI(parent)
    return
  end

  local nEncounterID = tonumber(encounterID)
  local encounterDrops = sessionDrops[nEncounterID]

  if encounterDrops == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("Missing Drops for Encounter")
    self:MissingDropsUI(parent)
    return
  end

  for _, drop in pairs(encounterDrops) do
    parent:AddChild(self:BuildDropItem(drop))
  end
end

function lootHistory:BuildDropItem(drop)
  -- Create the main container
  local dropContainer = AceGUI:Create("InlineGroup")
  dropContainer:SetTitle(drop.itemHyperlink)
  dropContainer:SetLayout("Flow")
  dropContainer:SetFullWidth(true)

  -- Header: Item Information

  local itemInfo = self:BuildItemInfo(drop.itemHyperlink)
  dropContainer:AddChild(itemInfo)

  local rollHeading = AceGUI:Create("Heading")
  rollHeading:SetText("Rolls")
  rollHeading:SetFullWidth(true)
  dropContainer:AddChild(rollHeading)

  local rollTable = AceGUI:Create("SimpleGroup")
  rollTable:SetLayout("List")
  rollTable:SetFullWidth(true)
  dropContainer:AddChild(rollTable)

  local tableHeader = self:BuildRollRow({
    "",
    "Name",
    "Class",
    "Roll Type",
    "Roll"
  })
  rollTable:AddChild(tableHeader)

  -- Create a row for each player's roll
  for _, rollInfo in ipairs(drop.rollInfos) do
    local icon = ""
    local playerName = rollInfo.playerName
    local playerClass = rollInfo.playerClass
    local rollTypeString = (function()
      local switch = {
        [0] = "Need",
        [1] = "Need (OS)",
        [2] = "Transmog",
        [3] = "Greed",
        [4] = "No Roll",
        [5] = "Pass"
      }
      return switch[rollInfo.state] or ""
    end)()

    -- Convert to switch statement

    local roll = rollInfo.roll

    if rollInfo.isWinner then
      icon = "Interface\\Icons\\INV_Misc_Coin_01"
    end

    if roll == nil then
      roll = ""
    end

    local rowGroup = self:BuildRollRow({
      icon,
      playerName,
      playerClass,
      rollTypeString,
      roll
    })
    rollTable:AddChild(rowGroup)
  end

  return dropContainer
end

function lootHistory:BuildItemInfo(sItemLink)
  local itemID, itemType, itemSubType, itemEquipLoc, icon, _, _ = C_Item.GetItemInfoInstant(sItemLink)

  local itemInfoGroup = AceGUI:Create("SimpleGroup")
  itemInfoGroup:SetLayout("Flow")
  itemInfoGroup:SetFullWidth(true)

  local itemIcon = AceGUI:Create("Label")
  itemIcon:SetImage(icon)
  itemIcon:SetImageSize(50, 50)
  itemIcon:SetWidth(60)
  itemInfoGroup:AddChild(itemIcon)

  local detailsGroup = AceGUI:Create("SimpleGroup")
  detailsGroup:SetLayout("List")
  itemInfoGroup:AddChild(detailsGroup)

  local itemNameLabel = AceGUI:Create("Label")
  itemNameLabel:SetText("Item Name: " .. "N/A")
  itemNameLabel:SetFullWidth(true)
  detailsGroup:AddChild(itemNameLabel)

  local itemLevelLabel = AceGUI:Create("Label")
  itemLevelLabel:SetText("Item Level: " .. "N/A")
  itemLevelLabel:SetFullWidth(true)
  detailsGroup:AddChild(itemLevelLabel)

  local item = Item:CreateFromItemLink(sItemLink)
  item:ContinueOnItemLoad(function()
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(sItemLink)
    local actualIlvl, previewLvl, sparseItemLvl = C_Item.GetDetailedItemLevelInfo(sItemLink)

    itemNameLabel:SetText("Item Name: " .. itemName)
    itemLevelLabel:SetText("Item Level: " .. actualIlvl)
  end)

  return itemInfoGroup
end

function lootHistory:BuildRollRow(columns)
  local rowGroup = AceGUI:Create("SimpleGroup")
  rowGroup:SetLayout("Flow")
  rowGroup:SetFullWidth(true)

  local iconColumn = AceGUI:Create("Label")
  iconColumn:SetWidth(20)
  iconColumn:SetHeight(10)
  iconColumn:SetImageSize(15, 15)
  iconColumn:SetImage(columns[1])
  rowGroup:AddChild(iconColumn)

  -- Name column
  local nameLabel = AceGUI:Create("Label")
  nameLabel:SetText(columns[2])
  nameLabel:SetWidth(100)
  local classColor = RAID_CLASS_COLORS[columns[3]]
  if classColor ~= nil then
    nameLabel:SetColor(classColor.r, classColor.g, classColor.b)
  end
  rowGroup:AddChild(nameLabel)

  -- Roll Type column (for now, simply "Roll")
  local rollTypeLabel = AceGUI:Create("Label")
  local rollText = columns[4]
  rollTypeLabel:SetText(rollText)
  -- local rollFilename = (function()
  --   local switch = {
  --     ["Need"] = C_Texture.GetAtlasInfo("lootroll-icon-need"),
  --     ["Need (OS)"] = C_Texture.GetAtlasInfo("loot-rollicon-needs"),
  --     ["Transmog"] = C_Texture.GetAtlasInfo("loot-rollicon-transmog"),
  --     ["Greed"] = C_Texture.GetAtlasInfo("loot-rollicon-greed"),
  --     ["No Roll"] = C_Texture.GetAtlasInfo("loot-rollicon-pass"),
  --     ["Pass"] = C_Texture.GetAtlasInfo("loot-rollicon-pass")
  --   }
  --   return (switch[rollText] or C_Texture.GetAtlasInfo("loot-rollicon-pass")).filename
  -- end)()
  -- rollTypeLabel:SetImage("Interface\\LootFrame\\LootRollFrame\\Loot-RollIcon-Transmog")
  -- rollTypeLabel:SetImage(rollFilename)
  -- rollTypeLabel:SetImageSize(15, 15)
  rollTypeLabel:SetWidth(80)
  rowGroup:AddChild(rollTypeLabel)

  -- Roll column
  local rollLabel = AceGUI:Create("Label")
  rollLabel:SetText(columns[5])
  rollLabel:SetWidth(50)
  rowGroup:AddChild(rollLabel)

  return rowGroup
end

function lootHistory:MissingDropsUI(parent)
  local missingDropsLabel = AceGUI:Create("Label")
  missingDropsLabel:SetText("Missing Drops")
  missingDropsLabel:SetFullWidth(true)
  parent:AddChild(missingDropsLabel)
end

function lootHistory:BuildEncounterSessionTree()
  local sessions = self.db.global.sessions

  local tree = {}
  for sessionID, session in pairs(sessions) do
    local sessionDateTime = date("%Y-%m-%d", session.startTime)
    local sessionName = session.instanceName

    local label = "(" .. sessionDateTime .. ") " .. sessionName

    local children = self:BuildEncounterTreeForSession(sessionID)

    if children ~= nil and #children ~= 0 then
      local sessionNode = {
        startTime = session.startTime,
        value = sessionID,
        text = label,
        children = children
      }
      table.insert(tree, sessionNode)
    end
  end

  -- Intentionally reverse sort by start time
  -- so more recent sessions are at the top
  table.sort(tree, function(a, b)
    return a.startTime > b.startTime
  end)

  return tree
end

function lootHistory:BuildEncounterTreeForSession(sessionID)
  local encounters = self.db.global.encounters[sessionID]
  local tree = {}

  if encounters == nil then
    return tree
  end

  for encounterID, encounter in pairs(encounters) do
    local encounterNode = {
      value = encounterID,
      text=encounter.encounterName,
      startTime = encounter.startTime
    }
    table.insert(tree, encounterNode)
  end

  -- Intentionally sort in order of encounter start time
  -- This list is shorter then sessions so we want it forward in time
  table.sort(tree, function(a, b)
    return a.startTime < b.startTime
  end)

  return tree
end
