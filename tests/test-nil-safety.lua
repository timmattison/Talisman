#!/usr/bin/env lua
--- Tests for nil safety issues similar to cryptid's thalia joker bug
--- Bug pattern: using potentially nil values as table keys

package.path = package.path .. ";../?.lua;../big-num/?.lua"

function number_format(b)
    if type(b) == "table" and b.to_string then return b:to_string() else return tostring(b) end
end

local TestRunner = require("test-runner")
local T = TestRunner

-- ============================================================================
-- NIL TABLE KEY PATTERN TESTS
-- This is the same bug pattern as cryptid's thalia joker
-- ============================================================================

T:test("nil table key crashes Lua", function()
    local seen = {}
    T:assertThrows(function()
        local key = nil
        seen[key] = 1  -- This crashes!
    end, "Using nil as table key should crash")
end)

T:test("safe pattern: check key before use", function()
    local seen = {}
    local key = nil

    T:assertNoThrow(function()
        if key then
            seen[key] = 1
        end
    end, "Checking key before use should not crash")
end)

-- ============================================================================
-- SIMULATED inc_career_stat PATTERN (talisman.lua:408-421)
-- Bug: uses `stat` as table key without nil check
-- ============================================================================

T:test("inc_career_stat pattern: nil stat crashes", function()
    -- Simulate the data structure
    local G = {
        PROFILES = {
            profile1 = {
                career_stats = {}
            }
        },
        SETTINGS = { profile = "profile1" },
        GAME = { seeded = false, challenge = false }
    }

    -- Original buggy pattern
    local function inc_career_stat_buggy(stat, mod)
        if G.GAME.seeded or G.GAME.challenge then return end
        -- BUG: if stat is nil, this crashes
        if not G.PROFILES[G.SETTINGS.profile].career_stats[stat] then
            G.PROFILES[G.SETTINGS.profile].career_stats[stat] = 0
        end
        G.PROFILES[G.SETTINGS.profile].career_stats[stat] =
            G.PROFILES[G.SETTINGS.profile].career_stats[stat] + (mod or 0)
    end

    T:assertThrows(function()
        inc_career_stat_buggy(nil, 5)
    end, "inc_career_stat with nil stat should crash")
end)

T:test("inc_career_stat pattern: safe version with nil check", function()
    local G = {
        PROFILES = {
            profile1 = {
                career_stats = {}
            }
        },
        SETTINGS = { profile = "profile1" },
        GAME = { seeded = false, challenge = false }
    }

    -- Fixed pattern with nil check
    local function inc_career_stat_safe(stat, mod)
        if G.GAME.seeded or G.GAME.challenge then return end
        if not stat then return end  -- Added nil check
        if not G.PROFILES[G.SETTINGS.profile].career_stats[stat] then
            G.PROFILES[G.SETTINGS.profile].career_stats[stat] = 0
        end
        G.PROFILES[G.SETTINGS.profile].career_stats[stat] =
            G.PROFILES[G.SETTINGS.profile].career_stats[stat] + (mod or 0)
    end

    T:assertNoThrow(function()
        inc_career_stat_safe(nil, 5)
        inc_career_stat_safe("valid_stat", 10)
    end, "Safe inc_career_stat should not crash with nil stat")

    T:assertEqual(10, G.PROFILES.profile1.career_stats.valid_stat,
        "Valid stat should be updated")
end)

-- ============================================================================
-- SIMULATED check_and_set_high_score PATTERN (talisman.lua:393-401)
-- Note: This pattern is actually SAFE because `and` short-circuits
-- G.GAME.round_scores[nil] returns nil, so the `and` stops evaluation
-- ============================================================================

T:test("check_and_set_high_score pattern: nil score is safe due to short-circuit", function()
    local G = {
        GAME = {
            round_scores = {},
            seeded = false
        }
    }

    local function to_big(x) return x end

    -- This pattern is actually safe because:
    -- G.GAME.round_scores[nil] returns nil (not crash)
    -- nil and <anything> returns nil (short-circuit)
    local function check_and_set_high_score(score, amt)
        if G.GAME.round_scores[score] and to_big(math.floor(amt)) > to_big(G.GAME.round_scores[score].amt) then
            G.GAME.round_scores[score].amt = to_big(math.floor(amt))
        end
    end

    T:assertNoThrow(function()
        check_and_set_high_score(nil, 100)
    end, "check_and_set_high_score with nil score should NOT crash due to short-circuit")
end)

T:test("check_and_set_high_score pattern: works with valid score", function()
    local G = {
        GAME = {
            round_scores = {
                chips = { amt = 50 }
            },
            seeded = false
        }
    }

    local function to_big(x) return x end

    local function check_and_set_high_score(score, amt)
        if G.GAME.round_scores[score] and to_big(math.floor(amt)) > to_big(G.GAME.round_scores[score].amt) then
            G.GAME.round_scores[score].amt = to_big(math.floor(amt))
        end
    end

    T:assertNoThrow(function()
        check_and_set_high_score("chips", 100)
    end, "check_and_set_high_score should work with valid score")

    T:assertEqual(100, G.GAME.round_scores.chips.amt,
        "Valid score should be updated")
end)

