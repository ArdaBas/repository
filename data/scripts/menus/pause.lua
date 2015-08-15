-- Script that creates a pause menu for a game.

-- Usage:
-- local pause_manager = require("scripts/menus/pause")
-- local pause_menu = pause_manager:create(game)

local pause_manager = {}

-- Initialize values for new savegame.
local function initialize_new_savegame(game)
  game:set_value("possession_nothing", 1)
end

-- Creates a pause menu for the specified game.
function pause_manager:create(game, exists)

  local pause_menu = {}
  
  -- If there is no savegame, initialize new savegame variables.
  if not exists then initialize_new_savegame(game) end

  function pause_menu:on_started()

    -- Define the available submenus.
    local inventory_builder = require("scripts/menus/pause_inventory")

    game.pause_submenus = {  -- Array of submenus (inventory, map, etc.).
      inventory_builder:new(game),
      -- For now there is only the inventory submenu.
      -- Add other pause submenus here.
    }

    -- Select the submenu that was saved if any.
    local submenu_index = game:get_value("pause_last_submenu") or 1
    if submenu_index <= 0
        or submenu_index > #game.pause_submenus then
      submenu_index = 1
    end
    game:set_value("pause_last_submenu", submenu_index)

    -- Play the sound of pausing the game.
    sol.audio.play_sound("pause_open")

    -- Start the selected submenu.
    sol.menu.start(game, game.pause_submenus[submenu_index], false)
  end

  function pause_menu:on_finished()

    -- Play the sound of unpausing the game.
    sol.audio.play_sound("pause_closed")

    game.pause_submenus = {}

    -- Restore the built-in effect of action and attack commands.
    game:set_custom_command_effect("action", nil)
    game:set_custom_command_effect("attack", nil)
  end

  return pause_menu
end

return pause_manager
