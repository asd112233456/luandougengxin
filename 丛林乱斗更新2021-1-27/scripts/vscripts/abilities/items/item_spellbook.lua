local imbaAbilityFirstAppearTime = 23 * 60

local courierSpecialRate = 30

local abilityWeightMap = {
    dazzle_bad_juju = {99, 98, 98, 96},
    silencer_glaives_of_wisdom = {99, 98, 98, 96},
    slark_essence_shift = {99, 98, 98, 96},
    faceless_void_time_lock = {98, 95, 95, 95},
    slardar_bash = {98, 95, 95, 95},
    alchemist_goblins_greed = {93, 90, 87, 84},
    elder_titan_natural_order = {93, 90, 87, 84},
    undying_flesh_golem = {93, 90, 87, 84},
    pangolier_lucky_shot = {90, 85, 80, 75},
    bloodseeker_thirst = {90, 85, 80, 75},
    dragon_knight_elder_dragon_form = {90, 85, 80, 75},
    -- obsidian_destroyer_arcane_orb = {85, 80, 75, 70},
    drow_ranger_marksmanship = {93, 90, 87, 84},
    phantom_assassin_coup_de_grace = {60, 55, 50, 45},
    viper_poison_attack = {60, 55, 50, 45},
    oracle_false_promise = {60, 55, 50, 45},
    abaddon_frostmourne = {60, 55, 50, 45},
    ursa_enrage = {60, 55, 50, 45},
    ancient_apparition_chilling_touch = {40, 35, 30, 25},
    doom_bringer_infernal_blade = {30, 20, 10, 5},
    spectre_dispersion = {40, 35, 30, 25},
    juggernaut_blade_fury = {40, 35, 30, 25},
    void_spirit_astral_step = {30, 20, 10, 5},
    lion_finger_of_death = {10, 2, 2, 2},
    rubick_arcane_supremacy = {20, 10, 10, 5},
    antimage_blink = {20, 10, 10, 5},
    queenofpain_blink = {20, 10, 10, 5},
    lion_voodoo = {10, 2, 2, 2},
    --centaur_return = {10, 2, 2, 2},
    pangolier_swashbuckle = {10, 2, 2, 2},
    lina_fiery_soul = {10, 2, 2, 2},
    shadow_shaman_voodoo = {10, 2, 2, 2}
}

local function getImbaAbilityReplaceChance(abilityName)
    local specialWeight = abilityWeightMap[abilityName] or {}
    local imbaAbilityReplacePercentage = specialWeight[1] or 75
    if GameRules.nCountDownTimer < 13 * 60 then
        imbaAbilityReplacePercentage = specialWeight[2] or 70
    end
    if GameRules.nCountDownTimer < 9 * 60 then
        imbaAbilityReplacePercentage = specialWeight[3] or 55
    end
    if GameRules.nCountDownTimer < 5 * 60 then
        imbaAbilityReplacePercentage = specialWeight[4] or 50
    end
    return imbaAbilityReplacePercentage
end

function OnAddUltimate(keys)
    local caster = keys.caster
    if not caster:IsRealHero() then
        return
    end
    local ability = keys.ability

    if not caster:HasAbility("empty_a6") then
        msg.bottom("#hud_error_only_one_ultimate", caster:GetPlayerID())
        return
    end

    local bookCount = 3
    local stars = caster:GetCurrentStar()
    if RollPercentage(stars) then
        bookCount = 4
    end

    local randomAbilities = table.random_some(GameRules.vUltimateAbilitiesPool, bookCount)

    if not GameRules.bFreeModeActivated == true then
        print("free mode is not activated, spell will be replaced")
        for k, ability in pairs(randomAbilities) do
            if table.contains(GameRules.vCourierAbilities_Ultimate, ability) then
                local imbaAbilityReplacePercentage = getImbaAbilityReplaceChance(ability)
                if
                    RollPercentage(imbaAbilityReplacePercentage) or
                        GameRules.nCountDownTimer > imbaAbilityFirstAppearTime
                 then
                    local randomAbility = table.random(GameRules.vUltimateAbilitiesPool)
                    while (table.contains(randomAbilities, randomAbility) or
                        table.contains(GameRules.vCourierAbilities_Ultimate, randomAbility)) do
                        randomAbility = table.random(GameRules.vUltimateAbilitiesPool)
                    end
                    randomAbilities[k] = randomAbility
                end
            end
        end
    end

    -- 避免被没点的初始技能覆盖了
    caster.__playerHaveSelectedAbility__ = true

    GameRules.vSpellbookRecorder = GameRules.vSpellbookRecorder or {}
    local id = "spell_book_" .. DoUniqueString("")
    GameRules.vSpellbookRecorder[id] = randomAbilities

    CustomGameEventManager:Send_ServerToPlayer(
        PlayerResource:GetPlayer(caster:GetPlayerID()),
        "show_ability_selector",
        {
            ID = id,
            Abilities = randomAbilities,
            Type = "ultimate"
        }
    )

    local charges = ability:GetCurrentCharges() - 1
    if charges <= 0 then
        ability:RemoveSelf()
    else
        ability:SetCurrentCharges(charges)
    end

    caster.__nNumUltimateBook__ = caster.__nNumUltimateBook__ or 0
    caster.__nNumUltimateBook__ = caster.__nNumUltimateBook__ + 1

    CustomGameEventManager:Send_ServerToPlayer(
        caster:GetPlayerOwner(),
        "player_update_book_count",
        {
            NormalBookCount = caster.__nNumNormalBook__ or 0,
            UltimateBookCount = caster.__nNumUltimateBook__ or 0
        }
    )
