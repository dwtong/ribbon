local Text = {}

-- constants used as symbols
local LINE_BREAK = "LINE_BREAK"
local WRAP_BREAK = "WRAP_BREAK"

Text.LINE_BREAK = LINE_BREAK
Text.WRAP_BREAK = WRAP_BREAK

function Text.trim(text)
  return text:gsub("^%s+", ""):gsub("%s$", "")
end

function Text.splice(text, new_text, index)
  return text:sub(1, index - 1) .. new_text .. text:sub(index)
end

function Text.remove(text, index)
  return text:sub(1, index - 1) .. text:sub(index + 1)
end

function Text.last_space_index(text)
  if text:find("%s") == nil then
    return nil
  else
    return text:len() - text:reverse():find("%s") + 1
  end
end

function Text.width(text)
  local space_px = 4
  local text_width_px = screen.text_extents(text)

  if text_width_px > 0 then
    local leading_text = text:match("^%s+")
    local leading_spaces = leading_text and leading_text:len() or 0
    local trailing_text = text:match("%s+$")
    local trailing_spaces = trailing_text and trailing_text:len() or 0
    local padded_space_px = space_px * (leading_spaces + trailing_spaces)

    return text_width_px + padded_space_px
  else
    local space_count = text:len()
    return space_px * space_count
  end
end

function Text.split_on_line_wrap(text, target_width)
  if Text.width(text) <= target_width then
    return { text }
  else
    local head = text
    local split_at, target

    repeat
      split_at = head:len() - 1
      local substring_with_space = head:sub(1, split_at)
      local space_index = Text.last_space_index(substring_with_space)

      if space_index then
        target = target_width + Text.width(" ")
        split_at = space_index
      else
        target = target_width
      end

      head = head:sub(1, split_at)
    until Text.width(head) <= target

    local tail = text:sub(split_at + 1)
    local splits = { head }
    local tail_splits = Text.split_on_line_wrap(tail, target_width)

    for _, split in ipairs(tail_splits) do
      table.insert(splits, split)
    end

    return splits
  end
end

function Text.unwrap_lines(lines, brks)
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

function Text.wrap_lines(lines, target_width)
  local next_lines = {}
  local next_brks = {}

  for line_index = 1, #lines do
    local line = lines[line_index]
    local wrapped_lines = Text.split_on_line_wrap(line, target_width)

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

function Text.rewrap_lines(lines, brks, target_width)
  local unwrapped_lines = Text.unwrap_lines(lines, brks)
  next_lines, next_brks = Text.wrap_lines(unwrapped_lines, target_width)
  return next_lines, next_brks
end

function Text.save_to_file(file_path, wrapped_lines, brks)
  local lines = Text.unwrap_lines(wrapped_lines, brks)
  local text_file = io.open(file_path, "w")

  if text_file then
    for _, line in ipairs(lines) do
      text_file:write(line .. "\n")
    end

    text_file:close()
    print("Saved to " .. file_path)
  else
    print("Failed to save " .. file_path)
  end
end

function Text.load_from_file(file_path)
  local lines = {}
  local brks = {}

  for line in io.lines(file_path) do
    lines[#lines + 1] = line
    brks[#brks + 1] = LINE_BREAK
  end

  if lines == {} then
    print("Failed to load " .. file_path)
  end

  return lines, brks
end

return Text
