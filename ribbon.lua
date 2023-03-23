--- ribbon
--
-- a simple text editor

local keyboard = require "core/keyboard"
local applies = {}
local reverts = {}
local keycodes = {}
local clocks = {}


local state = {
  pos = {
    line = 1,
    col = 1
  },
  lines = {""},
  keymods = {},
  cursor = {
    blink = true
  }
}

local history = {
  past = {},
  future = {}
}

local keybinds = {
  CTRL_Z = function() undo() end,
  CTRL_X = function() redo() end
}

function init()
  clock.run(clocks.cursor)
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.font_size(8)

  for index = 1, #state.lines do
    local line = state.lines[index]
    screen.move(0, 10 * index)
    screen.text(line)
  end

  local line = state.lines[#state.lines]
  local text = line:sub(1, state.pos.col)
  local cursor_x = text_width(text) + 1
  local cursor_y = 10 * #state.lines - 6
  local cursor_level = state.cursor.blink and 3 or 0

  screen.level(cursor_level)
  screen.move(cursor_x, cursor_y)
  screen.line_width(1)
  screen.line(cursor_x, cursor_y + 6)
  screen.stroke()

  screen.update()
end

function key(k, v)
  if v == 1 and k == 2 then
    r()
  end
end

function text_width(text)
  local trailing_width = 0
  local space_width = 3
  local index = 1

  while index <= text:len() and text:sub(-index, -index) == " " do
    trailing_width = trailing_width + space_width
    index = index - 1
  end

  return screen.text_extents(text) + trailing_width
end

function applies.insert(action)
  local line = state.lines[action.pos.line]
  local new_line =
    line:sub(1, action.pos.col) .. action.char .. line:sub(action.pos.col + 1)

  state.lines[action.pos.line] = new_line
  state.pos.col = state.pos.col + 1
end

function reverts.insert(action)
  local line = state.lines[action.pos.line]
  local new_line =
    line:sub(1, action.pos.col - 2) .. line:sub(action.pos.col)

  state.lines[action.pos.line] = new_line
  state.pos.col = state.pos.col - 1
end

function applies.delete(action)
  reverts.insert(action)
end

function reverts.delete(action)
  applies.insert(action)
end

function applies.newline(action)
  state.lines[action.line + 1] = ""
  state.pos.line = state.pos.line + 1
  state.pos.col = 1
end

function reverts.newline(action)
  state.lines[action.line + 1] = nil
  state.pos.line = state.pos.line - 1

  local line_len = state.lines[state.pos.line]:len()
  state.pos.col = line_len + 1
end

function apply(action)
  applies[action.type](action)
  table.insert(history.past, action)
  redraw()
end

function revert(action)
  reverts[action.type](action)
  table.insert(history.future, action)
  redraw()
end

function exec(action)
  apply(action)
  history.future = {}
end

function redo()
  local action = table.remove(history.future)
  if action then
    apply(action)
  end
end

function undo()
  local action = table.remove(history.past)
  if action then
    revert(action)
  end
end

function keycodes.ENTER(value)
  if value == 1 then
    exec {
      type =  "newline",
      line = state.pos.line
    }
  end
end

function keycodes.BACKSPACE(value)
  if value == 1 then
    local line = state.lines[state.pos.line]
    local col = state.pos.col - 1
    local char = line:sub(col, col)
    exec {
      type =  "delete",
      char = char,
      pos = state.pos
    }
  end
end

function keyboard.code(key, value)
  if keycodes[key] then
    keycodes[key](value)
  end
end

function keyboard.char(char)
  if keyboard.ctrl() then
    local key = "CTRL_"..char:upper()
    keybinds[key]()
  else
    exec {
      type = 'insert',
      char = char,
      pos = state.pos,
    } 
  end
end

function clocks.cursor()
  while true do
    state.cursor.blink = not state.cursor.blink
    redraw()
    clock.sleep(0.65)
  end
end

function r()
  norns.script.load(norns.state.script)
  screen.ping()
end