end

function OnAddNormal(keys)
    local caster = keys.caster
    if not caster:IsRealHero() then
        return
    end
    local ability = keys.ability
    if
        not (caster:HasAbility("empty_a1") or caster:HasAbility("empty_a2") or caster:HasAbility("empty_a3") or
            (caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT and caster:HasAbility("empty_a4")))
     then
        msg.bottom("#hud_error_ability_is_full", caster:GetPlayerID())
        return
    end

    local bookCount = 3
    local stars = caster:GetCurrentStar()
    if RollPercentage(stars) then
        bookCount = 4
    end

    local randomAbilities = table.random_some(GameRules.vNormalAbilitiesPool, bookCount)

    if not GameRules.bFreeModeActivated == true then
        for k, ability in pairs(randomAbilities) do
            if table.contains(GameRules.vCourierAbilities_Normal, ability) then
                local imbaAbilityReplacePercentage = getImbaAbilityReplaceChance(ability)
                if
                    RollPercentage(imbaAbilityReplacePercentage) or
                        GameRules.nCountDownTimer > imbaAbilityFirstAppearTime
                 then
                    local randomAbility = table.random(GameRules.vNormalAbilitiesPool)
                    while (table.contains(randomAbilities, randomAbility) or
                        table.contains(GameRules.vCourierAbilities_Normal, randomAbility)) do
                        randomAbility = table.random(GameRules.vNormalAbilitiesPool)
                    end
                    randomAbilities[k] = randomAbility
                end
            end
        end
    end

    -- 避免被没点的初始技能覆盖了
    caster.__playerHaveSelectedAbility__ = true

    GameRules.vSpellbookRecorder = GameRules.vSpellbookRecorder or {}
    local id = "spell_book_" .. DoUniqueString("")
    GameRules.vSpellbookRecorder[id] = randomAbilities

    CustomGameEventManager:Send_ServerToPlayer(
        PlayerResource:GetPlayer(caster:GetPlayerID()),
        "show_ability_selector",
        {
            ID = id,
            Abilities = randomAbilities,
            Type = "normal"
        }
    )

    local charges = ability:GetCurrentCharges() - 1
    if charges <= 0 then
        ability:RemoveSelf()
    else
        ability:SetCurrentCharges(charges)
    end

    caster.__nNumNormalBook__ = caster.__nNumNormalBook__ or 0
    caster.__nNumNormalBook__ = caster.__nNumNormalBook__ + 1

    CustomGameEventManager:Send_ServerToPlayer(
        caster:GetPlayerOwner(),
        "player_update_book_count",
        {
            NormalBookCount = caster.__nNumNormalBook__ or 0,
            UltimateBookCount = caster.__nNumUltimateBook__ or 0
        }
    )
end

function OnAddNormal_Courier(keys)
    local caster = keys.caster
    if not caster:IsRealHero() then
        return
    end
    local ability = keys.ability
    if
        not (caster:HasAbility("empty_a1") or caster:HasAbility("empty_a2") or caster:HasAbility("empty_a3") or
            (caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT and caster:HasAbility("empty_a4")))
     then
        msg.bottom("#hud_error_ability_is_full", caster:GetPlayerID())
        return
    end

    local randomAbilities = table.random_some(GameRules.vNormalAbilitiesPool, 3)

    -- 如果没有包含有附加的特殊技能，那么有大概率给一个
    local didntHave = true
    for k, ability in pairs(randomAbilities) do
        if table.contains(GameRules.vCourierAbilities_Normal, ability) then
            didntHave = false
            break
        end
    end
    if didntHave then
        if RollPercentage(courierSpecialRate) then
            local ability = table.random(GameRules.vCourierAbilities_Normal)
            randomAbilities[RandomInt(1, 3)] = ability
        end
    end

    -- 避免被没点的初始技能覆盖了
    caster.__playerHaveSelectedAbility__ = true

    GameRules.vSpellbookRecorder = GameRules.vSpellbookRecorder or {}
    local id = "spell_book_" .. DoUniqueString("")
    GameRules.vSpellbookRecorder[id] = randomAbilities

    CustomGameEventManager:Send_ServerToPlayer(
        PlayerResource:GetPlayer(caster:GetPlayerID()),
        "show_ability_selector",
        {
            ID = id,
            Abilities = randomAbilities,
            Type = "normal"
        }
    )

    local charges = ability:GetCurrentCharges() - 1
    if charges <= 0 then
        ability:RemoveSelf()
    else
        ability:SetCurrentCharges(charges)
    end

    caster.__nNumNormalBook__ = caster.__nNumNormalBook__ or 0
    caster.__nNumNormalBook__ = caster.__nNumNormalBook__ + 1

    CustomGameEventManager:Send_ServerToPlayer(
        caster:GetPlayerOwner(),
        "player_update_book_count",
        {
            NormalBookCount = caster.__nNumNormalBook__ or 0,
            UltimateBookCount = caster.__nNumUltimateBook__ or 0
        }
    )
