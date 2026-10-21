-- ============================================================================
-- RecipeRadar: Engine/Recorder.lua
-- Records where recipes are obtained while playing (WoW Forever) and exports it in the database format.
--
-- The game client has no data about vendors, trainers and drops of new recipes, so the addon notes
-- what the player sees: vendors that sell a known recipe item, trainers that teach a known recipe,
-- recipe items found in loot and recipe items offered as quest rewards.
--
-- The data is kept in the same shapes as the database files (npcs, items, skills, quests, objects),
-- and the export is a Lua table in that format, so tools/forever/merge_observed.py can merge it
-- without conversion. Nothing leaves the computer; the player copies the export and decides where to
-- share it. Only facts about recipes in the database are kept, and no character, realm, account or
-- GUID data.
-- ============================================================================

local RR = RecipeRadar
RR.Recorder = {}

local EXPORT_FORMAT = 2

local function Plain(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

--- Returns the id and kind ("npc" or "object") of a creature or object GUID, or nil
local function IdFromGuid(guid)
    guid = Plain(guid)
    if type(guid) ~= "string" then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    id = tonumber(id)
    if not id then return nil end
    if kind == "Creature" or kind == "Vehicle" then return id, "npc" end
    if kind == "GameObject" then return id, "object" end
    return nil
end

local function ItemIdFromLink(link)
    link = Plain(link)
    if type(link) ~= "string" then return nil end
    return tonumber(link:match("item:(%d+)"))
end

local function IsKnownItem(itemId)
    return RR.DB:GetItem(itemId) ~= nil or RR.DB:GetSkillByItemId(itemId) ~= nil
end

local function IsKnownSpell(spellId)
    return RR.DB:GetSkillBySpellId(spellId) ~= nil
end

local function Observed()
    return RecipeRadarDB and RecipeRadarDB.observed
end

--- Adds a value to an array once
local function AddOnce(list, value)
    for _, v in ipairs(list) do
        if v == value then return end
    end
    list[#list + 1] = value
end

--- Recording is on unless the player turned it off
function RR.Recorder:IsEnabled()
    return RR.Config:GetProfile().recordSources ~= false
end

function RR.Recorder:SetEnabled(enabled)
    RR.Config:GetProfile().recordSources = enabled and true or false
end

function RR.Recorder:Initialize()
    RecipeRadarDB.observed = RecipeRadarDB.observed or {}
    local obs = RecipeRadarDB.observed
    -- keyed by id while recording; the export turns them into sorted lists
    obs.npcs = obs.npcs or {}
    obs.items = obs.items or {}
    obs.skills = obs.skills or {}
    obs.quests = obs.quests or {}
    obs.objects = obs.objects or {}
    obs.format = EXPORT_FORMAT

    local frame = CreateFrame("Frame")
    RR.Utils:RegisterEvents(frame, {
        "MERCHANT_SHOW", "MERCHANT_UPDATE", "TRAINER_SHOW", "TRAINER_UPDATE", "LOOT_OPENED", "QUEST_COMPLETE",
    })
    frame:SetScript("OnEvent", function(_, event)
        if not RR.Recorder:IsEnabled() then return end
        if event == "MERCHANT_SHOW" or event == "MERCHANT_UPDATE" then
            RR.Recorder:ScanMerchant()
        elseif event == "TRAINER_SHOW" or event == "TRAINER_UPDATE" then
            RR.Recorder:ScanTrainer()
        elseif event == "LOOT_OPENED" then
            RR.Recorder:ScanLoot()
        elseif event == "QUEST_COMPLETE" then
            RR.Recorder:ScanQuestRewards()
        end
    end)
end

--- Where the player stands, in the database's coordinate format, plus zone data.
-- The player is within a few yards of the NPC while talking to it, which is accurate enough for a waypoint.
local function PlayerLocation()
    local location, mapId, mapName
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        mapId = C_Map.GetBestMapForUnit("player")
        local pos = mapId and C_Map.GetPlayerMapPosition(mapId, "player")
        if pos then
            local x, y = pos:GetXY()
            if x and y and (x > 0 or y > 0) then
                location = { x = string.format("%.2f", x * 100), y = string.format("%.2f", y * 100) }
            end
        end
        -- the name of the map is the zone ("Elwynn Forest"); GetRealZoneText can return a building such as an inn
        local info = mapId and C_Map.GetMapInfo and C_Map.GetMapInfo(mapId)
        mapName = info and Plain(info.name)
    end
    return location, mapId, mapName
end

--- Stores location, map and zone on an npc or object entry, once
local function SetLocation(entry)
    if entry.location ~= nil then return end
    local location, mapId, mapName = PlayerLocation()
    if location then
        entry.location = location
        entry.map_id = mapId
        entry.zone_name = mapName or (GetRealZoneText and GetRealZoneText()) or nil
        entry.zone_id = RR.DB:GetZoneIdByName(entry.zone_name)
    end
end

--- How the NPC treats the player, as the database's "reacts" value. A friendly NPC is credited to the
-- observer's own faction; the merge script corrects that when both factions have seen it friendly.
local function ReactsFor(reaction)
    if type(reaction) ~= "number" then return nil end
    if reaction <= 3 then return "Hostile" end
    if reaction == 4 then return "Neutral" end
    return UnitFactionGroup("player")
end

--- Notes an NPC in the database's npc shape. unit is a unit token the NPC can be read from, or nil.
local function RecordNpc(npcId, unit)
    local obs = Observed()
    local npc = obs.npcs[npcId] or { id = npcId }
    obs.npcs[npcId] = npc

    if unit then
        local name = Plain(UnitName(unit))
        if type(name) == "string" and name ~= "" then
            npc.name = npc.name or {}
            npc.name[RR.DB:GetLocaleKey()] = name
        end
        local level = Plain(UnitLevel(unit))
        if type(level) == "number" and level > 0 then
            local classification = UnitClassification and Plain(UnitClassification(unit))
            local elite = (classification == "elite" or classification == "rareelite" or classification == "worldboss") and 1 or 0
            local range = npc.xp_level or { min = level, max = level, is_elite = elite }
            range.min = math.min(range.min, level)
            range.max = math.max(range.max, level)
            if elite == 1 then range.is_elite = 1 end
            npc.xp_level = range
        end
        local reaction = UnitReaction and Plain(UnitReaction(unit, "player"))
        local reacts = ReactsFor(reaction)
        if reacts then
            npc.reacts = npc.reacts or reacts
            npc.seen_by = npc.seen_by or {}
            AddOnce(npc.seen_by, UnitFactionGroup("player"))
        end
    end

    SetLocation(npc)
end

local function EntryFor(tbl, id)
    tbl[id] = tbl[id] or { id = id }
    return tbl[id]
end

--- Adds an NPC id to a {price, sources} source table (vendors, trainers)
local function AddPricedSource(owner, key, npcId, price)
    local source = owner[key] or { sources = {} }
    owner[key] = source
    AddOnce(source.sources, npcId)
    if type(price) == "number" and price > 0 and source.price == nil then
        source.price = price
    end
end

function RR.Recorder:ScanMerchant()
    if not (GetMerchantNumItems and GetMerchantItemID) then return end
    local npcId, kind = IdFromGuid(UnitGUID("npc"))
    if not npcId or kind ~= "npc" then return end

    local found
    for index = 1, GetMerchantNumItems() or 0 do
        local itemId = Plain(GetMerchantItemID(index))
        if itemId and IsKnownItem(itemId) then
            local price
            local info = C_MerchantFrame and C_MerchantFrame.GetItemInfo and C_MerchantFrame.GetItemInfo(index)
            if type(info) == "table" and not (issecretvalue and issecretvalue(info)) then
                -- offers paid with currency or items have no copper price to record
                if Plain(info.hasExtendedCost) ~= true then
                    price = Plain(info.price)
                end
            end
            found = found or {}
            found[itemId] = price or false
        end
    end
    if not found then return end

    local obs = Observed()
    RecordNpc(npcId, "npc")
    for itemId, price in pairs(found) do
        AddPricedSource(EntryFor(obs.items, itemId), "vendors", npcId, price or nil)
    end
end

--- Recipe name -> spell id for the current language; only unambiguous names are kept.
-- Used when a trainer service does not link its spell.
local function SpellIdByName(name)
    if not RR.Recorder.nameIndex then
        local index = {}
        for _, list in pairs(RR.DB.Raw.skills or {}) do
            for _, skill in ipairs(list) do
                local text = RR.DB:GetLocalizedText(skill.name)
                if text ~= "" then
                    index[text] = (index[text] == nil) and skill.id or false -- false marks an ambiguous name
                end
            end
        end
        RR.Recorder.nameIndex = index
    end
    return RR.Recorder.nameIndex[name] or nil
end

function RR.Recorder:ScanTrainer()
    if not (GetNumTrainerServices and GetTrainerServiceInfo) then return end
    local npcId, kind = IdFromGuid(UnitGUID("npc"))
    if not npcId or kind ~= "npc" then return end

    local found
    for index = 1, GetNumTrainerServices() or 0 do
        local name = Plain((GetTrainerServiceInfo(index)))
        local spellId
        if GetTrainerServiceItemLink then
            local link = Plain(GetTrainerServiceItemLink(index))
            if type(link) == "string" then
                spellId = tonumber(link:match("spell:(%d+)") or link:match("enchant:(%d+)"))
            end
        end
        if not spellId and type(name) == "string" then
            spellId = SpellIdByName(name)
        end
        if spellId and IsKnownSpell(spellId) then
            local cost = GetTrainerServiceCost and Plain((GetTrainerServiceCost(index)))
            -- the skill rank the trainer asks for ("Requires Cooking (50)") is the recipe's minimum skill
            local rank
            if GetTrainerServiceSkillReq then
                -- the third result only says whether the player meets the requirement, so it is ignored
                local skillName, skillRank = GetTrainerServiceSkillReq(index)
                skillName, skillRank = Plain(skillName), Plain(skillRank)
                if type(skillName) == "string" and type(skillRank) == "number" and skillRank > 0 then rank = skillRank end
            end
            found = found or {}
            found[spellId] = { cost = (type(cost) == "number") and cost or nil, rank = rank }
        end
    end
    if not found then return end

    local obs = Observed()
    RecordNpc(npcId, "npc")
    for spellId, info in pairs(found) do
        local skill = EntryFor(obs.skills, spellId)
        AddPricedSource(skill, "trainers", npcId, info.cost)
        if info.rank and skill.min_skill == nil then
            skill.min_skill = info.rank
        end
    end
end

function RR.Recorder:ScanLoot()
    if not (GetNumLootItems and GetLootSlotLink and GetLootSourceInfo) then return end
    local obs = Observed()
    local targetGuid = Plain(UnitGUID("target"))

    for slot = 1, GetNumLootItems() or 0 do
        local itemId = ItemIdFromLink(GetLootSlotLink(slot))
        if itemId and IsKnownItem(itemId) then
            local sources = { GetLootSourceInfo(slot) }
            for i = 1, #sources, 2 do
                local guid = Plain(sources[i])
                local id, kind = IdFromGuid(guid)
                if id then
                    local item = EntryFor(obs.items, itemId)
                    if kind == "npc" then
                        item.drops = item.drops or { sources = {} }
                        AddOnce(item.drops.sources, id)
                        -- name and level only when the dead creature is still the target
                        RecordNpc(id, (guid == targetGuid) and "target" or nil)
                    else
                        item.objects = item.objects or {}
                        AddOnce(item.objects, id)
                        SetLocation(EntryFor(obs.objects, id))
                    end
                end
            end
        end
    end
end

function RR.Recorder:ScanQuestRewards()
    if not (GetQuestID and GetQuestItemLink) then return end
    local questId = Plain(GetQuestID())
    if type(questId) ~= "number" or questId <= 0 then return end

    local rewards
    local function collect(count, rewardType)
        for index = 1, count or 0 do
            local itemId = ItemIdFromLink(GetQuestItemLink(rewardType, index))
            if itemId and IsKnownItem(itemId) then
                rewards = rewards or {}
                rewards[itemId] = true
            end
        end
    end
    collect(GetNumQuestChoices and GetNumQuestChoices(), "choice")
    collect(GetNumQuestRewards and GetNumQuestRewards(), "reward")
    if not rewards then return end

    local obs = Observed()
    local quest = EntryFor(obs.quests, questId)
    local title = GetTitleText and Plain(GetTitleText())
    if type(title) == "string" and title ~= "" then
        quest.name = quest.name or {}
        quest.name[RR.DB:GetLocaleKey()] = title
    end
    local npcId, kind = IdFromGuid(UnitGUID("npc"))
    if npcId and kind == "npc" then
        quest.npcs = quest.npcs or {}
        AddOnce(quest.npcs, npcId)
        RecordNpc(npcId, "npc")
    end
    for itemId in pairs(rewards) do
        local item = EntryFor(obs.items, itemId)
        item.quests = item.quests or {}
        AddOnce(item.quests, questId)
    end
end

-- ----------------------------------------------------------------------------
-- Housekeeping and export
-- ----------------------------------------------------------------------------

local function CountKeys(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

--- Returns the counts shown to the player: npcs, vendor offers, trainer spells, drop sources, quests
function RR.Recorder:GetCounts()
    local obs = Observed() or {}
    local offers, spells, dropSources = 0, 0, 0
    for _, item in pairs(obs.items or {}) do
        if item.vendors then offers = offers + 1 end
        if item.drops then dropSources = dropSources + #item.drops.sources end
    end
    for _, skill in pairs(obs.skills or {}) do
        if skill.trainers then spells = spells + 1 end
    end
    return CountKeys(obs.npcs), offers, spells, dropSources, CountKeys(obs.quests)
end

function RR.Recorder:IsEmpty()
    local obs = Observed() or {}
    return next(obs.npcs or {}) == nil and next(obs.items or {}) == nil and next(obs.skills or {}) == nil
        and next(obs.quests or {}) == nil and next(obs.objects or {}) == nil
end

function RR.Recorder:Clear()
    local obs = Observed()
    if not obs then return end
    obs.npcs, obs.items, obs.skills, obs.quests, obs.objects = {}, {}, {}, {}, {}
end

-- Lua serializer with sorted keys and tabs, the same layout as the database files
local function Serialize(value, depth)
    -- spaces, not tabs: the game font shows tab characters as boxes
    local pad, close = string.rep("    ", depth + 1), string.rep("    ", depth)
    local kind = type(value)
    if kind == "string" then
        return string.format("%q", value):gsub("\\\n", "\\n")
    elseif kind == "number" or kind == "boolean" then
        return tostring(value)
    end
    local keys, isArray = {}, true
    for k in pairs(value) do
        keys[#keys + 1] = k
        if type(k) ~= "number" then isArray = false end
    end
    table.sort(keys, function(a, b)
        if type(a) == type(b) then return a < b end
        return type(a) == "number"
    end)
    local parts = {}
    for _, k in ipairs(keys) do
        local body = Serialize(value[k], depth + 1)
        parts[#parts + 1] = isArray and (pad .. body .. ",") or (pad .. "[" .. Serialize(k, 0) .. "] = " .. body .. ",")
    end
    return "{\n" .. table.concat(parts, "\n") .. (#parts > 0 and "\n" or "") .. close .. "}"
end

--- Entries of one table as a list sorted by id
local function SortedList(tbl)
    local list = {}
    for _, entry in pairs(tbl or {}) do list[#list + 1] = entry end
    table.sort(list, function(a, b) return a.id < b.id end)
    for _, entry in ipairs(list) do
        if entry.sources then table.sort(entry.sources) end
        for _, key in ipairs({ "vendors", "drops", "trainers" }) do
            if entry[key] and entry[key].sources then table.sort(entry[key].sources) end
        end
        for _, key in ipairs({ "quests", "objects", "npcs", "seen_by" }) do
            if type(entry[key]) == "table" then table.sort(entry[key]) end
        end
    end
    return list
end

--- Builds the export: a Lua file in the database format that tools/forever/merge_observed.py merges.
function RR.Recorder:BuildExport()
    local obs = Observed() or {}
    local version, build = GetBuildInfo()
    local data = {
        format = EXPORT_FORMAT,
        build = tostring(version) .. "." .. tostring(build),
        addon = RR.VERSION,
        locale = RR.DB:GetLocaleKey(),
        npcs = SortedList(obs.npcs),
        items = SortedList(obs.items),
        skills = SortedList(obs.skills),
        quests = SortedList(obs.quests),
        objects = SortedList(obs.objects),
    }
    return "RR_OBSERVED = " .. Serialize(data, 0) .. "\n"
end

--- Handles /rr record [on|off|clear]; without an argument it shows the state and the counts
function RR.Recorder:HandleCommand(argument)
    local prefix = RR.COLORS.TITLE .. "RecipeRadar: " .. RR.COLORS.WHITE
    if argument == "on" or argument == "off" then
        self:SetEnabled(argument == "on")
    elseif argument == "clear" then
        self:Clear()
        print(prefix .. RR.L["REC_CLEARED"])
        return
    end
    print(prefix .. (self:IsEnabled() and RR.L["REC_STATE_ON"] or RR.L["REC_STATE_OFF"]))
    print(prefix .. string.format(RR.L["REC_STATUS"], self:GetCounts()))
end
