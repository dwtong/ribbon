local Ribbon = {}

local key = include "lib/key"
local store = include "lib/store"
local text = include "lib/text"
local view = include "lib/view"

Ribbon.undo = store.undo
Ribbon.redo = store.redo
Ribbon.keybindings = {}

function Ribbon.init()
  store.init()
  view.init({ store = store })
  key.init({ store = store, bindings = Ribbon.keybindings })
end

function Ribbon.redraw()
  screen.clear()

  view.draw_lines()
  view.draw_cursor()
  view.draw_status()

  screen.update()
end

function Ribbon.keycode(k, v)
  screen.ping()
  key.code(k, v, store)
end

function Ribbon.keychar(char)
  key.char(char, store)
end

function Ribbon.load_file(file_path)
  local lines, brks = text.load_from_file(file_path)

  if lines and brks then
    store.init({ lines = lines, brks = brks })
  end
end

function Ribbon.save_file(file_path)
  local lines = store.state.lines
  local brks = store.state.brks
  text.save_to_file(file_path, lines, brks)
end

return Ribbon
