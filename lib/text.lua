-- constants used as symbols
local LINE_BREAK = "LINE_BREAK"
local WRAP_BREAK = "WRAP_BREAK"

local text = {}

text.LINE_BREAK = LINE_BREAK
text.WRAP_BREAK = WRAP_BREAK

function text.trim(str)
  return str:gsub("^%s+", ""):gsub("%s$", "")
end

function text.splice(str, new_str, index)
  return str:sub(1, index - 1) .. new_str .. str:sub(index)
end

function text.remove(str, index)
  return str:sub(1, index - 1) .. str:sub(index + 1)
end

function text.last_space_index(str)
  if str:find("%s") == nil then
    return nil
  else
    return str:len() - str:reverse():find("%s") + 1
  end
end

function text.width(str)
  local space_px = 4
  local text_width_px = screen.text_extents(str)

  if text_width_px > 0 then
    local leading_str = str:match("^%s+")
    local leading_spaces = leading_str and leading_str:len() or 0
    local trailing_str = str:match("%s+$")
    local trailing_spaces = trailing_str and trailing_str:len() or 0
    local padded_space_px = space_px * (leading_spaces + trailing_spaces)

    return text_width_px + padded_space_px
  else
    local space_count = str:len()
    return space_px * space_count
  end
end

function text.split_on_line_wrap(str, target_width)
  if text.width(str) < target_width then
    return { str }
  else
    local head = str
    local split_at

    repeat
      split_at = head:len() - 1
      local last_space_index = text.last_space_index(head:sub(1, split_at))
      split_at = last_space_index or split_at
      head = str:sub(1, split_at)
    until text.width(head) < target_width

    local tail = str:sub(split_at + 1)
    local splits = { head }
    local tail_splits = text.split_on_line_wrap(tail, target_width)

    for _, split in ipairs(tail_splits) do
      table.insert(splits, split)
    end

    table.insert(splits, "")
    return splits
  end
end

function text.unwrap_lines(lines, brks)
  local next_lines = {}

  for line_index = 1, #lines do
    local line = lines[line_index]
    local prev_brk = brks[line_index - 1]
    if prev_brk == nil then
      table.insert(next_lines, line)
    elseif prev_brk == LINE_BREAK then
      table.insert(next_lines, line)
    elseif prev_brk == WRAP_BREAK then
      next_lines[#next_lines] = next_lines[#next_lines] .. line
    end
  end

  return next_lines
end

function text.wrap_lines(lines, target_width)
  local next_lines = {}
  local next_brks = {}

  for line_index = 1, #lines do
    local line = lines[line_index]
    local wrapped_lines = text.split_on_line_wrap(line, target_width)

    for wrapped_index, wrapped_line in ipairs(wrapped_lines) do
      table.insert(next_lines, wrapped_line)

      if wrapped_index == #wrapped_lines then
        table.insert(next_brks, LINE_BREAK)
      else
        table.insert(next_brks, WRAP_BREAK)
      end
    end
  end

  return next_lines, next_brks
end

function text.rewrap_lines(lines, brks, target_width)
  local unwrapped_lines = text.unwrap_lines(lines, brks)
  next_lines, next_brks = text.wrap_lines(unwrapped_lines, target_width)
  return next_lines, next_brks
end

return text
