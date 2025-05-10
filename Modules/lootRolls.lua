local MyAddOnName, thisAddon = ...
local addon = _G[MyAddOnName]

local function CreateBorder(self, barExists)
    if not lootRoll.GUI.border then return end
    if not self.borders then
        self.borders = {}
        for i=1, 4 do
            self.borders[i] = self:CreateLine(nil, "OVERLAY", nil, 0)
            local l = self.borders[i]
            l:SetThickness(1)
            l:SetColorTexture(0.1, 0.1, 0.1, 0.8)
            if i==1 then
                l:SetStartPoint("TOPLEFT")
                l:SetEndPoint("TOPRIGHT")
            elseif i==2 then
                l:SetStartPoint("TOPRIGHT")
                l:SetEndPoint("BOTTOMRIGHT")
            elseif i==3 then
                l:SetStartPoint("BOTTOMRIGHT")
                l:SetEndPoint("BOTTOMLEFT")
            else
                l:SetStartPoint("BOTTOMLEFT")
                l:SetEndPoint("TOPLEFT")
            end
        end
    end
end

local encounter = 0

function addon:UpdateEncounter(event, encounterID)
    if encounter ~= encounterID then
        encounter = encounterID
        util.AddDebugData(encounterID,"Encounter updated ")
    end
end

function addon:GetQualitiy(quality) 
    if quality == 1 then
        return 1, 1, 1
    elseif quality == 2 then
        return 0.1, 1, 0.1
    elseif quality == 3 then
        return 0, 0.44, 0.87
    elseif quality == 4 then
        return 0.64, 0.21, 0.93
    elseif quality == 5 then
        return 1, 0.5, 0
    else
        return 0.6, 0.6, 0.6
    end
end

function addon:RollCancelEvent(event, rollID)
    for _, item in ipairs(lootRoll.items) do
        if item.rollID == rollID then
            addon:RemoveItem(item.frame)
        end
    end
end

function addon:RollEvent(event, rollID)
    GroupLootFrame1:Hide()
    GroupLootFrame2:Hide()
    GroupLootFrame3:Hide()
    GroupLootFrame4:Hide()
    GroupLootContainer:Hide()
    local texture, name, _, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, _, _, _, _, canTransmog = GetLootRollItemInfo(rollID)
    local itemID = select(2, GetLootRollItemInfo(rollID))
    local _, itemLink, _, itemLevel = GetItemInfo(itemID)
    -- itemData = {rollID, iconTexture, itemLevel, bop, itemName, canNeed, canGreed, canDisenchant, canTransmog}
    local itemData = {
        rollID = rollID,
        iconTexture = texture,
        itemLevel = itemLevel,
        quality = quality,
        itemName = name,
        bop = bindOnPickUp,
        canNeed = canNeed,
        canGreed = canGreed,
        canDisenchant = canDisenchant,
        canTransmog = canTransmog,
    }

    util.AddDebugData(itemData,"Item detail for Loot roll")

    if canNeed and not getPlayerInformation("none",itemID,"RP") then -- remove an item if you do not have the highest priority
	    itemData.canNeed = false
        canNeed = false
	end

    addon:AddItem(itemData)
    
    C_Timer.After(0.5, function ()
        if #lootRoll.items ~= 0 then
            addon:OpenGUI()
        end
    end)
    
end

