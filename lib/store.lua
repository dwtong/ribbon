local text = include "ribbon/lib/text"

local SCREEN_WIDTH = 110

local store = {}

local state = {
  lines = { "" },
  brks = {},
  keymods = {},
  clocks = {},
  pos = {
    row = 1,
    col = 1
  }
}

store.state = state

local history = {
  past = {},
  future = {}
}

-- reducers
local applies = {}
local reverts = {}

local function rewrap_lines()
end

local function apply(action)
  applies[action.type](action)
  -- TODO conditional history
  table.insert(history.past, action)
end

local function revert(action)
  reverts[action.type](action)
  -- TODO conditional history
  table.insert(history.future, action)
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
  reverts.insert(action)
end

function reverts.delete(action)
  applies.insert(action)
end

function applies.newline(action)
  -- state.lines[action.line + 1] = ""
  -- state.pos.row = state.pos.row + 1
  -- state.pos.col = 1
  rewrap_lines()
end

function reverts.newline(action)
  -- state.lines[action.line + 1] = nil
  -- state.pos.row = state.pos.row - 1

  -- local line_len = state.lines[state.pos.row]:len()
  -- state.pos.col = line_len + 1
  rewrap_lines()
end

function store.exec(action)
  apply(action)
  -- TODO conditional history
  history.future = {}
end

function store.redo()
  -- TODO conditional history
  local action = table.remove(history.future)

  if action then
    apply(action)
  end
end

function store.undo()
  -- TODO conditional history
  local action = table.remove(history.past)

  if action then
    revert(action)
  end
end

function rewrap_lines()
  local lines = state.lines
  local brks = state.brks
  local line = lines[state.pos.row]

  if text.width(line) > SCREEN_WIDTH then
    local next_lines, next_brks = text.rewrap_lines(lines, brks, SCREEN_WIDTH)
    state.lines = next_lines
    state.brks = next_brks
  end
end

function move_pos(col, row)
  local current_col = state.pos.col
  local current_row = state.pos.row

  local num_rows = #state.lines
  local next_row = math.min(current_row + row, num_rows)

  local next_line = state.lines[next_row]
  local next_col = current_col + col

  while next_col > next_line:len() + 1 do
  -- while next_col <= 1 do
  --   next_row = next_row - 1
  --   next_line = state.lines[next_row]
  --   next_col = next_line:len() + 2 - next_col
  -- end
  while next_col > next_line:len() + 1 and next_row < #state.lines do
    next_col = next_col - next_line:len()
    next_row = next_row + 1
    next_line = state.lines[next_row]
  end

  state.pos.row = next_row
  state.pos.col = next_col
end

return store
