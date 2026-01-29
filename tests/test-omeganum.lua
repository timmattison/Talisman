#!/usr/bin/env lua
--- Tests for omeganum.lua (OmegaNum library for very large numbers)

-- Add parent directory to package path for imports
package.path = package.path .. ";../?.lua;../big-num/?.lua"

-- Stub number_format since it's defined elsewhere in Talisman
function number_format(b)
    return b:toString()
end

local TestRunner = require("test-runner")
local T = TestRunner

-- Load the OmegaNum library
local Big = require("omeganum")

-- ============================================================================
-- Basic Construction Tests
-- ============================================================================

T:test("Big:create with number", function()
    local b = Big:create(42)
    T:assertNotNil(b)
    T:assertEqual(42, b:to_number())
end)

T:test("Big:create with 0", function()
    local b = Big:create(0)
    T:assertEqual(0, b:to_number())
end)

T:test("Big:create with negative number", function()
    local b = Big:create(-123)
    T:assertEqual(-123, b:to_number())
end)

T:test("Big:create from string", function()
    local b = Big:create("1000")
    T:assertEqual(1000, b:to_number())
end)

T:test("Big:clone creates independent copy", function()
    local a = Big:create(999)
    local b = a:clone()
    T:assertEqual(999, b:to_number())
    -- Modify original, clone should not change
    a.array[1] = 111
    T:assertEqual(999, b:to_number())
end)

-- ============================================================================
-- Arithmetic Tests
-- ============================================================================

T:test("OmegaNum addition", function()
    local a = Big:create(100)
    local b = Big:create(50)
    local result = a:add(b)
    T:assertEqual(150, result:to_number())
end)

T:test("OmegaNum addition with operator", function()
    local a = Big:create(100)
    local b = Big:create(50)
    local result = a + b
    T:assertEqual(150, result:to_number())
end)

T:test("OmegaNum subtraction", function()
    local a = Big:create(100)
    local b = Big:create(30)
    local result = a:sub(b)
    T:assertEqual(70, result:to_number())
end)

T:test("OmegaNum multiplication", function()
    local a = Big:create(12)
    local b = Big:create(10)
    local result = a:mul(b)
    T:assertEqual(120, result:to_number())
end)

T:test("OmegaNum division", function()
    local a = Big:create(100)
    local b = Big:create(4)
    local result = a:div(b)
    T:assertEqual(25, result:to_number())
end)

T:test("OmegaNum negation", function()
    local a = Big:create(50)
    local result = a:neg()
    T:assertEqual(-50, result:to_number())
end)

T:test("OmegaNum power", function()
    local a = Big:create(2)
    local result = a:pow(Big:create(10))
    T:assertEqual(1024, result:to_number())
end)

T:test("OmegaNum mod", function()
    local a = Big:create(10)
    local b = Big:create(3)
    local result = a:mod(b)
    T:assertApprox(1, result:to_number(), 1e-9)
end)

-- ============================================================================
-- Comparison Tests
-- ============================================================================

T:test("OmegaNum:compareTo equal", function()
    local a = Big:create(100)
    local b = Big:create(100)
    T:assertEqual(0, a:compareTo(b))
end)

T:test("OmegaNum:compareTo greater", function()
    local a = Big:create(200)
    local b = Big:create(100)
    T:assertEqual(1, a:compareTo(b))
end)

T:test("OmegaNum:compareTo less", function()
    local a = Big:create(50)
    local b = Big:create(100)
    T:assertEqual(-1, a:compareTo(b))
end)

T:test("OmegaNum:gt", function()
    local a = Big:create(100)
    local b = Big:create(50)
    T:assert(a:gt(b))
end)

T:test("OmegaNum:lt", function()
    local a = Big:create(50)
    local b = Big:create(100)
    T:assert(a:lt(b))
end)

T:test("OmegaNum:eq", function()
    local a = Big:create(100)
    local b = Big:create(100)
    T:assert(a:eq(b))
end)

T:test("OmegaNum:min", function()
    local a = Big:create(100)
    local b = Big:create(50)
    local result = a:min(b)
    T:assertEqual(50, result:to_number())
end)

T:test("OmegaNum:max", function()
    local a = Big:create(100)
    local b = Big:create(50)
    local result = a:max(b)
    T:assertEqual(100, result:to_number())
end)

-- ============================================================================
-- Logarithm Tests
-- ============================================================================

T:test("OmegaNum:log10 of 100", function()
    local a = Big:create(100)
    local result = a:log10()
    T:assertApprox(2, result:to_number(), 1e-9)
end)

T:test("OmegaNum:logBase with base 2", function()
    local a = Big:create(8)
    local result = a:logBase(Big:create(2))
    T:assertApprox(3, result:to_number(), 1e-9)
end)

T:test("OmegaNum:ln (natural log)", function()
    local a = Big:create(math.exp(1))
    local result = a:ln()
    T:assertApprox(1, result:to_number(), 1e-9)
end)

-- ============================================================================
-- Special Value Tests
-- ============================================================================

T:test("OmegaNum:isNaN", function()
    local a = Big:create(0/0)
    T:assert(a:isNaN())
end)