function addon:createRollFrame()
	local width = self.PLdb.profile.GUI.width or 500
    local height = self.PLdb.profile.GUI.height or 400

    lootRoll.frame = CreateFrame("Frame", "MyLootRollContainer", UIParent)
    lootRoll.frame:SetSize(width, height)
    lootRoll.frame:SetPoint(self.PLdb.profile.GUI.point, UIParent, self.PLdb.profile.GUI.point, self.PLdb.profile.GUI.xPos, self.PLdb.profile.GUI.yPos)
    lootRoll.frame:SetScale(self.PLdb.profile.GUI.scale)
    
	lootRoll.bg = lootRoll.frame:CreateTexture(nil, "BACKGROUND")
	lootRoll.bg:SetAllPoints(true)
	lootRoll.bg:SetColorTexture(0.1,0.1,0.1,0.8)
    lootRoll.bg:Hide()

    lootRoll.scrollFrame = CreateFrame("ScrollFrame", nil, lootRoll.frame, "UIPanelScrollFrameTemplate")
    lootRoll.scrollFrame:SetAllPoints(true)
	lootRoll.scrollFrame.ScrollBar:Hide()
    
    lootRoll.contentFrame = CreateFrame("Frame", nil, lootRoll.scrollFrame)
    lootRoll.contentFrame:SetSize(width, height)
    lootRoll.scrollFrame:SetScrollChild(lootRoll.contentFrame)
    
    lootRoll.items = {}
    lootRoll.nextY = 0

	lootRoll.frame:Hide()
end

local protection = false

local function getClassColoredName(playerName, className, roll)
    local classColors = RAID_CLASS_COLORS[className]
    if not classColors then
        classColors = { r = 1, g = 1, b = 1 } 
    end
    local coloredPlayerName = string.format("|cff%02x%02x%02x%s|r", 
                                            classColors.r * 255, 
                                            classColors.g * 255, 
                                            classColors.b * 255, 
                                            playerName)
    local result = string.format("%s |cffffffffRoll %d|r", coloredPlayerName, roll)
    return result
end

local function getInfos(itemData)
    --local states = {"Need", "Need", "Transmog", "Greed", "Pass", "Pass"}
    if encounter ~= 0 then
        local stateList = {0, 0, 0, 0}
        local drops = C_LootHistory.GetSortedDropsForEncounter(encounter)
        for _, drop in ipairs(drops) do
            local item = C_Item.GetItemNameByID(drop.itemHyperlink)
            if item == itemData.itemName then
                GameTooltip:AddLine(" ")
                for _, rollers in ipairs(drop.rollInfos) do
                    local playerName = rollers.playerName
                    local playerClass = rollers.playerClass
                    local roll = rollers.roll or 0
                    if rollers.state == 0 or rollers.state == 1 then
                        stateList[1] = stateList[1] + 1
                    elseif rollers.state == 2 then
                        stateList[2] = stateList[2] + 1
                    elseif rollers.state == 3 then
                        stateList[3] = stateList[3] + 1
                    elseif rollers.state == 4 or rollers.state == 5 then
                        stateList[4] = stateList[4] + 1
                    end
                    if rollers.state == 4 or rollers.state == 5 or roll == 0 then
                        return
                    end
                    local fany = getClassColoredName(playerName, playerClass, roll)
                    GameTooltip:AddLine(fany)


                end
                GameTooltip:AddLine("  ")
                GameTooltip:AddLine("Needed: "..stateList[1].." Transmog: "..stateList[2].." Greeded: "..stateList[3].." Passed: "..stateList[4])
            end
        end
    end
end

