--[[  NEXT GOALS:
-JOIN THE 2 SCRIPTS OF THE INVENTARY IN ONLY 1
-USE A DIFFERENT SCRIPT FOR DIALOG MENUS WITH ANOTHER NPC HERO
-PROGRAM SWITCHING HERO BETWEEN DIFFERENT MAPS (USING THE MENU!!!)
-PROGRAM A COMBINED ACTION FOR THE WIZARD AND ARCHER (FIRE + ARROW)
-ALLOW SWITCHING HERO DURING COMBINED ACTIONS (ACTION STAYS AFTER CHANGE), OR NOT ALLOWING SWITCHING ???
-DO NOT ALLOW SWITCHING HERO ON BAD GROUND OR DURING SOME ACTION WHICH IS NOT A COMBINED ACTION!

-MAKE MAP MENU (ACCES TO IT FROM INVENTARY???)
-MAKE A SAVING SCRIPT, TO SAVE ONLY ON ENTRANCES OF CAVES/HOUSES/DUNGEONS, FOR THE 3 HEROS!!!
--
REPAIR INVENTARY !!!
PROGRAM OPTIONS OF HERO-DIALOG MENU: TALKING, TRADE ITEMS, ASK FOR COMBINED ACTION???, LEAVING,...

]]

local hero_manager_builder = {}


-- Initialize values for new savegame: savegame_locations and current_hero_index.
local function initialize_new_savegame(game)
  local variables = {
    current_hero_index=1,
    npc1_map="root_prairie/000x000", npc1_x=200, npc1_y=200, npc1_layer=0, npc1_direction=3, npc1_is_on_team = true,
    npc2_map="root_prairie/000x000", npc2_x=248, npc2_y=120, npc2_layer=0, npc2_direction=2, npc2_is_on_team = true,
	  npc3_map="root_prairie/000x000", npc3_x=248, npc3_y=150, npc3_layer=0, npc3_direction=2, npc3_is_on_team = true
  }  
  for k,val in pairs(variables) do game:set_value(k, val) end
end 

function hero_manager_builder:create(game, exists)

  -- If there is no savegame, initialize new savegame variables.
  if not exists then initialize_new_savegame(game) end
  -- Set up the hero manager.
  local hero_manager = {
    enabled = true,
    changing_hero = false, 
    current_hero_index = game:get_value("current_hero_index"),
    npc_heroes_properties = {}, -- Initialized a few lines below.
    npc_heroes_on_map = {}, -- Initialized by on_map_changed().
    npc_heroes_to_switch = {}, -- Initialized by on_map_changed().
    switch_heroes_enabled = true,
    dialog_enabled = false,
    hero_dialog_menu = require("scripts/hero_manager/hero_dialog"),
  }
  -- Initialize npc_heroes_properties on the map from the savegame.
  for i = 1,3 do
    hero_manager.npc_heroes_properties[i] = {}
    hero_manager.npc_heroes_properties[i].map = game:get_value("npc"..i.."_map")
    hero_manager.npc_heroes_properties[i].index = i
    hero_manager.npc_heroes_properties[i].x = game:get_value("npc"..i.."_x")
    hero_manager.npc_heroes_properties[i].y = game:get_value("npc"..i.."_y")
    hero_manager.npc_heroes_properties[i].layer = game:get_value("npc"..i.."_layer")
    hero_manager.npc_heroes_properties[i].direction = game:get_value("npc"..i.."_direction")
    hero_manager.npc_heroes_properties[i].is_on_team = game:get_value("npc"..i.."_is_on_team")
  end
  -- Initializes sprite and direction of main hero.
   hero_manager.hero_tunic_sprites = {"main_heroes/edgar", "main_heroes/robyne", "main_heroes/wizard_blue", 
     "main_heroes/edgar_carrying", "main_heroes/robyne_carrying", "main_heroes/wizard_blue_carrying"}
  local hero = game:get_hero()
  hero:set_tunic_sprite_id(hero_manager.hero_tunic_sprites[hero_manager.current_hero_index])
  hero:set_animation("stopped")
  hero:set_direction(hero_manager.npc_heroes_properties[hero_manager.current_hero_index].direction)
  -- Define a function to get the index of the current hero and other to change to carrying state. (The same functions are defined for npc_heroes.)
  function hero:get_index() return hero_manager.current_hero_index end
  function hero:set_carrying(boolean) 
    local i = 0; if boolean then i = 1 end
    hero:set_tunic_sprite_id(hero_manager.hero_tunic_sprites[((hero_manager.current_hero_index-1+(3*i))%6)+1])
  end
  
