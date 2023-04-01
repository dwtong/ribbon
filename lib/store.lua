local text = include "ribbon/lib/text"

local SCREEN_WIDTH = 124
local LINE_COUNT = 6
local CURSOR_MAX_LEVEL = 4

local Store = {}

local history = {
  past = {},
  future = {}
}

local applies = {}
local reverts = {}

local undoable_actions = {
  delete = true,
  insert = true,
  newline = true
}

local rewrap_lines, move_pos

local state = {
  lines = { "" },
  brks = {},
  pos = {
    row = 1,
    col = 1
  },
  screen = {
    top_row = 1,
    line_count = LINE_COUNT
  },
  cursor = {
    freeze = false,
    level = 4
  }
}

Store.state = state

function Store.exec(action)
  applies[action.type](action)

  if undoable_actions[action.type] then
    table.insert(history.past, action)
    history.future = {}
  end
end

function Store.redo()
  local action = table.remove(history.future)

  if action then
    applies[action.type](action)
    table.insert(history.past, action)
  end
end

function Store.undo()
  local action = table.remove(history.past)

  if action then
    reverts[action.type](action)
    table.insert(history.future, action)
  end
end

function applies.insert(action)
  local line = state.lines[action.pos.row]
  local new_line = text.splice(line, action.char, action.pos.col)

  state.lines[action.pos.row] = new_line

  rewrap_lines()
  move_pos(1, 0)
end

function reverts.insert(action)
  local line = state.lines[action.pos.row]
  local new_line = text.remove(line, action.pos.col)

  state.lines[action.pos.row] = new_line

  rewrap_lines()
  move_pos(-1, 0)
end

function applies.delete(action)
  if action.char == text.LINE_BREAK then
    reverts.newline(action)
  else
    reverts.insert(action)
  end
end

function reverts.delete(action)
  if action.char == text.LINE_BREAK then
    applies.newline(action)
  else
    applies.insert(action)
  end
end

function applies.newline(action)
  table.insert(state.lines, action.pos.row + 1, "")
  table.insert(state.brks, action.pos.row, text.LINE_BREAK)

  rewrap_lines()
  move_pos(0, 1)
end

function reverts.newline(action)
  local line = state.lines[action.pos.row - 1]

  table.remove(state.lines, action.pos.row)
  table.remove(state.brks, action.pos.row - 1)

  rewrap_lines()
  move_pos(line:len(), -1)
end

function applies.navigate(action)
  state.cursor.freeze = true
  state.cursor.level = CURSOR_MAX_LEVEL

  move_pos(action.pos.col, action.pos.row)
end

function applies.blinkcursor()
  if state.cursor.level == 0 then
    state.cursor.level = CURSOR_MAX_LEVEL
  else
    state.cursor.level = 0
  end
end

function applies.unfreezecursor()
  state.cursor.freeze = false
end

function rewrap_lines()
  local lines = state.lines
  local brks = state.brks
  local line = lines[state.pos.row]

  if line and text.width(line) > SCREEN_WIDTH then
    local next_lines, next_brks = text.rewrap_lines(lines, brks, SCREEN_WIDTH)

    state.lines = next_lines
    state.brks = next_brks
  end
end

function move_pos(col, row)
  local current_col = state.pos.col
  local current_row = state.pos.row

  local top_row = state.screen.top_row
  local bottom_row = top_row + LINE_COUNT - 1

  local num_rows = #state.lines
  local next_row = util.clamp(current_row + row, 1, num_rows)

  local next_line = state.lines[next_row]
  local next_col = current_col + col

  while next_col > next_line:len() + 1 and next_row < #state.lines do
    next_col = next_col - next_line:len()
    next_row = next_row + 1
    next_line = state.lines[next_row]
  end

  while next_col < 1 and next_row > 0 do
    next_row = next_row - 1
    next_line = state.lines[next_row]
    next_col = next_line:len() - next_col + 1
  end

  if next_col > next_line:len() + 1 then
    next_col = next_line:len() + 1
  end

  state.pos.row = next_row
  state.pos.col = next_col

  if next_row > bottom_row and bottom_row < num_rows then
    state.screen.top_row = top_row + 1
  elseif next_row < top_row and top_row > 1 then
    state.screen.top_row = top_row - 1
  end
end

return Store
