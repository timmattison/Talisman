#!/usr/bin/env lua
--- Tests for bignumber.lua (Big number library)

-- Add parent directory to package path for imports
package.path = package.path .. ";../?.lua;../big-num/?.lua"

-- Stub number_format since it's defined elsewhere in Talisman
function number_format(b)
    return b:to_string()
end

local TestRunner = require("test-runner")
local T = TestRunner

-- Load the Big number library
local Big = require("bignumber")

-- ============================================================================
-- Basic Construction Tests
-- ============================================================================

T:test("Big:new with number creates valid Big", function()
    local b = Big:new(42)
    T:assertNotNil(b)
    T:assertEqual(42, b:to_number())
end)

T:test("Big:new with 0 creates zero", function()
    local b = Big:new(0)
    T:assertEqual(0, b:to_number())
    T:assertEqual(0, b.e)
    T:assertEqual(0, b.m)
end)

T:test("Big:new with negative number", function()
    local b = Big:new(-123)
    T:assertApprox(-123, b:to_number(), 1e-9)
end)

T:test("Big:new with mantissa and exponent", function()
    local b = Big:new(1.5, 3)
    T:assertApprox(1500, b:to_number(), 1e-9)
end)

T:test("Big:new from string", function()
    local b = Big:new("1e10")
    T:assertApprox(1e10, b:to_number(), 1)
end)

T:test("Big:new from another Big (copy)", function()
    local a = Big:new(999)
    local b = Big:new(a)
    T:assertEqual(999, b:to_number())
end)

-- ============================================================================
-- Arithmetic Tests
-- ============================================================================

T:test("Big addition", function()
    local a = Big:new(100)
    local b = Big:new(50)
    local result = a + b
    T:assertEqual(150, result:to_number())
end)

T:test("Big addition with number", function()
    local a = Big:new(100)
    local result = a + 25
    T:assertEqual(125, result:to_number())
end)

T:test("Number + Big", function()
    local b = Big:new(100)
    local result = 25 + b
    T:assertEqual(125, result:to_number())
end)

T:test("Big subtraction", function()
    local a = Big:new(100)
    local b = Big:new(30)
    local result = a - b
    T:assertApprox(70, result:to_number(), 1e-9)
end)

T:test("Big multiplication", function()
    local a = Big:new(12)
    local b = Big:new(10)
    local result = a * b
    T:assertEqual(120, result:to_number())
end)

T:test("Big division", function()
    local a = Big:new(100)
    local b = Big:new(4)
    local result = a / b
    T:assertEqual(25, result:to_number())
end)

T:test("Big negation", function()
    local a = Big:new(50)
    local result = -a
    T:assertEqual(-50, result:to_number())
end)

T:test("Big:pow with integer exponent", function()
    local a = Big:new(2)
    local result = a:pow(10)
    T:assertApprox(1024, result:to_number(), 1e-9)
end)

T:test("Big:pow with fractional exponent", function()
    local a = Big:new(16)
    local result = a:pow(0.5)
    T:assertApprox(4, result:to_number(), 1e-9)
end)

T:test("Big:sqrt", function()
    local a = Big:new(81)
    local result = a:sqrt()
    T:assertApprox(9, result:to_number(), 1e-9)
end)

T:test("Big:cbrt (cube root)", function()
    local a = Big:new(27)
    local result = a:cbrt()
    T:assertApprox(3, result:to_number(), 1e-9)
end)

-- ============================================================================
-- Logarithm Tests
-- ============================================================================

T:test("Big:log10 of 100", function()
    local a = Big:new(100)
    local result = a:log10()
    T:assertApprox(2, result, 1e-9)
end)

T:test("Big:log10 of 1000", function()
    local a = Big:new(1000)
    local result = a:log10()
    T:assertApprox(3, result, 1e-9)
end)

T:test("Big:log with base 2", function()
    local a = Big:new(8)
    local result = a:log(2)
    T:assertApprox(3, result, 1e-9)
end)

T:test("Big:ln (natural log)", function()
    local a = Big:new(math.exp(1))
    local result = a:ln()
    T:assertApprox(1, result, 1e-9)
end)

T:test("Big:ld (log base 2)", function()
    local a = Big:new(32)
    local result = a:ld()
    T:assertApprox(5, result, 1e-9)
end)

-- ============================================================================
-- Comparison Tests
-- ============================================================================

T:test("Big:compare equal", function()
    local a = Big:new(100)
    local b = Big:new(100)
    T:assertEqual(0, a:compare(b))
end)

T:test("Big:compare greater", function()
    local a = Big:new(200)
    local b = Big:new(100)
    T:assertEqual(1, a:compare(b))
end)

T:test("Big:compare less", function()
    local a = Big:new(50)
    local b = Big:new(100)
    T:assertEqual(-1, a:compare(b))
end)

T:test("Big:gt", function()
    local a = Big:new(100)
    local b = Big:new(50)
    T:assert(a:gt(b))
    T:assert(not b:gt(a))
end)

