--- ribbon
--
-- a simple text editor

local keyboard = require "core/keyboard"

MAX_WIDTH = 120
LINE_COUNT = 6
REDRAW_FPS = 30
KEY_REPEAT_INIT_MS = 200
KEY_REPEAT_MS = 100

ribbon = ""
key_repeat_clocks = {}
screen_dirty = true
key_actions = {}
top_line = 1

key_actions['BACKSPACE'] = function ()
  ribbon = ribbon:sub(1, -2)
end

key_actions['ENTER'] = function ()
  ribbon = ribbon .. '\n'
end

key_actions['UP'] = function ()
  top_line = top_line > 1 and top_line - 1 or 1
end

key_actions['DOWN'] = function ()
  top_line = top_line + 1
end

function init()
  ribbon = read_file(_path.code.."ribbon/test.txt")

  clock.run(function()
    while true do
      if screen_dirty then redraw() end
      clock.sleep(1/REDRAW_FPS)
    end
  end)
end

function enc(e, d)
  if e == 2 then
    d = util.clamp(d, -1, 1)
    top_line = top_line + d > 1 and top_line + d or 1
    screen_dirty = true
  end
end

function redraw()
  local baked_lines = lines()

  screen.clear()
  screen.level(15)
  screen.font_size(8)

  for i=1, LINE_COUNT do
    local line = baked_lines[i+top_line] or ''
    screen.move(0, 10*i)
    screen.text(line)
  end

  screen.update()
  screen_dirty = false
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

  while pos <= ribbon:len() do
    local char = ribbon:sub(pos, pos)
    local nline = lines[line]..char
    local width = screen.text_extents(nline) + 2 

    if char == "\n" then
      line = line + 1
      pos = pos + 1
      lines[line] = ""
    elseif width > MAX_WIDTH then
      local br = 1

      while char ~= " " do
        char = ribbon:sub(pos-br, pos-br)
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
  if value == 1 and key_actions[key] then
    key_repeat_clocks[key] = repeat_key(key)
  elseif value == 0 and key_repeat_clocks[key] then
    clock.cancel(key_repeat_clocks[key])
  end

  screen_dirty = true
end

function keyboard.char(ch)
  ribbon = ribbon .. ch
  screen_dirty = true
end

function repeat_key(key)
  return clock.run(function()
    key_actions[key]()
    clock.sleep(KEY_REPEAT_INIT_MS/1000)

    while true do
      key_actions[key]()
      clock.sleep(KEY_REPEAT_MS/1000)
    end
  end)
end
