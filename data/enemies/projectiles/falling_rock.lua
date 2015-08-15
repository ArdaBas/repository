local enemy = ...


function enemy:on_created()
  -- Initialize animations and falling movement.
  self:set_invincible(); self:set_can_attack(false)
  self:set_traversable(true)
  self:set_size(16,16); self:set_origin(8,13)
  self:set_damage(2); self:set_hurt_style("normal")
  local shadow = self:create_sprite("things/rock")
  local rock = enemy:create_sprite("things/rock")
  rock:set_xy(0,-96)

  -- Set position in upper layer.
  self:set_layer_independent_collisions(true)
  local x,y,_ = self:get_position()
  self:set_position(x,y,2)
  
  function enemy:on_restarted()
    shadow:set_animation("stopped")
    rock:set_animation("walking") 
    local m = sol.movement.create("straight")
    m:set_speed(150); m:set_angle(3*math.pi/2)
    m:set_max_distance(96); m:set_ignore_obstacles(true)
    m:start(rock)
    function m:on_finished() enemy:destroy() end
  end
  
  -- Destroy rock after breaking animation.
  function enemy:destroy()
    self:set_can_attack(true)
	sol.audio.play_sound("falling_rock")
    rock:set_animation("breaking")
	function rock:on_animation_finished(animation)
	  enemy:remove()
	end
  end

end

