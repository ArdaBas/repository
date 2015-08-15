-- This script is used in the hero_manager script to create an npc_hero with certain index = 1, 2 or 3. 

local npc_hero = ...

npc_hero.is_npc_hero = true ----- QUITAR ESTO MAS ADELANTE!!!!
npc_hero.can_push_buttons = true
npc_hero.moved_on_platform = true

local index, is_on_team

function npc_hero:on_created()
  self:set_drawn_in_y_order(true)
end

-- Returns the index 1,2 or 3 of the hero npc.
function npc_hero:get_index() return index end
-- Changes the index 1,2 or 3 of the hero npc. Sprites are changed too.
-- This function must be used after creating an instance of npc_hero to create the sprite.
function npc_hero:set_index(new_index) index = new_index end

-- Creates a sprite for the npc hero. This is used immediately after creation of the npc_hero in the hero_manager. 
function npc_hero:set_sprite(sprite_id)
  local sprite = npc_hero:get_sprite()
  if sprite ~= nil then npc_hero:remove_sprite(sprite) end
  npc_hero:create_sprite(sprite_id)
end

-- Functions to know if the npc_hero is on the team and set it or not on the team.
-- Make the npc_hero not traversable by the hero when he is not on the team. 
function npc_hero:is_on_team() return is_on_team end
function npc_hero:set_on_team(boolean) 
  is_on_team = boolean 
  npc_hero:set_traversable_by("hero", boolean)
end

-- Returns boolean: true if hero is facing npc_hero in the same layer and close.
function npc_hero:is_facing_hero()
  local map = npc_hero:get_map()
  local hero = map:get_entity("hero")
  local hero_x, hero_y, hero_z = hero:get_position()
  local npc_x, npc_y, npc_z = npc_hero:get_position()
  local has_good_direction = hero:get_direction4_to(npc_hero) == hero:get_direction()
  local is_close = (math.abs(hero_x - npc_x) < 10 and math.abs(hero_y - npc_y) < 18) or 
                   (math.abs(hero_x - npc_x) < 18 and math.abs(hero_y - npc_y) < 10)
  return has_good_direction and is_close and hero_z == npc_z
end

function npc_hero:set_carrying(boolean)
  local i = 0; if boolean then i = 1 end
  local direction = self:get_direction()
  local sprite_id = self:get_game():get_hero_manager().hero_tunic_sprites[((index-1+(3*i))%6)+1]
  self:remove_sprite(self:get_sprite())  
  local sprite = self:create_sprite(sprite_id); sprite:set_direction(direction)
end

--[[
-- BORRAR ESTO!!!!!!!!!!!!
-- The npc_hero dialog menu is activated. This is done calling the hero dialog menu in the game manager. 
function npc_hero:start_dialog()
  npc_hero:set_direction(2)
  sol.audio.play_sound("secret")
  npc_hero:get_game():hero_dialog_menu(index)
end
--]]


