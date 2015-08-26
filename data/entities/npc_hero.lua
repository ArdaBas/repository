-- This script is used in the hero_manager script to create an npc_hero with certain index = 1, 2 or 3. 

local npc_hero = ...

npc_hero.is_npc_hero = true ----- MAYBE I SHOULD DELETE THIS!!!!
npc_hero.can_push_buttons = true
npc_hero.moved_on_platform = true
npc_hero.custom_carry = nil
npc_hero.action_effect = "talk"

local index, is_on_team

function npc_hero:on_created()
  self:set_drawn_in_y_order(true)
  self:set_can_traverse_ground("hole", true)
  self:set_can_traverse_ground("deep_water", true)
  self:set_can_traverse_ground("lava", true)
  -- Interaction properties for the HUD.
  self:get_game():set_interaction_enabled(npc_hero, true)
end

-- Activate the hero dialog menu.
function npc_hero:on_custom_interaction()
  local game = self:get_game()
  local hero_manager = game.hero_manager
  hero_manager.hero_dialog_menu:start(game, hero_manager, self)
  -- SELECT DIALOG!!!
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

function npc_hero:set_carrying(boolean)
  local i = 0; if boolean then i = 1 end
  local direction = self:get_direction()
  local sprite_id = self:get_game().hero_manager.hero_tunic_sprites[((index-1+(3*i))%6)+1]
  self:remove_sprite(self:get_sprite())  
  local sprite = self:create_sprite(sprite_id); sprite:set_direction(direction)
end

-- Notify carried entities to follow npc_hero with on_position_changed() method.
function npc_hero:on_position_changed()
  if self.custom_carry then
    local x, y, layer = self:get_position()
    self.custom_carry:set_position(x, y+2, layer)
  end
end
