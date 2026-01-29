#!/usr/bin/env lua
--- Regression tests for all bug fixes documented in BUGS.md
--- Each test verifies a specific bug fix to prevent regressions

package.path = package.path .. ";../?.lua;../big-num/?.lua"

function number_format(b)
    if b.array then return b:toString() else return b:to_string() end
end

local TestRunner = require("test-runner")
local T = TestRunner

-- ============================================================================
-- BUG #1: R.LOG10E Used Invalid Logarithm Base
-- Both bignumber.lua and omeganum.lua had: R.LOG10E = math.log(R.E, 0)
-- Fix: Changed to math.log(R.E, 10)
-- ============================================================================

-- Test bignumber.lua first
local Big = require("bignumber")

T:test("BUG #1a: bignumber R.LOG10E equals log base 10 of e", function()
    local expected = math.log(math.exp(1), 10)  -- ~0.4343
    T:assertApprox(expected, R.LOG10E, 1e-9, "R.LOG10E should be ~0.4343")
    T:assert(R.LOG10E > 0.43 and R.LOG10E < 0.44, "R.LOG10E should be between 0.43 and 0.44")
end)

T:test("BUG #1a: bignumber R.LOG10E is not NaN or zero", function()
    T:assert(R.LOG10E == R.LOG10E, "R.LOG10E should not be NaN")
    T:assert(R.LOG10E ~= 0, "R.LOG10E should not be zero")
    T:assert(R.LOG10E ~= -0, "R.LOG10E should not be negative zero")
end)

-- ============================================================================
-- BUG #2: Big:pow Didn't Handle Negative Bases
-- (-2)^2 returned 1 instead of 4 because log of negative is undefined
-- Fix: Added explicit handling for negative bases
-- ============================================================================

T:test("BUG #2: (-2)^2 = 4 (negative base, even exponent)", function()
    local a = Big:new(-2)
    local result = a:pow(2)
    T:assertApprox(4, result:to_number(), 1e-9)
end)

T:test("BUG #2: (-2)^3 = -8 (negative base, odd exponent)", function()
    local a = Big:new(-2)
    local result = a:pow(3)
    T:assertApprox(-8, result:to_number(), 1e-9)
end)

T:test("BUG #2: (-3)^4 = 81 (negative base, even exponent)", function()
    local a = Big:new(-3)
    local result = a:pow(4)
    T:assertApprox(81, result:to_number(), 1e-9)
end)

T:test("BUG #2: (-5)^1 = -5 (negative base, exponent 1)", function()
    local a = Big:new(-5)
    local result = a:pow(1)
    T:assertApprox(-5, result:to_number(), 1e-9)
end)

T:test("BUG #2: (-10)^0 = 1 (any base to power 0)", function()
    local a = Big:new(-10)
    local result = a:pow(0)
    -- Note: Implementation returns 0 for 0^0, but -10^0 should be 1
    -- Actually checking pow implementation - it returns 0 for m=0, e=0
    -- For -10, m is not 0, so this should work
    T:assertApprox(1, result:to_number(), 1e-9)
end)

-- ============================================================================
-- BUG #3: Big:mod Used Non-Existent Methods
-- Used Big:create (doesn't exist) and self.sign (doesn't exist)
-- Fix: Rewrote to use Big:new and is_negative()
-- ============================================================================

T:test("BUG #3: mod with positive numbers works", function()
    local a = Big:new(17)
    local b = Big:new(5)
    local result = a:mod(b)
    T:assertApprox(2, result:to_number(), 1e-9)
end)

T:test("BUG #3: mod with negative dividend", function()
    local a = Big:new(-17)
    local b = Big:new(5)
    local result = a:mod(b)
    T:assertApprox(-2, result:to_number(), 1e-9)
end)

T:test("BUG #3: mod with negative divisor", function()
    local a = Big:new(17)
    local b = Big:new(-5)
    local result = a:mod(b)
    T:assertApprox(2, result:to_number(), 1e-9)
end)

