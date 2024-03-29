local enemy = ...

-- Default parameters of the beam particle.
local particle_sprite = "things/rock"
local damage = 1

function enemy:on_created(properties)
  -- Get properties and target coordinates.
  if properties then
    if properties.particle_sprite then particle_sprite = properties.particle_sprite end
    if properties.damage then damage = properties.damage end
  end
  -- Set properties.
  self:set_size(8, 8)
  self:set_invincible()
  self:create_sprite(particle_sprite)
  self:set_damage(damage)
end

function enemy:explode()
  -- (SHOW AN EXPLOSION ANIMATION HERE + SOUND).
  self:remove()
end
