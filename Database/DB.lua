-- ============================================================================
-- RecipeRadar: Database/DB.lua
-- Central database query engine (Classic Era + TBC)
-- Fully ID-driven & dynamic Blizzard API localization across all languages
-- ============================================================================

local RR = RecipeRadar
RR.DB = {}

RR.DB.Raw = {
    skills = {},
    items = {},
    npcs = {},
    quests = {},
    objects = {},
    zones = {},
    factions = {},
    professions = {},
    continents = {},
}

RR.DB.npcMap = {}
RR.DB.zoneMap = {}
RR.DB.questMap = {}
RR.DB.itemMap = {}
RR.DB.profNameToKey = {}

-- Official Blizzard Profession Spell-IDs (Universal across all locales)
local LOCALE_TO_DB_KEY = {
    ["deDE"] = "German",
    ["enUS"] = "English",
    ["enGB"] = "English",
    ["frFR"] = "French",
    ["esES"] = "Spanish",
    ["esMX"] = "Mexican",
    ["ruRU"] = "Russian",
    ["zhCN"] = "Chinese",
    ["zhTW"] = "Taiwanese",
    ["koKR"] = "Korean",
    ["ptBR"] = "Portuguese",
}

function RR.DB:GetLocalizedText(nameTable)
    if not nameTable then return "" end
    if type(nameTable) == "string" then return nameTable end
    local locale = GetLocale()
    local dbKey = LOCALE_TO_DB_KEY[locale] or "English"
    return nameTable[dbKey] or nameTable[locale] or nameTable["German"] or nameTable["English"] or ""
end

local PROFESSION_SPELL_IDS = {
    ["Alchemy"] = 2259,
    ["Blacksmithing"] = 2018,
    ["Cooking"] = 2550,
    ["Enchanting"] = 7411,
    ["Engineering"] = 4036,
    ["First Aid"] = 3273,
    ["Fishing"] = 7620,
    ["Herbalism"] = 2366,
    ["Jewelcrafting"] = 25229,
    ["Leatherworking"] = 2108,
    ["Mining"] = 2575,
    ["Poisons"] = 2842,
    ["Skinning"] = 8613,
    ["Tailoring"] = 3908,
}

