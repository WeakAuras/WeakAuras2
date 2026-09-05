-- The options panel compiles stored aura code to show errors under the code
-- box, and AceConfig evaluates the name and hidden callbacks of that label on
-- every render. That evaluation must stay inside the sandbox.
local testsDir = arg[0]:match("^(.*)[/\\][^/\\]*$") or "."
package.path = testsDir .. "/?.lua;" .. package.path
local T = require("helpers")
local stubs = require("wow_stubs")

stubs.install()
local realG = _G
_G.WeakAuras = stubs.permissive(stubs.newWeakAuras())
local Private, warnings = stubs.newPrivate()

T.loadAddonFile("WeakAuras/AuraEnvironment.lua", "WeakAuras", Private)
local OptionsPrivate = stubs.permissive({ Private = Private })
T.loadAddonFile("WeakAurasOptions/CommonOptions.lua", "WeakAurasOptions", OptionsPrivate)

-- Custom Variables is registered without encloseInFunction and with a
-- validator, so its text is evaluated as an expression on every render.
local maliciousCode = table.concat({
  "(function()",
  "  _G.OWNED_FROM_OPTIONS = true",
  "  _G.SEEN_ENUMERATE = EnumerateFrames()",
  "  return {}",
  "end)()",
}, "\n")

local function buildErrorLabel(addCodeOption, code, validator)
  local data = { id = "victim", customVariables = code }
  local args = {}
  addCodeOption(args, data, "Custom Variables", "custom_variables", "https://example.invalid/wiki", 11,
                function() return false end, { "customVariables" }, false, { validator = validator })
  return args["custom_variables_customError"]
end

for _, builder in ipairs({ "AddCodeOption", "AddCodeOptionTimeMachine" }) do
  local addCodeOption = OptionsPrivate.commonOptions[builder]
  T.section(builder .. ": rendering the error label runs stored code only inside the sandbox")

  local validatedWith
  local label = buildErrorLabel(addCodeOption, maliciousCode, function(value)
    validatedWith = value
    return nil
  end)
  if T.expect(label and type(label.hidden) == "function" and type(label.name) == "function",
              "the error label has name and hidden callbacks") then
    for _, callback in ipairs({ "hidden", "name" }) do
      realG.OWNED_FROM_OPTIONS = nil
      realG.SEEN_ENUMERATE = nil
      validatedWith = nil
      label[callback]()
      T.expect(realG.OWNED_FROM_OPTIONS == nil, callback .. ": the stored code does not write the real global table")
      T.expect(realG.SEEN_ENUMERATE ~= "REAL_EnumerateFrames", callback .. ": the stored code does not reach the real EnumerateFrames")
      T.expect(type(validatedWith) == "table", callback .. ": the code was still evaluated and its result reached the validator")
    end
  end

  T.section(builder .. ": the error label still reports problems")
  local broken = buildErrorLabel(addCodeOption, "{ this is not lua", function() return nil end)
  T.expect(broken.hidden() == false, "a syntax error shows the label")
  T.expect(type(broken.name()) == "string" and broken.name():find("|cFFFF0000", 1, true) ~= nil,
           "a syntax error is reported in red")
  local rejected = buildErrorLabel(addCodeOption, "{}", function() return "Not what I wanted" end)
  T.expect(rejected.name():find("Not what I wanted", 1, true) ~= nil, "a validator message is reported")
end

T.expect(#warnings > 0, "the sandbox raised warnings while evaluating the malicious code")

T.finish()
