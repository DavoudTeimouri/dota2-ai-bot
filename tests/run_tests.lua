--[[
Test runner for AetherWeaver bot unit tests.
Run with: lua5.1 tests/run_tests.lua
]]

local results = {}

local function run_test(testFile)
    print(string.format("\n=== Running %s ===", testFile))
    local ok, err = pcall(dofile, testFile)
    if ok then
        results[testFile] = "PASS"
        print(string.format("=== %s PASSED ===", testFile))
    else
        results[testFile] = "FAIL: " .. tostring(err)
        print(string.format("=== %s FAILED: %s ===", testFile, tostring(err)))
    end
end

-- Discover and run all test_*.lua files in tests/
local testFiles = {}
for i = 1, 100 do
    local name = string.format("tests/test_%02d.lua", i)
    local f = io.open(name, "r")
    if f then
        f:close()
        table.insert(testFiles, name)
    else
        break
    end
end

-- Also add explicitly named test files
local explicitTests = {
    "tests/test_hero_selection.lua",
}
for _, tf in ipairs(explicitTests) do
    local found = false
    for _, tf2 in ipairs(testFiles) do
        if tf2 == tf then found = true break end
    end
    if not found then table.insert(testFiles, tf) end
end

if #testFiles == 0 then
    print("No test files found in tests/")
    os.exit(0)
end

for _, tf in ipairs(testFiles) do
    run_test(tf)
end

print("\n" .. string.rep("=", 50))
print("SUMMARY")
print(string.rep("=", 50))
local totalPass = 0
local totalFail = 0
for tf, result in pairs(results) do
    if result == "PASS" then
        totalPass = totalPass + 1
        print(string.format("  PASS: %s", tf))
    else
        totalFail = totalFail + 1
        print(string.format("  FAIL: %s - %s", tf, result))
    end
end
print(string.format("\nTotal: %d passed, %d failed", totalPass, totalFail))
if totalFail > 0 then os.exit(1) end
