const fs = require('fs');
const path = require('path');

console.log(
`if not WeakAuras.IsLibsOK() then return end
---@type string
local AddonName = ...
---@class OptionsPrivate
local OptionsPrivate = select(2, ...)

local WeakAurasAPI =
{
 Name = "WeakAuras",
 Type = "System",
 Namespace = "WeakAuras",`
)

function isNilable(obj) {
  return obj.view.match("nil|\\?") ? "true" : "false"
}

function wowType(obj) {
  if (obj.view.match("string")) {
    return "string";
  }
  if (obj.view.match("boolean")) {
    return "bool";
  }
  if (obj.view.match("integer|number")) {
    return "number";
  }
  if (obj.view === "unknown|nil") {
    return "unknown"
  }
  if (obj.view === "(\"friendly\"|\"hostile\")?") { // I don't know how to handle this alias properly
    return "string"
  }
  return obj.view;
}

const data = fs.readFileSync(path.join(__dirname, 'doc.json'), { encoding: 'utf8', flags: 'r' });
const obj = JSON.parse(data);
for (const entry of obj) {
  if (entry.name === "WeakAuras") {
    if (entry.fields) {
      console.log(` Functions =`);
      console.log(` {`);
      for (const field of entry.fields) {
        if (field?.extends?.type === "function" && field?.visible === "public") {
          console.log(`  {`);
          console.log(`   Name = "${field.name}",`);
          console.log(`   Type = "Function",`);
          const args = field?.extends?.args
          if (args && args.length > 0) {
            console.log("");
            console.log(`   Arguments =`);
            console.log(`   {`);
            for (const arg of args) {
              console.log(`    { Name = "${arg.name}", Type = "${wowType(arg)}", Nilable = ${isNilable(arg)} },`);
            };
            console.log(`   },`);
          }
          const returns = field?.extends?.returns
          if (returns && returns.length > 0) {
            console.log("");
            console.log(`   Returns =`);
            console.log(`   {`);
            for (const ret of returns) {
              console.log(`    { Name = "${ret.name}", Type = "${wowType(ret)}", Nilable = ${isNilable(ret)} },`);
            };
            console.log(`   },`);
          }
          console.log(`  },`);
        }
      };
      console.log(` },`);
    }
  }
}

console.log(
`
 Events =
 {
 },

 Tables =
 {
 },
};
local loaded = false
function OptionsPrivate.LoadDocumentation()
  if not loaded then
    APIDocumentation:AddDocumentationTable(WeakAurasAPI);
    loaded = true
  end
end
`
);
