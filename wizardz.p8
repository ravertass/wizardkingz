pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- kingz of wizardz
-- a spooky game jam game

---- diagnostics ----

c_perf_names = {"update", "draw"}
c_perf_history = {}
c_draw_perf_hist = {}
c_diag_counter = 0

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
  printh("Perf (average over "..n_points.." frames):")
  foreach(c_perf_names, print_diag_line)
end

---- constants ----

skeltal_sprs = {064, 065}
c_startscreen_timer = "startscreen_timer"
c_startscreen_timer_countdown_start = 3
projectile_sprs = {
  fireball = {128, 129},
  lightning_ball = {132, 133, 134}
}
skull_spr = {205}
skull_fx_sprs = {202, 203, 204}

c_song_1 = 000
sfx_shoot = 21
sfx_expl = 22
sfx_ouch = 23

pl1_run_down = {013, 014}
pl1_run_side = {045, 046}
pl1_run_up = {029, 030}
pl1_idle = {011, 012}
pl1_idle_up = {027, 028}
pl1_idle_side = {043, 044}

anim_count = 0
c_max_health = 100

---- init ----
local timers = {}
local startscreen_game_time = nil

function _init()
  reset_diag()
  pl1 = new_player1()
  pl2 = new_player2()
  skeltals = {}
  projectiles = {}
  fire_particles = {}
  add(skeltals, new_skeltal())
  add(skeltals, new_skeltal())
  add(skeltals, new_skeltal())
  init_startscreen()
  music(c_song_1)
end

function new_player1()
  return {
    type = 'player',
    x = 10,
    y = 10,
    spr = 011,
    spr_ix = 1,
    no = 0,
    vel = {
      x = 0,
      y = 0
    },
    dir = {
      x = 1,
      y = 0
    },
    projectile_type = "fireball",
    did_shoot = false,
    health = c_max_health,
    invincibility_counter = 60,
    flip_pl = false
  }
end

function new_player2()
  return {
    type = 'player',
    x = 100,
    y = 10,
    spr = 011,
    spr_ix = 1,
    no = 1,
    vel = {
      x = 0,
      y = 0
    },
    dir = {
      x = 1,
      y = 0
    },
    projectile_type = "lightning_ball",
    did_shoot = false,
    health = c_max_health,
    invincibility_counter = 60,
    flip_pl = false
  }
end

function new_skeltal()
  return {
    x = rnd(128),
    y = rnd(128),
    vel = {
      x = 0,
      y = 0
    },
    type = "skeltal",
    spr = 064
  }
end

function init_startscreen()
  mode = 0 ---- startscreen = 0 | gamescreen = 1 ----
  startscreen_game_timer_exists = false
  startscreen_game_time = time()
  skull_fx_index = 1
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

---- update ----

function _update()
  ---- diagnostics ----
  c_diag_counter += 1
  if c_diag_counter == 30 then
    c_diag_counter = 0
    print_diagnostics()
    reset_diag()
  end
  ---- startscreen ----
  update_timers()
  if mode == 0 then
    if btn(5) and not startscreen_game_timer_exists then
      startscreen_game_timer_exists = true
      startscreen_game_time = time()
      create_startscreen_countdown()
    end
  end
  ---- gamescreen ----
  if mode == 1 then
    count()
    update_player(pl1)
    update_player(pl2)
    foreach(skeltals, update_entity)
    foreach(projectiles, update_entity)
  end
  ---- diagnostics ----
  time_after = stat(1)
  log_perf("update", 0, time_after)
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
    end
  )
end

function count()
  anim_count += 1
  if anim_count == 29 then
    anim_count = 0
  end
end

function update_player(pl)
  if btn(0, pl.no) then
    pl.vel.x = -1
  elseif btn(1, pl.no) then
    pl.vel.x = 1
  else
    pl.vel.x = 0
  end
  pl.x = pl.x + pl.vel.x

  if btn(2, pl.no) then
    pl.vel.y = -1
  elseif btn(3, pl.no) then
    pl.vel.y = 1
  else
    pl.vel.y = 0
  end
  pl.y = pl.y + pl.vel.y

  if pl.vel.x != 0 or pl.vel.y != 0 then
    pl.dir.x = pl.vel.x
    pl.dir.y = pl.vel.y
  end

  if btn(4, pl.no) then
    if not pl.did_shoot then
      shoot_fireball(pl)
      pl.did_shoot = true
    end
  else
    pl.did_shoot = false
  end

  update_invincibility(pl)
  player_collisions(pl)
end