end

function OnAddUltimate_Courier(keys)
    local caster = keys.caster
    if not caster:IsRealHero() then
        return
    end
    local ability = keys.ability

    if not caster:HasAbility("empty_a6") then
        msg.bottom("#hud_error_only_one_ultimate", caster:GetPlayerID())
        return
    end

    local randomAbilities = table.random_some(GameRules.vUltimateAbilitiesPool, 3)

    -- 如果没有包含有附加的特殊技能，那么有大概率给一个
    local didntHave = true
    for k, ability in pairs(randomAbilities) do
        if table.contains(GameRules.vCourierAbilities_Ultimate, ability) then
            didntHave = false
            break
        end
    end
    if didntHave then
        if RollPercentage(courierSpecialRate) then
            local ability = table.random(GameRules.vCourierAbilities_Ultimate)
            randomAbilities[RandomInt(1, 3)] = ability
        end
    end

    -- 避免被没点的初始技能覆盖了
    caster.__playerHaveSelectedAbility__ = true

    GameRules.vSpellbookRecorder = GameRules.vSpellbookRecorder or {}
    local id = "spell_book_" .. DoUniqueString("")
    GameRules.vSpellbookRecorder[id] = randomAbilities

    CustomGameEventManager:Send_ServerToPlayer(
        PlayerResource:GetPlayer(caster:GetPlayerID()),
        "show_ability_selector",
        {
            ID = id,
            Abilities = randomAbilities,
            Type = "ultimate"
        }
    )

    local charges = ability:GetCurrentCharges() - 1
    if charges <= 0 then
        ability:RemoveSelf()
    else
        ability:SetCurrentCharges(charges)
    end

    caster.__nNumUltimateBook__ = caster.__nNumUltimateBook__ or 0
    caster.__nNumUltimateBook__ = caster.__nNumUltimateBook__ + 1

    CustomGameEventManager:Send_ServerToPlayer(
        caster:GetPlayerOwner(),
        "player_update_book_count",
        {
            NormalBookCount = caster.__nNumNormalBook__ or 0,
            UltimateBookCount = caster.__nNumUltimateBook__ or 0
        }
    )
end

function OnAddUnlimited(keys)
    local caster = keys.caster
    if not caster:IsRealHero() then
        return
    end
    local ability = keys.ability

    if
        not (caster:HasAbility("empty_a1") or caster:HasAbility("empty_a2") or caster:HasAbility("empty_a3") or
            (caster:GetPrimaryAttribute() == DOTA_ATTRIBUTE_INTELLECT and caster:HasAbility("empty_a4")) or
            caster:HasAbility("empty_a6"))
     then
        msg.bottom("#hud_error_ability_is_full", caster:GetPlayerID())
        return
    end

    local randomPool = table.join(GameRules.vUltimateAbilitiesPool, GameRules.vNormalAbilitiesPool)
    local randomAbilities = table.random_some(randomPool, RandomInt(2, 4))
    caster.__playerHaveSelectedAbility__ = true
    GameRules.vSpellbookRecorder = GameRules.vSpellbookRecorder or {}
    local id = "spell_book_" .. DoUniqueString("")
    GameRules.vSpellbookRecorder[id] = randomAbilities

    CustomGameEventManager:Send_ServerToPlayer(
        PlayerResource:GetPlayer(caster:GetPlayerID()),
        "show_ability_selector",
        {
            ID = id,
            Abilities = randomAbilities,
            Type = "ultimate"
        }
    )

    local charges = ability:GetCurrentCharges() - 1
    if charges <= 0 then
        ability:RemoveSelf()
    else
        ability:SetCurrentCharges(charges)
    end
end
