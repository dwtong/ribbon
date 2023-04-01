local Ribbon = {}

store = include "ribbon/lib/store"
text = include "ribbon/lib/text"
view = include "ribbon/lib/view"

local keycodes = {}
local state = store.state

Ribbon.undo = store.undo
Ribbon.redo = store.redo
Ribbon.keybinds = {}

function Ribbon.init()
  view.init()
end

function Ribbon.redraw()
  screen.clear()

  view.draw_lines()
  view.draw_cursor()
  view.draw_status()

  screen.update()
end

function Ribbon.keycode(key, value)
  screen.ping()

  if value == 1 and keycodes[key] then
    keycodes[key](value)
    redraw()
  end
end

function Ribbon.keychar(char)
  if keyboard.ctrl() then
    local key = "CTRL_" .. char:upper()
    Ribbon.keybinds[key]()
  else
    store.exec {
      type = "insert",
      char = char,
      pos = {
        row = state.pos.row,
        col = state.pos.col
      }
    }
  end

  redraw()
end

function keycodes.ENTER()
  store.exec {
    type = "newline",
    pos = {
      row = state.pos.row
    }
  }
  redraw()
end

function keycodes.BACKSPACE()
  if state.pos.col > 0 then
    local col = state.pos.col - 1
    local char

    if col == 0 then
      char = state.brks[state.pos.row - 1]
    else
      local line = state.lines[state.pos.row]
      char = line:sub(col, col)
    end

    store.exec {
      type = "delete",
      char = char,
      pos = {
        row = state.pos.row,
        col = col
      }
    }

    redraw()
  end
end

function keycodes.UP()
  local next_line = state.lines[state.pos.row - 1]
  local col = next_line:len() - state.pos.col + 1

  cursor.freeze = true
  store.exec {
    type = "navigate",
    pos = {
      row = -1,
      col = col
    }
  }
end

function keycodes.DOWN()
  local next_line = state.lines[state.pos.row + 1]
  local col = next_line:len() - state.pos.col + 1

  cursor.freeze = true
  store.exec {
    type = "navigate",
    pos = {
      row = 1,
      col = col
    }
  }
end

function keycodes.LEFT()
  cursor.freeze = true
  store.exec {
    type = "navigate",
    pos = {
      row = 0,
      col = -1,
    }
  }
end

function keycodes.RIGHT()
  cursor.freeze = true
  store.exec {
    type = "navigate",
    pos = {
      row = 0,
      col = 1,
    }
  }
end

return Ribbon
