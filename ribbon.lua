--- ribbon
--
-- a simple text editor

local keyboard = require "core/keyboard"

local LINE_COUNT = 6
local SCREEN_WIDTH = 110

local applies = {}
local reverts = {}
local keycodes = {}
local clocks = {}

state = {
  lines = {""},
  keymods = {},
  clocks = {},
  pos = {
    line = 1,
    col = 1
  },
  cursor = {
    level = 4,
    freeze = false
  }
}

history = {
  past = {},
  future = {}
}

local keybinds = {
  CTRL_Z = function() undo() end,
  CTRL_X = function() redo() end
}

function init()
  state.clocks.cursor = clock.run(clocks.cursor)
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.font_size(8)

  local index = 1
  while index < LINE_COUNT do
    local line = wrapped_lines(state.lines)[index] or ""
    screen.move(1, 10 * index)
    screen.text(line)

    index = index + 1
  end

  local line = state.lines[state.pos.line]
  local text = line:sub(1, state.pos.col - 1)
  local cursor_x = 1
  local cursor_y = 10 * state.pos.line - 6

  if state.pos.col > 1 then
    cursor_x = text_width(text) + 2
  end

  screen.level(state.cursor.level)
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
  local space_px = 4
  local text_width_px = screen.text_extents(text)

  if text_width_px > 0 then
    local leading_str = text:match("^%s+")
    local leading_spaces = leading_str and leading_str:len() or 0
    local trailing_str = text:match("%s+$")
    local trailing_spaces = trailing_str and trailing_str:len() or 0
    local padded_space_px = space_px * (leading_spaces + trailing_spaces)

    return text_width_px + padded_space_px
  else
    local space_count = text:len()
    return space_px * space_count
  end
end

function trim_text(text)
  return text:gsub("^%s+", ""):gsub("%s$", "")
  -- return text:gsub("^%s*(.-)%s*$", "%1")
end

function split_line(line)
  -- local line_has_spaces = line:match("%s")
  local max = 15 -- for testing
  local line_width = text_width(line)

  if line_width > SCREEN_WIDTH then
    local split_at = line:len() - 1
    local head = line:sub(1, split_at)

    while text_width(head) > SCREEN_WIDTH do
      -- TODO split at spaces rather than just character position
      split_at = split_at - 1
      head = line:sub(1, split_at)
    end

    local tail = line:sub(split_at + 1)
    local splits = { head }
    local tail_splits = split_line(tail)

    for _, split in ipairs(tail_splits) do
      local trimmed_split = trim_text(split)

      if trimmed_split:len() > 0 then
        table.insert(splits, trimmed_split)
      end
    end

    return splits
  else
    return { line }
  end
end

function wrapped_lines(lines)
  local wrapped = {}

  for _, line in ipairs(lines) do
    local trimmed_line = trim_text(line)
    local splits = split_line(trimmed_line)

    for _, split in ipairs(splits) do
      table.insert(wrapped, split)
    end
  end

  return wrapped
end

function applies.insert(action)
  local line = state.lines[action.pos.line]
  local new_line =
    line:sub(1, action.pos.col - 1) .. action.char .. line:sub(action.pos.col)

  state.lines[action.pos.line] = new_line
  state.pos.col = action.pos.col + 1
end

function reverts.insert(action)
  local line = state.lines[action.pos.line]
  local new_line =
    line:sub(1, action.pos.col - 1) .. line:sub(action.pos.col + 1)

  state.lines[action.pos.line] = new_line
  state.pos.col = action.pos.col
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

function shift_row(distance)
  local new_line_pos = state.pos.line + distance
  local new_line = state.lines[new_line_pos]
  local line_len = 1 + (new_line and new_line:len() or 0)

  if new_line_pos > 0 and new_line_pos <= #state.lines then
    state.pos.line = new_line_pos

    if state.pos.col > line_len then
      state.pos.col = line_len
    end

    redraw()
  end
end

function shift_col(distance)
  local line_len = state.lines[state.pos.line]:len() 
  local new_col = state.pos.col + distance

  if new_col > 0 and new_col <= line_len + 1 then
    state.pos.col = new_col
    redraw()
  end
end

function keycodes.ENTER(value)
  exec {
    type =  "newline",
    line = state.pos.line
  }
end

function keycodes.BACKSPACE(value)
  if state.pos.col > 1 then
    local line = state.lines[state.pos.line]
    local col = state.pos.col - 1
    local char = line:sub(col, col)
    exec {
      type =  "delete",
      char = char,
      pos = {
        line = state.pos.line,
        col = col
      }
    }
  end
end

function keycodes.UP(value)
  state.cursor.freeze = true
  shift_row(-1)
end

function keycodes.DOWN(value)
  state.cursor.freeze = true
  shift_row(1)
end

function keycodes.LEFT(value)
  state.cursor.freeze = true
  shift_col(-1)
end

function keycodes.RIGHT(value)
  state.cursor.freeze = true
  shift_col(1)
end

function keyboard.code(key, value)
  if value == 1 and keycodes[key] then
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
      pos = {
        line = state.pos.line,
        col = state.pos.col
      }
    } 
  end
end

function clocks.cursor()
  while true do
    if state.cursor.freeze then
      state.cursor.level = 4
      clock.sleep(0.2)
      state.cursor.freeze = false
    elseif state.cursor.level > 0 then
      state.cursor.level = 0
    else
      state.cursor.level = 4
    end
    redraw()
    clock.sleep(0.5)
  end
end

function r()
  norns.script.load(norns.state.script)
  screen.ping()
end
