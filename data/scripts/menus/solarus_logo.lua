local logo_menu = {}

local logo_img = sol.surface.create("menus/solarus_logo.png")
local logo_menu_finished = false

function logo_menu:on_started()

  logo_menu_finished = false
  local logo_movement = sol.movement.create("straight")
  logo_movement:set_speed(128)
  logo_movement:set_angle(3 * math.pi / 2)
  logo_movement:set_max_distance(160)
  logo_movement:start(logo_img, function()
    if not logo_menu_finished then
      sol.audio.play_sound("ok")
      sol.timer.start(logo_menu, 500, function()
        logo_menu_finished = true
        sol.menu.stop(logo_menu)
      end)
    end
  end)
end

function logo_menu:on_draw(dst_surface)

  logo_img:draw(dst_surface, 0, -160)
end

function logo_menu:on_key_pressed(key)

  if key == "space" then
    logo_menu_finished = true
    sol.menu.stop(logo_menu)
  end
end

return logo_menu
