--- ted
--
-- a simple text editor

local keyboard = require 'core/keyboard'

data = {}
char_count = 26
line_count = 6
line = 1

function init()
  for i=1, line_count do
    data[i]=""
  end

  redraw()
end

function redraw()
  screen.clear()
  screen.level(15)
  screen.font_size(8)

  for i=1, line_count do
    screen.move(0, 10*i)
    screen.text(data[i])
  end

  screen.update()
end

-- handler provided by norns core/keyboard.lua library
function keyboard.code(key, value)
  -- only do action on key down
  if (value == 1) then
    if (key == 'BACKSPACE') then
      remove_char()
    elseif (key == 'ENTER') then
      new_line()
    end

    redraw()
  end
end

-- handler provided by norns core/keyboard.lua library
function keyboard.char(ch)

  if (#data[line] > char_count) then
    -- we have reached the end of the line, go to a new line
    new_line()
  end

  -- append character 'ch' to current 'line'
  data[line] = data[line] .. ch

  redraw()
end

function remove_char()
  if (#data[line] > 0) then
    -- backspace current line
    data[line] = data[line]:sub(1, -2)
  elseif (line > 1) then
    -- no more characters on this line, go back to previous line
    line = line - 1
  end

  if (data[line] == nil) then
    -- ensure that the current line is a string, not nil
    data[line] = ''
  end
end

function new_line()
  if (line < line_count) then
    print("new line")
    line = line + 1
  else
    print("no more lines to be had - time to implement scrolling!")
  end
end
