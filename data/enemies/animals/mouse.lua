local enemy = ...

enemy.can_save_state = true

sol.main.load_file("enemies/generic_towards_hero")(enemy)
enemy:set_properties({
 sprite = "animals/mouse", life = 1, damage = 1, normal_speed = 32, faster_speed = 48, 
 hurt_style = "normal", push_hero_on_sword = false, pushed_when_hurt = true, 
 movement_create = function() local m = sol.movement.create("random_path") return m end
})







