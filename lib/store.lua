local text = include "ribbon/lib/text"

local SCREEN_WIDTH = 110

local store = {
  state = {
    lines = { "" },
    brks = {},
    keymods = {},
    clocks = {},
    pos = {
      row = 1,
      col = 1
    }
  }
}

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
  rewrap_lines()
  -- TODO conditional history
  table.insert(history.past, action)
end

local function revert(action)
  reverts[action.type](action)
  rewrap_lines()
  -- TODO conditional history
  table.insert(history.future, action)
end

function applies.insert(action)
  local line = store.state.lines[action.pos.row]
  local new_line = text.splice(line, action.char, action.pos.col)

  store.state.pos.col = action.pos.col + 1
  store.state.lines[action.pos.row] = new_line
end

function reverts.insert(action)
  local line = store.state.lines[action.pos.row]
  local new_line = text.remove(line, action.pos.col)

  store.state.lines[action.pos.row] = new_line
  store.state.pos.col = action.pos.col
end

function applies.delete(action)
  reverts.insert(action)
end

function reverts.delete(action)
  applies.insert(action)
end

function applies.newline(action)
  store.state.lines[action.line + 1] = ""
  store.state.pos.row = store.state.pos.row + 1
  store.state.pos.col = 1
end

function reverts.newline(action)
  store.state.lines[action.line + 1] = nil
  store.state.pos.row = store.state.pos.row - 1

  local line_len = store.state.lines[store.state.pos.row]:len()
  store.state.pos.col = line_len + 1
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
  local lines = store.state.lines
  local brks = store.state.brks
  local next_lines, next_brks = text.rewrap_lines(lines, brks, SCREEN_WIDTH)
  store.state.lines = next_lines
  store.state.brks = next_brks
end

return store