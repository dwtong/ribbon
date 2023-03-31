local Ribbon = {}

local LINE_COUNT = 6

store = include "ribbon/lib/store"
text = include "ribbon/lib/text"

local keycodes = {}
local clocks = {}
local state = store.state

-- TODO should this be tracked in state?
local cursor = {
  level = 4,
  freeze = false
}

Ribbon.undo = store.undo
Ribbon.redo = store.redo
Ribbon.keybinds = {}

function Ribbon.init()
  clock.run(clocks.cursor)
end

function Ribbon.redraw()
  screen.clear()
  screen.level(15)
  screen.font_size(8)

  for index = 1, LINE_COUNT do
    local line = state.lines[index] or ""
    screen.move(1, 10 * index)
    screen.text(line)
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

  screen.level(15)
  screen.move(110, 60)
  screen.text(state.pos.row .. ":" .. state.pos.col)


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
  -- TODO action for navigation
  --store.exec {
  --  type = "shiftrow",
  --  distance = value
  --}
end

function keycodes.DOWN()
  cursor.freeze = true
  -- TODO action for navigation
end

function keycodes.LEFT()
  cursor.freeze = true
  -- TODO action for navigation
end

function keycodes.RIGHT()
  cursor.freeze = true
  -- TODO action for navigation
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

return Ribbon
