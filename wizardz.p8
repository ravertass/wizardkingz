pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- kingz of wizardz
-- a spooky game jam game

function sign(num)
  if num == 0 then
    return 0
  else
    return sgn(num)
  end
end

function indexof(e, list)
  for i=1, #list do
    if e == list[i] then
      return i
    end
  end
end

function posneg()
  if rnd(1) > 0.5 then
    return 1
  else
    return -1
  end
end

---- diagnostics ----

c_perf_names = {"update", "draw"}
c_perf_history = {}
c_draw_perf_hist = {}
diag_counter = 0

function list_avg(lst)
  sum = 0
  for i = 1, #lst do
    sum += lst[i]
  end
  if #lst > 0 then
    avg = sum / #lst
  else
    avg = 0
  end
  return avg
end

function log_perf(name, before, after)
  add(c_perf_history[name], (after - before))
end

function reset_diag()
  for i = 1, #c_perf_names do
    c_perf_history[c_perf_names[i]] = {}
  end
end

function print_diag_line(diag_name)
  diag_list = c_perf_history[diag_name]
  avg = list_avg(diag_list)
  printh("  "..diag_name..": "..avg)
end

function print_diagnostics()
  n_points = #c_perf_history.update
  printh("perf (average over "..n_points.." frames):")
  foreach(c_perf_names, print_diag_line)
end

---- constants ----

skeltal_sprs = {064, 065}
skeltal_ranged_sprs = {068, 069}
skeltal_spawn_sprs = {072, 073}
human_sprs = {080, 081}
human_ranged_sprs = {084, 085}
human_spawn_sprs = {088, 089}
c_startscreen_timer = "startscreen_timer"
c_startscreen_timer_countdown_start = 3
c_original_max_mana = 40
projectile_sprs = {
  fireball = {128, 129},
  lightning_ball = {132, 133, 134},
  bone = {070, 071},
  star = {086, 087}
}

bait_spr = {
  meat = {96}, -- temporary
  cat = {66, 67}
}

powerup_spr = {
  mana_regen = 82,
  mana = 83,
  meat = 99,
  cat = 98,
  health = 114,
  fire = 115,
  lightning = 97
}

chest_closed_spr = 112
chest_open_spr = 113

chest_types = {"bait", "mana", "mana_regen", "health", "super_magic"}

skull_spr = {205}
skull_fx_sprs = {202, 203, 204}
death_fire = {052, 053, 054}
death_counter = 1
death_fire_flip = false
death_scene_counter = 0

c_song_game = 000
c_song_start = 020
c_song_over = 030

sfx_shoot = {
  fireball = 21,
  lightning_ball = 24
}
sfx_expl = 22
sfx_ouch = 23
sfx_mana_punishment = 25

--[[ pl1_run_down = {013, 014}
pl1_run_side = {045, 046}
pl1_run_up = {029, 030}
pl1_idle = {011, 012}
pl1_idle_up = {027, 028}
pl1_idle_side = {043, 044} ]]

pl_acc = 0.3
pl_max_vel = 1

projectile_max_vel = 3

c_bait_lifetime = 150

anim_count = 0
c_max_health = 100

c_loser_no = -1

---- environment ----
fence_sprs = {192, 193, 194, 195, 211}
house_sprs = {208, 209, 210}
house1_sprs = {224, 225, 226}
moon_spr = {196}
scary_tree_spr = {198, 200}
tombstone_spr = {240, 241}
house_animation_index = 1
house1_animation_index = 1
house_countdown = 1

c_map_limits = {0, 0, 128, 128}

---- init ----
local timers = {}
local startscreen_game_time = nil

function _init()
  reset_diag()
  init_startscreen()
end

function new_player1()
  return {
    type = 'player',
    x = 20,
    y = 32,
    spr = 011,
    spr_ix = 1,
    no = 0,
    friction = 0.2,
    acc = {
      x = 0,
      y = 0
    },
    vel = {
      x = 0,
      y = 0
    },
    dir = {
      x = 1,
      y = 0
    },
    dead = false,
    projectile_type = "fireball",
    bait_type = "meat",
    active_baits = 0,
    shoot_counter = 10,
    max_mana = c_original_max_mana,
    mana = c_original_max_mana,
    mana_punishment_counter = 0,
    mana_regen = 0.5,
    health = c_max_health,
    invincibility_counter = 60,
    powerup_type = 0,
    flip_pl = false,
    pl1_run_down = {013, 014},
    pl1_run_side = {045, 046},
    pl1_run_up = {029, 030},
    pl1_idle = {011, 012},
    pl1_idle_up = {027, 028},
    pl1_idle_side = {043, 044}
  }
end

function new_player2()
  return {
    type = 'player',
    x = 100,
    y = 32,
    spr = 011,
    spr_ix = 1,
    no = 1,
    friction = 0.1,
    acc = {
      x = 0,
      y = 0
    },
    vel = {
      x = 0,
      y = 0
    },
    dir = {
      x = 1,
      y = 0
    },
    dead = false,
    projectile_type = "lightning_ball",
    bait_type = "cat",
    active_baits = 0,
    shoot_counter = 10,
    max_mana = c_original_max_mana,
    mana = c_original_max_mana,
    mana_punishment_counter = 0,
    mana_regen = 0.5,
    health = c_max_health,
    invincibility_counter = 60,
    powerup_type = 0,
    flip_pl = false,
    pl1_run_down = {006, 007},
    pl1_run_side = {038, 039},
    pl1_run_up = {022, 023},
    pl1_idle = {004, 005},
    pl1_idle_up = {020, 021},
    pl1_idle_side = {036, 037}
  }
end

function add_human()
  add(humans, {
    x = rnd(104)+8,
    y = rnd(72)+32,
    vel = {
      x = 0,
      y = 0
    },
    type = 'human',
    attack_type = 'melee',
    sprs = human_sprs,
    spr = human_sprs[1],
    spawn_sprs = human_spawn_sprs,
    spawn_time = time(),
    spawned = false,
    spawn_frame_count = 1,
    last_projectile = time()
  })
end

function add_human_ranged()
  add(humans, {
    x = rnd(104)+8,
    y = rnd(72)+32,
    vel = {
      x = 0,
      y = 0
    },
    type = 'human',
    attack_type = 'ranged',
    sprs = human_ranged_sprs,
    spr = human_ranged_sprs[1],
    spawn_sprs = human_spawn_sprs,
    spawn_time = time(),
    spawned = false,
    spawn_frame_count = 1,
    last_projectile = time()
  })
end

function add_skeltal()
  add(skeltals, {
    x = rnd(104)+8,
    y = rnd(72)+32,
    vel = {
      x = 0,
      y = 0
    },
    type = 'skeltal',
    attack_type = 'melee',
    sprs = skeltal_sprs,
    spr = skeltal_sprs[1],
    spawn_sprs = skeltal_spawn_sprs,
    spawn_time = time(),
    spawned = false,
    spawn_frame_count = 1,
    last_projectile = time()
  })
end

function add_skeltal_ranged()
  add(skeltals, {
    x = rnd(104)+8,
    y = rnd(72)+32,
    vel = {
      x = 0,
      y = 0
    },
    type = 'skeltal',
    attack_type = 'ranged',
    sprs = skeltal_ranged_sprs,
    spr = skeltal_ranged_sprs[1],
    spawn_sprs = skeltal_spawn_sprs,
    spawn_time = time(),
    spawned = false,
    spawn_frame_count = 1,
    last_projectile = time()
  })
end

function init_startscreen()
  mode = 0 ---- startscreen = 0 | gamescreen = 1 | gameover = 2 ----
  startscreen_game_timer_exists = false
  startscreen_game_time = time()
  skull_fx_index = 1
  music(c_song_start)
end

function init_gamescreen()
  pl1 = new_player1()
  pl2 = new_player2()
  c_loser_no = -1
  skeltals = {}
  humans = {}
  projectiles = {}
  creature_projectiles = {}
  expl_particles = {}
  baits = {}
  chests = {}

  add_skeltal()
  add_human()

  music(c_song_game)
end

