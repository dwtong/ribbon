local Key = {}

local keyboard = require "core/keyboard"

local keycodes = {}
local store, state, bindings

function Key.init(config)
  store = config.store
  state = config.store.state
  bindings = config.bindings
end

function Key.code(key, value)
  if value == 1 and keycodes[key] then
    keycodes[key](store, value)
  end
end

function Key.char(char)
  if keyboard.ctrl() then
    local key = "CTRL_" .. char:upper()
    bindings[key]()
  else
    store.exec({
      type = "insert",
      char = char,
      pos = {
        row = state.pos.row,
        col = state.pos.col
      }
    })
  end
end

function keycodes.ENTER()
  store.exec({
    type = "newline",
    pos = {
      row = state.pos.row,
      col = state.pos.col
    }
  })
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
      new_row = row
      char = line:sub(new_col, new_col)
    end

    store.exec({
      type = "delete",
      char = char,
      pos = {
        row = new_row,
        col = new_col
      }
    })
  end
end

function keycodes.UP()
  local col = state.pos.col
  local row = state.pos.row
  local next_line = state.lines[row - 1]
  local next_row, next_col

  if next_line then
    next_col = next_line:len() - col + 1
    next_row = -1
  elseif col > 1 then
    next_col = -col + 1
    next_row = 0
  end

  store.exec({
    type = "navigate",
    pos = {
      row = next_row,
      col = next_col
    }
  })
end

function keycodes.DOWN()
  local col = state.pos.col
  local row = state.pos.row
  local next_line = state.lines[row + 1]

  if next_line then
    local next_col = next_line:len() - col + 1

    store.exec({
      type = "navigate",
      pos = {
        row = 1,
        col = next_col
      }
    })
  end
end

function keycodes.LEFT()
  store.exec({
    type = "navigate",
    pos = {
      row = 0,
      col = -1,
    }
  })
end

function keycodes.RIGHT()
  store.exec({
    type = "navigate",
    pos = {
      row = 0,
      col = 1,
    }
  })
end

return Key
