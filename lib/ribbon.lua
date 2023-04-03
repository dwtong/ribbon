local Ribbon = {}

local key = include "ribbon/lib/key"
local store = include "ribbon/lib/store"
local view = include "ribbon/lib/view"

Ribbon.undo = store.undo
Ribbon.redo = store.redo
Ribbon.keybindings = {}

function Ribbon.init()
  local redraw_callback = function() redraw() end

  view.init({ store = store })
  key.init({ store = store, bindings = Ribbon.keybindings })
  store.add_event_listener("onchange", redraw_callback)
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

return Ribbon