function update_invincibility(pl)
  pl.invincibility_counter = max(0, pl.invincibility_counter - 1)
end

function player_collisions(pl)
  if pl.invincibility_counter == 0 then
    for skeltal in all(skeltals) do
      player_skeltal_collision(pl, skeltal)
    end
  end
end

function player_skeltal_collision(pl, skeltal)
  local pl_rect = player_rect(pl)
  local skeltal_rect = skeltal_rect(skeltal)
  if intersect(pl_rect, skeltal_rect) then
    take_damage(pl)
  end
end

function take_damage(pl)
  sfx(sfx_ouch, 1)
  pl.health = max(pl.health - 20, 0)
  if pl.health <= 0 then
    kill_player(pl)
  end
  pl.invincibility_counter = 30
end

function kill_player(pl)
  -- TODO: Player should die
end

function shoot_fireball(pl)
  vel = {
    x = pl.vel.x + 2 * pl.dir.x,
    y = pl.vel.y + 2 * pl.dir.y,
  }
  add(projectiles, new_projectile(pl.x, pl.y, vel, pl.projectile_type))
  sfx(sfx_shoot, 2)
end

function follow(target, e)
  world_size = 128
  norm_x=(target.x-e.x)/world_size
  norm_y=(target.y-e.y)/world_size
  e.dir=atan2(norm_x,norm_y)
  move(e)
end

function move(e)
  max_speed = 0.4
  speed = rnd(max_speed)
  dx=cos(e.dir)*speed
  dy=sin(e.dir)*speed
  e.vel.x = dx
  e.vel.y = dy
  e.x += dx
  e.y += dy
end

function kill(target, wpn)
  sfx(sfx_expl, 2)
  del(skeltals, target)
  del(projectiles, wpn)
  add(skeltals, new_skeltal())
  add(skeltals, new_skeltal())
  create_skeltal_particles(skeltal, wpn)
end

cols_skeltal = {7,8,9}
function create_skeltal_particles(skeltal, fireball)
  local x = skeltal.x+3
  local y = skeltal.y+3
  local dxoffs=skeltal.vel.x+cos(2)*fireball.vel.x
  local dyoffs=skeltal.vel.y+sin(2)*fireball.vel.x
  for i = 1, 5 do
    add(fire_particles, create_fire_particle(x, y, dxoffs, dyoffs, cols_skeltal[flr(rnd(3))+1]))
  end
end

function create_fire_particle(x, y, dxoffs, dyoffs, col)
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

function update_fire_particle(particle)
  particle.x += particle.dx
  particle.y += particle.dy
  particle.dy += particle.ddy
  particle.count -= 1
  if particle.count < 1 then
    del(fire_particles, particle)
  end
end

function fireball_collision(fireball)
  for i = 1, #skeltals do
    skeltal = skeltals[i]
    if intersect(
      skeltal_rect(skeltal),
      {fireball.x+1, fireball.y+2,
        fireball.x+6, fireball.y+6})
    then
      kill(skeltal, fireball)
      return
    end
  end
end

function skeltal_rect(s)
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

function intersect(rect1,rect2)
  return
    intersect_intervals(rect1[1], rect1[3], rect2[1], rect2[3])
    and
    intersect_intervals(rect1[2], rect1[4], rect2[2], rect2[4])
end

function intersect_intervals(a_lo, a_hi, b_lo, b_hi)
  return a_lo < b_hi and a_hi > b_lo
end

function update_entity(e)
  if e.type == "skeltal" then
    update_skeltal(e)
  elseif e.type == "projectile" then
    update_projectile(e)
  end
end

function update_skeltal(s)
  local action = flr(rnd(10))
  if action <= 8 then
    follow(pl1, s)
  elseif action == 9 then
    s.x = s.x + rnd(2) - 1
    s.y = s.y + rnd(2) - 1
  else
    -- do nothing
  end
end

function update_projectile(f)
  f.x += f.vel.x
  f.y += f.vel.y
  if f.projectile_type == 'fireball' then
    fireball_collision(f)
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

---- draw ----

function _draw()
  ---- diagnostics ----
  time_before = stat(1)
  ---- startscreen ----
  if mode == 0 then
    draw_startscreen()
  elseif mode == 1 then
    draw_gamescreen()
  end
  ---- diagnostics ----
  time_after = stat(1)
  log_perf("draw", time_before, time_after)
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
  print("kingz of wizardz", 32, 60, 7)
  if startscreen_game_timer_exists then
    print("game starting in "..tostr(ceil(c_startscreen_timer_countdown_start - timers[c_startscreen_timer].elapsed)), 28, 90, 6)
  else
    print("press x to start", 32, 90, 6)
  end
