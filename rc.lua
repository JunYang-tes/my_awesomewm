local awful = require("awful")
local gears = require("gears")
pcall(require, "luarocks.loader")
package.path = os.getenv("AWESOME_LUA_PATH") .. package.path
local ok, err = pcall(require, "main")
if not ok then
  local naughty = require("naughty")
  naughty.notify({ preset = naughty.config.presets.critical,
    title = "Oops, an error happened!",
    text = tostring(err) })
  print("Fallback Mode")
  print(err)
  local t = awful.tag.add("tag", { screen = awful.screen.focused(), layout = awful.layout.suit.tile })
  print("Tag created")
  t:view_only()
  --pcall(require "rules")
  _G.root.keys(
    gears.table.join(
      awful.key(
        { "Mod4", "Control" }, "r",
        _G.awesome.restart

      ),
      awful.key({ "Mod4" }, "Return", function()
        awful.spawn("kitty")
      end)
    )
  )
end
