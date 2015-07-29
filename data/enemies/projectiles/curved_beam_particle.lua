local enemy = ...

-- Parameters of the beam particle.
local particle_sprite = "things/rock"
local damage = 1
local speed = 150

function enemy:on_created(properties)
  -- Get properties and target coordinates.
  local tx, ty 
  if properties then
    tx, ty = properties.target_x, properties.target_y
    if properties.particle_sprite then particle_sprite = properties.particle_sprite end
    if properties.damage then damage = properties.damage end
    if properties.speed then speed = properties.speed end   
  else tx, ty, _ = self:get_map():get_hero():get_position() 
  end
  -- Set properties.
  self:set_size(8, 8)
  self:set_invincible()
  self:create_sprite(particle_sprite)
  self:set_damage(damage)
  -- Create movement. Destroy enemy when the movement ends.
  local m = sol.movement.create("target")
  m:set_target(tx, ty); m:set_speed(speed)
  function m:on_finished() enemy:explode() end
  function m:on_obstacle_reached() enemy:explode() end
  m:start(self)
end

function enemy:explode()
  -- (SHOW AN EXPLOSION ANIMATION HERE + SOUND).
  self:remove()
end