end

function draw_gamescreen()
  cls()
  draw_entity(pl1)
  draw_entity(pl2)
  foreach(skeltals, draw_entity)
  foreach(skeltals, skeltal_chew)
  foreach(projectiles, draw_entity)
  foreach(projectiles, update_projectile_spr)
  foreach(fire_particles, update_fire_particle)
  foreach(fire_particles, draw_fire_particle)
  draw_healthbars()
end

function skeltal_chew(e)
  if anim_count % 2 == 0 then
    if e.spr == skeltal_sprs[1] then
     e.spr = skeltal_sprs[2]
    else
      e.spr = skeltal_sprs[1]
    end
  end
end

function update_projectile_spr(e)
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

function draw_entity(e)
  if e.type == "projectile" then
    draw_projectile(e)
  elseif e.type == 'skeltal' then
    draw_skeltal(e)
  elseif e.type == 'player' then
  draw_player(e)
  else
    spr(e.spr, e.x, e.y)
  end
end

function draw_player(e)
  if (e.invincibility_counter % 3) == 1 then
    return
  end

  if e.vel.x == 0 and e.vel.y == 0 then
    if e.dir.x > 0 and e.dir.y == 0 and anim_count % 6 == 0 then
      e.flip_pl = false
      animate_player(e, pl1_idle_side)
    elseif e.dir.x < 0 and e.dir.y == 0 and anim_count % 6 == 0 then
      e.flip_pl = true
      animate_player(e, pl1_idle_side)
    elseif e.dir.x == 0 and e.dir.y > 0 and anim_count % 6 == 0 then
      e.flip_pl = false
      animate_player(e, pl1_idle)
    elseif e.dir.x == 0 and e.dir.y < 0 and anim_count % 6 == 0 then
      e.flip_pl = false
      animate_player(e, pl1_idle_up)
    end
  elseif e.vel.x > 0 then
    e.flip_pl = false
    if anim_count % 2 == 0 then
      animate_player(e, pl1_run_side)
    end
  elseif e.vel.x < 0 then
    e.flip_pl = true
    if anim_count % 2 == 0 then
      animate_player(e, pl1_run_side)
    end
  elseif e.vel.y > 0 then
    e.flip_pl = false
    if anim_count % 2 == 0 then
      animate_player(e, pl1_run_down)
    end
  elseif e.vel.y < 0 then
    e.flip_pl = false
    if anim_count % 2 == 0 then
      animate_player(e, pl1_run_up)
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

function draw_skeltal(e)
  flip_x = e.vel.x < 0
  spr(e.spr, e.x, e.y, 1, 1, flip_x)
end

function draw_projectile(e)
  spr_x = flr(e.spr % 16) * 8
  spr_y = flr(e.spr / 16) * 8
  pos_x = e.x - ((e.size - 8) / 2)
  pos_y = e.y - ((e.size - 8) / 2)
  sspr(spr_x, spr_y, 8, 8, pos_x, pos_y, e.size, e.size, e.flip_x, e.flip_y)
  for i = 0, 5 do
    add_particle(e)
  end
end

function draw_fire_particle(particle)
  circ(particle.x, particle.y, 0, particle.col)
end

function add_particle(e)
  -- e is a projectile
  alpha_0 = atan2(-e.vel.x, -e.vel.y)
  alpha = alpha_0 + rnd(0.15) - 0.075

  proj_front_x = 4
  if e.vel.x != 0 then
    proj_front_x += 4 * sgn(e.vel.x)
  end
  proj_front_y = 4
  if e.vel.y != 0 then
    proj_front_y += 4 * sgn(e.vel.y)
  end

  x_offs = cos(alpha)
  y_offs = sin(alpha)
  r = rnd(8) + 4
  x = e.x + proj_front_x + r * x_offs
  y = e.y + proj_front_y + r * y_offs
  pset(x, y, 7)
end

function draw_healthbars()
  draw_healthbar(pl1, 8)
  draw_healthbar(pl2, 80)
end

