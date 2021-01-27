-- luacheck: ignore
exclude_files = {"deps", "examples"}

ignore = {"2../_.*", "631"}

globals = {
  "p", "process", "table.unpack"
}

std = "luajit"