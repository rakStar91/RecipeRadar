-- ============================================================================
-- RecipeRadar: Engine/AltTracker.lua
-- Multi-character recipe knowledge tracker across realm
-- ============================================================================

local RR = RecipeRadar
RR.AltTracker = {}

--- Returns a list of all alts on the current realm and their knowledge status for a recipe
-- @param profName string: Profession name (localized or English)
-- @param spellId number: Recipe spell ID
-- @param spellName string: Recipe localized name
-- @return table list of { name = string, class = string, level = number, isKnown = boolean, hasProfession = boolean }
function RR.AltTracker:GetAltStatusForRecipe(profName, spellId, spellName)
    local results = {}
    if not (RecipeRadarDB and RecipeRadarDB.characters) then return results end

    local realm = GetRealmName() or "UnknownRealm"
    local realmChars = RecipeRadarDB.characters[realm]
    if not realmChars then return results end

    local playerFaction = UnitFactionGroup("player") or "Neutral"
    local currentCharName = UnitName("player")

    for charName, charData in pairs(realmChars) do
        -- Show alts from the same faction
        if charData.faction == playerFaction and charName ~= currentCharName then
            local isKnown = false
            local profData = RR.Scanner and RR.Scanner:GetProfessionData(charData, profName)
            if profData and profData.known then
                local knownTable = profData.known
                if (spellId and knownTable[spellId]) or (spellName and knownTable[spellName]) then
                    isKnown = true
                end

                -- Fallback: check all localized names from database for this spell ID
                if not isKnown and RR.DB and spellId then
                    local engProf = RR.DB:GetEnglishProfessionName(profName)
                    local recipes = RR.DB:GetRecipesForProfession(engProf)
                    for _, r in ipairs(recipes) do
                        if r.id == spellId and r.name then
                            for _, n in pairs(r.name) do
                                if knownTable[n] then
                                    isKnown = true
                                    break
                                end
                            end
                            break
                        end
                    end
                end
            end

            -- If this alt has the profession or has recipes recorded
            if profData ~= nil then
                table.insert(results, {
                    name = charName,
                    class = charData.class or "WARRIOR",
                    isKnown = isKnown,
                    hasProfession = true,
                })
            end
        end
    end

    table.sort(results, function(a, b) return a.name < b.name end)
    return results
end