function draw_healthbar(pl, x)
  local col = healthbar_color(pl.health)
  local x_end = x + (pl.health/c_max_health)*40
  rectfill(x, 120, x_end, 124, col)
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
__gfx__
0000000000000000000000000000000000000000000000000000000000000000000000000ccccc000ccccc000ccccc00000000000ccccc000ccccc0000000000
000000000808000000000000000000000000000000000000000000000000000000000000ccccccc0ccccccc0ccccccc00ccccc00ccccccc0ccccccc000000000
007007000000000000000000000000000000000000000000000000000000000000000000c6f1f1f6c6f1f1f6c6f1f1f6ccccccc0c6f1f1f6c6f1f1f600000000
00077000000000800000000000000000000000000000000000000000000000000000000006efffe606efffe606efffe6c6f1f1f606efffe606efffe600000000
00077000880008800000000000000000000000000000000000000000000000000000000000666660006666600066666006efffe6006666600066666000000000
007007000888880000000000000000000000000000000000000000000000000000000000fcc666cf0fc666f000c666000066666000c6660000c6660000000000
00000000000000000000000000000000000000000000000000000000000000000000000000cc6c0000cc6c0000cc6c0000c6660004cc6c0000cc6c4000000000
00000000000000000000000000000000000000000000000000000000000000000000000000400400004004000040040000406400000004000040000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000cccc0000cccc0000cccc000000000000cccc0000cccc0000000000
0000000000000000000000000000000000000000000000000000000000000000000000000cccccc00cccccc00cccccc000cccc000cccccc00cccccc000000000
00000000000000000000000000000000000000000000000000000000000000000000000066cccc6666cccc6666cccc660cccccc066cccc6666cccc6600000000
000000000000000000000000000000000000000000000000000000000000000000000000666cc666666cc666666cc66666cccc66666cc666666cc66600000000
000000000000000000000000000000000000000000000000000000000000000000000000066666600666666006666660666cc666066666600666666000000000
000000000000000000000000000000000000000000000000000000000000000000000000fcc66ccf0fc66cf000c66c000666666000c66c0000c66c0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000cccc0000cccc0000cccc0000c66c0000cccc4004cccc0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000400400004004000040040000400400004000000000040000000000
0000000000000000000000000000000000000000000000000000000000000000000000000ccccc000ccccc000ccccc00000000000ccccc000ccccc0000000000
000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0ccccccc0ccccccc00ccccc00ccccccc0ccccccc000000000
000000000000000000000000000000000000000000000000000000000000000000000000cc66f1f0cc66f1f0cc66f1f0ccccccc0cc66f1f0cc66f1f000000000
0000000000000000000000000000000000000000000000000000000000000000000000000666efff0666efff0666efffcc66f1f00666efff0666efff00000000
0000000000000000000000000000000000000000000000000000000000000000000000000066666000666660006666600666efff006666600066666000000000
00000000000000000000000000000000000000000000000000000000000000000000000000cfc66000cccccf00ccc6600066666000ccc66000ccc66000000000
00000000000000000000000000000000000000000000000000000000000000000000000000cccc6000cccc6000cccc6000ccc66000cccc6404cccc6000000000
00000000000000000000000000000000000000000000000000000000000000000000000000400400004004000040040000400460004000000000040000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00787800007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700007878000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700007777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777000007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
80000000008000000000000000000000c000c0000c000c000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000
09090000090000000000000000000000cc0c00000c0c0c00c00c0c00000000000000000000000000000000000000000000000000000000000000000000000000
80a0a90000a0a900000000000000000000c0c70000c0c70000c0c700000000000000000000000000000000000000000000000000000000000000000000000000
000aa790090aa7900000000000000000c00cc770cc0cc770cc0cc770000000000000000000000000000000000000000000000000000000000000000000000000
00aa777900aa77790000000000000000c0cc77770ccc77770ccc7777000000000000000000000000000000000000000000000000000000000000000000000000
009777790097777900000000000000000c777777c0777777c0777777000000000000000000000000000000000000000000000000000000000000000000000000
00097790000977900000000000000000000777700007777000077770000000000000000000000000000000000000000000000000000000000000000000000000
00009900000099000000000000000000000077000000770000007700000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888880000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000080000000008888888888888800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000008000000086666666665888880
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000800000000800800000000000866666666666588888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000008866668866666658888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000800088000000000000000000086686686666666665888
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000008000000886686866666666665888
00000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000800080000008000868666666688866666588
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000866660666866666666588
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008666600068666666666588
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008666660666666666666588
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008006660666006666666588
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000666660000666666580
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000666660000666665580
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000666660000666665580
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086006665666006666655800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000086666655566666666555800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085666505056666655558000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000085555505005555555580000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000087755050005555558800000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000877675050057775880000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000877677677676775800000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000878776776776778000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088778778778778000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000880880880880000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
__music__
01 0002040f
00 01030510
00 0002040f
00 13140510
00 0a060711
00 0b080911
00 0a060711
02 0c0d0e12

