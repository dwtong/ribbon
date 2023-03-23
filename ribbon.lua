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

local applys = {}
local reverts = {}
local past = {}
local future = {}
local keydowns = {}
local keyups = {}

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

function applys.insert(action)
  local line = state.lines[action.pos.line]
  local new_line =
    line:sub(1, action.pos.col) .. action.char .. line:sub(action.pos.col + 1)

  state.lines[action.pos.line] = new_line
  state.pos.col = state.pos.col + 1
end

function reverts.insert(action)
  local char = action.char
  local pos = action.pos
  local line = state.lines[pos.line]
  local new_line =
    line:sub(1, pos.col - 2) .. line:sub(pos.col)

  state.lines[pos.line] = new_line
  state.pos.col = state.pos.col - 1
end

function applys.newline(action)
  state.lines[action.line + 1] = ""
  state.pos.line = state.pos.line + 1
end

function reverts.newline(action)
  state.lines[action.line + 1] = nil
  state.pos.line = state.pos.line - 1
end

function apply(action)
  applys[action.type](action)
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


function keydowns.ENTER()
  exec {
    type =  "newline",
    line = state.pos.line
  }
end

function keydowns.CTRL_Z()
  undo()
end

function keydowns.CTRL_X()
  redo()
end

function keydowns.CTRL()
  state.keymods.CTRL = true
end

function keyups.CTRL()
  state.keymods.CTRL = false
end

function active_keymods()
  local keymods = {}
  for mod, is_active in pairs(state.keymods) do
    if is_active then
      table.insert(keymods,mod)
    end
  end
  return keymods
end

function keyboard.code(key, value)
  if value == 1 then
    local key = key:gsub("LEFT", ""):gsub("RIGHT", "")
    if keydowns[key] then
      keydowns[key]()
    end
  else
    if keyups[key] then
      keyups[key]()
    end
  end
end

function keyboard.char(char)
  if active_keymods() then
    local keymod = table.concat(active_keymods(), "_")
    local key = keymod.."_"..char:upper()
    keydowns[key]()
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
end