function new_projectile(x, y, vel, _type)
  return {
    x = x,
    y = y,
    vel = vel,
    type = "projectile",
    projectile_type = _type,
    spr = projectile_sprs[_type][1],
    spr_ix = 1,
    size = 8,
    size_dx = 1,
    flip_x = false,
    flip_y = false
  }
end

function new_creature_projectile(x, y, dir, speed, _type)
  return {
    x = x,
    y = y,
    dir = dir,
    type = "projectile",
    projectile_type = _type,
    spr = projectile_sprs[_type][1],
    spr_ix = 1,
    speed = speed,
  }
end

function new_bait(x, y, bait_type, lifetime)
  return {
    x = x,
    y = y,
    type = "bait",
    bait_type = bait_type,
    lifetime = lifetime,
    spr = bait_spr[bait_type][1],
    sprs = bait_spr[bait_type],
    spr_ix = 1
  }
end

---- update ----

function _update()
--  do_pre_diagnostics()
  if mode == 0 then
    update_startscreen()
  elseif mode == 1 then
    update_gamescreen()
  elseif mode == 2 then
    update_gameover()
  end
--  do_post_diagnostics()
end

function do_pre_diagnostics()
  diag_counter += 1
  if diag_counter == 30 then
    diag_counter = 0
    print_diagnostics()
    reset_diag()
  end
end

function do_post_diagnostics()
  local time_after = stat(1)
  log_perf("update", 0, time_after)
end

function update_startscreen()
  update_timers()
  if (btnp(4) or btnp(5)) and not startscreen_game_timer_exists then
    startscreen_game_timer_exists = true
    startscreen_game_time = time()
    create_startscreen_countdown()
  end
end

function update_gamescreen()
  count()
  update_player(pl1)
  update_player(pl2)
  foreach(chests, update_chest)
  foreach(baits, update_bait)
  foreach(skeltals, update_enemy)
  foreach(humans, update_enemy)
  foreach(projectiles, update_projectile)
  foreach(creature_projectiles, update_creature_projectile)
  generate_chests()
end

function update_gameover()
  if btnp(4) or btnp(5) then
    _init()
  end
end

function create_startscreen_countdown()
  local last_int = 0
  add_timer(
    c_startscreen_timer,
    c_startscreen_timer_countdown_start,
    nil,
    function ()
      mode = 1
      startscreen_game_init = false
      init_gamescreen()
    end
  )
end

function count()
  anim_count += 1
  if anim_count == 30 then
    anim_count = 0
  end
end

function update_player(pl)
  update_player_acc(pl)
  update_player_pos(pl)
  handle_magic(pl)
  handle_bait(pl)
  update_invincibility(pl)
  player_collisions(pl)
end

function update_player_acc(pl)
  if pl.dead == false then
    if btn(0, pl.no) then
      pl.acc.x = -pl_acc
    elseif btn(1, pl.no) then
      pl.acc.x = pl_acc
    else
      pl.acc.x = 0
    end
    pl.x = pl.x + pl.vel.x
    if pl.x <= 4 then
      pl.x = 4
    end
    if pl.x >= 116 then
      pl.x = 116
    end

    if btn(2, pl.no) then
      pl.acc.y = -pl_acc
    elseif btn(3, pl.no) then
      pl.acc.y = pl_acc
    else
      pl.acc.y = 0
    end
    pl.y = pl.y + pl.vel.y
    if pl.y <= 28 then
      pl.y = 28
    end
    if pl.y >= 109 then
      pl.y = 109
    end
  else
    pl.vel.x = 0
    pl.vel.y = 0
    pl.acc.x = 0
    pl.acc.y = 0
  end
end

function handle_magic(pl)
  pl.shoot_counter = max(0, pl.shoot_counter - 1)
  if pl.mana_punishment_counter > 0 then
    pl.mana_punishment_counter -= 1
  else
    pl.mana = min(pl.max_mana, pl.mana + pl.mana_regen)
    if btn(5, pl.no) and pl.shoot_counter == 0 and pl.mana > 10 then
      shoot_straight_fireball(pl)
      pl.mana -= 20
      pl.shoot_counter = 10

      if pl.mana < 0 then
        pl.mana = 0
        pl.mana_punishment_counter = 60
        sfx(sfx_mana_punishment)
      end
    end
  end
end

function handle_bait(pl)
  if btn(4, pl.no) then
    if pl.powerup_type == "bait" then
      leave_bait(pl)
      pl.active_baits += 1
      pl.powerup_type = 0
    elseif pl.powerup_type == "super_magic" then
      throw_super_magic(pl)
      pl.powerup_type = 0
    end
  end
end

function throw_super_magic(pl)
  local vels = {-3, 0, 3}
  throw_super_magic_with_vels(pl, vels)
  vels = {-1, 0, 1}
  throw_super_magic_with_vels(pl, vels)
end

function throw_super_magic_with_vels(pl, vels)
  for x_vel in all(vels) do
    for y_vel in all(vels) do
      if not (y_vel == 0 and x_vel == 0) then
        local vel = {
          x = x_vel,
          y = y_vel
        }
        shoot_fireball(pl.x, pl.y, vel, pl.projectile_type)
      end
    end
  end
end

function update_invincibility(pl)
  pl.invincibility_counter = max(0, pl.invincibility_counter - 1)
end

function update_player_pos(pl)
  friction_x = sign(pl.vel.x) * pl.friction
  friction_y = sign(pl.vel.y) * pl.friction
  if sign(pl.vel.x) != sign(pl.vel.x - friction_x) then
    pl.vel.x = 0
  else
    pl.vel.x -= friction_x
  end
  if sign(pl.vel.y) != sign(pl.vel.y - friction_y) then
    pl.vel.y = 0
  else
    pl.vel.y -= friction_y
  end
  pl.vel.x += pl.acc.x
  pl.vel.y += pl.acc.y

  clamp_velocity(pl.vel, pl_max_vel)

  pl.x = pl.x + pl.vel.x
  pl.y = pl.y + pl.vel.y

  if pl.vel.x != 0 or pl.vel.y != 0 then
    pl.dir.x = sign(pl.vel.x)
    pl.dir.y = sign(pl.vel.y)
  end
end

function clamp_velocity(vel, max_val)
  if vel.x * vel.x + vel.y * vel.y > max_val * max_val then
    a = atan2(vel.x, vel.y)
    vel.x = cos(a) * max_val
    vel.y = sin(a) * max_val
  end
end

function player_collisions(pl)
  player_chest_collisions(pl)
  player_enemy_collisions(pl)
end

function player_chest_collisions(pl)
  for chest in all(chests) do
    if chest.remove_counter == -1 and intersect(player_rect(pl), chest_rect(chest)) then
      pickup_chest(pl, chest)
    end
  end
end

function pickup_chest(pl, chest)
  if chest.type == "mana" then
    pl.max_mana += 30
    pl.mana_punishment_counter = 0
    pl.mana = pl.max_mana
  elseif chest.type == "mana_regen" then
    pl.mana_regen += 0.5
    pl.mana_punishment_counter = 0
  elseif chest.type == "health" then
    pl.health = min(pl.health + 50, c_max_health)
  else
    pl.powerup_type = chest.type
  end

  chest.spr = chest_open_spr
  chest.remove_counter = 40
  chest.player = pl.no
end

function player_enemy_collisions(pl)
  if pl.invincibility_counter == 0 then
    if pl.projectile_type == 'fireball' then
      for skeltal in all(skeltals) do
        player_skeltal_collision(pl, skeltal)
      end
    else
      for human in all(humans) do
        player_skeltal_collision(pl, human)
      end
    end
  end
end

function player_skeltal_collision(pl, skeltal)
  local pl_rect = player_rect(pl)
  local skeltal_rect = enemy_rect(skeltal)
  if(skeltal.spawned) then
    if intersect(pl_rect, skeltal_rect) then
      take_damage(pl)
    end
  end
end

function take_damage(pl)
  sfx(sfx_ouch, 1)
  pl.health = max(pl.health - 20, 0)
  if pl.health <= 0 then
    pl.dead = true
    if c_loser_no == -1 then
      c_loser_no = pl.no
    end
  end
  pl.invincibility_counter = 30