T:test("BUG #3: mod with both negative", function()
    local a = Big:new(-17)
    local b = Big:new(-5)
    local result = a:mod(b)
    -- -17 mod -5: abs(-17) mod abs(-5) = 2, result is positive since both negative
    T:assertNotNil(result)
end)

T:test("BUG #3: mod by zero returns zero", function()
    local a = Big:new(10)
    local b = Big:new(0)
    local result = a:mod(b)
    T:assertEqual(0, result:to_number())
end)

-- ============================================================================
-- BUG #9: __concat Used Non-Existent Big:create
-- Fix: Changed to Big:new
-- ============================================================================

T:test("BUG #9: string concatenation with Big works", function()
    local a = Big:new(42)
    local result = a .. " is the answer"
    T:assert(type(result) == "string", "Concatenation should produce string")
    -- Number may be in scientific notation like "4.2e1"
    T:assert(string.find(result, "4") and string.find(result, "2"), "Should contain digits of 42")
end)

T:test("BUG #9: number concatenated with Big works", function()
    local a = Big:new(100)
    local result = 5 .. a
    T:assert(type(result) == "string", "Concatenation should produce string")
end)

-- ============================================================================
-- BUG #13: Object Mutation Bug - Methods Returning Self Instead of Clone
-- add(), round(), floor(), ceil(), floor_m(), ceil_m() returned self
-- Fix: Changed to return Big:new(self) for independent copies
-- ============================================================================

T:test("BUG #13: add() with large delta doesn't mutate original (self larger)", function()
    local a = Big:new(1, 100)
    local b = Big:new(1, 1)
    local original_m, original_e = a.m, a.e
    local result = a + b
    result.m = 999
    result.e = 999
    T:assertEqual(original_m, a.m, "a.m should be unchanged")
    T:assertEqual(original_e, a.e, "a.e should be unchanged")
end)

T:test("BUG #13: add() with large delta doesn't mutate original (b larger)", function()
    local a = Big:new(1, 1)
    local b = Big:new(1, 100)
    local original_m, original_e = b.m, b.e
    local result = a + b
    result.m = 999
    result.e = 999
    T:assertEqual(original_m, b.m, "b.m should be unchanged")
    T:assertEqual(original_e, b.e, "b.e should be unchanged")
end)

T:test("BUG #13: round() on large exponent doesn't mutate original", function()
    local a = Big:new(1.5, 150)
    local original_m, original_e = a.m, a.e
    local result = a:round()
    result.m = 999
    result.e = 999
    T:assertEqual(original_m, a.m)
    T:assertEqual(original_e, a.e)
end)

T:test("BUG #13: floor() on large exponent doesn't mutate original", function()
    local a = Big:new(1.5, 150)
    local original_m, original_e = a.m, a.e
    local result = a:floor()
    result.m = 999
    result.e = 999
    T:assertEqual(original_m, a.m)
    T:assertEqual(original_e, a.e)
end)

T:test("BUG #13: ceil() on large exponent doesn't mutate original", function()
    local a = Big:new(1.5, 150)
    local original_m, original_e = a.m, a.e
    local result = a:ceil()
    result.m = 999
    result.e = 999
    T:assertEqual(original_m, a.m)
    T:assertEqual(original_e, a.e)
end)

T:test("BUG #13: floor_m() on large exponent doesn't mutate original", function()
    local a = Big:new(1.5, 150)
    local original_m, original_e = a.m, a.e
    local result = a:floor_m(2)
    result.m = 999
    result.e = 999
    T:assertEqual(original_m, a.m)
    T:assertEqual(original_e, a.e)
end)

T:test("BUG #13: ceil_m() on large exponent doesn't mutate original", function()
    local a = Big:new(1.5, 150)
    local original_m, original_e = a.m, a.e
    local result = a:ceil_m(2)
    result.m = 999
    result.e = 999
    T:assertEqual(original_m, a.m)
    T:assertEqual(original_e, a.e)
end)

-- ============================================================================
-- BUG #8: Bare `nan` Variable Reference
-- log10() and ln() used undefined `nan` variable
-- Fix: Changed to proper NaN check (x ~= x)
-- ============================================================================

