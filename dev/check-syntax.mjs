// Fast Lua syntax gate: parse every mod .lua file as Lua 5.2 and report errors.
// Catches load-breaking typos without launching Factorio. Run: npm run check
// (Syntax only — for semantic linting use luacheck if you have a Lua toolchain.)
import luaparse from "luaparse";
import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const SKIP = new Set(["node_modules", "dev", ".git", ".gstack"]);

function luaFiles(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    if (SKIP.has(name)) continue;
    const p = join(dir, name);
    const st = statSync(p);
    if (st.isDirectory()) out.push(...luaFiles(p));
    else if (name.endsWith(".lua")) out.push(p);
  }
  return out;
}

let failed = false;
for (const f of luaFiles(".")) {
  try {
    luaparse.parse(readFileSync(f, "utf8"), { luaVersion: "5.2" });
    console.log("OK  " + f);
  } catch (e) {
    failed = true;
    console.log("ERR " + f + " -> " + e.message);
  }
}
process.exit(failed ? 1 : 0);