end

function check_dead(pl)
  if pl.dead == true then
    death_scene(pl)
  end
  if death_scene_counter > 2 then
    mode = 2
    death_scene_counter = 0
    music(c_song_over)
  end
end

function death_scene(e)
  local cols = {8, 9, 10}
  spr(death_fire[death_counter], e.x, e.y, 1, 1, death_fire_flip)
  add(expl_particles, create_expl_particle(e.x + 4, e.y + 4, 0, -1, cols[flr(rnd(3))+1]))
  --[[ death_counter += 1 ]]
  if anim_count % 5 == 0 then
    death_fire_flip = not death_fire_flip
  end
  if anim_count == 29 then
    death_counter += 1
    death_scene_counter += 1
  end
  if death_counter > #death_fire then
    death_counter = 1
  end
end

function wait(a) for i = 1,a do flip() end end

function shoot_fireball(x, y, vel, projectile_type)
  clamp_velocity(vel, projectile_max_vel)
  add(projectiles, new_projectile(x, y, vel, projectile_type))
  sfx(sfx_shoot[projectile_type], 2)
end

function shoot_straight_fireball(pl)
  vel = {
    x = 3 * pl.dir.x,
    y = 3 * pl.dir.y,
  }
  shoot_fireball(pl.x, pl.y, vel, pl.projectile_type)
end

function leave_bait(pl)
  add(baits, new_bait(pl.x, pl.y, pl.bait_type, c_bait_lifetime))
end

function follow(target, e)
  local world_size = 128
  local norm_x=(target.x-e.x)/world_size
  local norm_y=(target.y-e.y)/world_size
  e.dir=atan2(norm_x,norm_y)
  move(e)
end

function move(e)
  local max_speed = 0.4
  local speed = rnd(max_speed)
  local dx=cos(e.dir)*speed
  local dy=sin(e.dir)*speed
  e.vel.x = dx
  e.vel.y = dy
  e.x += dx
  e.y += dy
end

function kill_skeltal(s, wpn)
  sfx(sfx_expl, 2)
  del(skeltals, s)
  del(projectiles, wpn)
  for x = 1,2 do
    spawn_action = ceil(rnd(10))
    if spawn_action > 9 then
      add_human_ranged()
    else
      add_human()
    end
  end
  create_expl_particles(s, wpn)
end

function kill_human(h, wpn)
  sfx(sfx_expl, 2)
  del(humans, h)
  del(projectiles, wpn)
  for x = 1,2 do
    spawn_action = ceil(rnd(10))
    if spawn_action > 9 then
      add_skeltal_ranged()
    else
      add_skeltal()
    end
  end
  create_expl_particles(h, wpn)
end

function create_expl_particles(target, wpn)
  local cols
  if target.type == 'skeltal' then
    cols = {7,8,10}
  elseif target.type == 'human' then
    cols = {7,9,12}
  end

  if wpn.projectile_type == 'bone' then
    cols = {7}
  elseif wpn.projectile_type == 'star' then
    cols = {5}
  end

  local x = target.x+3
  local y = target.y+3
  local dxoffs
  local dyoffs
  local wpn_vel_x
  local wpn_vel_y
  if wpn.projectile_type == 'bone' or wpn.projectile_type == 'star' then
    wpn_vel_x = cos(wpn.dir)*wpn.speed
    wpn_vel_y = sin(wpn.dir)*wpn.speed
  else
    wpn_vel_x = wpn.vel.x
    wpn_vel_y = wpn.vel.y
  end

  local dxoffs = target.vel.x + 0.5*wpn_vel_x
  local dyoffs = target.vel.y + 0.5*wpn_vel_y

  for i = 1, 5 do
    add(expl_particles, create_expl_particle(x, y, dxoffs, dyoffs, cols[flr(rnd(3))+1]))
  end
end

function create_expl_particle(x, y, dxoffs, dyoffs, col)
  return {
    x = x,
    y = y,
    col = col,
    dx = rnd(2)-1+dxoffs,
    dy = -rnd(1)+dyoffs,
    ddy = 0.1,
    count = 30
 }
end

function update_expl_particle(particle)
  particle.x += particle.dx
  particle.y += particle.dy
  particle.dy += particle.ddy
  particle.count -= 1
  if particle.count < 1 then
    del(expl_particles, particle)
  end
end

function wpn_hit(wpn, target)
  return intersect(
    enemy_rect(target), {
      wpn.x+1,
      wpn.y+2,
      wpn.x+6,
      wpn.y+6
    }
  )
end

function wpn_collision(wpn)
  if wpn.projectile_type == 'fireball' then
    fireball_collision(wpn)
  elseif wpn.projectile_type == 'lightning_ball' then
    lightning_collision(wpn)
  elseif wpn.projectile_type == 'bone' then
    ai_wpn_collision(wpn, pl1)
  elseif wpn.projectile_type == 'star' then
    ai_wpn_collision(wpn, pl2)
  else
    printh('weapon type not handled')
  end
end

function ai_wpn_collision(wpn, pl)
  if pl.invincibility_counter == 0 then
    if wpn_hit(wpn, pl) then
      take_damage(pl)
      create_expl_particles(pl, wpn)
    end
  end
end

function fireball_collision(fireball)
  for i = 1, #skeltals do
    skeltal = skeltals[i]
    if wpn_hit(fireball, skeltal) then
      kill_skeltal(skeltal, fireball)
      return
    end
  end
end

function lightning_collision(lightning)
  for i = 1, #humans do
    human = humans[i]
    if wpn_hit(lightning, human) then
      kill_human(human, lightning)
      return
    end
  end
end

function enemy_rect(s)
  return {
    s.x+1, s.y+1,
    s.x+6, s.y+9
  }
end

function player_rect(pl)
  return {
    pl.x+0, pl.y+1,
    pl.x+7, pl.y+7
  }
end

function chest_rect(c)
  return {
    c.x+0, c.y+2,
    c.x+7, c.y+7
  }
end

function intersect(rect1,rect2)
  return
    intersect_intervals(rect1[1], rect1[3], rect2[1], rect2[3])
    and
    intersect_intervals(rect1[2], rect1[4], rect2[2], rect2[4])
end

function intersect_intervals(a_lo, a_hi, b_lo, b_hi)
  return a_lo < b_hi and a_hi > b_lo
end

function update_chest(c)
  if c.remove_counter > 0 then
    c.remove_counter -= 1
  elseif c.remove_counter == 0 then
    del(chests, c)
  end
end

function update_enemy(e)
  if e.spawned then
    local action = flr(rnd(10))
    if e.attack_type == 'melee' then
      if action <= 8 then
        target = select_target(e)
        follow(target, e)
      elseif action == 9 then
        e.x = e.x + rnd(2) - 1
        e.y = e.y + rnd(2) - 1
      else
        -- do nothing
      end
    elseif e.attack_type == 'ranged' then
      if action <= 1 and e.last_projectile + 2 < time() then
        e.last_projectile = time()
        if e.type == 'skeltal' then
          add_creature_projectile(e, 'bone')
        else
          add_creature_projectile(e, 'star')
        end
      elseif action <= 5 then
        target = select_target(e)
        follow(target, e)
      elseif action == 9 then
        e.x = e.x + rnd(2) - 1
        e.y = e.y + rnd(2) - 1
      else
        -- do nothing
      end
    end
  else
    spawn_creature(e)
  end
end

function update_creature_projectile(e)
  local dx=cos(e.dir)*e.speed
  local dy=sin(e.dir)*e.speed
  e.x += dx
  e.y += dy 
  wpn_collision(e)
end

function spawn_creature(c) 
  if flr(c.spawn_time)+1 <= time() then
    c.spawned = true
  end
  if c.spawn_frame_count % 5 == 0 then
    add(expl_particles, create_expl_particle(c.x, c.y, 0, 0, flr(rnd(3))+1))
  end
end

function add_creature_projectile(c, type)
  local target
  if type == 'bone' then
    target = pl1
  else 
    target = pl2
  end
  local world_size = 128
  local norm_x=(target.x-c.x)/world_size
  local norm_y=(target.y-c.y)/world_size
  local dir = atan2(norm_x,norm_y)
  add(creature_projectiles, new_creature_projectile(c.x, c.y, dir, 2, type))
