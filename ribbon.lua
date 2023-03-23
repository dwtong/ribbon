--- ribbon
--
-- a simple text editor

local keyboard = require "core/keyboard"

state = {
  pos = {
    line = 1,
    col = 1
  },
  lines = {""},
  keymods = {}
}

local applies = {}
local reverts = {}
local past = {}
local future = {}
local keycodes = {}
local keybinds = {
  CTRL_Z = function() undo() end,
  CTRL_X = function() redo() end
}

function init()
  redraw()
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

  screen.update()
end

function key(k, v)
  if v == 1 and k == 2 then
    r()
  end
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
  table.insert(past, action)
  redraw()
end

function revert(action)
  reverts[action.type](action)
  table.insert(future, action)
  redraw()
end

function exec(action)
  apply(action)
  future = {}
end

function redo()
  local action = table.remove(future)
  if action then
    apply(action)
  end
end

function undo()
  local action = table.remove(past)
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

function r()
  norns.script.load(norns.state.script)
  screen.ping()
end
