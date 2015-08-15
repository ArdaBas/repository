local item = ...

local jump_duration = 300 -- Change this for duration of the jump.
local is_jumping

function item:on_created()
  self:set_savegame_variable("possesion_feather")
  self:set_variant(1)
  self:set_assignable(true)
end

-- Return true if the hero can jump/save on this ground.
local function is_solid_ground(ground_type)
  return ((ground_type == "traversable") or (ground_type == "low_wall")
    or (ground_type == "wall_top_right") or (ground_type == "wall_top_left")
    or (ground_type == "wall_bottom_left") or (ground_type == "wall_bottom_right")
    or (ground_type == "shallow_water")  or (ground_type == "ice"))
end

function item:on_using()
  -- Do nothing if already jumping or carrying something, or if the ground is not "jumpable".
  local game = self:get_game()
  local map = self:get_map()
  local hero = map:get_hero()
  hero:unfreeze()
  local state = game:get_custom_command_effect("action")
  if is_jumping or state == "custom_carry" then return end ----- ADD MORE RESTRICTIONS!!!!
  local ground = map:get_ground(hero:get_position())
  if not is_solid_ground(ground) then return end
  -- Set jumping to true. Disable teletransporters during jump.
  is_jumping = true
  game.save_between_maps:disable_teletransporters(map)  
  -- The hero can jump. Change custom state, save solid position.
  game:set_custom_command_effect("action", "custom_jump")
	game:set_custom_command_effect("attack", "custom_jump")
  hero:save_solid_ground()
  -- Unfreeze, play sound, set invincible.
  sol.audio.play_sound("jump")
  hero:set_invincible(true)
  -- Change animation set to display the jump.
  local hero_manager = self:get_game():get_hero_manager()
  local jump_set = hero_manager.hero_tunic_sprites[hero:get_index()] .. "_jumping"
  local current_set = hero:get_tunic_sprite_id()
  hero:set_tunic_sprite_id(jump_set)
  -- Create shadow platform with traversable ground that follows the hero under him.
  local x,y,layer = hero:get_position()
  local tile = self:get_map():create_custom_entity({x=x,y=y,layer=layer,direction=0,width=8,height=8})
  tile:set_origin(4, 4)
  tile:set_modified_ground("traversable")
  tile:create_sprite("entities/shadow")
  function tile:on_update() tile:set_position(hero:get_position()) end -- Follow the hero.
  -- Finish the jump.
  sol.timer.start(self, jump_duration, function()
    hero:set_tunic_sprite_id(current_set)
    tile:remove()
    -- If ground is empty, move hero to lower layer.
    x,y,layer = hero:get_position()
    ground = map:get_ground(hero:get_position())
    if ground == "empty" and layer > 0 then hero:set_position(x,y,layer-1) end
    x,y,layer = hero:get_position()
    ground = map:get_ground(hero:get_position())
    if ground == "empty" and layer > 0 then hero:set_position(x,y,layer-1) end
    -- Restore custom states. Enable teletransporters after jump.
    game:set_custom_command_effect("action", nil)
	  game:set_custom_command_effect("attack", nil)
    game.save_between_maps:enable_teletransporters(map)
    hero:set_invincible(false)
    -- Restore solid ground when possible.
    sol.timer.start(game, 1000, function()
      ground = map:get_ground(hero:get_position())
      if is_solid_ground(ground) and (not is_jumping) then
        hero:reset_solid_ground()
      end
    end)
  -- Finish the jump.
  is_jumping = false
  item:set_finished()
  end)
end