function RR.DB:Initialize()
    if RR_DATA then
        self.Raw.skills = RR_DATA["skills"] or {}
        self.Raw.items = RR_DATA["items"] or {}
        self.Raw.npcs = RR_DATA["npcs"] or {}
        self.Raw.quests = RR_DATA["quests"] or {}
        self.Raw.objects = RR_DATA["objects"] or {}
        self.Raw.zones = RR_DATA["zones"] or {}
        self.Raw.factions = RR_DATA["factions"] or {}
        self.Raw.professions = RR_DATA["professions"] or {}
        self.Raw.continents = RR_DATA["continents"] or {}

        -- 1. Build O(1) Lookup Maps
        self.npcMap = {}
        for _, npc in pairs(self.Raw.npcs) do
            if type(npc) == "table" and npc.id then
                self.npcMap[npc.id] = npc
            end
        end

        self.zoneMap = {}
        for _, z in pairs(self.Raw.zones) do
            if type(z) == "table" and z.id then
                self.zoneMap[z.id] = z
            end
        end

        self.questMap = {}
        for _, q in pairs(self.Raw.quests) do
            if type(q) == "table" and q.id then
                self.questMap[q.id] = q
            end
        end

        self.itemMap = {}
        for prof, list in pairs(self.Raw.items) do
            if type(list) == "table" then
                for _, item in pairs(list) do
                    if type(item) == "table" and item.id then
                        self.itemMap[item.id] = item
                    end
                end
            end
        end


        -- 1b. Build comprehensive item-to-skill and spell-to-skill lookup maps
        self.itemToSkillMap = {}
        self.craftedItemToSkillMap = {}
        self.spellToSkillMap = {}

        local spellToItem = RR_DATA and RR_DATA["spell_to_item"]

        if self.Raw.skills then
            for profName, skillList in pairs(self.Raw.skills) do
                if type(skillList) == "table" then
                    for _, skill in ipairs(skillList) do
                        local entry = {
                            profession = profName,
                            skill = skill,
                            spellId = skill.id,
                        }

                        if skill.id then
                            self.spellToSkillMap[skill.id] = entry
                        end

                        -- Map recipe / pattern items
                        if skill.items and type(skill.items) == "table" then
                            for _, itmId in ipairs(skill.items) do
                                self.itemToSkillMap[itmId] = entry
                            end
                        end

                        -- Map crafted items (from trainers, drops, quests, etc.)
                        if spellToItem and skill.id and spellToItem[skill.id] then
                            local craftedId = spellToItem[skill.id]
                            self.craftedItemToSkillMap[craftedId] = entry
                        end
                    end
                end
            end
        end
        -- 2. Build Dynamic Multilingual Profession Name Resolver via Blizzard API & DB
        self.profNameToKey = {}
        
        -- Query Blizzard Spell API for the active client language
        for engKey, spellId in pairs(PROFESSION_SPELL_IDS) do
            local spellName = nil
            if C_Spell and C_Spell.GetSpellInfo then
                local info = C_Spell.GetSpellInfo(spellId)
                spellName = info and info.name
            elseif GetSpellInfo then
                spellName = GetSpellInfo(spellId)
            end

            if spellName then
                self.profNameToKey[spellName] = engKey
            end
            self.profNameToKey[engKey] = engKey
        end

        -- Also index all 10 language dictionaries from Database/Base/professions.lua
        if self.Raw.professions then
            for engName, pData in pairs(self.Raw.professions) do
                if type(pData) == "table" and pData.name then
                    for _, locName in pairs(pData.name) do
                        if locName and locName ~= "" then
                            self.profNameToKey[locName] = engName
                        end
                    end
                end
            end
        end
    end
end

function RR.DB:GetEnglishProfessionName(profName)
    if not profName then return "Tailoring" end
    return self.profNameToKey[profName] or profName
end

function RR.DB:GetRecipesForProfession(professionName)
    local engName = self:GetEnglishProfessionName(professionName)
    return (self.Raw.skills and self.Raw.skills[engName]) or {}
end

function RR.DB:GetNPC(npcId)
    if not npcId then return nil end
    return self.npcMap and self.npcMap[npcId]
end

function RR.DB:GetQuest(questId)
    if not questId then return nil end
    return self.questMap and self.questMap[questId]
end

function RR.DB:GetCraftedItemId(spellId)
    if not spellId then return nil end
    if RR_DATA and RR_DATA["spell_to_item"] then
        return RR_DATA["spell_to_item"][spellId]
    end
    return nil
end

function RR.DB:GetItem(itemId)
    if not itemId then return nil end
    return self.itemMap and self.itemMap[itemId]
end

function RR.DB:GetContinents()
    local list = {}
    if self.Raw.continents then
        for _, c in ipairs(self.Raw.continents) do
            local name = self:GetLocalizedText(c.name)
            if name == "" then name = "Continent" end
            table.insert(list, {
                id = c.id,
                name = name,
            })
        end
    end
    return list
end

function RR.DB:GetZonesInContinent(continentId)
    local zones = {}
    if self.Raw.zones then
        for _, z in pairs(self.Raw.zones) do
            local cId = z.continent_id or z.cont_id
            if not continentId or continentId == "any" or cId == continentId then
                local zName = self:GetLocalizedText(z.name)
                if zName == "" then zName = "Zone" end
                table.insert(zones, {
                    id = z.id,
                    name = zName,
                    continentId = cId,
                })
            end
        end
    end
    table.sort(zones, function(a, b) return a.name < b.name end)
    return zones
end

function RR.DB:GetZoneName(zoneId)
    if not zoneId then return "Unknown Zone" end
    local z = self.zoneMap and self.zoneMap[zoneId]
    if z and z.name then
        local name = self:GetLocalizedText(z.name)
        if name ~= "" then return name end
    end
    return "Unknown Zone"
