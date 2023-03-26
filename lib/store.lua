local store = {
  state = {
    lines = {""},
    pos = {
      line = 1,
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
  local line = store.state.lines[action.pos.line]
  local new_line =
    line:sub(1, action.pos.col - 1) .. action.char .. line:sub(action.pos.col)

  store.state.lines[action.pos.line] = new_line
  store.state.pos.col = action.pos.col + 1
end

function reverts.insert(action)
  local line = store.state.lines[action.pos.line]
  local new_line =
    line:sub(1, action.pos.col - 1) .. line:sub(action.pos.col + 1)

  store.state.lines[action.pos.line] = new_line
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
  store.state.pos.line = store.state.pos.line + 1
  store.state.pos.col = 1
end

function reverts.newline(action)
  store.state.lines[action.line + 1] = nil
  store.state.pos.line = store.state.pos.line - 1

  local line_len = store.state.lines[store.state.pos.line]:len()
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

return store