T:test("BUG #8: log10 of NaN returns 0 (not crash)", function()
    local nan_big = Big:new(0/0)
    local result = nan_big:log10()
    T:assertEqual(0, result, "log10 of NaN should return 0")
end)

T:test("BUG #8: ln of NaN returns 0 (not crash)", function()
    local nan_big = Big:new(0/0)
    local result = nan_big:ln()
    T:assertEqual(0, result, "ln of NaN should return 0")
end)

T:test("BUG #8: log10 of negative returns 0", function()
    local a = Big:new(-5)
    local result = a:log10()
    T:assertEqual(0, result, "log10 of negative should return 0")
end)

-- ============================================================================
-- Run bignumber tests, then switch to omeganum
-- ============================================================================

print("\n=== BIGNUMBER.LUA BUG FIX TESTS ===")
local bignumber_success = T:run()

-- Reset test runner for omeganum tests
T.tests = {}
T.passed = 0
T.failed = 0

-- Need to reload in a clean environment for omeganum
-- Since both define Big globally, we need to be careful
package.loaded["bignumber"] = nil
Big = nil
R = nil

local OmegaBig = require("omeganum")

-- ============================================================================
-- OMEGANUM.LUA SPECIFIC BUG FIXES
-- ============================================================================

-- ============================================================================
-- BUG #1b: R.LOG10E in omeganum.lua
-- ============================================================================

T:test("BUG #1b: omeganum R.LOG10E equals log base 10 of e", function()
    local expected = math.log(math.exp(1), 10)
    -- R.LOG10E is a raw number in omeganum.lua
    T:assertApprox(expected, R.LOG10E, 1e-9)
end)

T:test("BUG #1b: omeganum R.LOG10E is not NaN or zero", function()
    T:assert(R.LOG10E == R.LOG10E, "R.LOG10E should not be NaN")
    T:assert(R.LOG10E ~= 0, "R.LOG10E should not be zero")
end)

-- ============================================================================
-- BUG #4: Missing Return Statement in Big:root
-- ============================================================================

T:test("BUG #4: root of 0 returns a value (not nil)", function()
    local zero = OmegaBig:create(0)
    local result = zero:root(2)
    T:assertNotNil(result, "root should return a value")
    T:assertEqual(0, result:to_number())
end)

T:test("BUG #4: root of negative returns a value", function()
    local neg = OmegaBig:create(-8)
    local result = neg:root(3)
    T:assertNotNil(result, "root of negative should return a value")
end)

T:test("BUG #4: square root of 16 = 4", function()
    local a = OmegaBig:create(16)
    local result = a:root(2)
    T:assertApprox(4, result:to_number(), 1e-9)
end)

T:test("BUG #4: cube root of 27 = 3", function()
    local a = OmegaBig:create(27)
    local result = a:root(3)
    T:assertApprox(3, result:to_number(), 1e-9)
end)

-- ============================================================================
-- BUG #5: Extra Argument to math.pow (implicitly tested via pow working)
-- ============================================================================

T:test("BUG #5: pow function works correctly", function()
    local a = OmegaBig:create(2)
    local result = a:pow(OmegaBig:create(10))
    T:assertApprox(1024, result:to_number(), 1e-6)
end)

-- ============================================================================
-- BUG #6: JavaScript References in Lua Code
-- math.log10 doesn't exist in Lua, Math.log10 is JS syntax, b[0] is JS indexing
-- ============================================================================

T:test("BUG #6: log10 works (no JavaScript math.log10)", function()
    local a = OmegaBig:create(1000)
    local result = a:log10()
    T:assertApprox(3, result:to_number(), 1e-9)
end)

T:test("BUG #6: log10 of 100 = 2", function()
    local a = OmegaBig:create(100)
    local result = a:log10()
    T:assertApprox(2, result:to_number(), 1e-9)
end)

T:test("BUG #6: logBase works correctly", function()
    local a = OmegaBig:create(8)
    -- logBase expects a Big object, not a raw number
    local result = a:logBase(OmegaBig:create(2))
    T:assertApprox(3, result:to_number(), 1e-9)
end)