end

--- Returns comprehensive acquisition metadata for a recipe
function RR.DB:GetRecipeAcquisitionMetadata(recipe)
    local meta = {
        zones = {},
        continents = {},
        sourceTypes = {},
        factions = {},
        expansion = recipe.expansion or 1,
        phase = recipe.phase or 1,
        reputationFactionId = nil,
        reputationLevel = nil,
        reputations = {},
        dropRange = nil,
        special_action = recipe.special_action,
        objects = recipe.objects,
    }

    local function addNPC(npcId, sType)
        local npc = self:GetNPC(npcId)
        if npc then
            local zId = (npc.location and npc.location.zone_id) or npc.zone_id
            if zId then
                meta.zones[zId] = true
                local z = self.zoneMap and self.zoneMap[zId]
                if z then
                    local cId = z.continent_id or z.cont_id
                    if cId then meta.continents[cId] = true end
                end
            end
            if sType then meta.sourceTypes[sType] = true end
            if npc.reacts then
                if type(npc.reacts) == "table" then
                    for _, r in ipairs(npc.reacts) do
                        meta.factions[r] = true
                    end
                elseif type(npc.reacts) == "string" then
                    meta.factions[npc.reacts] = true
                end
            elseif npc.faction then
                meta.factions[npc.faction] = true
            end
        end
    end

    local function addQuest(qId)
        local q = self:GetQuest(qId)
        if q then
            local qzId = q.zone_id
            if not qzId and q.npcs and q.npcs[1] then
                local npc = self:GetNPC(q.npcs[1])
                if npc then
                    qzId = (npc.location and npc.location.zone_id) or npc.zone_id
                end
            end
            if not qzId and q.givers and q.givers.npcs and q.givers.npcs[1] then
                local npc = self:GetNPC(q.givers.npcs[1])
                if npc then
                    qzId = (npc.location and npc.location.zone_id) or npc.zone_id
                end
            end
            if qzId then
                meta.zones[qzId] = true
                local z = self.zoneMap and self.zoneMap[qzId]
                if z then
                    local cId = z.continent_id or z.cont_id
                    if cId then meta.continents[cId] = true end
                end
            end
            meta.sourceTypes["quest"] = true
            if q.reacts then
                if type(q.reacts) == "table" then
                    for _, r in ipairs(q.reacts) do
                        meta.factions[r] = true
                    end
                elseif type(q.reacts) == "string" then
                    meta.factions[q.reacts] = true
                end
            end
            if q.npcs then
                for _, nId in ipairs(q.npcs) do addNPC(nId, "quest") end
            end
            if q.givers and q.givers.npcs then
                for _, nId in ipairs(q.givers.npcs) do addNPC(nId, "quest") end
            end
        end
    end

    -- Direct trainers
    if recipe.trainers then
        meta.sourceTypes["trainer"] = true
        local tr = recipe.trainers.sources or (type(recipe.trainers) == "table" and recipe.trainers)
        if type(tr) == "table" then
            for _, id in ipairs(tr) do addNPC(id, "trainer") end
        end
    end

    -- Direct vendors
    if recipe.vendors then
        meta.sourceTypes["vendor"] = true
        local vn = recipe.vendors.sources or (type(recipe.vendors) == "table" and recipe.vendors)
        if type(vn) == "table" then
            for _, id in ipairs(vn) do addNPC(id, "vendor") end
        end
    end

    -- Direct quests
    if recipe.quests then
        meta.sourceTypes["quest"] = true
        local qs = recipe.quests.sources or (type(recipe.quests) == "table" and recipe.quests)
        if type(qs) == "table" then
            for _, id in ipairs(qs) do addQuest(id) end
        end
    end

    -- Direct drops
    if recipe.drops then
        meta.sourceTypes["drop"] = true
        if recipe.drops.range then
            meta.dropRange = recipe.drops.range
        end
        local dr = recipe.drops.sources or (type(recipe.drops) == "table" and recipe.drops)
        if type(dr) == "table" then
            for _, id in ipairs(dr) do addNPC(id, "drop") end
        end
    end

    -- Items (Teaching items / patterns / recipes)
    if recipe.items and type(recipe.items) == "table" then
        for _, itemId in ipairs(recipe.items) do
            local itm = self:GetItem(itemId)
            if itm then
                if itm.expansion then meta.expansion = itm.expansion end
                if itm.phase then meta.phase = itm.phase end
                if itm.vendors then
                    meta.sourceTypes["vendor"] = true
                    local iv = itm.vendors.sources or itm.vendors
                    if type(iv) == "table" then
                        for _, id in ipairs(iv) do addNPC(id, "vendor") end
                    end
                end
                if itm.quests then
                    meta.sourceTypes["quest"] = true
                    local iq = itm.quests.sources or itm.quests
                    if type(iq) == "table" then
                        for _, id in ipairs(iq) do addQuest(id) end
                    end
                end
                if itm.drops then
                    meta.sourceTypes["drop"] = true
                    if itm.drops.range then
                        meta.dropRange = itm.drops.range
                    end
                    local idr = itm.drops.sources or itm.drops
                    if type(idr) == "table" then
                        for _, id in ipairs(idr) do addNPC(id, "drop") end
                    end
                end
                if itm.reputation then
                    meta.sourceTypes["reputation"] = true
                    local fid = itm.reputation.faction_id
                    local lid = itm.reputation.level_id or itm.reputation.level
                    if fid then
                        meta.reputationFactionId = fid
                        meta.reputationLevel = lid
                        table.insert(meta.reputations, {
                            faction_id = fid,
                            level_id = lid,
                        })
                    end
                end
                if itm.holiday then meta.sourceTypes["holiday"] = true end
                if itm.objects then
                    meta.sourceTypes["object"] = true
                    meta.objects = itm.objects
                end
                if itm.special_action then
                    meta.special_action = itm.special_action
                end
            end
        end
    end

    -- Direct reputation / holiday / object
    if recipe.reputation then
        meta.sourceTypes["reputation"] = true
        local fid = recipe.reputation.faction_id
        local lid = recipe.reputation.level_id or recipe.reputation.level
        if fid then
            meta.reputationFactionId = fid
            meta.reputationLevel = lid
            table.insert(meta.reputations, {
                faction_id = fid,
                level_id = lid,
            })
        end
    end
    if recipe.holiday then meta.sourceTypes["holiday"] = true end
    if recipe.objects then meta.sourceTypes["object"] = true end

    -- Fallback only if absolutely no source found
    if not next(meta.sourceTypes) then
        meta.sourceTypes["trainer"] = true
    end

    return meta
