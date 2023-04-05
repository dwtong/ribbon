local Ribbon = {}

local key = include "lib/key"
local store = include "lib/store"
local text = include "lib/text"
local view = include "lib/view"

local data_path = _path.data .. "ribbon/"

Ribbon.undo = store.undo
Ribbon.redo = store.redo
Ribbon.keybindings = {}

function Ribbon.init()
  store.init()
  view.init({ store = store })
  key.init({ store = store, bindings = Ribbon.keybindings })
end

function Ribbon.init_params()
  params:add_separator("RIBBON")

  params:add_file("ribbon_load_file", "load", data_path)
  params:set_action("ribbon_load_file", function(path)
    if path then
      Ribbon.load_file(path)
      _menu.set_mode(false)
    end
  end)

  params:add_text("ribbon_save_as_file", "save as", filename)
  params:set_action("ribbon_save_as_file", function(filename)
    if filename then
      local path = data_path .. filename
      Ribbon.save_file(path)
      _menu.set_mode(false)
    end
  end)

  params:add_separator("RIBBON DANGER ZONE")
  params:add_binary("ribbon_new", "new (!)", "momentary")
  params:set_action("ribbon_new", function()
    store.init()
  end)
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
  print "load"
  local lines, brks = text.load_from_file(file_path)

  if lines and brks then
    store.init({ lines = lines, brks = brks })
  end
end

function Ribbon.save_file(file_path)
  print "save"
  local lines = store.state.lines
  local brks = store.state.brks
  text.save_to_file(file_path, lines, brks)
end

return Ribbon