end

function select_target(s)
  local targets = get_targets(s)
  local best_dist = 32767
  local best_target = targets[1]
  for target in all(targets) do
    local dx = s.x - target.x
    local dy = s.y - target.y
    local dist = dx * dx + dy * dy
    if dist < best_dist then
      best_dist = dist
      best_target = target
    end
  end
  return best_target
end

function get_targets(s)
  local target_pl
  if s.type == "skeltal" then
    target_pl = pl1
  else
    target_pl = pl2
  end
  local targets = {target_pl}
  for bait in all(baits) do
    if bait.bait_type == target_pl.bait_type then
      add(targets, bait)
    end
  end
  return targets
end

function update_projectile(f)
  f.x += f.vel.x
  f.y += f.vel.y
  proj_box = { f.x, f.y, f.x + 8, f.y + 8 }
  if not intersect(proj_box, c_map_limits) then
    del(projectiles, f)
    return
  end
  wpn_collision(f)
end

function update_bait(b)
  b.lifetime -= 1
  if b.lifetime < 0 then
    del(baits, b)
    if b.bait_type == "meat" then
      pl1.active_baits -= 1
    elseif b.bait_type == "cat" then
      pl2.active_baits -= 1
    end
  end
end

function add_timer (name,
    length, step_fn, end_fn,
    start_paused)
  local timer = {
    length=length,
    elapsed=0,
    active=not start_paused,
    step_fn=step_fn,
    end_fn=end_fn
  }
  timers[name] = timer
  return timer
end

function update_timers()
  local t = time()
  local dt = t - startscreen_game_time
  startscreen_game_time = t
  for name,timer in pairs(timers) do
    if timer.active then
      timer.elapsed += dt
      local elapsed = timer.elapsed
      local length = timer.length
      if elapsed < length then
        if timer.step_fn then
          timer.step_fn(dt,elapsed,length,timer)
        end
      else
        if timer.end_fn then
          timer.end_fn(dt,elapsed,length,timer)
        end
        timer.active = false
      end
    end
  end
end

function restart_timer(name, start_paused)
  local timer = timers[name]
  if (not timer) return
  timer.elapsed = 0
  timer.active = not start_paused
end

function generate_chests()
  if #chests < 3 and rnd(200) < 1 then
    new_chest()
  end
end