function addon:AddItem(itemData)
    local width = lootRoll.GUI.width or 500 
    local itemHeight = lootRoll.GUI.itemHeight or 48 
    local IconSize = math.min(itemHeight, 48)

    -- Create Item Frame
    local itemFrame = CreateFrame("Frame", nil, lootRoll.contentFrame)
    itemFrame:SetSize(width, itemHeight)
    itemFrame:SetPoint("TOPLEFT", lootRoll.contentFrame, "TOPLEFT", 0, -lootRoll.nextY)

    -- Create icon frame
    local iconFrame = CreateFrame("Frame", nil, itemFrame)
    iconFrame:SetSize(IconSize, IconSize)
    iconFrame:SetPoint("LEFT", itemFrame, "LEFT", 10, 0)

    if itemData.rollID then
        iconFrame:EnableMouse(true)

        iconFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetLootRollItem(itemData.rollID) 
            getInfos(itemData)
            GameTooltip:Show()
        end)

        iconFrame:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    end
    

    local iconTexture = iconFrame:CreateTexture(nil, "BACKGROUND")
    iconTexture:SetAllPoints(true)
    iconTexture:SetTexture(itemData.iconTexture)
    if lootRoll.GUI.zoomIcon then
        iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    end
    

	CreateBorder(iconFrame)
    
    -- Add item level text
    local itemLevelText = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    itemLevelText:SetPoint("BOTTOM", iconFrame, "BOTTOM", 0, 5)
    itemLevelText:SetText(itemData.itemLevel)
    itemLevelText:SetTextColor(1, 1, 1, 1)
    PriorityLoot:ApplyFontString(itemLevelText)

    -- Add progress bar
    local duration = itemData.rollID and (C_Loot.GetLootRollDuration(itemData.rollID) or 0) / 1000 or 60
    local startTime = GetTime()
    local r,g,b = addon:GetQualitiy(itemData.quality)

	local progressBarFrameBG = CreateFrame("StatusBar", nil, itemFrame)
    progressBarFrameBG:SetSize(width - IconSize - 20, 14)
    progressBarFrameBG:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMRIGHT", 5, 0)
    progressBarFrameBG:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    progressBarFrameBG:SetMinMaxValues(0, 1)
    progressBarFrameBG:SetValue(100)
    progressBarFrameBG:SetStatusBarColor(r,g,b, 0.4)

    local progressBarFrame = CreateFrame("StatusBar", nil, itemFrame)
    progressBarFrame:SetSize(width - IconSize - 20, 14)
    progressBarFrame:SetPoint("BOTTOMLEFT", iconFrame, "BOTTOMRIGHT", 5, 0)
    progressBarFrame:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    progressBarFrame:SetMinMaxValues(0, 1)
    progressBarFrame:SetValue(100)
    progressBarFrame:SetStatusBarColor(r,g,b, 1)

    progressBarFrame:SetScript("OnUpdate", function(self, elapsed)
        local timeLeft = duration - (GetTime() - startTime)
        self:SetValue(timeLeft / duration)
        if timeLeft <= 0 then
            addon:RemoveItem(itemFrame)
            self:SetScript("OnUpdate", nil)
        end
    end)

	CreateBorder(progressBarFrame)
    
    local sparkTexture = progressBarFrame:CreateTexture(nil, "OVERLAY")
    sparkTexture:SetSize(32, 32)
    sparkTexture:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    sparkTexture:SetBlendMode("ADD")
    
    local function UpdateSpark()
        local value = progressBarFrame:GetValue()
        local minValue, maxValue = progressBarFrame:GetMinMaxValues()
        local barWidth = progressBarFrame:GetWidth()
        local sparkPosition = ((value - minValue) / (maxValue - minValue)) * barWidth
        sparkTexture:SetPoint("CENTER", progressBarFrame, "LEFT", sparkPosition, 0)
    end

    UpdateSpark()

    progressBarFrame:SetScript("OnValueChanged", UpdateSpark)
    
    -- Add item name text
    local itemNameText = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    itemNameText:SetPoint("BOTTOMLEFT", progressBarFrame, "TOPLEFT", 0, 10)
    itemNameText:SetText(self:trimText(itemData.itemName))
    itemNameText:SetTextColor(1, 1, 1, 1)
    PriorityLoot:ApplyFontString(itemNameText)

    -- Add buttons
    local buttonSize = 24
    local buttonOffsetX = -2
    local buttons = {
        {name = "Pass", texture = "Interface\\Buttons\\UI-GroupLoot-Pass-Up", rollType = 0},
        {name = "Disenchant", texture = "Interface\\Buttons\\UI-GroupLoot-DE-Up", rollType = 3, check = "canDisenchant"},
        {name = "Transmog", texture = "Interface\\Minimap\\Tracking\\Transmogrifier", rollType = 4, check = "canTransmog"},
        {name = "Greed", texture = "Interface\\Buttons\\UI-GroupLoot-Coin-Up", rollType = 2, check = "canGreed"},
        {name = "Need", texture = "Interface\\Buttons\\UI-GroupLoot-Dice-Up", rollType = 1, check = "canNeed"},
    }

    local conditions = {
        canNeed = itemData.canNeed,
        canGreed = itemData.canGreed,
        canDisenchant = itemData.canDisenchant,
        canTransmog = itemData.canTransmog,
    }

    for i, buttonInfo in ipairs(buttons) do
        local buttonFrame = CreateFrame("Frame", nil, itemFrame)
        buttonFrame:SetSize(buttonSize, buttonSize)
        buttonFrame:SetPoint("BOTTOMRIGHT", progressBarFrame, "TOPRIGHT", buttonOffsetX, 5)
        
        local buttonTexture = buttonFrame:CreateTexture(nil, "ARTWORK")
        buttonTexture:SetAllPoints(true)
        buttonTexture:SetTexture(buttonInfo.texture)

        local canClick = conditions[buttonInfo.check] ~= false
        
        if not canClick then
            buttonTexture:SetDesaturated(true)
            buttonTexture:SetAlpha(0.1)
            buttonFrame:EnableMouse(false)
        else
            buttonFrame:EnableMouse(true)
            buttonFrame:SetScript("OnMouseDown", function()
                if buttonInfo.rollType then
                    if itemData.rollID then
                        if lootRoll.GUI.protection then
                            if protection then
                                print("PriorityLoot >> ".. L["Protection enabled, please wait a couples seconds, you can disable or reduce in options!"])
                                return
                            else
                                protection = true
                                RollOnLoot(itemData.rollID, buttonInfo.rollType)
                                addon:RemoveItem(itemFrame)
                                C_Timer.After(lootRoll.GUI.protectionTimer, function ()
                                    protection = false
                                end)
                            end
                        else
                            RollOnLoot(itemData.rollID, buttonInfo.rollType)
                            addon:RemoveItem(itemFrame)
                        end
                    end
                end
            end)
        end
        
        buttonFrame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(buttonFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(buttonInfo.name, 1, 1, 1)
            GameTooltip:Show()
        end)
        buttonFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        buttonOffsetX = buttonOffsetX - buttonSize - 10
    end

    if itemData.bop then
        local itemBoP = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        itemBoP:SetPoint("BOTTOMRIGHT", progressBarFrame, "TOPRIGHT", buttonOffsetX, 10)
        itemBoP:SetText("BoP")
        itemBoP:SetTextColor(1, 0, 0, 1)
        addon:ApplyFontString(itemBoP)
    end

    lootRoll.nextY = lootRoll.nextY + itemHeight + 4
    lootRoll.contentFrame:SetSize(width, lootRoll.nextY)

    table.insert(lootRoll.items, {frame = itemFrame, rollID = itemData.rollID})
    return itemFrame
