exclude_files = {"deps", "examples", "tests"}
ignore = {"2../_.*", "631"}
std = "luajit"

globals = {
  "p", "process", "table.unpack"
}

stds.tests = {
  globals = { "toast" }
}

files["**/spec/**/*_spec.lua"] = "busted+tests+luajit"