function new_chest()
  add(chests, {
    x = rnd(104)+8,
    y = rnd(72)+32,
    remove_counter = -1,
    type = chest_types[flr(rnd(#chest_types))+1],
    spr = chest_closed_spr,
    player = -1 -- used to know what powerup should be drawn
  })
end

---- draw ----

function _draw()
  ---- diagnostics ----
  --time_before = stat(1)
  ---- startscreen ----
  if mode == 0 then
    draw_startscreen()
  elseif mode == 1 then
    draw_gamescreen()
  elseif mode == 2 then
    draw_gameoverscreen()
  end
  ---- diagnostics ----
  --time_after = stat(1)
  --log_perf("draw", time_before, time_after)
end

function draw_startscreen()
  cls()
  spr(skull_fx_sprs[ceil(skull_fx_index/5)], 46, 15, 1, 1)
  spr(skull_fx_sprs[ceil(skull_fx_index/5)], 51, 13, 1, 1)
  spr(skull_fx_sprs[ceil(skull_fx_index/5)], 66, 13, 1, 1, true, false)
  spr(skull_fx_sprs[ceil(skull_fx_index/5)], 71, 15, 1, 1, true, false)
  spr(skull_spr[1], 36, 20, 4, 4)
  spr(skull_spr[1], 65, 20, 4, 4, true, false)
  skull_fx_index += 1
  if skull_fx_index > 15 then
    skull_fx_index = 1
  end

  -- draw logo
  sspr(24, 112, 39, 16, 43, 49)
  print("of", 60, 69, 2)
  print("of", 60, 66, 8)
  print("of", 59, 67, 8)
  print("of", 61, 67, 8)
  print("of", 60, 68, 8)
  print("of", 60, 67, 6)
  sspr(56, 80, 61, 12, 32, 74)

  if startscreen_game_timer_exists then
    print("game starting in "..tostr(ceil(c_startscreen_timer_countdown_start - timers[c_startscreen_timer].elapsed)), 28, 102, 6)
  else
    print("press button to start", 21, 102, 6)
  end
end

function draw_gamescreen()
  cls()
  draw_environment()
  foreach(baits, update_bait_spr)
  foreach(baits, draw_entity)
  foreach(chests, draw_entity)
  draw_enemies()
  draw_players()
  foreach(creature_projectiles, draw_entity)
  foreach(creature_projectiles, update_projectile_spr)
  draw_bottom_fences()
  foreach(projectiles, draw_entity)
  foreach(projectiles, update_projectile_spr)
  foreach(expl_particles, update_expl_particle)
  foreach(expl_particles, draw_expl_particle)
  foreach(chests, draw_chest_powerup)
  draw_manabars()
  draw_healthbars()
  draw_powerup(pl1)
  draw_powerup(pl2)
end

function draw_powerup(pl)
  local sprite
  if pl.powerup_type == "bait" then
    if pl.no == 0 then
      sprite = powerup_spr["meat"]
    else
      sprite = powerup_spr["cat"]
    end
  elseif pl.powerup_type == "super_magic" then
    if pl.no == 0 then
      sprite = powerup_spr["fire"]
    else
      sprite = powerup_spr["lightning"]
    end
  end

  local draw_y = 120
  local draw_x
  if pl.no == 0 then
    draw_x = 0
  else
    draw_x = 120
  end

  if pl.powerup_type != 0 then
    spr(sprite, draw_x, draw_y)
  end
end

function draw_gameoverscreen()
  cls()
  if c_loser_no == pl2.no then
    spr(pl1.pl1_idle[1], 58, 40)
    print("player 1 wins", 38, 60, 7)
  else
    spr(pl2.pl1_idle[1], 58, 40)
    print("player 2 wins", 38, 60, 7)
  end
  print("press button to continue", 16, 80, 6)

  print("made by fabian, jakob, jens,", 10, 100, 5)
  print("joel & magnus", 37, 108, 5)
end

function draw_environment()
  draw_fences()
  draw_moon()
  draw_scary_trees()
  draw_houses()
  draw_tombstones()
end

function draw_players()
  if pl1.y >= pl2.y then
    draw_entity(pl2)
    draw_entity(pl1)
  else
    draw_entity(pl1)
    draw_entity(pl2)
  end
  check_dead(pl1)
  check_dead(pl2)
end

function update_spr(e)
  if anim_count % 2 == 0 then
    local nextspr = indexof(e.spr, e.sprs) + 1
    if nextspr > #e.sprs then
      nextspr = 1
    end
    e.spr = e.sprs[nextspr]
  end
end

function update_projectile_spr(e)
  if e.projectile_type == 'bone' or e.projectile_type == 'star' then
    e.spr = projectile_sprs[e.projectile_type][ceil(e.spr_ix/5)]
    e.spr_ix += 1
    if e.spr_ix > 9 then
      e.spr_ix = 1
    end
  else
    e.spr_ix += 1
    if e.spr_ix > #(projectile_sprs[e.projectile_type]) then
      e.spr_ix = 1
    end

    e.flip_x = e.vel.x < 0
    e.flip_y = e.vel.y < 0
    e.spr = projectile_sprs[e.projectile_type][e.spr_ix]
    if e.vel.x == 0 then
      e.spr += 16
    elseif e.vel.x != 0 and e.vel.y != 0 then
      e.spr += 32
    end
    e.size += e.size_dx
    if e.size >= 10 then
      e.size_dx = -1
    elseif e.size <= 7 then
      e.size_dx = 1
    end
  end
end

function update_bait_spr(e)
  e.spr_ix += 1
  if ceil(e.spr_ix/10) > #e.sprs then
    e.spr_ix = 1
  end
  e.spr = e.sprs[ceil(e.spr_ix/10)]
end

function draw_chest_powerup(c)
  if c.remove_counter != -1 and (c.remove_counter % 4) > 0 then
    local powerup_sprite
    if c.type == "bait" then
      if c.player == 0 then
        powerup_sprite = powerup_spr["meat"]
      else
        powerup_sprite = powerup_spr["cat"]
      end
    elseif c.type == "super_magic" then
      if c.player == 0 then
        powerup_sprite = powerup_spr["fire"]
      else
        powerup_sprite = powerup_spr["lightning"]
      end
    else
      powerup_sprite = powerup_spr[c.type]
    end
    spr(powerup_sprite, c.x, c.y - 10)
  end
end

function draw_entity(e)
  if e.type == "projectile" then
    draw_projectile(e)
  elseif e.type == 'skeltal' or e.type == 'human' then
    draw_enemy(e)
  elseif e.type == 'player' then
    draw_player(e)
  else
    spr(e.spr, e.x, e.y)
  end
end

function draw_player(e)
  if (e.invincibility_counter % 3) == 1 and not e.dead then
    return
  end

  if e.vel.x == 0 and e.vel.y == 0 then
    if e.dir.x > 0 and e.dir.y == 0 and anim_count % 6 == 0 then
      e.flip_pl = false
      animate_player(e, e.pl1_idle_side)
    elseif e.dir.x < 0 and e.dir.y == 0 and anim_count % 6 == 0 then
      e.flip_pl = true
      animate_player(e, e.pl1_idle_side)
    elseif e.dir.x == 0 and e.dir.y > 0 and anim_count % 6 == 0 then
      e.flip_pl = false
      animate_player(e, e.pl1_idle)
    elseif e.dir.x == 0 and e.dir.y < 0 and anim_count % 6 == 0 then
      e.flip_pl = false
      animate_player(e, e.pl1_idle_up)
    end
  elseif e.vel.x > 0 then
    e.flip_pl = false
    if anim_count % 2 == 0 then
      animate_player(e, e.pl1_run_side)
    end
  elseif e.vel.x < 0 then
    e.flip_pl = true
    if anim_count % 2 == 0 then
      animate_player(e, e.pl1_run_side)
    end
  elseif e.vel.y > 0 then
    e.flip_pl = false
    if anim_count % 2 == 0 then
      animate_player(e, e.pl1_run_down)
    end
  elseif e.vel.y < 0 then
    e.flip_pl = false
    if anim_count % 2 == 0 then
      animate_player(e, e.pl1_run_up)
    end
  else
    e.spr = 001
  end
  spr(e.spr, e.x, e.y, 1, 1, e.flip_pl)
end

function animate_player(e, anims)
  e.spr_ix += 1
  if e.spr_ix > #anims then
     e.spr_ix = 1
  end
  e.spr = anims[e.spr_ix]
end

function draw_enemy(e)
  if e.spawned then
    flip_x = e.vel.x < 0
    spr(e.spr, e.x, e.y, 1, 1, flip_x)
  else
    draw_spawn_creature(e)
  end
end

function draw_spawn_creature(e)
  if e.spawn_frame_count < 15 then 
    spr(e.spawn_sprs[1], e.x+posneg(), e.y+posneg(), 1, 1)
  else
    spr(e.spawn_sprs[2], e.x+posneg(), e.y+posneg(), 1, 1)
  end
  e.spawn_frame_count += 1
end

function draw_projectile(e)
  if e.projectile_type == 'bone' or e.projectile_type == 'star' then
    spr(e.spr, e.x, e.y)
  else
    spr_x = flr(e.spr % 16) * 8
    spr_y = flr(e.spr / 16) * 8
    pos_x = e.x - ((e.size - 8) / 2)
    pos_y = e.y - ((e.size - 8) / 2)
    sspr(spr_x, spr_y, 8, 8, pos_x, pos_y, e.size, e.size, e.flip_x, e.flip_y)
    for i = 0, 5 do
      add_particle(e)
    end
  end
end

function draw_expl_particle(particle)
  circ(particle.x, particle.y, 0, particle.col)
end

function add_particle(e)
  -- e is a projectile
  alpha_0 = atan2(-e.vel.x, -e.vel.y)
  alpha = alpha_0 + rnd(0.15) - 0.075

  proj_front_x = 4 + 4 * sign(e.vel.x)
  proj_front_y = 4 + 4 * sign(e.vel.y)

  x_offs = cos(alpha)
  y_offs = sin(alpha)
  r = rnd(8) + 4
  x = e.x + proj_front_x + r * x_offs
  y = e.y + proj_front_y + r * y_offs
  pset(x, y, 7)
end

function draw_enemies()
  draw_skeltals()
  draw_humans()
end

function draw_skeltals()
  foreach(skeltals, draw_entity)
  foreach(skeltals, update_spr)
end

function draw_humans()
  foreach(humans, draw_entity)
  foreach(humans, update_spr)
end

function draw_manabars()
  draw_manabar(pl1, 8)
  draw_manabar(pl2, 80)
end

function draw_manabar(pl, x)
  local col = manabar_color(pl)
  local x_end = x + (pl.mana/pl.max_mana)*40
  if (pl.mana_punishment_counter % 4) == 0 then
    rectfill(x, 122, x_end, 122, col)
  end
end

function manabar_color(pl)
  if pl.mana_punishment_counter > 0 then
    return 14
  elseif pl.mana > ((2*pl.max_mana)/3) then
    return 12
  elseif pl.mana > (pl.max_mana/3) then
    return 13
  else
    return 1
  end
end

function draw_healthbars()
  print("p1", 52, 122, 12)
  draw_healthbar(pl1, 8)
  print("p2", 70, 122, 8)
  draw_healthbar(pl2, 80)
end

function draw_healthbar(pl, x)
  local col = healthbar_color(pl.health)
  local x_end = x + (pl.health/c_max_health)*40
  rectfill(x, 123, x_end, 126, col)
end

function healthbar_color(health)
  if health > ((2*c_max_health)/3) then
   return 11
  elseif health > (c_max_health/3) then
   return 10
  else
   return 8
  end
end

function draw_fences()
---- top corners ----
  spr(fence_sprs[4], 0, 24, 1, 1, true)
  spr(fence_sprs[4], 120, 24, 1, 1, false)

---- top row ----
  for i = 1,14 do
    spr(fence_sprs[1], 8 * i, 24)
  end
---- left row ----
  for i = 1,10 do
    spr(fence_sprs[2], 0, 8 * i + 24)
  end
---- right row ----
  for i = 1,10 do
    spr(fence_sprs[3], 120, 8 * i + 24)
  end
end

function draw_bottom_fences()
---- bottom corners ----
  spr(fence_sprs[5], 0, 112, 1, 1, true)
  spr(fence_sprs[5], 120, 112, 1, 1, false)

---- bottom row ----
  for i = 1,14 do
    spr(fence_sprs[1], 8 * i, 112, 1, 1, false)
  end
end

function draw_houses()
  spr(house_sprs[ceil(house_animation_index/10)], 72, 16)
  if house_countdown > 100 and house_countdown < 100 + 30 then
    house_animation_index += 1
    if house_animation_index > 29 then
      house_animation_index = 1
    end
  else
    house_animation_index = 20
  end
  spr(house1_sprs[ceil(house1_animation_index/10)], 96, 16)
  if house_countdown > 200 and house_countdown < 200 + 30 then
    house1_animation_index += 1
    if house1_animation_index > 29 then
      house1_animation_index = 1
    end
  else
    house1_animation_index = 1
  end
  house_countdown += 1
  if house_countdown > 300 then
    house_countdown = 1
  end
end

function draw_moon()
  spr(moon_spr[1], 112, 0, 2, 2)
end

function draw_scary_trees()
  spr(scary_tree_spr[1], 102, 8, 2, 2)
  spr(scary_tree_spr[2], 66, 6, 2, 2)
end

function draw_tombstones()
  spr(tombstone_spr[1], 8, 16)
  spr(tombstone_spr[2], 16, 16)
  spr(tombstone_spr[1], 24, 16)
  spr(tombstone_spr[1], 32, 16)
  spr(tombstone_spr[2], 40, 16)
end

__gfx__
0000000000000000055555000555550005555500000000000555550005555500000000000ccccc000ccccc000ccccc00000000000ccccc000ccccc0000000000
000000000808000055555550555555505555555005555500555555505555555000000000ccccccc0ccccccc0ccccccc00ccccc00ccccccc0ccccccc000000000
007007000000000057686867576868675768686755555550576868675768686700000000c6f1f1f6c6f1f1f6c6f1f1f6ccccccc0c6f1f1f6c6f1f1f600000000
00077000000000800766666707666667076666675768686707666667076666670000000006efffe606efffe606efffe6c6f1f1f606efffe606efffe600000000
00077000880008800077777000777770007777700766666700777770007777700000000000666660006666600066666006efffe6006666600066666000000000
007007000888880065577756065777600057770000777770005777000057770000000000fcc666cf0fc666f000c666000066666000c6660000c6660000000000
00000000000000000055750000557500005575000057770004557500005575400000000000cc6c0000cc6c0000cc6c0000c6660004cc6c0000cc6c4000000000
00000000000000000040040000400400004004000040740000000400004000000000000000400400004004000040040000406400000004000040000000000000
00000000000000000055550000555500005555000000000000555500005555000000000000cccc0000cccc0000cccc000000000000cccc0000cccc0000000000
0000000000000000055555500555555005555550005555000555555005555550000000000cccccc00cccccc00cccccc000cccc000cccccc00cccccc000000000
00000000000000007755557777555577775555770555555077555577775555770000000066cccc6666cccc6666cccc660cccccc066cccc6666cccc6600000000
000000000000000077755777777557777775577777555577777557777775577700000000666cc666666cc666666cc66666cccc66666cc666666cc66600000000
000000000000000007777770077777700777777077755777077777700777777000000000066666600666666006666660666cc666066666600666666000000000
000000000000000065577556065775600057750007777770005775000057750000000000fcc66ccf0fc66cf000c66c000666666000c66c0000c66c0000000000
00000000000000000055550000555500005555000057750000555540045555000000000000cccc0000cccc0000cccc0000c66c0000cccc4004cccc0000000000
00000000000000000040040000400400004004000040040000400000000004000000000000400400004004000040040000400400004000000000040000000000
0000000000000000055555000555550005555500000000000555550005555500000000000ccccc000ccccc000ccccc00000000000ccccc000ccccc0000000000
000000000000000055555550555555505555555005555500555555505555555000000000ccccccc0ccccccc0ccccccc00ccccc00ccccccc0ccccccc000000000
000000000000000055776860557768605577686055555550557768605577686000000000cc66f1f0cc66f1f0cc66f1f0ccccccc0cc66f1f0cc66f1f000000000
0000000000000000077766660777666607776666557768600777666607776666000000000666efff0666efff0666efffcc66f1f00666efff0666efff00000000
0000000000000000007777700077777000777770077766660077777000777770000000000066666000666660006666600666efff006666600066666000000000
00000000000000000056577000555556005557700077777000555770005557700000000000cfc66000cccccf00ccc6600066666000ccc66000ccc66000000000
00000000000000000055557000555570005555700055577000555574045555700000000000cccc6000cccc6000cccc6000ccc66000cccc6404cccc6000000000
00000000000000000040040000400400004004000040047000400000000004000000000000400400004004000040040000400460004000000000040000000000
00000000000000000000000000000000000000000000000000900000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000090090000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000090000a09a0a90000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000900900aaaa9a0a000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000090900a09aaaa9aaa000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000900090aaa0aa0aaaaaaa9a000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000090a09a09aaaaa9aaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000aaaaaaaa0aaaa9a00aaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000002272000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00787800007777000505005000000050007828000022720000000000000707000400000004000044000000000000000000000000000000000000000000000000
00077700007878000555050505050505000676000078280000000000000676000040000000500450000000000000000000000000000000000000000000000000
00700000007777000a5a050005550500607505600076760067000076000070000047000000454700000000000000000000000000000000000000000000000000
0077770000777700055500500a5a0050076777000067770006777760000070000000440000044400000000000000000000000000000000000000000000000000
00070000000700000555500505555005000700000707070067666676000070000000040000470470000000000000000000000000000000000000000000000000
00777000007770000555555505555555007770006077706006000060000767000000000004400054000000000000000000000000000000000000000000000000
00707000007070000155551001555510006060000060600000000000000606000000000000000005000000000000000000000000000000000000000000000000
00444440000000000000000000000000005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f1f1000044444000060000000600000051f1000055550000000d000000d0000400000004000044000000000000000000000000000000000000000000000000
00ffff0000f1f100000b0000000c0000005555000051f1000dd0dd000000d0000040000000500450000000000000000000000000000000000000000000000000
00ff000000ffff00006bb000006cc000105500100055550005ddd5000dddd0000049000000453400000000000000000000000000000000000000000000000000
00ffff0000ffff00067bbb00067ccc000155550000555500005ddd00055dddd00000440000044400000000000000000000000000000000000000000000000000
00999000009990000bbbb3000ccccd00005550000155510000dd5dd0000d55500000040000940940000000000000000000000000000000000000000000000000
0099900000999000003b300000dcd00000ddd00010ddd01000d50550000d00000000000004400054000000000000000000000000000000000000000000000000
00303000003030000000000000000000005050000050500000500000000500000000000000000005000000000000000000000000000000000000000000000000
00000560000000000000000000000000001111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009997600c0c0000005050000007000001878000011110000000000000000000000000000000000000000000000000000000000000000000000000000000000
00999945000cc0000005550000094700007777000018780000000000000000000000000000000000000000000000000000000000000000000000000000000000
0999444100c7c000000a5a0000944000007606000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000
048244400c777c000005550000824000057777000576760000000000000000000000000000000000000000000000000000000000000000000000000000000000
56784410077777000000000007740000525552505255525000000000000000000000000000000000000000000000000000000000000000000000000000000000
77624100007770000000000000700000225552202255522000000000000000000000000000000000000000000000000000000000000000000000000000000000
57510000000000000000000000000000008080000080800000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011991100000000000000000008880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001122221100e0e00000808000088dfd000088800000000000000000000000000000000000000000000000000000000000000000000000000000000000
09444440122222210e7888000009900008ffff00088dfd0000000000000000000000000000000000000000000000000000000000000000000000000000000000
94444444122222210888880000aaa00000ff000008ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000
111aa111444224440088200009a7a90000ffff0000ffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000
444a94444444444400020000099799000034b0000034b00000000000000000000000000000000000000000000000000000000000000000000000000000000000
5444444554444445000000000099900000b3400000b3400000000000000000000000000000000000000000000000000000000000000000000000000000000000
15555551155555510000000000000000003030000030300000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000c0c000c0c0c000000cc00000000000000000000000000000000000000000000000000000000000000000000000000
00009990000099900000000000000000ccc0777000c0777000c07770000000000000000000000000000000000000000000000000000000000000000000000000
00aaa779800aa7790000000000000000000cc777c00cc777cc0cc777000000000000000000000000000000000000000000000000000000000000000000000000
890a777909aa777900000000000000000ccc7777cc0c777700cc7777000000000000000000000000000000000000000000000000000000000000000000000000
09aa7779890a7779000000000000000000cc777700cc77770ccc7777000000000000000000000000000000000000000000000000000000000000000000000000
800aa77900aaa7790000000000000000c00cc7770c0cc777000cc777000000000000000000000000000000000000000000000000000000000000000000000000
000099900000999000000000000000000cc07770000c7770cc0c7770000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000c000000000000ccc000000000000000000000000000000000000000000000000000000000000000000000000000
0080800000080800000000000000000000c000c00000cc000c000c00000000000000000000000000000000000000000000000000000000000000000000000000
000990000009900000000000000000000c00c0c000c0c00c0c0c0c00000000000000000000000000000000000000000000000000000000000000000000000000
000a0a0000a0a00000000000000000000c0cc0c0000c00c0c00cc0c0000000000000000000000000000000000000000000000000000000000000000000000000
00aaaa0000aaaa00000000000000000000cccc0c0ccccc0ccccccc00000000000000000000000000000000000000000000000000000000000000000000000000
09a77a9009a77a90000000000000000007c77c7007c77c70c7c77c7c000000000000000000000000000000000000000000000000000000000000000000000000
09777790097777900000000000000000c777777c0777777c0777777c000000000000000000000000000000000000000000000000000000000000000000000000
09777790097777900000000000000000077777700777777007777770000000000000000000000000000000000000000000000000000000000000000000000000
00999900009999000000000000000000007777000077770000777700000000000000000000000000000000000000000000000000000000000000000000000000
80000000008000000000000000000000c000c0000c000c000ccc0000088000008888000000000000000000000000000000000000088800000000000000000000
09090000090000000000000000000000cc0c00000c0c0c00c00c0c00878000008782000000000000000000000000000000000000878000000000000000000000
80a0a90000a0a900000000000000000000c0c70000c0c70000c0c700878000008780088800000000000000000000000000000000878000000000000000000000
000aa790090aa7900000000000000000c00cc770cc0cc770cc0cc770878000008780878200888888800088888808808888000000878000888888800000000000
00aa777900aa77790000000000000000c0cc77770ccc77770ccc7777877800087680882008777778200877778000887778800088878008777778200000000000
009777790097777900000000000000000c777777c0777777c0777777287808087820220002888878008768867800878886800877768000888878000000000000
00097790000977900000000000000000000777700007777000077770087788876800088000228782008780086800878228208768668000008782000000000000
00009900000099000000000000000000000077000000770000007700028787878200878000087800008780086800878002008780868000087800000000000000
00000000000000000000000000000000000000000000000000000000008776768000878000878888808768866800878000008768668000878888800000000000
00000000000000000000000000000000000000000000000000000000002878682000878008766668008866668680878000008766686808766668000000000000
00000000000000000000000000000000000000000000000000000000000882880000882008888882002888882820882000002888828208888882000000000000
00000000000000000000000000000000000000000000000000000000000220220000220002222220000222220200220000000222202002222220000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000940000000000490000000000000076666c0000000055000000055000000555500055550000000000000000000000000000000000000088888880000
00000000044000000000044000666000000c66766666600000005550000550000055555555555050000000000000008000000080000000008888888888888800
0909090900440000000044000d666d0000c6676c66766c0000000050055500000555555555500005000000000008000000000008000000086666666665888880
04040404004500000000540005dddd000666766cc6cc6cc005500055555005500505550555550000000000800000000800800000000000866666666666588888
444444440940000000000490455ddd000c66666666c666c000550005550055005505000555555000000000000000008000000000000008866668866666658888
0404040404400000000004400155d40066c676666766c6cc00055005555500000005005500555550000800088000000000000000000086686686666666665888
4444444400440000000044004115540066c6666c6666cccc55005555555500000055005000055055000000080000000000008000000886686866666666665888
05050505004500000000540001111400667c6676c6c66ccc05505555500055000050055000055005080000000000800080000008000868666666688866666588
00000000000000000000000000000400676c6c666666c6cc00555550555000500050000000055000000000000000000000000000000866660666866666666588
00000010000000100000001000666400666676666666c6cc00055500005500500000000000555000000000000000000000000000008666600068666666666588
0022221000222210002222100d666d00c676c6c6c666cccc00055500050050000000000055555000000000000000000000000000008666660666666666666588
02222220022222200222222005dddd0006666666c666ccc000055500050000000000000055550000000000000000000000000000008006660666006666666588
222222222222222222222222455ddd000c666c6c6c6cccc000055550000000000000005555500000000000000000000000000000008000666660000666666580
2222222222222222222222220155dd0000cc666cc6cccc0000055555500000000000555555500000000000000000000000000000080000666660000666665580
0d9dd4d00d0dd4d00d9dd4d041155500000ccc66ccccc00000055555555000000005555555500000000000000000000000000000080000666660000666665580
0dddd4d00dddd4d00dddd4d00111110000000cccccc0000000555555555500000055555555555500000000000000000000000000086006665666006666655800
00000000000000000000005008800888000000000000000000000000000000000000000000000000000000000000000000000000086666655566666666555800
00000000000000500000000087808782008880000000000000000000000000000000000000000000000000000000000000000000085666505056666655558000
00ddd02000ddd02000ddd02087887820087820000000000000000000888888800000000000000000000000000000000000000000085555505005555555580000
0ddddd200ddddd200ddddd2087878200088208088888000088888808777778200000000000000000000000000000000000000000087755050005555558800000
dddddddddddddddddddddddd87782000022008877778800877788202888878000000000000000000000000000000000000000000877675050057775880000000
dddd1110dddd1110dddd111087680000008802876866808768678000228782000000000000000000000000000000000000000000877677677676775800000000
01911610019116100191161087868000087800878286808782868000087800000000000000000000000000000000000000000000878776776776778000000000
01111610011116100111161087886800087800878086808768668000878888800000000000000000000000000000000000000000088778778778778000000000
05550000005000000000000087828680087800878086802866668008766668000000000000000000000000000000000000000000000880880880880000000000
55550000005000000000000088202888088200882088200288868008888882000000000000000000000000000000000000000000000000000000000000000000
50055000555550000000000022000222022000220022000022868002222220000000000000000000000000000000000000000000000000000000000000000000
55555000005000000000000000000000000000000000000800868000000000000000000000000000000000000000000000000000000000000000000000000000
55555000005000000000000000000000000000000000008688668000000000000000000000000000000000000000000000000000000000000000000000000000
11111000005000000000000000000000000000000000008866682000000000000000000000000000000000000000000000000000000000000000000000000000
01111100001000000000000000000000000000000000002888820000000000000000000000000000000000000000000000000000000000000000000000000000
00111100000110000000000000000000000000000000000222200000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000080000000008000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000008080008000000080008080000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000008000000080000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000008888888000000000000088888880000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000888888888888880000000008888888888888800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008666666666588888000000088888566666666680000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000086666666666658888800000888885666666666668000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000886666886666665888800000888856666668866668800000000000000000000000000000000000000000000
00000000000000000000000000000000000000008668668666666666588800000888566666666686686680000000000000000000000000000000000000000000
00000000000000000000000000000000000000088668686666666666588800000888566666666668686688000000000000000000000000000000000000000000
00000000000000000000000000000000000000086866666668886666658800000885666668886666666868000000000000000000000000000000000000000000
00000000000000000000000000000000000000086666066686666666658800000885666666668666066668000000000000000000000000000000000000000000
00000000000000000000000000000000000000866660006866666666658800000885666666666860006666800000000000000000000000000000000000000000
00000000000000000000000000000000000000866666066666666666658800000885666666666666066666800000000000000000000000000000000000000000
00000000000000000000000000000000000000800666066600666666658800000885666666600666066600800000000000000000000000000000000000000000
00000000000000000000000000000000000000800066666000066666658000000085666666000066666000800000000000000000000000000000000000000000
00000000000000000000000000000000000008000066666000066666558000000085566666000066666000080000000000000000000000000000000000000000
00000000000000000000000000000000000008000066666000066666558000000085566666000066666000080000000000000000000000000000000000000000
00000000000000000000000000000000000008600666566600666665580000000008556666600666566600680000000000000000000000000000000000000000
00000000000000000000000000000000000008666665556666666655580000000008555666666665556666680000000000000000000000000000000000000000
00000000000000000000000000000000000008566650505666665555800000000000855556666650505666580000000000000000000000000000000000000000
00000000000000000000000000000000000008555550500555555558000000000000085555555500505555580000000000000000000000000000000000000000
00000000000000000000000000000000000008775505000555555880000000000000008855555500050557780000000000000000000000000000000000000000
00000000000000000000000000000000000087767505005777588000000000000000000088577750050576778000000000000000000000000000000000000000
00000000000000000000000000000000000087767767767677580000000000000000000008577676776776778000000000000000000000000000000000000000
00000000000000000000000000000000000087877677677677800000000000000000000000877677677677878000000000000000000000000000000000000000
00000000000000000000000000000000000008877877877877800000000000000000000000877877877877880000000000000000000000000000000000000000
00000000000000000000000000000000000000088088088088000000000000000000000000088088088088000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000880088800000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008780878200888000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008788782008782000000000000000000088888880000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008787820008820808808800008888880877777820000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008778200002200887786680087778820288886800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008768000000880287666680876867800022868200000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008786800008780087888680878286800008680000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008788680008780087828680876866800086888880000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008782868008780087808680286666800866666800000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000008820288808820088208820028886800888888200000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000002200022202200022002200002286800222222000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000080086800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000868866800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000886668200000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000288882000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000022220000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000008808880000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000086686668000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000868686880000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000868686680000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000868686800000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000866886800000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000088208000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000022002000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000088000008888000000000000000000000000000000000000088800000000000000000000000000000000000000000000
00000000000000000000000000000000878000008782000000000000000000000000000000000000878000000000000000000000000000000000000000000000
00000000000000000000000000000000878000008780088800000000000000000000000000000000878000000000000000000000000000000000000000000000
00000000000000000000000000000000878000008780878200888888800088888808808888000000878000888888800000000000000000000000000000000000
00000000000000000000000000000000877800087680882008777778200877778000887778800088878008777778200000000000000000000000000000000000
00000000000000000000000000000000287808087820220002888868008768867800878886800877768000888868000000000000000000000000000000000000
00000000000000000000000000000000087788876800088000228682008780086800878228208768668000008682000000000000000000000000000000000000
00000000000000000000000000000000028787878200878000086800008780086800878002008780868000086800000000000000000000000000000000000000
00000000000000000000000000000000008776768000878000868888808768866800878000008768668000868888800000000000000000000000000000000000
00000000000000000000000000000000002878682000878008666668008866668680878000008766686808666668000000000000000000000000000000000000
00000000000000000000000000000000000882880000882008888882002888882820882000002888828208888882000000000000000000000000000000000000
00000000000000000000000000000000000220220000220002222220000222220200220000000222202002222220000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000066606660666006600660000066606060666066600660660000006660066000000660666066606660666000000000000000000000000
00000000000000000000060606060600060006000000060606060060006006060606000000600606000006000060060606060060000000000000000000000000
00000000000000000000066606600660066606660000066006060060006006060606000000600606000006660060066606600060000000000000000000000000
00000000000000000000060006060600000600060000060606060060006006060606000000600606000000060060060606060060000000000000000000000000
00000000000000000000060006060666066006600000066600660060006006600606000000600660000006600060060606060060000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
010e00002134023340233402135023350233502135023350233502136023360213602236022350233502334021340233402334021350233502335021350233502335021360233602136026372263722837228372
010e00002f3702f3702f3702836028360283602d3502d3502d3502634026340263402b3402b34026330263302334023340233402635026350283502536025360253502535025340253411e3311e3321e3321e332
010e00001c1401e1401e1401c1401e1401e1401c1401e1401e1401c1401e1401c1301d1301d1301e1301e1301c1401e1401e1401c1401e1401e1401c1401e1401e1401c1401e1401c14023150231502114021140
010e0000231402314023144231442314023144231442314022140221452214022140211402114021144211401c1401c1401c1451c1401c1451c1451e1301e1301e1421e1521e1421e13521162211722117221162
010e00000b0750b0700b0750b0750b0700b0750b0750b0700b075040700407504075040700407504070040750b0750b0700b0750b0750b0700b0750b0750b0700b07504070060700407007070040700807004070
010e00000b0700b0700b0750b0700b0700b0750407004070040750407004070040750607006075060700607009070090700907509070090700907509070090700907502070020700207504070040700907009070
010e00001705017050170501704017030170251705017050170501704017030170251705017050170401703513050130501305013040130301302513050130501305013040130301302513050130501304013035
010e0000170001700017000120501205012050120401203012025120501205012050120401203512050120500e0140e0100e0150e0500e0500e0500e0400e0300e0250e0500e0500e0500e0400e0350e0500e050
010e00001505015050150501504015030150251505015050150501504015030150251505015050150401503517050170551705517050170551705517050170551805018050170501705018050180501705017050
010e00000e0400e0300e0251005010050100501004010030100201005510050100501004010035100501005012050120551205512050120551205512050120551305013050120501205013050130501205012050
010e00002346123360233602336023352233522335223352233422334223342233452335023350253502535026362263622636226362263522635226352263522634226342263422634526350263502835028350
010e00002a3602a3602a3622a3622a3522a3552a3502a350293502935029352293522835028350283522835223350233502335223352233522335223352233522335223352233422334223332233322332223322
010e00002a3602a3602a3622a3622a3522a3552a3502a35029350293502a3602a3602c3602c3602d3602d3602f3702f3702f3722f3722f3622f3622f3622f3622f3522f3522f3422f3422f3322f3322f3222f322
010e00001505015050150501504015030150251505015050150501504015030150251505015050150401503517050170551705517050170551705517050170551905219052190521905219052190521905219052
010e00000e0400e0300e0251005010050100501004010030100201005510050100501004010035100501005012050120551205512050120551205512050120551305513055130551305513055130551305513055
010e0000060730000000000060732f6330000006003060732f6000607300000060732f6332f613000002f603060730000000000060732f633000002f603060732f6000607300000060732f6332f6032f6332f603
010e0000060730000000000060732f6330000006003060732f6000607300000060732f6332f613000002f603060730000000000060732f633000002f603060732f6000607300000060732f6332f6332f6332f613
010e00000607300000000002f63306003000000607300000060030607300000060032f6332f6132f6032f6030607300000000002f63306003000000607300000060030607300000060032f6332f6332f6132f603
010e00000607300000000002f63306003000000607300000060030607300000060032f6332f6132f6032f6030607300000000002f633060030000006073000002f6332f6332f6332f6332f6332f6332f6332f633
010e00002f3702f3702f3702836028360283602d3502d3502d3502634026340263402b3402b34026330263302334023340233402635026350283502a3522a3522a3622a3622a3622a3612d3612d3622d3722d372
010e00002314023140231442314423140231442314423140221402214522140221402114021140211442114025142251522515525152251552515525142251422515225142251322512523132231422313223125
0001000015d70166701ad701d67020d701667018d701c6701ed502165023d502464025d402663027d302862029d202961029d1001d0000d0000d0000d0000d0000d0000d0000d0000d0000d0000d0000d0000000
00020000211502415027110281203162031620306302f6402d6702a6702867024670206701b67015620116500b6500665001650106000c6000860005600036000160001600016000160001600016000160001600
000200001e32016330143401a35021360283702f370323703437034370303602a350203401633014320123200e310073100331001310103000e3000e3000c3000a30008300053000430002300000000000000000
010300001136715267172671a2571d247212372322726217292170000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000000000
010400003245038450384500000000000324503845038450000000000032450354503545000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0120000026732267322674226742267522675226742267452a7322a7322a7422a7422a7522a7522a7422a74525732257322574225742257522575225742257422574225742257322573225722257222571225715
0120000017030170301704017040170501705017040170451a0301a0301a0401a0401a0501a0501a0401a04521030210302104021040210502105021040210402104021040210302103021020210202101021015
012000000b073000000b053000000b033000000b013000000b073000000b053000000b033000000b013000000b073000000b053000000b033000000b013000000b073000000b053000000b033000000b01300000
012000002f5302d5302a540285402a5302d5302a520285202f5302d5302a540285402a5302d5302a520285202f5302d5302a540285402a5302d5302a520285202853026530235402154023530265302352021520
012000001c5301c5301c5401c5401c5501c5501c5401c540235302353023540235402355023550235402354021530215302154021540215502155021540215402154021540215302153021520215202151021510
__music__
01 0002040f
00 01030510
00 0002040f
00 13140510
00 0a060711
00 0b080911
00 0a060711
02 0c0d0e12
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 1a1b1c44
00 1a1b1c44
00 1a1b1c1d
00 1a1b1c1d
00 1a1b1c1e
02 1a1b1c1e
00 41424344
00 41424344
00 41424344
00 41424344
03 1c424344

