-- The small keys counter shown during dungeons or maps with small keys enabled.

local small_keys_builder = {}

function small_keys_builder:new(game)

  local small_keys = {}

  function small_keys:initialize()

    small_keys.visible = false
    small_keys.surface = sol.surface.create(40, 8)
    small_keys.icon_img = sol.surface.create("hud/small_key_icon.png")
    small_keys.digits_text = sol.text_surface.create{
      font = "white_digits",
      horizontal_alignment = "left",
      vertical_alignment = "top",
    }

    small_keys:check()
    small_keys:rebuild_surface()
  end

  function small_keys:check()

    local need_rebuild = false

    local visible = game.are_small_keys_enabled ~= nil and game:are_small_keys_enabled()

    -- Check the number of small keys.
    if visible then
      local nb_keys = game:get_num_small_keys()
      local nb_keys_displayed = tonumber(small_keys.digits_text:get_text())
      if nb_keys_displayed ~= nb_keys then
        small_keys.digits_text:set_text(nb_keys)
        need_rebuild = true
      end
    end

    if visible ~= small_keys.visible then
      small_keys.visible = visible
      need_rebuild = true
    end

    -- Redraw the surface is something has changed.
    if need_rebuild then
      small_keys:rebuild_surface()
    end

    -- Schedule the next check.
    sol.timer.start(game, 40, function()
      small_keys:check()
    end)
  end

  function small_keys:rebuild_surface()

    small_keys.surface:clear()
    small_keys.icon_img:draw(small_keys.surface)
    small_keys.digits_text:draw(small_keys.surface, 10, 0)
  end

  function small_keys:set_dst_position(x, y)
    small_keys.dst_x = x
    small_keys.dst_y = y
  end

  function small_keys:on_draw(dst_surface)

    if small_keys.visible then
      local x, y = small_keys.dst_x, small_keys.dst_y
      local width, height = dst_surface:get_size()
      if x < 0 then
        x = width + x
      end
      if y < 0 then
        y = height + y
      end

      small_keys.surface:draw(dst_surface, x, y)
    end
  end

  small_keys:initialize()

  return small_keys
end

return small_keys_builder

