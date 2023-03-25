local text = {}

function text.trim(str)
  return str:gsub("^%s+", ""):gsub("%s$", "")
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

function text.split(str, target_width)
  -- TODO split at spaces rather than just character position
  -- local str_has_spaces = text:match("%s")
  local text_width = text.width(str)

  if text_width > target_width then
    local split_at = str:len() - 1
    local head = str:sub(1, split_at)

    while text.width(head) > target_width do
      split_at = split_at - 1
      head = str:sub(1, split_at)
    end

    local tail = str:sub(split_at + 1)
    local splits = { head }
    local tail_splits = text.split(tail, target_width)

    for _, split in ipairs(tail_splits) do
      local trimmed_split = text.trim(split)

      if trimmed_split:len() > 0 then
        table.insert(splits, trimmed_split)
      end
    end

    return splits
  else
    return { str }
  end
end

return text