end

--- Returns true if currently running on The Burning Crusade Classic
function RR.DB:IsTBC()
    local _, _, _, tocVersion = GetBuildInfo()
    if tocVersion and tocVersion >= 20000 and tocVersion < 30000 then
        return true
    end
    if WOW_PROJECT_ID and (WOW_PROJECT_ID == (WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5)) then
        return true
    end
    return false
end

--- Returns localized name for content phase (Era vs TBC)
function RR.DB:GetPhaseName(phaseVal, expansionId)
    if not phaseVal or phaseVal == 0 or phaseVal == "any" then return RR.L["PHASE_ALL"] or "All Phases" end
    
    if type(phaseVal) == "string" then
        local expKey, pNum = phaseVal:match("^(%a+)_(%d+)$")
        if expKey and pNum then
            pNum = tonumber(pNum)
            if expKey == "tbc" then
                return RR.L["PHASE_TBC_" .. pNum] or string.format("TBC Phase %d", pNum)
            else
                local eraName = RR.L["PHASE_" .. pNum] or string.format("Phase %d", pNum)
                return (self:IsTBC() and "Classic " or "") .. eraName
            end
        end
    end

    local phaseNum = tonumber(phaseVal) or 1
    expansionId = expansionId or (self:IsTBC() and 2 or 1)
    
    if expansionId == 2 then
        return RR.L["PHASE_TBC_" .. phaseNum] or string.format("Phase %d", phaseNum)
    else
        local eraName = RR.L["PHASE_" .. phaseNum] or string.format("Phase %d", phaseNum)
        if self:IsTBC() then
            return "Classic " .. eraName
        else
            return eraName
        end
    end
