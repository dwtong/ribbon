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
  local redraw_callback = function() redraw() end
  store.add_event_listener("onchange", redraw_callback)
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
end

function keycodes.ENTER()
  store.exec {
    type = "newline",
    pos = {
      row = state.pos.row,
      col = state.pos.col
    }
  }
end

function keycodes.BACKSPACE()
  local col = state.pos.col
  local row = state.pos.row

  if col > 1 or (col == 1 and row > 1) then
    local char, new_col, new_row

    if col == 1 and row > 1 then
      local next_row = row - 1
      local next_line = state.lines[next_row]
      new_col = next_line:len()
      new_row = next_row
      char = state.brks[next_row]
    else
      local line = state.lines[row]
      new_col = col - 1
      new_row = state.pos.row
      char = line:sub(new_col, new_col)
    end

    store.exec {
      type = "delete",
      char = char,
      pos = {
        row = new_row,
        col = new_col
      }
    }
  end
end

function keycodes.UP()
  local next_line = state.lines[state.pos.row - 1]

  if next_line then
    local col = next_line:len() - state.pos.col + 1

    store.exec {
      type = "navigate",
      pos = {
        row = -1,
        col = col
      }
    }
  elseif state.pos.col > 1 then
    local col = -state.pos.col + 1

    store.exec {
      type = "navigate",
      pos = {
        row = 0,
        col = col
      }
    }
  end
end

function keycodes.DOWN()
  local next_line = state.lines[state.pos.row + 1]

  if next_line then
    local col = next_line:len() - state.pos.col + 1

    store.exec {
      type = "navigate",
      pos = {
        row = 1,
        col = col
      }
    }
  end
end

function keycodes.LEFT()
  store.exec {
    type = "navigate",
    pos = {
      row = 0,
      col = -1,
    }
  }
end

function keycodes.RIGHT()
  store.exec {
    type = "navigate",
    pos = {
      row = 0,
      col = 1,
    }
  }
end

return Ribbon
