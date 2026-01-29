#!/usr/bin/env lua
--- Run all tests and show summary

print("=" .. string.rep("=", 59))
print("TALISMAN BIG NUMBER LIBRARY TESTS")
print("=" .. string.rep("=", 59))
print("")

local function run_test_file(filename)
    print("Running " .. filename .. "...")
    print("")
    local handle = io.popen("lua " .. filename .. " 2>&1")
    local result = handle:read("*a")
    local success = handle:close()
    print(result)
    return success
end

local bignumber_success = run_test_file("test-bignumber.lua")
print("")
local omeganum_success = run_test_file("test-omeganum.lua")
print("")
local edge_success = run_test_file("test-edge-cases.lua")

print("")
print("=" .. string.rep("=", 59))
print("SUMMARY")
print("=" .. string.rep("=", 59))
print("bignumber.lua tests: " .. (bignumber_success and "PASS" or "FAIL"))
print("omeganum.lua tests:  " .. (omeganum_success and "PASS" or "FAIL"))
print("edge case tests:     " .. (edge_success and "PASS" or "FAIL"))
print("")
print("See BUGS.md for documentation of fixed issues.")
