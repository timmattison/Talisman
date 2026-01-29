# Claude Code Guidelines for Talisman

## Bug Fix Protocol

When discovering or fixing bugs, you MUST follow this test-driven approach:

### Required Steps for Every Bug Fix

1. **Write a failing test first**
   - Create a test that demonstrates the bug
   - Run the test to confirm it fails
   - Document what the expected vs actual behavior is

2. **Verify the test fails on the current code**
   - Run the test before making any fixes
   - If the test passes, the test is wrong or the bug doesn't exist
   - Save/note the failure output as evidence

3. **Implement the fix**
   - Make the minimal change needed to fix the bug
   - Do not refactor or make unrelated changes

4. **Verify the test passes**
   - Run the test again after the fix
   - Confirm it now passes
   - Run all other tests to ensure no regressions

5. **Document the bug**
   - Add the bug to BUGS.md with:
     - Location (file and line number)
     - Problem description with code example
     - Fix description with code example
     - Which test covers it

### Example Workflow

```bash
# 1. Write test in tests/test-bug-fixes.lua
T:test("BUG #X: description", function()
    -- Test that would fail before fix
    local result = buggy_function()
    T:assertEqual(expected, result)
end)

# 2. Run test - should FAIL
cd tests && lua test-bug-fixes.lua
# Expected: FAIL

# 3. Implement fix in the source file

# 4. Run test again - should PASS
cd tests && lua test-bug-fixes.lua
# Expected: PASS

# 5. Run all tests - should all PASS
lua run-all-tests.lua
```

### Why This Matters

- Proves the bug actually existed
- Proves the fix actually works
- Prevents regressions in the future
- Creates documentation through tests

## Project Structure

- `big-num/bignumber.lua` - Simpler big number library (uses `Big:new()`)
- `big-num/omeganum.lua` - Complex big number library for very large numbers (uses `Big:create()`)
- `tests/` - All test files
- `BUGS.md` - Documentation of all bugs found and fixed

## Running Tests

```bash
cd tests
lua run-all-tests.lua
```

## Common Bug Patterns

See BUGS.md for detailed documentation of common patterns to watch for:

1. API naming inconsistency (`Big:create` vs `Big:new`)
2. JavaScript to Lua port issues
3. IEEE 754 special value handling (infinity, NaN)
4. Object mutation (returning `self` instead of clone)
5. Undefined variable references
6. Missing return statements