-- ============================================================================
-- SIMULATED Card:get_chip_x_bonus PATTERN (talisman.lua:852-857)
-- Potential bug: accesses self.ability without nil check
-- ============================================================================

T:test("Card:get_chip_x_bonus pattern: nil ability crashes", function()
    local Card = {}

    -- Original pattern
    function Card:get_chip_x_bonus_buggy()
        if self.debuff then return 0 end
        -- BUG: if self.ability is nil, this crashes
        if self.ability.set == 'Joker' then return 0 end
        if (self.ability.x_chips or 0) <= 1 then return 0 end
        return self.ability.x_chips
    end

    local card_without_ability = { debuff = false }
    setmetatable(card_without_ability, { __index = Card })

    T:assertThrows(function()
        card_without_ability:get_chip_x_bonus_buggy()
    end, "get_chip_x_bonus with nil ability should crash")
end)

T:test("Card:get_chip_x_bonus pattern: safe version with nil check", function()
    local Card = {}

    -- Fixed pattern with nil check
    function Card:get_chip_x_bonus_safe()
        if self.debuff then return 0 end
        if not self.ability then return 0 end  -- Added nil check
        if self.ability.set == 'Joker' then return 0 end
        if (self.ability.x_chips or 0) <= 1 then return 0 end
        return self.ability.x_chips
    end

    local card_without_ability = { debuff = false }
    setmetatable(card_without_ability, { __index = Card })

    local card_with_ability = {
        debuff = false,
        ability = { set = 'Default', x_chips = 2 }
    }
    setmetatable(card_with_ability, { __index = Card })

    T:assertNoThrow(function()
        local result1 = card_without_ability:get_chip_x_bonus_safe()
        T:assertEqual(0, result1, "nil ability should return 0")

        local result2 = card_with_ability:get_chip_x_bonus_safe()
        T:assertEqual(2, result2, "valid ability should return x_chips")
    end, "Safe get_chip_x_bonus should not crash with nil ability")
end)

-- ============================================================================
-- DEEP NESTED ACCESS PATTERN (talisman.lua:410)
-- G.PROFILES[G.SETTINGS.profile].career_stats[stat]
-- ============================================================================

T:test("deep nested access: nil intermediate crashes", function()
    local G = {
        PROFILES = {},  -- profile1 doesn't exist
        SETTINGS = { profile = "profile1" }
    }

    T:assertThrows(function()
        -- This crashes because G.PROFILES["profile1"] is nil
        local _ = G.PROFILES[G.SETTINGS.profile].career_stats
    end, "Accessing .career_stats on nil profile should crash")
end)

T:test("deep nested access: safe pattern", function()
    local G = {
        PROFILES = {},
        SETTINGS = { profile = "profile1" }
    }

    T:assertNoThrow(function()
        local profile = G.PROFILES[G.SETTINGS.profile]
        if profile and profile.career_stats then
            local stats = profile.career_stats
        end
    end, "Safe nested access should not crash")
end)

-- ============================================================================
-- VERIFY ACTUAL FIXES IN talisman.lua
-- ============================================================================

-- Read talisman.lua content
local function read_file(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content
end

local talisman_content = read_file("../talisman.lua")

T:test("talisman.lua: inc_career_stat has nil check for stat", function()
    T:assertNotNil(talisman_content, "Should be able to read talisman.lua")
    T:assert(
        talisman_content:find("if not stat then return end"),
        "inc_career_stat should check if stat is nil before using as table key"
    )
end)

T:test("talisman.lua: Card:get_chip_e_bonus has nil check for ability", function()
    T:assertNotNil(talisman_content, "Should be able to read talisman.lua")
    -- Check for the pattern in get_chip_e_bonus
    T:assert(
        talisman_content:find("function Card:get_chip_e_bonus")
        and talisman_content:find("if not self%.ability then return 0 end"),
        "Card:get_chip_e_bonus should check if self.ability is nil"
    )
end)

T:test("talisman.lua: Card:get_chip_hyper_bonus has nil check for ability", function()
    T:assertNotNil(talisman_content, "Should be able to read talisman.lua")
    T:assert(
        talisman_content:find("function Card:get_chip_hyper_bonus")
        and talisman_content:find("if not self%.ability then return {0,0} end"),
        "Card:get_chip_hyper_bonus should check if self.ability is nil"
    )
end)

-- ============================================================================
-- Run all tests
-- ============================================================================

local success = T:run()
os.exit(success and 0 or 1)
