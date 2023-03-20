--- ted
--
-- a simple text editor

local keyboard = require "core/keyboard"

MAX_WIDTH = 120
LINE_COUNT = 6

text = ""

function init()
  -- text = read_file(_path.code.."ted/test.txt")
  redraw()
end

function redraw()
  local baked_lines = lines()

  screen.clear()
  screen.level(15)
  screen.font_size(8)

  for i=1, LINE_COUNT do
    local line = baked_lines[i] or ''
    screen.move(0, 10*i)
    screen.text(line)
  end

  screen.update()
end

function read_file(path)
  local file = io.open(path, "r")
  if not file then return nil end
  local content = file:read "*all"
  file:close()
  return content
end


function lines()
  local pos = 1
  local lines = {[1]=""}
  local line = 1

  while pos <= text:len() do
    local char = text:sub(pos, pos)
    local nline = lines[line]..char
    local width = screen.text_extents(nline) + 2 

    if char == "\n" then
      line = line + 1
      pos = pos + 1
      lines[line] = ""
    elseif width > MAX_WIDTH then
      local br = 1

      while char ~= " " do
        char = text:sub(pos-br, pos-br)
        br = br + 1
      end

      pos = pos - br + 2
      lines[line] = lines[line]:sub(1, -br)
      line = line + 1
      lines[line] = ""
    else
      lines[line] = nline
      pos = pos + 1
    end
  end

  return lines
end

function keyboard.code(key, value)
    if (value == 1) then
      if (key == 'BACKSPACE') then
        remove_char()
      elseif (key == 'ENTER') then
        text = text .. '\n'
      end

      redraw()
    end
  end

  function keyboard.char(ch)
    text = text .. ch

    redraw()
  end

  function remove_char()
    text = text:sub(1, -2)
    -- if (text == nil) then text = '' end
  end
