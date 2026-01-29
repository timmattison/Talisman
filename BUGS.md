# Bugs Found and Fixed in Talisman Big Number Libraries

This document lists bugs discovered and fixed through testing of `bignumber.lua` and `omeganum.lua`.

## Fixed Bugs

### 1. R.LOG10E Used Invalid Logarithm Base ✅ FIXED

**Location:**
- `big-num/bignumber.lua:362`
- `big-num/omeganum.lua:31`

**Problem:**
```lua
R.LOG10E = math.log(R.E, 0)  -- base 0 is invalid
```

**Fix:**
```lua
R.LOG10E = math.log(R.E, 10)  -- Correct: ~0.4343
```

---

### 2. Big:pow Didn't Handle Negative Bases ✅ FIXED

**Location:** `big-num/bignumber.lua:138-146`

**Problem:** The `pow` function used logarithms which returned 0 for negative numbers, causing `(-2)^2` to return `1` instead of `4`.

**Fix:** Added explicit handling for negative bases that:
- Computes power of absolute value
- Applies correct sign based on whether exponent is odd/even

---

### 3. Big:mod Used Non-Existent Methods ✅ FIXED

**Location:** `big-num/bignumber.lua:94-106`

**Problems:**
- `Big:create` didn't exist (should be `Big:new`)
- `self.sign` didn't exist (used `is_negative()` instead)
- Missing `return` statement

**Fix:** Rewrote function to use correct methods and added `Big:abs()` function.

---

### 4. Missing Return Statement in Big:root ✅ FIXED

**Location:** `big-num/omeganum.lua:962`

**Problem:**
```lua
else
    Big:create(B.ZERO)  -- Missing return
end
```

**Fix:**
```lua
else
    return Big:create(B.ZERO)
end
```

---

### 5. Extra Argument to math.pow ✅ FIXED

**Location:** `big-num/omeganum.lua:276`

**Problem:**
```lua
x.array[1] = math.pow(10, x.array[1], 10)  -- Third argument ignored
```

**Fix:**
```lua
x.array[1] = math.pow(10, x.array[1])
```

---

### 6. JavaScript References in Lua Code ✅ FIXED

**Location:** `big-num/omeganum.lua:515, 534`

**Problems:**
- `math.log10(b[1])` - Lua doesn't have `math.log10`
- `Math.log10(d)` - JavaScript syntax
- `b[0]` - JavaScript 0-indexed array access

**Fix:** Changed to proper Lua syntax:
- `math.log(b[1], 10)`
- `math.log(d, 10)`
- `b[1]` (Lua is 1-indexed)

---

### 7. Intentional Crashes for Error Handling ✅ FIXED

**Location:**
- `big-num/omeganum.lua:1302-1305`
- `big-num/omeganum.lua:1347-1349`
- `big-num/omeganum.lua:1379-1381`

**Problem:**
```lua
local a = nil
return a.b  -- Intentional crash
```

**Fix:** Replaced with proper `error()` calls with descriptive messages.

---

### 8. Bare `nan` Variable Reference ✅ FIXED

**Location:** `big-num/bignumber.lua:118, 125`

**Problem:**
```lua
if self.e == nan and self.m == nan then return 0 end
```

`nan` was not defined.

**Fix:** Changed to proper NaN check:
```lua
if self.e ~= self.e or self.m ~= self.m then return 0 end
```

---

### 9. __concat Used Non-Existent Big:create ✅ FIXED

**Location:** `big-num/bignumber.lua:349`

**Problem:**
```lua
a = Big:create(a)  -- Big:create doesn't exist
```

**Fix:**
```lua
a = Big:new(a)
```

---

### 10. Infinity Minus Infinity Returned 0 Instead of NaN ✅ FIXED

**Location:** `big-num/omeganum.lua:694-701`

**Problem:** The equality check `x:eq(other)` happened before the infinity check, so `inf - inf` returned `0` instead of `NaN`.

**Fix:** Moved infinity check before the equality check:
```lua
-- inf - inf is undefined (NaN), must check before equality check
if (x:isInfinite() and other:isInfinite() and x.sign == other.sign) then
    return Big:create(B.NaN)
end
```

---

### 11. Zero Divided by Zero Returned Infinity Instead of NaN ✅ FIXED

**Location:** `big-num/omeganum.lua:761-762`

**Problem:** Division by zero always returned infinity, even for `0/0` which should be `NaN`.

**Fix:** Added explicit check for 0/0:
```lua
-- 0 / 0 is undefined (NaN)
if (x:eq(B.ZERO) and other:eq(B.ZERO)) then
    return Big:create(B.NaN)
end
```

---

### 12. Infinity Divided by Infinity Returned Infinity Instead of NaN ✅ FIXED

**Location:** `big-num/omeganum.lua:758`

**Problem:** The check `x:isInfinite() and other:isInfinite() and x:eq(other:neg())` only caught `inf / -inf`, not `inf / inf`.

**Fix:** Simplified to catch all infinity/infinity cases:
```lua
-- inf / inf is undefined (NaN)
if (x:isInfinite() and other:isInfinite()) then
    return Big:create(B.NaN)
end
```

---

### 13. Object Mutation Bug - Methods Returning Self Instead of Clone ✅ FIXED

**Location:** `big-num/bignumber.lua` (multiple functions)

**Problem:** Several methods returned `self` directly instead of creating a clone when early-returning for edge cases. This caused mutations to the result object to also affect the original input object.

**Affected functions:**
- `Big:add()` - lines 53-54: Returned `b` or `self` when magnitudes differed by >14
- `Big:round()` - line 197: Returned `self` when `self.e > 100`
- `Big:floor()` - line 211: Returned `self` when `self.e > 100`
- `Big:ceil()` - line 216: Returned `self` when `self.e > 100`
- `Big:floor_m()` - line 221: Returned `self` when `self.e > 100`
- `Big:ceil_m()` - line 226: Returned `self` when `self.e > 100`

**Example of the bug:**
```lua
local a = Big:new(1, 100)  -- 1e100
local b = Big:new(1, 1)    -- 10
local result = a + b       -- Due to precision limits, returns copy of a
result.m = 999             -- This ALSO modified a!
```

**Fix:** Changed all instances to return `Big:new(self)` or `Big:new(b)` to create independent copies:
```lua
if delta > 14 then return Big:new(b) end
if delta < -14 then return Big:new(self) end
```

---

## Test Coverage

Tests are located in:
- `tests/test-runner.lua` - Simple test framework
- `tests/test-bignumber.lua` - 57 tests for bignumber.lua
- `tests/test-omeganum.lua` - 51 tests for omeganum.lua
- `tests/test-edge-cases.lua` - 58 edge case tests
- `tests/test-bug-fixes.lua` - 45 regression tests for bug fixes

Run tests with:
```bash
cd tests
lua test-bignumber.lua
lua test-omeganum.lua
lua test-edge-cases.lua
lua test-bug-fixes.lua
# Or run all:
lua run-all-tests.lua
```

All 211 tests now pass.
