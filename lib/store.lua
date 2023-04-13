local text = include "ribbon/lib/text"
local fn = include "ribbon/lib/fn"

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

local rewrap_lines, move_pos, set_visible_rows
local call_event_listeners

local event_listeners = {
  onchange = {}
}

local state = {
  clocks = {},
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

function Store.init(attrs)
  local redraw_callback = function() redraw() end
  Store.add_event_listener("onchange", redraw_callback)

  state.lines = attrs and attrs.lines or { "" }
  state.brks = attrs and attrs.brks or {}
  state.row = 1
  state.col = 1
  state.screen.top_row = 1

  rewrap_lines()
end


local debounced_group_past_actions

function Store.exec(action)
  applies[action.type](action)

  if undoable_actions[action.type] then
    table.insert(history.past, action)
    debounced_group_past_actions()
    history.future = {}
  end

  call_event_listeners("onchange")
end

function Store.redo()
  local action = table.remove(history.future)

  if action then
    applies[action.type](action)
    table.insert(history.past, action)
  end

  call_event_listeners("onchange")
end

function Store.undo()
  local action = table.remove(history.past)

  if action then
    reverts[action.type](action)
    table.insert(history.future, action)
  end

  call_event_listeners("onchange")
end

function Store.add_event_listener(event, callback)
  table.insert(event_listeners[event], callback)
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
  state.pos.col = action.pos.col + 1
  state.pos.row = action.pos.row

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
  local old_line = state.lines[action.pos.row]
  local split_at = action.pos.col - 1
  local line_start = old_line:sub(1, split_at)
  local line_end = old_line:sub(split_at + 1)
  local next_row = action.pos.row + 1

  state.lines[action.pos.row] = line_start
  table.insert(state.lines, next_row, line_end)
  table.insert(state.brks, action.pos.row, text.LINE_BREAK)

  jump_to_pos(1, next_row)
  rewrap_lines()
end

function reverts.newline(action)
  local next_row = action.pos.row
  local line_start = state.lines[next_row]
  local line_end = state.lines[next_row + 1]
  local next_col = line_start:len() + 1

  state.lines[next_row] = line_start .. line_end

  table.remove(state.lines, next_row + 1)
  table.remove(state.brks, next_row)

  jump_to_pos(next_col, next_row)
  rewrap_lines()
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

function applies.runclock(action)
  if state.clocks[action.clock_id] == nil then
    local clk = clock.run(action.fn)
    state.clocks[action.clock_id] = clk
  end
end

function applies.cancelclock(action)
  local clk = state.clocks[action.clock_id]

  if clk then
    clock.cancel(clk)
    state.clocks[action.clock_id] = nil
  end
end

function applies.group(action)
  for _, action in ipairs(action.actions) do
    applies[action.type](action)
  end
end

function reverts.group(action)
  for index = #action.actions, 1, -1 do
    local action = action.actions[index]
    reverts[action.type](action)
  end
end

function rewrap_lines()
  local lines = state.lines
  local brks = state.brks

  local next_lines, next_brks = text.rewrap_lines(lines, brks, SCREEN_WIDTH)

  state.lines = next_lines
  state.brks = next_brks
end

function jump_to_pos(col, row)
  state.pos.col = col
  state.pos.row = row

  set_visible_rows()
end

function move_pos(col, row)
  local current_col = state.pos.col
  local current_row = state.pos.row

  local num_rows = #state.lines
  local next_row = util.clamp(current_row + row, 1, num_rows)

  local next_line = state.lines[next_row]
  local next_col = current_col + col

  while next_col > next_line:len() + 1 and next_row < #state.lines do
    next_col = next_col - next_line:len()
    next_row = next_row + 1
    next_line = state.lines[next_row]
  end

  while next_col < 1 and next_row > 1 do
    next_row = next_row - 1
    next_line = state.lines[next_row]
    next_col = next_line:len() - next_col + 1
  end

  if next_col > next_line:len() + 1 then
    next_col = next_line:len() + 1
  end

  if next_col < 1 then
    next_col = 1
  end

  state.pos.row = next_row
  state.pos.col = next_col

  set_visible_rows()
end

function set_visible_rows()
  local top_row = state.screen.top_row
  local bottom_row = top_row + LINE_COUNT - 1
  local next_row = state.pos.row
  local num_rows = #state.lines

  if next_row > bottom_row and bottom_row < num_rows then
    state.screen.top_row = top_row + 1
  elseif next_row < top_row and top_row > 1 then
    state.screen.top_row = top_row - 1
  end
end

function call_event_listeners(event_type)
  for _, callback in ipairs(event_listeners[event_type]) do
    callback()
  end
end

function group_past_actions()
  local groupable_actions = {}
  for index = #history.past, 1, -1 do
    local action = table.remove(history.past)
    if action.type == 'group' then
      table.insert(history.past, action)
      break
    end
    table.insert(groupable_actions, 1, action)
  end

  table.insert(history.past, {
    type = 'group',
    actions = groupable_actions,
  })
end

debounced_group_past_actions = fn.debounce(group_past_actions, 2000)

return Store
