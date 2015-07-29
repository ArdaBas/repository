local enemy = ...

-- Parameters of the beam.
local particle_sprite = "things/rock"
local damage = 1
local speed = 150
local max_distance = 100
local time_between_particles = 50

function enemy:on_created()
  self:create_sprite("enemies/red_demon")
  self:set_invincible(); self:set_can_attack(false); self:set_traversable(true)
  self:set_size(16,16); self:set_origin(8,13)
end

function enemy:on_restarted()
  -- Start throwing beam particles.
  local properties = {particle_sprite = particle_sprite, damage = damage, speed = speed, breed = "projectiles/beam_particle"}
  local tx, ty
  sol.timer.start(enemy, time_between_particles, function()
    -- Actualize target position. Create beam particle if the hero is close.
    tx, ty, _ = enemy:get_map():get_hero():get_position()
	if enemy:get_distance(tx, ty) < max_distance then
	  properties.target_x, properties.target_y = tx, ty
      enemy:create_enemy(properties)
	end
	-- Restart timer.
	return true
  end) 
end
  
