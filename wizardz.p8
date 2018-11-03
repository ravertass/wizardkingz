pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- kingz of wizardz
-- a spooky game jam game

---- constants ----

skeltal_sprs = {064, 065}
c_startscreen_timer = "startscreen_timer"
c_startscreen_timer_countdown_start = 3
fireball_sprs = {128, 129}
lightning_ball_sprs = {132, 133, 134, 135}

c_song_1 = 000
pl1_run_down = {013, 014}
pl1_run_side = {045, 046}
pl1_run_up = {029, 030}
pl1_idle = {011, 012}

---- init ----
local timers = {}
local startscreen_game_time = nil

function _init()
  pl1 = new_player1()
  pl2 = new_player2()
  enemies = {}
  fireballs = {}
  add(enemies, new_skeltal())
  add(enemies, new_skeltal())
  add(enemies, new_skeltal())
  init_startscreen()
  music(c_song_1)
end

function new_player1()
  return {
    x = 10,
    y = 10,
    spr = 011,
    no = 0,
    vel = {
      x = 0,
      y = 0
    },
    dir = {
      x = 1,
      y = 0
    },
    did_shoot = false
  }
end

function new_player2()
  return {
    x = 100,
    y = 10,
    spr = 011,
    no = 1,
    vel = {
      x = 0,
      y = 0
    },
    dir = {
      x = 1,
      y = 0
    },
    did_shoot = false
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
  mode = 1 ---- startscreen = 0 | gamescreen = 1 ----
  startscreen_game_timer_exists = false
  startscreen_game_time = time()
end

function new_fireball(x, y, vel)
  return {
    x = x,
    y = y,
    vel = vel,
    type = "fireball",
    spr = fireball_sprs[1],
    spr_ix = 1,
    flip_x = false,
    flip_y = false
  }
end

---- update ----

function _update()
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
    update_player(pl1)
    update_player(pl2)
    foreach(enemies, update_entity)
    foreach(fireballs, update_entity)
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
    end
  )
end

function update_player(pl)
  if btn(0, pl.no) then
    pl.vel.x = -1
    update_player_spr(pl, pl1_run_side)
  elseif btn(1, pl.no) then
    pl.vel.x = 1
    update_player_spr(pl, pl1_run_side)
  else
    pl.vel.x = 0
  end
  pl.x = pl.x + pl.vel.x

  if btn(2, pl.no) then
    pl.vel.y = -1
    update_player_spr(pl, pl1_run_up)
  elseif btn(3, pl.no) then
    pl.vel.y = 1
    update_player_spr(pl, pl1_run_down)
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
end

function shoot_fireball(pl)
  vel = {
    x = pl.vel.x + 2 * pl.dir.x,
    y = pl.vel.y + 2 * pl.dir.y,
  }
  add(fireballs, new_fireball(pl.x, pl.y, vel))
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

function update_entity(e)
  if e.type == "skeltal" then
    update_skeltal(e)
  elseif e.type == "fireball" then
    update_fireball(e)
  end
end

function update_skeltal(s)
  follow(pl1, s)
  -- if rnd(3) > 2 then
  --   s.x = s.x + rnd(3) - 1.5
  --   s.y = s.y + rnd(3) - 1.5
  -- end
end

function update_fireball(f)
  f.x += f.vel.x
  f.y += f.vel.y
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

function update_timers ()
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

function restart_timer (name, start_paused)
  local timer = timers[name]
  if (not timer) return
  timer.elapsed = 0
  timer.active = not start_paused
end

---- draw ----

function _draw()
  ---- startscreen ----
  if mode == 0 then
    cls()
    print("kingz of wizardz", 32, 60, 7)
    if startscreen_game_timer_exists then
      print("game starting in "..tostr(ceil(c_startscreen_timer_countdown_start - timers[c_startscreen_timer].elapsed)), 28, 90, 6)
    else 
      print("press x to start", 32, 90, 6)
    end
  end
  ---- gamescreen ----
  if mode == 1 then
    cls()
    draw_entity(pl1)
    draw_entity(pl2)
    foreach(enemies, draw_entity)
    foreach(enemies, skeltal_chew)
    foreach(fireballs, draw_entity)
    foreach(fireballs, update_fireball_spr)
  end
end

function skeltal_chew(e)
  if e.spr == skeltal_sprs[1] then
    e.spr = skeltal_sprs[2]
  else
    e.spr = skeltal_sprs[1]
  end
end

function update_fireball_spr(e)
  e.spr_ix += 1
  if e.spr_ix > #fireball_sprs then
    e.spr_ix = 1
  end

  e.flip_x = e.vel.x < 0
  e.flip_y = e.vel.y < 0
  e.spr = fireball_sprs[e.spr_ix]
  if e.vel.x == 0 then
    e.spr += 16
  end
end

function update_player_spr(e, anim)
    if e.spr == anim[1] then
    e.spr = anim[2]
  else
    e.spr = anim[1]
  end
end

function draw_entity(e)
  if e.type == "fireball" then
    draw_fireball(e)
  elseif e.type == 'skeltal' then
    draw_skeltal(e)
  else
    spr(e.spr, e.x, e.y)
  end
end

