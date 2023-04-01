local View = {}

store = include "ribbon/lib/store"

local state = store.state
local unfreeze_cursor, blink_cursor, cursor_clock

function View.init()
  clock.run(cursor_clock)
end

function View.draw_lines()
  local line_count = state.screen.line_count

  screen.level(15)
  screen.font_size(8)

  for index = 1, line_count do
    local line_index = index + state.screen.top_row - 1
    local line = state.lines[line_index] or ""

    screen.move(1, 10 * index)
    screen.text(line)
  end
end

function View.draw_cursor()
  local line = state.lines[state.pos.row]
  local text_behind_cursor = line:sub(1, state.pos.col - 1)
  local cursor_x = 1
  local cursor_y = 10 * state.pos.row - 6

  if state.pos.col > 1 then
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

    -- TODO screen_dirty
    redraw()
    clock.sleep(0.5)
  end
end

function unfreeze_cursor()
  store.exec {
    type = "unfreezecursor"
  }
end

function blink_cursor()
  store.exec {
    type = "blinkcursor"
  }
end

return View