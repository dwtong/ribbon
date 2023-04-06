--- ribbon
--
-- a simple text editor

fileselect = require "fileselect"
keyboard = require "core/keyboard"
ribbon = include "lib/ribbon"

-- TODO: fix undo/redo
-- ribbon.keybindings = {
--   CTRL_Z = function() ribbon.undo() end,
--   CTRL_X = function() ribbon.redo() end
-- }

local selecting_file = false

function init()
  ribbon.init()
  ribbon.init_params()
  redraw()
end

function redraw()
  if not selecting_file then
    ribbon.redraw()
  end
end

function key(k, v)
  if v == 1 then
    if k == 2 then
      reload()
    elseif k == 3 then
      open_file()
    end
  end
end

function keyboard.code(key, value)
  ribbon.keycode(key, value)
end

function keyboard.char(char)
  ribbon.keychar(char)
end

function reload()
  norns.script.load(norns.state.script)
  screen.ping()
end

function open_file()
  selecting_file = true

  fileselect.enter(_path.data .. "ribbon/", function(file)
    if file ~= "cancel" then
      ribbon.load_file(file)
    end
    selecting_file = false
  end)
end