end

--- Returns current player zone ID in Classic DB
function RR.DB:GetCurrentZoneId()
    local zName = GetRealZoneText() or ""
    if zName == "" then return nil end

    if self.zoneMap then
        for id, z in pairs(self.zoneMap) do
            if z.name then
                local locZName = self:GetLocalizedText(z.name)
                if locZName == zName then
                    return id
                end
                -- Fallback check for raw match
                if type(z.name) == "table" then
                    for _, val in pairs(z.name) do
                        if val == zName then return id end
                    end
                end
            end
        end
    end
    return nil
end

--- Returns localized faction name by faction ID
function RR.DB:GetFactionName(factionId)
    if not factionId then return nil end
    local facs = RR_DATA and RR_DATA["factions"]
    if facs then
        for _, f in ipairs(facs) do
            if f.id == factionId then
                return self:GetLocalizedText(f.name)
            end
        end
    end
    return nil
end

local ALLIANCE_REPUTATION_FACTIONS = {
    [946] = true, -- Honor Hold / Ehrenfeste
    [978] = true, -- Kurenai
}

local HORDE_REPUTATION_FACTIONS = {
    [922] = true, -- Tranquillien / Tristessa
    [941] = true, -- The Mag'har / Die Mag'har
    [947] = true, -- Thrallmar
}

--- Returns lists of curated reputation factions for Classic and TBC filtered by factionFilter (Alliance, Horde, Neutral)
function RR.DB:GetReputationFactions(factionFilter)
    local isTBC = self:IsTBC()

    local classicFactions = {
        529, -- Argent Dawn / Argentumdämmerung
        87,  -- Bloodsail Buccaneers / Blutsegelbukaniere
        909, -- Darkmoon Faire / Dunkelmond-Jahrmarkt
        369, -- Gadgetzan
        576, -- Timbermaw Hold / Holzschlundfeste
        270, -- Zandalar Tribe / Stamm der Zandalar
        70,  -- Syndicate / Syndikat
        59,  -- Thorium Brotherhood / Thoriumbruderschaft
        609, -- Cenarion Circle / Zirkel des Cenarius
        749, -- Hydraxian Waterlords / Hydraxianer
    }

    local tbcFactions = {
        1012, -- Ashtongue Deathsworn / Aschenzungenkaste
        933,  -- The Consortium / Das Konsortium
        967,  -- The Violet Eye / Das Violette Auge
        932,  -- The Aldor / Die Aldor
        941,  -- The Mag'har / Die Mag'har (Horde)
        934,  -- The Scryers / Die Seher
        935,  -- The Sha'tar / Die Sha'tar
        990,  -- The Scale of the Sands / Die Wächter der Sande
        946,  -- Honor Hold / Ehrenfeste (Alliance)
        942,  -- Cenarion Expedition / Expedition des Cenarius
        989,  -- Keepers of Time / Hüter der Zeit
        978,  -- Kurenai / Kurenai (Alliance)
        1015, -- Netherwing / Netherschwingen
        1077, -- Shattered Sun Offensive / Offensive der Zerschmetterten Sonne
        1038, -- Ogri'la / Ogri'la
        970,  -- Sporeggar / Sporeggar
        947,  -- Thrallmar / Thrallmar (Horde)
        922,  -- Tranquillien / Tristessa (Horde)
        1011, -- Lower City / Unteres Viertel
    }

    local function buildList(idList)
        local res = {}
        for _, id in ipairs(idList) do
            local isAlly = ALLIANCE_REPUTATION_FACTIONS[id] == true
            local isHorde = HORDE_REPUTATION_FACTIONS[id] == true
            local isNeutral = not isAlly and not isHorde

            local matches = true
            if factionFilter == "Alliance" then
                matches = isAlly or isNeutral
            elseif factionFilter == "Horde" then
                matches = isHorde or isNeutral
            elseif factionFilter == "Neutral" then
                matches = isNeutral
            end

            if matches then
                local fName = self:GetFactionName(id)
                if fName and fName ~= "" then
                    table.insert(res, {
                        id = id,
                        name = fName,
                        allegiance = isAlly and "Alliance" or (isHorde and "Horde" or "Neutral"),
                    })
                end
            end
        end
        table.sort(res, function(a, b) return a.name < b.name end)
        return res
    end

    local classicSorted = buildList(classicFactions)
    local tbcSorted = isTBC and buildList(tbcFactions) or {}

    return classicSorted, tbcSorted