end

function addon:RemoveItem(itemFrame)
    if itemFrame then
        itemFrame:Hide()
        itemFrame:SetParent(nil)
        
        for i, item in ipairs(lootRoll.items) do
            if item.frame == itemFrame then
                table.remove(lootRoll.items, i)
                break
            end
        end

        lootRoll.nextY = 0
        for _, item in ipairs(lootRoll.items) do
            item.frame:SetPoint("TOPLEFT", lootRoll.contentFrame, "TOPLEFT", 0, -lootRoll.nextY)
            lootRoll.nextY = lootRoll.nextY + item.frame:GetHeight() + 4
        end

        lootRoll.contentFrame:SetSize(lootRoll.contentFrame:GetWidth(), lootRoll.nextY)

        if #lootRoll.items == 0 then
            encounter = 0
            addon:HideGUI()
        end
    end
end

function addon:OpenGUI()
    if not lootRoll.frame:IsShown() then
        lootRoll.frame:Show()
    end
end

function addon:HideGUI()
    if lootRoll.frame:IsShown() then
        lootRoll.frame:Hide()
    end
end

function addon:ApplyFontString(fontString)
    local fontName = LSM:Fetch("font", addon.PLdb.profile.GUI.font)
    local fontSize = addon.PLdb.profile.GUI.fontSize or 12
    local fontFlags = addon.PLdb.profile.GUI.fontFlags or ""

    fontString:SetFont(fontName, fontSize, fontFlags)
end
