const fs = require('fs');
const path = require('path');
const namespace = "WeakAuras"

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
 Namespace = "WeakAuras",

 Functions =
 {`
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
const allFunctions = new Object;
for (const entry of obj) {
  if (entry.name === namespace) {
    if (entry.fields) {
      for (const field of entry.fields) {
        if (field?.extends?.type === "function" && field?.visible === "public") {
          const currFunction = new Object;
          const args = field?.extends?.args
          if (args && args.length > 0) {
            currFunction.arguments = new Array;
            for (const arg of args) {
              currFunction.arguments.push({ name: arg.name, type: wowType(arg), nilable: isNilable(arg)});
            };
          }
          const returns = field?.extends?.returns
          if (returns && returns.length > 0) {
            currFunction.returns = new Array;
            for (const ret of returns) {
              currFunction.returns.push({ name: ret.name, type: wowType(ret), nilable: isNilable(ret)})
            };
          }
          // if there is already a function with this name, we check if the new has more args or returns
          if (allFunctions[field.name]) {
            const currArgs = currFunction.args ? currFunction.args.length : 0
            const oldArgs = allFunctions[field.name].args ? allFunctions[field.name].length : 0
            const currRets = currFunction.returns ? currFunction.returns.length : 0
            const oldRets = allFunctions[field.name].returns ? allFunctions[field.name].returns.length : 0
            if (currArgs > oldArgs || currRets > oldRets) {
              allFunctions[field.name] = currFunction
            }
          } else {
            allFunctions[field.name] = currFunction
          }
        }
      };
    }
  }
}

for (var key in allFunctions) {
  const currFunction = allFunctions[key]
  console.log(`  {`);
  console.log(`   Name = "${key}",`);
  console.log(`   Type = "Function",`);
  if (currFunction.arguments) {
    console.log("");
    console.log(`   Arguments =`);
    console.log(`   {`);
    for (const arg of currFunction.arguments) {
      console.log(`    { Name = "${arg.name}", Type = "${arg.type}", Nilable = ${arg.nilable} },`);
    };
    console.log(`   },`);
  }
  if (currFunction.returns) {
    console.log("");
    console.log(`   Returns =`);
    console.log(`   {`);
    for (const ret of currFunction.returns) {
      console.log(`    { Name = "${ret.name}", Type = "${ret.type}", Nilable = ${ret.nilable} },`);
    };
    console.log(`   },`);
  }
  console.log(`  },`);
}

console.log(
`
 },

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
