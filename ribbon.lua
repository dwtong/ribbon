--- ribbon
--
-- a simple text editor

keyboard = require "core/keyboard"
ribbon = include "lib/ribbon"

ribbon.keybinds = {
  CTRL_Z = function() ribbon.undo() end,
  CTRL_X = function() ribbon.redo() end
}

function init()
  ribbon.init()
  redraw()
end

function redraw()
  ribbon.redraw()
end

function key(k, v)
  if v == 1 and k == 2 then
    reload()
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
