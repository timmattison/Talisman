#!/usr/bin/env lua
--- Edge case and stress tests to find more bugs
--- Note: bignumber.lua and omeganum.lua both define Big globally,
--- so we test them in separate processes

package.path = package.path .. ";../?.lua;../big-num/?.lua"

function number_format(b)
    if b.array then return b:toString() else return b:to_string() end
end

local TestRunner = require("test-runner")
local T = TestRunner

-- ============================================================================
-- OMEGANUM.LUA EDGE CASES (test this first since it's more comprehensive)
-- ============================================================================

local Big = require("omeganum")

T:test("Omega: Create from very large number", function()
    local a = Big:create(1e300)
    T:assert(a:isFinite(), "Should be finite")
    T:assert(a:gt(Big:create(0)), "Should be positive")
end)

T:test("Omega: Infinity arithmetic", function()
    local inf = Big:create(1/0)
    local num = Big:create(100)
    T:assert((inf + num):isInfinite(), "inf + num should be infinite")
    T:assert((inf * num):isInfinite(), "inf * num should be infinite")
end)

T:test("Omega: NaN propagation", function()
    local nan = Big:create(0/0)
    local num = Big:create(100)
    T:assert((nan + num):isNaN(), "NaN + num should be NaN")
    T:assert((nan * num):isNaN(), "NaN * num should be NaN")
end)

T:test("Omega: Infinity minus infinity is NaN", function()
    local inf = Big:create(1/0)
    local result = inf:sub(inf)
    T:assert(result:isNaN(), "inf - inf should be NaN")
end)

T:test("Omega: Negative infinity minus negative infinity is NaN", function()
    local neg_inf = Big:create(-1/0)
    local result = neg_inf:sub(neg_inf)
    T:assert(result:isNaN(), "-inf - (-inf) should be NaN")
end)

T:test("Omega: Infinity minus negative infinity is infinity", function()
    local pos_inf = Big:create(1/0)
    local neg_inf = Big:create(-1/0)
    local result = pos_inf:sub(neg_inf)
    T:assert(result:isInfinite(), "inf - (-inf) should be infinite")
end)

T:test("Omega: Zero divided by zero is NaN", function()
    local zero = Big:create(0)
    local result = zero:div(zero)
    T:assert(result:isNaN(), "0/0 should be NaN")
end)

T:test("Omega: Infinity divided by infinity is NaN", function()
    local inf = Big:create(1/0)
    local result = inf:div(inf)
    T:assert(result:isNaN(), "inf/inf should be NaN")
end)

T:test("Omega: Number divided by zero is infinity", function()
    local num = Big:create(5)
    local zero = Big:create(0)
    local result = num:div(zero)
    T:assert(result:isInfinite(), "5/0 should be infinity")
end)

T:test("Omega: Negative number absolute value", function()
    local a = Big:create(-12345)
    local result = a:abs()
    T:assertEqual(12345, result:to_number())
    T:assertEqual(1, result.sign)
end)

T:test("Omega: Clone independence", function()
    local a = Big:create(100)
    local b = a:clone()
    a.array[1] = 999
    T:assertEqual(100, b:to_number(), "Clone should be independent")
end)

T:test("Omega: ensureBig with Big returns same", function()
    local a = Big:create(100)
    local b = Big:ensureBig(a)
    T:assert(a:eq(b), "ensureBig on Big should return equivalent")
end)

T:test("Omega: ensureBig with number", function()
    local a = Big:ensureBig(42)
    T:assertEqual(42, a:to_number())
end)

T:test("Omega: Tetration base 1", function()
    local one = Big:create(1)
    local result = one:tetrate(100)
    T:assertEqual(1, result:to_number(), "1^^anything = 1")
end)

T:test("Omega: Tetration height 0", function()
    local a = Big:create(10)
    local result = a:tetrate(0)
    T:assertEqual(1, result:to_number(), "x^^0 = 1")
end)

T:test("Omega: Tetration height 1", function()
    local a = Big:create(5)
    local result = a:tetrate(1)
    T:assertEqual(5, result:to_number(), "x^^1 = x")
end)

T:test("Omega: Power of 10", function()
    local ten = Big:create(10)
    local result = ten:pow(Big:create(3))
    T:assertEqual(1000, result:to_number())
end)

T:test("Omega: Log10 of power of 10", function()
    local a = Big:create(10000)
    local result = a:log10()
    T:assertApprox(4, result:to_number(), 1e-9)
end)

T:test("Omega: rec (reciprocal)", function()
    local a = Big:create(4)
    local result = a:rec()
    T:assertApprox(0.25, result:to_number(), 1e-9)
end)

T:test("Omega: Reciprocal of infinity is zero", function()
    local inf = Big:create(1/0)
    local result = inf:rec()
    T:assertEqual(0, result:to_number())
end)

T:test("Omega: floor of large number", function()
    local a = Big:create(1e20)
    local result = a:floor()
    T:assert(result:eq(a), "Floor of integer should be same")
end)

T:test("Omega: Negative sign handling in add", function()
    local a = Big:create(-5)
    local b = Big:create(10)
    local result = a:add(b)
    T:assertEqual(5, result:to_number())
end)

T:test("Omega: Subtraction with negative result", function()
    local a = Big:create(5)
    local b = Big:create(10)
    local result = a:sub(b)
    T:assertEqual(-5, result:to_number())
end)

T:test("Omega: Parse tower notation", function()
    local success, result = pcall(function()
        return Big:parse("ee5")
    end)
    if success then
        T:assert(result:gt(Big:create(1e100)), "ee5 should be very large")
    end
end)

T:test("Omega: arraySize for simple number", function()
    local a = Big:create(100)
    T:assertEqual(1, a:arraySize())
end)

T:test("Omega: Comparison with different array sizes", function()
    local small = Big:create(100)
    local large = Big:create(1e100)
    T:assert(large:gt(small), "1e100 > 100")
    T:assert(small:lt(large), "100 < 1e100")
end)

T:test("Omega: slog of 10", function()
    local ten = Big:create(10)
    local result = ten:slog(10)
    T:assertApprox(1, result:to_number(), 1e-9, "slog_10(10) = 1")
end)

T:test("Omega: slog of 10^10", function()
    local a = Big:create(1e10)
    local result = a:slog(10)
    T:assertApprox(2, result:to_number(), 0.1, "slog_10(10^10) ≈ 2")
end)

T:test("Omega: Arrow notation 2^^^2", function()
    local two = Big:create(2)
    local result = two:arrow(3, 2)
    T:assertEqual(4, result:to_number())
end)

T:test("Omega: mod returns correct type", function()
    local a = Big:create(17)
    local b = Big:create(5)
    local result = a:mod(b)
    T:assertApprox(2, result:to_number(), 1e-9)
end)

T:test("Omega: Negative mod", function()
    local a = Big:create(-17)
    local b = Big:create(5)
    local result = a:mod(b)
    T:assertNotNil(result)
end)

T:test("Omega: max_for_op returns valid Big", function()
    local result = Big:max_for_op(2)
    T:assertNotNil(result)
    T:assert(result:isFinite(), "Should be finite")
end)

T:test("Omega: toString of negative number", function()
    local a = Big:create(-42)
    local s = a:toString()
    T:assert(string.sub(s, 1, 1) == "-", "Should start with minus")
end)

T:test("Omega: Operator metamethods work", function()
    local a = Big:create(10)
    local b = Big:create(3)
    T:assert((a + b):eq(Big:create(13)), "Addition operator")
    T:assert((a - b):eq(Big:create(7)), "Subtraction operator")
    T:assert((a * b):eq(Big:create(30)), "Multiplication operator")
    T:assert((a % b):eq(Big:create(1)), "Modulo operator")
end)

T:test("Omega: Unary minus operator", function()
    local a = Big:create(42)
    local result = -a
    T:assertEqual(-42, result:to_number())
end)

T:test("Omega: Comparison operators", function()
    local a = Big:create(10)
    local b = Big:create(5)
    T:assert(a > b, "10 > 5")
    T:assert(b < a, "5 < 10")
    T:assert(a >= a, "10 >= 10")
    T:assert(a <= a, "10 <= 10")
end)

T:test("Omega: Equality operator", function()
    local a = Big:create(42)
    local b = Big:create(42)
    T:assert(a == b, "Equal Bigs should be ==")
end)

T:test("Omega: exp function", function()
    local result = Big:create(1):exp()
    T:assertApprox(math.exp(1), result:to_number(), 1e-9)
end)

T:test("Omega: Very small positive number", function()
    local a = Big:create(1e-100)
    T:assert(a:to_number() > 0, "Should be positive")
    T:assert(a:lt(Big:create(1)), "Should be less than 1")
end)

T:test("Omega: Multiply by zero", function()
    local a = Big:create(1e50)
    local result = a * Big:create(0)
    T:assertEqual(0, result:to_number())
end)

T:test("Omega: Power of 1", function()
    local a = Big:create(12345)
    local result = a:pow(Big:create(1))
    T:assertApprox(12345, result:to_number(), 1e-9)
end)

T:test("Omega: Power of 0", function()
    local a = Big:create(12345)
    local result = a:pow(Big:create(0))
    T:assertApprox(1, result:to_number(), 1e-9)
end)

T:test("Omega: 1 to any power is 1", function()
    local one = Big:create(1)
    T:assertApprox(1, one:pow(Big:create(100)):to_number(), 1e-9)
    T:assertApprox(1, one:pow(Big:create(0)):to_number(), 1e-9)
end)

T:test("Omega: Negative power (reciprocal)", function()
    local a = Big:create(2)
    local result = a:pow(Big:create(-1))
    T:assertApprox(0.5, result:to_number(), 1e-9)
end)

T:test("Omega: Square root via power", function()
    local a = Big:create(16)
    local result = a:pow(Big:create(0.5))
    T:assertApprox(4, result:to_number(), 1e-9)
end)

T:test("Omega: Log of 1 is 0", function()
    local one = Big:create(1)
    T:assertApprox(0, one:log10():to_number(), 1e-9)
end)

T:test("Omega: Chained operations", function()
    local a = Big:create(10)
    local result = ((a + Big:create(5)) * Big:create(2) - Big:create(10)) / Big:create(5)
    T:assertApprox(4, result:to_number(), 1e-9)
end)

T:test("Omega: Double negation", function()
    local a = Big:create(42)
    local result = a:neg():neg()
    T:assertApprox(42, result:to_number(), 1e-9)
end)

T:test("Omega: Comparing equal negative numbers", function()
    local a = Big:create(-100)
    local b = Big:create(-100)
    T:assert(a:eq(b), "Equal negative numbers should be equal")
end)

T:test("Omega: floor of negative number", function()
    local a = Big:create(-3.7)
    local result = a:floor()
    T:assertEqual(-4, result:to_number())
end)

T:test("Omega: ceil of negative number", function()
    local a = Big:create(-3.2)
    local result = a:ceil()
    T:assertEqual(-3, result:to_number())
end)

T:test("Omega: Parse negative scientific notation", function()
    local a = Big:parse("-1e5")
    T:assertApprox(-100000, a:to_number(), 1)
end)

T:test("Omega: Mod with equal numbers", function()
    local a = Big:create(10)
    local b = Big:create(10)
    local result = a:mod(b)
    T:assertApprox(0, result:to_number(), 1e-9)
end)

T:test("Omega: isint for integer", function()
    local a = Big:create(42)
    T:assert(a:isint(), "42 should be an integer")
end)

T:test("Omega: isint for non-integer", function()
    local a = Big:create(42.5)
    T:assert(not a:isint(), "42.5 should not be an integer")
end)

T:test("Omega: Multiplication sign rules", function()
    local pos = Big:create(5)
    local neg = Big:create(-3)
    T:assert((pos * neg):lt(Big:create(0)), "pos * neg should be negative")
    T:assert((neg * pos):lt(Big:create(0)), "neg * pos should be negative")
    T:assert((neg * neg):gt(Big:create(0)), "neg * neg should be positive")
end)

T:test("Omega: Division sign rules", function()
    local pos = Big:create(10)
    local neg = Big:create(-2)
    T:assert((pos / neg):lt(Big:create(0)), "pos / neg should be negative")
    T:assert((neg / pos):lt(Big:create(0)), "neg / pos should be negative")
    T:assert((neg / neg):gt(Big:create(0)), "neg / neg should be positive")
end)

T:test("Omega: Concatenation operator", function()
    local a = Big:create(42)
    local result = a .. " is the answer"
    T:assert(string.find(result, "42"), "Should contain 42")
end)

-- ============================================================================
-- Run all tests
-- ============================================================================

local success = T:run()
os.exit(success and 0 or 1)