function draw_skeltal(e)
  flip_x = e.vel.x < 0
  spr(e.spr, e.x, e.y, 1, 1, flip_x)
end

function draw_fireball(e)
  spr(e.spr, e.x, e.y, 1, 1, e.flip_x, e.flip_y)
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
00000000000000000000000000000000000c0c000c0c0c000000cc00cc0000000000000000000000000000000000000000000000000000000000000000000000
00009990000099900000000000000000ccc0ddd000c0ddd000c0ddd000c0ddd00000000000000000000000000000000000000000000000000000000000000000
00aaa779800aa7790000000000000000000cc77dc00cc77dcc0cc77d0cccc77d0000000000000000000000000000000000000000000000000000000000000000
890a777909aa777900000000000000000ccc777dcc0c777d00cc777dc00c777d0000000000000000000000000000000000000000000000000000000000000000
09aa7779890a7779000000000000000000cc777d00cc777d0ccc777dcccc777d0000000000000000000000000000000000000000000000000000000000000000
800aa77900aaa7790000000000000000c00cc77d0c0cc77d000cc77d00ccc77d0000000000000000000000000000000000000000000000000000000000000000
000099900000999000000000000000000cc0ddd0000cddd0cc0cddd0cc0cddd00000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000c000000000000ccc00000c000000000000000000000000000000000000000000000000000000000000000000000
0080800000080800000000000000000000c000c00000cc000c000c000c0cc00c0000000000000000000000000000000000000000000000000000000000000000
000990000009900000000000000000000c00c0c000c0c00c0c0c0c000c0c0c0c0000000000000000000000000000000000000000000000000000000000000000
000a0a0000a0a00000000000000000000c0cc0c0000c00c0c00cc0c0c0cc0cc00000000000000000000000000000000000000000000000000000000000000000
00aaaa0000aaaa00000000000000000000cccc0c0ccccc0ccccccc000ccccc000000000000000000000000000000000000000000000000000000000000000000
09a77a9009a77a9000000000000000000dc77cd00dc77cd0cdc77cdc0dc77cd00000000000000000000000000000000000000000000000000000000000000000
09777790097777900000000000000000cd7777dc0d7777dc0d7777dc0d7777d00000000000000000000000000000000000000000000000000000000000000000
097777900977779000000000000000000d7777d00d7777d00d7777d00d7777d00000000000000000000000000000000000000000000000000000000000000000
0099990000999900000000000000000000dddd0000dddd0000dddd0000dddd000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000b0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000b0b0b0b0b0b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000b0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010e00002134023340233402134023340233402134023340233402134023340213402234022340233402334021340233402334021340233402334021340233402334021340233402134026342263422834228342
010e00002f3402f3402f3402834028340283402d3402d3402d3402634026340263402b3402b34026340263402334023340233402634026340283402534025340253402534025340253411e3411e3421e3421e342
010e00001c1501e1501e1501c1501e1501e1501c1501e1501e1501c1501e1501c1501d1501d1501e1501e1501c1501e1501e1501c1501e1501e1501c1501e1501e1501c1501e1501c15023150231502115021150
010e0000231502315023154231542315023154231542315022150221552215022150211502115021154211501c1501c1501c1551c1501c1551c1551e1301e1301e1421e1521e1421e13521162211722117221162
010e00000b0650b0600b0650b0650b0600b0650b0650b0600b065040600406504065040600406504060040650b0650b0600b0650b0650b0600b0650b0650b0600b06504060060600406007060040600806004060
010e00000b0600b0600b0650b0600b0600b0650406004060040650406004060040650606006065060600606009060090600906509060090600906509060090600906502060020600206504060040600906009060
010e00001705017050170501704017030170251705017050170501704017030170251705017050170401703513050130501305013040130301302513050130501305013040130301302513050130501304013035
010e0000170001700017000120501205012050120401203012025120501205012050120401203512050120500e0140e0100e0150e0500e0500e0500e0400e0300e0250e0500e0500e0500e0400e0350e0500e050
010e00001505015050150501504015030150251505015050150501504015030150251505015050150401503517050170551705517050170551705517050170551805018050170501705018050180501705017050
010e00000e0400e0300e0251005010050100501004010030100201005510050100501004010035100501005012050120551205512050120551205512050120551305013050120501205013050130501205012050
010e00002345123350233502335023352233522335223352233522335223352233552335023350253502535026352263522635226352263522635226352263522635226352263522635526350263502835028350
010e00002a3502a3502a3522a3522a3522a3552a3502a350293502935029352293522835028350283522835223350233502335223352233522335223352233522335223352233422334223332233322332223322
010e00002a3502a3502a3522a3522a3522a3552a3502a35029350293502a3502a3502c3502c3502d3502d3502f3502f3502f3522f3522f3522f3522f3522f3522f3522f3522f3422f3422f3322f3322f3222f322
010e00001505015050150501504015030150251505015050150501504015030150251505015050150401503517050170551705517050170551705517050170551305013055130501305513050130551305013055
010e00000e0400e0300e0251005010050100501004010030100201005510050100501004010035100501005012050120551205512050120551205512050120551905019055190501905519050190551905019055
__music__
01 00020444
00 01030544
00 00020444
00 01030544
00 0a060744
00 0b080944
00 0a060744
02 0c0d0e44
