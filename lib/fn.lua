local Fn = {}

function Fn.debounce(callback, timeout_seconds)
  local debounce_clock

  return function(...)
    local args = ...

    if debounce_clock then
      clock.cancel(debounce_clock)
    end

    debounce_clock = clock.run(function()
      clock.sleep(timeout_seconds)
      callback(args)
    end)
  end
end

return Fn