---------------------------------------------------------------------------------------
  
  -- Saves starting positions and hero index in game variables.
  function hero_manager:refresh_savegame_variables()
  
    game:set_value("current_hero_index", hero_manager.current_hero_index)
	  game:set_starting_location(hero_manager.npc_heroes_properties[hero_manager.current_hero_index].map)
    for i=1,3 do
	  game:set_value("npc"..i.."_map", hero_manager.npc_heroes_properties[i].map)
	  game:set_value("npc"..i.."_x", hero_manager.npc_heroes_properties[i].x)
	  game:set_value("npc"..i.."_y", hero_manager.npc_heroes_properties[i].y)
	  game:set_value("npc"..i.."_layer", hero_manager.npc_heroes_properties[i].layer)
	  game:set_value("npc"..i.."_direction", hero_manager.npc_heroes_properties[i].direction)
	  game:set_value("npc"..i.."_is_on_team", hero_manager.npc_heroes_properties[i].is_on_team)
	end
  end
  
  -- Call this function to notify the hero manager that the current map has changed. Initialize npc heroes.
  function hero_manager:on_map_changed(map)
	  -- If disabled, do nothing.
	  if not hero_manager.enabled then return end
    -- Reset some variables.
    game:set_custom_command_effect("action", nil)
    -- Create the npc heroes that are in this map. Initialize the lists npc_heroes_on_map and npc_heroes_to_switch.
    hero_manager.npc_heroes_on_map = {}; hero_manager.npc_heroes_to_switch = {}
    for k, properties in pairs(hero_manager.npc_heroes_properties) do
      if properties.map == map:get_id() and properties.index ~= hero_manager.current_hero_index then 
        hero_manager.npc_heroes_on_map[k] = properties 	
        hero_manager:create_npc_hero(properties)
        if properties.is_on_team then hero_manager.npc_heroes_to_switch[k] = properties end
      end
    end
    
    -- Actualize npc_heroes coordinates when leaving the map (just in case the npc_hero is moved by some entity).
    -- The same is done for all the entities on the map, but only in case there is some npc_hero on the map. 
    function map:on_finished()
	    -- Function called when the player goes to another map. Save the state of the entities in case some npc_hero
	    -- is left on the map; otherwise delete the info. The info is stored temporarily in "game.active_maps".
      -- Items carried by the current hero are always saved.
      local some_hero_remains = (hero_manager:cardinal(hero_manager.npc_heroes_to_switch) > 0)
      game.save_between_maps:save_map(map, some_hero_remains)
      -- Finally, we store the position of the npc_heroes (it may have changed even without switching heroes).
      for npc in map:get_entities("npc_hero") do
        local x,y,layer = npc:get_position(); local dir = npc:get_direction(); local index = npc:get_index()
        local prop = hero_manager.npc_heroes_properties[index]
        prop.x = x; prop.y = y; prop.layer = layer; prop.direction = dir
      end	
    end
  -- End of function on_map_changed.
  end	

  -- Given a list of properties = {index=..., x=..., y=..., layer=..., direction=..., is_on_team=..., animation_set=..., animation=...} 
  -- of some npc_hero, a new npc_hero is created on the map and returned by the function.
  function hero_manager:create_npc_hero(properties)
    local map = game:get_map()
    properties.name = "npc_hero_"..properties.index; properties.model = "npc_hero"
    local npc_hero = map:create_custom_entity(properties)
    properties.name = nil; properties.model = nil
    npc_hero:set_index(properties.index)
    npc_hero:set_sprite(properties.animation_set or hero_manager.hero_tunic_sprites[properties.index])
    npc_hero:set_direction(properties.direction)
    npc_hero:get_sprite():set_animation("stopped")
    npc_hero:set_drawn_in_y_order(true)
    npc_hero:set_on_team(properties.is_on_team)
    npc_hero.custom_carry = properties.custom_carry
    return npc_hero
  end
 
  -- Interchange hero with npc_hero.
  function hero_manager:switch_hero()
    -- Do nothing if switching is disabled, or while changing hero, or if there are no npc heroes on the map that can be switched. 
    if (not hero_manager.switch_heroes_enabled) or hero_manager.changing_hero 
	  or hero_manager:cardinal(hero_manager.npc_heroes_to_switch) == 0 or game:is_suspended() then return end
	-- Allow changing hero only for the following states: free, carrying, swimming, hurt. 
	local state = hero:get_state()
	if state ~= "free" and state ~= "carrying" and state ~= "swimming" and state ~= "hurt" then return end
	-- Do nothing if there is bad ground below.
	local ground = game:get_map():get_ground(hero:get_position())
	if ground == "hole" or ground == "wall" or ground == "ladder" or ground == "prickles" then return end
	-- Freeze movement of hero.  
	hero_manager.changing_hero = true
	hero:freeze()
	local map = game:get_map()
	local direction_hero = hero:get_direction()
	local x_hero, y_hero, z_hero = hero:get_position()
	local index_hero = hero_manager.current_hero_index
	-- Select index of the next hero, to switch.
	local index_npc = hero_manager:next_index(index_hero)
	if hero_manager.npc_heroes_to_switch[index_npc] == nil then index_npc = hero_manager:next_index(index_npc) end
	local npc = map:get_entity("npc_hero_"..index_npc)
	-- Take current properties of the (old) npc_hero (these may have changed if something moved the npc_hero).
	local npc_properties = hero_manager.npc_heroes_on_map[index_npc]
	npc_properties.x, npc_properties.y, npc_properties.layer = npc:get_position()
	npc_properties.direction = npc:get_direction()
	local sprite = npc:get_sprite()
	npc_properties.animation_set = sprite:get_animation_set()
	npc_properties.custom_carry = npc.custom_carry
	-- Take current properties of the hero. 
	local hero_properties = {map=map:get_id(), index=index_hero, x=x_hero, y=y_hero, layer=z_hero, 
	  direction=direction_hero, is_on_team=true, animation_set=hero:get_tunic_sprite_id(), 
	  custom_carry=hero.custom_carry }
	-- Create new npc_hero with new index, sprite and position. 
	local new_npc = hero_manager:create_npc_hero(hero_properties)
	-- Change index, sprites, position, and other properties of the hero.
	hero:set_tunic_sprite_id(npc_properties.animation_set) 
	hero:set_animation("stopped")
	hero:set_direction(npc_properties.direction)
  hero.custom_carry = npc_properties.custom_carry -- Do this before changing hero position (so carried entity cannot move).
	hero:set_position(npc_properties.x, npc_properties.y, npc_properties.layer)
	if hero.custom_carry ~= nil then
	  game:set_custom_command_effect("attack", "custom_carry") 
	else 
	  game:set_custom_command_effect("attack", nil) 
	end
  game:set_custom_command_effect("action", nil)
	hero_manager.current_hero_index = index_npc
 	-- Remove from the map the old npc_hero.	 
	map:remove_entities("npc_hero_" .. index_npc)
	-- Move the camera.
	map:move_camera(npc_properties.x, npc_properties.y, 250, function() end, 0, 0)
	-- Actualize lists of heroes.
	hero_manager.npc_heroes_properties[index_hero] = hero_properties
	hero_manager.npc_heroes_on_map[index_hero] = hero_properties
	hero_manager.npc_heroes_to_switch[index_hero] = hero_properties
	hero_manager.npc_heroes_on_map[index_npc] = nil
	hero_manager.npc_heroes_to_switch[index_npc] = nil
	-- Actualizes savegame variables. Restart movement of hero.
	hero_manager:refresh_savegame_variables()
	hero_manager.changing_hero = false
  -- Restart interaction of the hero.
  game:clear_interaction()
  -- Unfreeze.
	hero:unfreeze()
  end
   
  
  -- Get the npc_hero or hero on the map of the given index.
  function hero_manager:get_hero_entity(index) 
    if self.current_hero_index == index then local hero = game:get_hero(); return hero
	  else return game:get_map():get_entity("npc_hero_"..index) end 
  end
  -- Returns the next index cyclically: 1,2,3.  
  function hero_manager:next_index(index) return math.max((index+1)%4, 1) end  
  -- Returns boolean. True if the hero of certain index (1, 2 or 3) is on the current map (as an npc_hero or the hero). 
  function hero_manager:is_hero_on_screen(index) return (hero_manager.current_hero_index == index) or (hero_manager.npc_heroes_on_map[index] ~= nil) end  
  -- Returns the number of elements of a table.
  function hero_manager:cardinal(my_table) local n=0; for _,_ in pairs(my_table) do n=n+1 end return n end
  -- Call this function to notify the hero manager that the game was just paused/unpaused.
  function hero_manager:on_paused() hero_manager.enabled = false end
  function hero_manager:on_unpaused() hero_manager.enabled = true end
  -- When destroying the game.
  function hero_manager:quit() hero_manager.enabled = false end
  -- More functions.
  function hero_manager:is_enabled() return hero_manager.enabled end
  function hero_manager:set_enabled(enabled) hero_manager.enabled = enabled end
  function hero_manager:is_dialog_enabled() return hero_manager.dialog_enabled end
  function hero_manager:set_dialog_enabled(enabled) hero_manager.dialog_enabled = enabled end

--------------------------------------------------------------  
  return hero_manager
end

return hero_manager_builder


