-- This is the main Lua script of your project.
-- You will probably make a title screen and then start a game.
-- See the Lua API! http://www.solarus-games.org/solarus/documentation/


local game_manager = require("scripts/game_manager.lua")
local logo_menu = require("scripts/menus/solarus_logo")
local game

local function start_game()
  if game == nil then
    game = game_manager:create("save1.dat")
    game:start()
  end
end

function sol.main:on_started()

  sol.language.set_language("en")
  --sol.audio.preload_sounds()
  --sol.video.set_mode("hq2x") -- Video modes: normal, scale2x, hq2x, hq3x, hq4x.
  sol.menu.start(sol.main, logo_menu)
  
  function logo_menu.on_finished(logo_menu)
    start_game()
  end
  
end

-- Returns the font and font size to be used for dialogs
-- depending on the specified language (the current one by default).
function sol.language.get_dialog_font(language)
  -- For now the same font is used by all languages.
  return "fixed8", 11
end

-- Returns the font and font size to be used to display text in menus
-- depending on the specified language (the current one by default).
function sol.language.get_menu_font(language)
  -- For now the same font is used by all languages.
  return "Viner Hand Itc", 8
end