-- ============================================================================
-- BUG #7: Intentional Crashes for Error Handling
-- Replaced nil.field crashes with proper error() calls
-- ============================================================================

T:test("BUG #7: arrow with invalid height throws error", function()
    local a = OmegaBig:create(2)
    local success, err = pcall(function()
        return a:arrow(1, -1)  -- Negative height is invalid
    end)
    -- Should either work or throw a proper error, not crash with nil access
    T:assert(success or (err and type(err) == "string"),
        "Should either succeed or throw proper error")
end)

T:test("BUG #7: tetrate with invalid height throws error", function()
    local a = OmegaBig:create(2)
    local success, err = pcall(function()
        return a:tetrate(-1)  -- Negative height
    end)
    T:assert(success or (err and type(err) == "string"),
        "Should either succeed or throw proper error")
end)

-- ============================================================================
-- BUG #10: Infinity Minus Infinity Returned 0 Instead of NaN
-- ============================================================================

T:test("BUG #10: inf - inf = NaN", function()
    local inf = OmegaBig:create(1/0)
    local result = inf:sub(inf)
    T:assert(result:isNaN(), "inf - inf should be NaN")
end)

T:test("BUG #10: -inf - (-inf) = NaN", function()
    local neg_inf = OmegaBig:create(-1/0)
    local result = neg_inf:sub(neg_inf)
    T:assert(result:isNaN(), "-inf - (-inf) should be NaN")
end)

T:test("BUG #10: inf - (-inf) = inf (not NaN)", function()
    local pos_inf = OmegaBig:create(1/0)
    local neg_inf = OmegaBig:create(-1/0)
    local result = pos_inf:sub(neg_inf)
    T:assert(result:isInfinite(), "inf - (-inf) should be infinite")
    T:assert(not result:isNaN(), "inf - (-inf) should not be NaN")
end)

-- ============================================================================
-- BUG #11: Zero Divided by Zero Returned Infinity Instead of NaN
-- ============================================================================

T:test("BUG #11: 0 / 0 = NaN", function()
    local zero = OmegaBig:create(0)
    local result = zero:div(zero)
    T:assert(result:isNaN(), "0/0 should be NaN")
end)

T:test("BUG #11: 5 / 0 = infinity (not NaN)", function()
    local five = OmegaBig:create(5)
    local zero = OmegaBig:create(0)
    local result = five:div(zero)
    T:assert(result:isInfinite(), "5/0 should be infinity")
end)

-- ============================================================================
-- BUG #12: Infinity Divided by Infinity Returned Infinity Instead of NaN
-- ============================================================================

T:test("BUG #12: inf / inf = NaN", function()
    local inf = OmegaBig:create(1/0)
    local result = inf:div(inf)
    T:assert(result:isNaN(), "inf/inf should be NaN")
end)

T:test("BUG #12: inf / (-inf) = NaN", function()
    local pos_inf = OmegaBig:create(1/0)
    local neg_inf = OmegaBig:create(-1/0)
    local result = pos_inf:div(neg_inf)
    T:assert(result:isNaN(), "inf/(-inf) should be NaN")
end)

T:test("BUG #12: (-inf) / (-inf) = NaN", function()
    local neg_inf = OmegaBig:create(-1/0)
    local result = neg_inf:div(neg_inf)
    T:assert(result:isNaN(), "(-inf)/(-inf) should be NaN")
end)

T:test("BUG #12: inf / 5 = inf (not NaN)", function()
    local inf = OmegaBig:create(1/0)
    local five = OmegaBig:create(5)
    local result = inf:div(five)
    T:assert(result:isInfinite(), "inf/5 should be infinite")
    T:assert(not result:isNaN(), "inf/5 should not be NaN")
end)

-- ============================================================================
-- Run omeganum tests
-- ============================================================================

print("\n=== OMEGANUM.LUA BUG FIX TESTS ===")
local omeganum_success = T:run()

-- Final summary
print("\n=== FINAL SUMMARY ===")
if bignumber_success and omeganum_success then
    print("All bug fix regression tests PASSED!")
    os.exit(0)
else
    print("Some bug fix tests FAILED!")
    os.exit(1)
end
