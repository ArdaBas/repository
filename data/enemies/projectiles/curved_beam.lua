local enemy = ...

-- Parameters of the beam.
local particle_sprite = "things/rock"
local damage = 1
local speed = 150
local max_distance = 100
local time_between_particles = 50
local particles_per_beam = 5 -- Set to 0 for not stopping (unlimited particles per beam).
local stop_time = 1000

function enemy:on_created()
  self:create_sprite("enemies/red_demon")
  self:set_invincible(); self:set_can_attack(false); self:set_traversable(true)
  self:set_size(16,16); self:set_origin(8,13)
end

function enemy:on_restarted()
  -- Start throwing beam particles.
  local properties = {particle_sprite = particle_sprite, damage = damage, breed = "projectiles/beam_particle"}
  local particles = particles_per_beam
  sol.timer.start(enemy, time_between_particles, function()
    -- Number of remaining particles.
    if particles_per_beam > 0 then 
	  if particles <= 0 then enemy:stop_firing(); return false end	  
	end
    -- Actualize target position. Create beam particle if the hero is close.
    local tx, ty, _ = enemy:get_map():get_hero():get_position()
	if enemy:get_distance(tx, ty) < max_distance then
	  if particles_per_beam > 0 then particles = particles - 1 end
      local e = enemy:create_enemy(properties)
	  -- Create movement. Destroy enemy when the movement ends.
      local m = sol.movement.create("target")
      m:set_target(tx, ty); m:set_speed(speed)
      function m:on_finished() e:explode() end
      function m:on_obstacle_reached() e:explode() end
      m:start(e)
	end
	-- Restart timer.
	return true
  end) 
end

-- Function to stop firing for a while.
function enemy:stop_firing()
  sol.timer.stop_all(enemy)
  sol.timer.start(enemy, stop_time, function() enemy:on_restarted() end)
end
