local enemy = ...

-- Parameters of the beam.
local particle_sprite = "things/rock"
local damage = 1
local particle_speed = 200
local aim_speed = 60
local max_distance = 100
local min_distance = 1
local time_between_particles = 50
local max_number_particles = 50 -- Max length of the particle array.

function enemy:on_created()
  self:create_sprite("enemies/red_demon")
  self:set_invincible(); self:set_can_attack(false); self:set_traversable(true)
  self:set_size(16,16); self:set_origin(8,13)
end

function enemy:on_restarted()

  -- Start throwing beam particles.
  local properties = {particle_sprite = particle_sprite, damage = damage, breed = "projectiles/beam_particle"}
  local particles = {}
  local x, y, z = enemy:get_position()

  -- Function to start creating beam particles periodically.
  local function shoot()
    local index = 1
    sol.timer.start(enemy, time_between_particles, function()
      -- Stop shooting if target is too far.
	  if enemy:get_distance(enemy.target.x, enemy.target.y) > max_distance then enemy:stop_firing(); return end
	  -- Create new particle. (Max number of particles coincides with max_distance.)
      if particles[index] then particles[index]:remove() end
	  local e = enemy:create_enemy(properties)
	  e.distance = min_distance
	  particles[index] = e
	  index = (index %max_number_particles) +1 -- Next index.
      return true
   end)
  end
  
  -- Function to start creating beam particles periodically.
  local function move_particles()
    local t = math.floor(1000/particle_speed) -- Time between position changes.
    sol.timer.start(enemy, t, function()
      local angle = enemy:get_angle(enemy.target.x, enemy.target.y)
      for k, v in pairs(particles) do
        local d = v.distance + 1
		local dt = enemy:get_distance(enemy.target.x, enemy.target.y)
	    if d > max_distance or d >= dt then
		  particles[k] = nil; v:explode()
	    else 
	      v.distance = d
	      v:set_position(x + d*math.cos(angle), y - d*math.sin(angle), z)
	    end
      end
	  return true
    end)
  end
  
  -- Function to stop firing.
  function enemy:stop_firing()
    sol.timer.stop_all(enemy)
    -- Remove target and beam particles.
    enemy.target = nil
    for k, v in pairs(particles) do v:remove(); particles[k] = nil end
    sol.timer.start(enemy, 50, function() enemy:on_restarted() end)
  end
  
  -- Check if hero is close to shoot.
  sol.timer.start(enemy, 50, function()
    local hx, hy, _ = enemy:get_map():get_hero():get_position()
	if enemy:get_distance(hx, hy) < max_distance then
	  -- Create target position.
	  local tx = (x+hx)/2; ty = (y+hy)/2 -- Middle point between hero and enemy.
	  if not enemy.target then enemy.target = {x = tx, y = ty} end
	  -- Move the target position towards hero.
      local m = sol.movement.create("target")
	  m:set_ignore_obstacles()
	  local hero = enemy:get_map():get_hero()
      m:set_target(hero); m:set_speed(aim_speed); m:start(enemy.target)
	  -- Start shooting towards target position. Start moving particles.
	  shoot(); move_particles()
	  return false -- Stop timer.
	end
	return true
  end)

end