T:test("Big:lt", function()
    local a = Big:new(50)
    local b = Big:new(100)
    T:assert(a:lt(b))
    T:assert(not b:lt(a))
end)

T:test("Big:eq", function()
    local a = Big:new(100)
    local b = Big:new(100)
    T:assert(a:eq(b))
end)

T:test("Big:gte", function()
    local a = Big:new(100)
    local b = Big:new(100)
    local c = Big:new(50)
    T:assert(a:gte(b))
    T:assert(a:gte(c))
    T:assert(not c:gte(a))
end)

T:test("Big:lte", function()
    local a = Big:new(100)
    local b = Big:new(100)
    local c = Big:new(150)
    T:assert(a:lte(b))
    T:assert(a:lte(c))
    T:assert(not c:lte(a))
end)

T:test("Comparing positive and negative", function()
    local a = Big:new(100)
    local b = Big:new(-100)
    T:assert(a:gt(b))
    T:assert(b:lt(a))
end)

T:test("Comparing with zero", function()
    local a = Big:new(100)
    local b = Big:new(-100)
    local zero = Big:new(0)
    T:assert(a:gt(zero))
    T:assert(zero:lt(a))
    T:assert(zero:gt(b))
    T:assert(b:lt(zero))
end)

-- ============================================================================
-- Rounding Tests
-- ============================================================================

T:test("Big:floor", function()
    local a = Big:new(3.7)
    T:assertEqual(3, a:floor():to_number())
end)

T:test("Big:ceil", function()
    local a = Big:new(3.2)
    T:assertEqual(4, a:ceil():to_number())
end)

T:test("Big:round down", function()
    local a = Big:new(3.4)
    T:assertEqual(3, a:round():to_number())
end)

T:test("Big:round up", function()
    local a = Big:new(3.6)
    T:assertEqual(4, a:round():to_number())
end)

-- ============================================================================
-- Large Number Tests
-- ============================================================================

T:test("Big handles large numbers", function()
    local a = Big:new(1, 100) -- 1e100
    T:assertEqual(100, a.e)
    T:assertApprox(1, a.m, 1e-9)
end)

T:test("Big multiplication with large numbers", function()
    local a = Big:new(1, 50)
    local b = Big:new(1, 50)
    local result = a * b
    T:assertEqual(100, result.e)
end)

T:test("Adding very different magnitudes returns larger", function()
    local a = Big:new(1, 100)
    local b = Big:new(1, 1)
    local result = a + b
    -- Due to precision limits, result should be approximately equal to a
    T:assert(result:eq(a))
end)

-- ============================================================================
-- Edge Cases and Potential Bug Detection
-- ============================================================================

T:test("Big:mod positive numbers", function()
    local a = Big:new(10)
    local b = Big:new(3)
    local result = a:mod(b)
    T:assertApprox(1, result:to_number(), 1e-9)
end)

T:test("Big:mod with larger divisor", function()
    local a = Big:new(3)
    local b = Big:new(10)
    local result = a:mod(b)
    T:assertApprox(3, result:to_number(), 1e-9)
end)

T:test("Big:abs", function()
    local a = Big:new(-42)
    local result = a:abs()
    T:assertApprox(42, result:to_number(), 1e-9)
end)

T:test("R.LOG10E equals log base 10 of e", function()
    -- R.LOG10E should be math.log(R.E, 10) = ~0.4343
    local expected = math.log(math.exp(1), 10)
    T:assertApprox(expected, R.LOG10E, 1e-9)
end)

T:test("Division by zero handling", function()
    local a = Big:new(10)
    local b = Big:new(0)
    local result = a / b
    -- Should handle infinity or NaN gracefully
    T:assert(result.m ~= result.m or result.m == math.huge or result.m == -math.huge,
        "Division by zero should result in inf or nan")
end)

T:test("Zero to power of zero", function()
    local zero = Big:new(0)
    local result = zero:pow(0)
    -- 0^0 is mathematically undefined, implementation returns 0
    T:assertEqual(0, result:to_number())
end)

T:test("Negative number to even power is positive", function()
    -- (-2)^2 = 4
    local a = Big:new(-2)
    local result = a:pow(2)
    T:assertApprox(4, result:to_number(), 1e-9)
end)

T:test("Negative number to odd power is negative", function()
    -- (-2)^3 = -8
    local a = Big:new(-2)
    local result = a:pow(3)
    T:assertApprox(-8, result:to_number(), 1e-9)
end)

-- ============================================================================
-- Trigonometry Tests
-- ============================================================================

T:test("Big:sin", function()
    local a = Big:new(0)
    T:assertApprox(0, a:sin():to_number(), 1e-9)
end)

T:test("Big:cos", function()
    local a = Big:new(0)
    T:assertApprox(1, a:cos():to_number(), 1e-9)
end)

T:test("Big:tan", function()
    local a = Big:new(0)
    T:assertApprox(0, a:tan():to_number(), 1e-9)
end)

-- ============================================================================
-- Run all tests
-- ============================================================================

local success = T:run()
os.exit(success and 0 or 1)
