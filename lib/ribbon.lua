local ribbon = {}

local LINE_COUNT = 6
local SCREEN_WIDTH = 110

local store = include "ribbon/lib/store"
local text = include "ribbon/lib/text"

local keycodes = {}
local clocks = {}
local state = store.state

-- TODO should this be tracked in state?
local cursor = {
  level = 4,
  freeze = false
}

ribbon.undo = store.undo
ribbon.redo = store.redo
ribbon.keybinds = {}

function ribbon.init()
  clock.run(clocks.cursor)
end

function ribbon.redraw()
  screen.clear()
  screen.level(15)
  screen.font_size(8)

  local index = 1
  while index < LINE_COUNT do
    -- TODO generate wrapped lines as part of state changes in store
    local line = state.lines[index] or ""
    screen.move(1, 10 * index)
    screen.text(line)

    index = index + 1
  end

  local line = state.lines[state.pos.row]
  local text_behind_cursor = line:sub(1, state.pos.col - 1)
  local cursor_x = 1
  local cursor_y = 10 * state.pos.row - 6

  if state.pos.col > 1 then
    cursor_x = text.width(text_behind_cursor) + 2
  end

  screen.level(cursor.level)
  screen.move(cursor_x, cursor_y)
  screen.line_width(1)
  screen.line(cursor_x, cursor_y + 6)
  screen.stroke()

  screen.update()
end

function shift_row(distance)
  local new_line_pos = state.pos.row + distance
  local new_line = state.lines[new_line_pos]
  local line_len = 1 + (new_line and new_line:len() or 0)

  if new_line_pos > 0 and new_line_pos <= #state.lines then
    -- TODO don't directly mutate state
    state.pos.row = new_line_pos

    if state.pos.col > line_len then
      -- TODO don't directly mutate state
      state.pos.col = line_len
    end

    redraw()
  end
end

function shift_col(distance)
  local line_len = state.lines[state.pos.row]:len()
  local new_col = state.pos.col + distance

  if new_col > 0 and new_col <= line_len + 1 then
    -- TODO don't directly mutate state
    state.pos.col = new_col
    redraw()
  end
end

function keycodes.ENTER()
  store.exec {
    type = "newline",
    row = state.pos.row
  }
  redraw()
end

function keycodes.BACKSPACE()
  if state.pos.col > 1 then
    local line = state.lines[state.pos.row]
    local col = state.pos.col - 1
    local char = line:sub(col, col)
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

function keycodes.UP(value)
  cursor.freeze = true
  -- shift_row(-1)
  store.exec {
    type = "shiftrow",
    distance = value
  }
end

function keycodes.DOWN()
  cursor.freeze = true
  shift_row(1)
end

function keycodes.LEFT()
  cursor.freeze = true
  shift_col(-1)
end

function keycodes.RIGHT()
  cursor.freeze = true
  shift_col(1)
end

function ribbon.keycode(key, value)
  if value == 1 and keycodes[key] then
    keycodes[key](value)
    redraw()
  end
end

function ribbon.keychar(char)
  if keyboard.ctrl() then
    local key = "CTRL_" .. char:upper()
    ribbon.keybinds[key]()
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

function clocks.cursor()
  while true do
    if cursor.freeze then
      cursor.level = 4
      clock.sleep(0.2)
      cursor.freeze = false
    elseif cursor.level > 0 then
      cursor.level = 0
    else
      cursor.level = 4
    end
    redraw()
    clock.sleep(0.5)
  end
end

return ribbon
