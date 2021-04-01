exclude_files = {"deps", "examples", "tests", "spec}
ignore = {"2../_.*"}
std = "luajit"

globals = {
  "p", "process", "table.unpack"
}

stds.tests = {
  globals = { "toast" }
}