end

--- Returns localized reputation level name (e.g. Friendly, Honored, Revered, Exalted)
function RR.DB:GetReputationLevelName(levelId)
    if not levelId then return nil end
    local lvls = RR_DATA and RR_DATA["reputation_levels"]
    if lvls then
        for _, l in ipairs(lvls) do
            if l.id == levelId then
                return self:GetLocalizedText(l.name)
            end
        end
    end
    return nil
end

--- Returns localized description for a special action key
function RR.DB:GetSpecialActionText(actionKey)
    if not actionKey then return nil end
    local sa = RR_DATA and RR_DATA["special_actions"] and RR_DATA["special_actions"][actionKey]
    if sa and sa.name then
        return self:GetLocalizedText(sa.name)
    end
    return actionKey
end

--- Returns object data by ID
function RR.DB:GetObject(objectId)
    if not objectId then return nil end
    local objs = RR_DATA and RR_DATA["objects"]
    if objs then
        for _, obj in ipairs(objs) do
            if obj.id == objectId then
                return obj
            end
        end
    end
    return nil
end

--- Returns localized display name for a profession in the current locale
function RR.DB:GetProfessionDisplayName(profInput)
    if not profInput or profInput == "" then
        profInput = "Leatherworking"
    end

    local engKey = self:GetEnglishProfessionName(profInput)
    if engKey and self.Raw.professions and self.Raw.professions[engKey] then
        local pData = self.Raw.professions[engKey]
        if pData and pData.name then
            local locText = self:GetLocalizedText(pData.name)
            if locText and locText ~= "" then
                return locText
            end
        end
    end

    -- Check Blizzard Spell API for localized spell name
    if engKey and PROFESSION_SPELL_IDS[engKey] then
        local spellId = PROFESSION_SPELL_IDS[engKey]
        local spellName = nil
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellId)
            spellName = info and info.name
        elseif GetSpellInfo then
            spellName = GetSpellInfo(spellId)
        end
        if spellName and spellName ~= "" then
            return spellName
        end
    end

    return profInput
end

function RR.DB:GetSpecialisations(professionName)
    local engName = self:GetEnglishProfessionName(professionName)
    if RR_DATA and RR_DATA["specialisations"] and RR_DATA["specialisations"][engName] then
        return RR_DATA["specialisations"][engName]
    end
    return {}
end

function RR.DB:GetSpecialisationName(specId)
    if not specId or specId == 0 or specId == "any" then return nil end
    if RR_DATA and RR_DATA["specialisations"] then
        for _, specs in pairs(RR_DATA["specialisations"]) do
            for _, s in ipairs(specs) do
                if s.id == specId then
                    return self:GetLocalizedText(s.name)
                end
            end
        end
    end
    return nil
end

function RR.DB:GetSkillByItemId(itemId)
    if not itemId then return nil end
    if self.itemToSkillMap and self.itemToSkillMap[itemId] then
        return self.itemToSkillMap[itemId]
    end
    if self.craftedItemToSkillMap and self.craftedItemToSkillMap[itemId] then
        return self.craftedItemToSkillMap[itemId]
    end
    return nil
end

function RR.DB:GetSkillBySpellId(spellId)
    if not spellId then return nil end
    return self.spellToSkillMap and self.spellToSkillMap[spellId]
end