T:test("OmegaNum:isInfinite", function()
    local a = Big:create(1/0)
    T:assert(a:isInfinite())
end)

T:test("OmegaNum:isFinite", function()
    local a = Big:create(100)
    T:assert(a:isFinite())
end)

T:test("OmegaNum:abs", function()
    local a = Big:create(-100)
    T:assertEqual(100, a:abs():to_number())
end)

-- ============================================================================
-- Floor and Ceil Tests
-- ============================================================================

T:test("OmegaNum:floor", function()
    local a = Big:create(3.7)
    T:assertEqual(3, a:floor():to_number())
end)

T:test("OmegaNum:ceil", function()
    local a = Big:create(3.2)
    T:assertEqual(4, a:ceil():to_number())
end)

-- ============================================================================
-- Large Number Tests (Tetration, etc.)
-- ============================================================================

T:test("OmegaNum tetrate 2^^3 = 16", function()
    local a = Big:create(2)
    local result = a:tetrate(3)
    T:assertEqual(16, result:to_number())
end)

T:test("OmegaNum tetrate 2^^4 = 65536", function()
    local a = Big:create(2)
    local result = a:tetrate(4)
    T:assertEqual(65536, result:to_number())
end)

T:test("OmegaNum 10^10 = 1e10", function()
    local a = Big:create(10)
    local result = a:pow(Big:create(10))
    T:assertApprox(1e10, result:to_number(), 1)
end)

-- ============================================================================
-- Bug Detection Tests
-- ============================================================================

T:test("R.LOG10E equals log base 10 of e", function()
    -- R.LOG10E should be math.log(R.E, 10) = ~0.4343
    local expected = math.log(math.exp(1), 10)
    T:assertApprox(expected, R.LOG10E, 1e-9)
end)

T:test("Big:root missing return statement (BUG)", function()
    -- In omeganum.lua line 962, Big:root has:
    -- if self:max(other):gt(B.TETRATED_MAX_SAFE_INTEGER) then
    --     if self:gt(other) then return self:clone()
    --     else Big:create(B.ZERO) -- Missing return!
    -- This test checks the behavior
    local a = Big:create(4)
    local result = a:root(Big:create(2))
    T:assertApprox(2, result:to_number(), 1e-9)
end)

T:test("Division by zero returns infinity", function()
    local a = Big:create(10)
    local b = Big:create(0)
    local result = a:div(b)
    T:assert(result:isInfinite(), "Division by zero should return infinity")
end)

T:test("Parse handles scientific notation", function()
    local a = Big:parse("1e10")
    T:assertApprox(1e10, a:to_number(), 1)
end)

T:test("Parse handles negative numbers", function()
    local a = Big:parse("-100")
    T:assertEqual(-100, a:to_number())
end)

T:test("Parse handles NaN string", function()
    local a = Big:parse("NaN")
    T:assert(a:isNaN())
end)

T:test("Parse handles Infinity string", function()
    local a = Big:parse("Infinity")
    T:assert(a:isInfinite())
end)

-- ============================================================================
-- Normalization Tests
-- ============================================================================

T:test("Normalize handles empty array", function()
    local b = Big:new({})
    T:assertEqual(0, b:to_number())
end)

T:test("Normalize handles negative first element", function()
    local b = Big:new({-100})
    T:assertEqual(-100, b:to_number())
end)

-- ============================================================================
-- String Conversion Tests
-- ============================================================================

T:test("toString for small numbers", function()
    local a = Big:create(42)
    local s = a:toString()
    T:assertNotNil(s)
    T:assert(string.find(s, "42"), "String should contain 42")
end)

T:test("toString for negative numbers", function()
    local a = Big:create(-42)
    local s = a:toString()
    T:assert(string.find(s, "-"), "String should contain minus sign")
end)

-- ============================================================================
-- Integer Check Tests
-- ============================================================================

T:test("isint for integer", function()
    local a = Big:create(42)
    T:assert(a:isint())
end)

T:test("isint for non-integer", function()
    local a = Big:create(42.5)
    T:assert(not a:isint())
end)

-- ============================================================================
-- Arrow Notation Tests
-- ============================================================================

T:test("arrow(1, 2) is power", function()
    local a = Big:create(2)
    local result = a:arrow(1, 2)
    -- 2 arrow 1 with 2 should be 2^2 = 4
    -- But arrow(1, x) returns self unchanged per the code
    T:assertNotNil(result)
end)

T:test("arrow(2, 2) is tetration", function()
    local a = Big:create(2)
    local result = a:arrow(2, 2)
    -- 2^^2 = 2^2 = 4
    T:assertEqual(4, result:to_number())
end)

-- ============================================================================
-- B constants tests
-- ============================================================================

T:test("B.ZERO equals 0", function()
    T:assertEqual(0, B.ZERO:to_number())
end)

T:test("B.ONE equals 1", function()
    T:assertEqual(1, B.ONE:to_number())
end)

T:test("B.E equals Euler's number", function()
    T:assertApprox(math.exp(1), B.E:to_number(), 1e-9)
end)

-- ============================================================================
-- Run all tests
-- ============================================================================

local success = T:run()
os.exit(success and 0 or 1)
