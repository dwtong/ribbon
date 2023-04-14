local View = {}

local text = include "ribbon/lib/text"

local SCREEN_WIDTH = 48

local store, state
local unfreeze_cursor, blink_cursor, cursor_clock
local get_view_lines

View.lines = {}

function View.init(config)
  store = config.store
  state = config.store.state

  clock.run(cursor_clock)
end

function View.draw_lines()
  local line_count = state.screen.line_count

  screen.level(15)
  screen.font_size(8)

  View.lines = get_view_lines(store.state.lines)
  View.pos = get_view_pos(store.state.pos, store.state.lines, View.lines)

  for index = 1, line_count do
    local line_index = index + state.screen.top_row - 1
    local line = View.lines[line_index] or ""

    screen.move(1, 10 * index)
    screen.text(line)
  end
end

function View.draw_cursor()
  tab.print(View.lines)
  tab.print(View.pos)
  local line = View.lines[View.pos.row]
  local text_behind_cursor = line:sub(1, View.pos.col - 1)
  local relative_row = View.pos.row - state.screen.top_row + 1
  local cursor_x = 1
  local cursor_y = 10 * relative_row - 6

  if View.pos.col > 1 then
    cursor_x = text.width(text_behind_cursor) + 2
  end

  screen.level(state.cursor.level)
  screen.move(cursor_x, cursor_y)
  screen.line_width(1)
  screen.line(cursor_x, cursor_y + 6)
  screen.stroke()
end

function View.draw_status()
  screen.level(15)
  screen.move(110, 60)
  screen.text(state.pos.row .. ":" .. state.pos.col)
end

function cursor_clock()
  while true do
    if state.cursor.freeze then
      clock.sleep(0.2)
      unfreeze_cursor()
    else
      blink_cursor()
    end

    clock.sleep(0.5)
  end
end

function unfreeze_cursor()
  store.exec({
    type = "unfreezecursor"
  })
end

function blink_cursor()
  store.exec({
    type = "blinkcursor"
  })
end

function get_view_lines(lines)
  local view_lines, view_brks = text.wrap_lines(lines, SCREEN_WIDTH)
  return view_lines
end

function get_view_pos(state_pos, state_lines, view_lines)
  -- for every state row, move the full length of the state line
  -- then on the last line, only move the length of the state col.

  local num_chars = 0
  for row = 1, state_pos.row - 1 do
    num_chars = num_chars + state_lines[row]:len()
  end
  num_chars = num_chars + state_pos.col

  local view_row = 1
  local view_col = 1
  for index = 1, #view_lines do
    local view_line = view_lines[index]
    local width = view_line:len()
    if num_chars > width + 1 then
      num_chars = num_chars - width
      view_row = view_row + 1
    else
      view_col = num_chars
    end
  end

  return {
    col = view_col,
    row = view_row,
  }
end

return View
