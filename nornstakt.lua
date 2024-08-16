
engine.name="MxSynths"

musicutil = require("musicutil")
tabutil = require("tabutil")
util = require("util")
UI = require("ui")
lattice = require("lattice")

Step = include("lib/step")
Track = include("lib/track")
Button = include("lib/ui/button")
IsoKeys = include("lib/ui/iso_keys")

-- TRANSPORT
transport = lattice:new()

played_notes = {}

-- TRACKS
tracks = {
  Track:new(1, transport, played_notes),
  Track:new(2, transport, played_notes),
  Track:new(3, transport, played_notes),
  Track:new(4, transport, played_notes),
  Track:new(5, transport, played_notes),
  Track:new(6, transport, played_notes)
}
selected_track = 1

selected_step = 0
copied_step = nil

tick = 0
last_note = 60

selected_param = 1

rec = Button:new(1,5,nil,function() copied_step = tracks[selected_track]:get_step(selected_step) end)
play = Button:new(2,5,function () transport:hard_restart() end,function() tracks[selected_track]:set_step(selected_step, Step:new()) end)
stop = Button:new(3,5,function () transport:stop() end,function() tracks[selected_track]:set_step(selected_step, Step:new(copied_step)) end)
  
up = Button:new(15,4,function () iso_keys.root = iso_keys.root + iso_keys.interval end,nil)
down = Button:new(15,5,function () iso_keys.root = iso_keys.root - iso_keys.interval end,nil)
left = Button:new(14,5,nil,function () tracks[selected_track]:move_steps(-1) end)
right = Button:new(16,5,nil,function () tracks[selected_track]:move_steps(1) end)

track_a = Button:new(14,7,function () selected_track = 1 end,nil)
track_b = Button:new(15,7,function () selected_track = 2 end,nil)
track_c = Button:new(16,7,function () selected_track = 3 end,nil)
track_d = Button:new(14,8,function () selected_track = 4 end,nil)
track_e = Button:new(15,8,function () selected_track = 5 end,nil)
track_f = Button:new(16,8,function () selected_track = 6 end,nil)
track_a.show = function (self, grid) g:led(self.x,self.y,selected_track == 1 and 15 or 5) end
track_b.show = function (self, grid) g:led(self.x,self.y,selected_track == 2 and 15 or 5) end
track_c.show = function (self, grid) g:led(self.x,self.y,selected_track == 3 and 15 or 5) end
track_d.show = function (self, grid) g:led(self.x,self.y,selected_track == 4 and 15 or 5) end
track_e.show = function (self, grid) g:led(self.x,self.y,selected_track == 5 and 15 or 5) end
track_f.show = function (self, grid) g:led(self.x,self.y,selected_track == 6 and 15 or 5) end

shift = Button:new(1,3,nil,nil)
page = Button:new(16,3,nil,nil)
pattern = Button:new(1,7,nil,nil)

buttons = {rec,play,stop,up,down,left,right,track_a,track_b,track_c,track_d,track_e,track_f,shift,page,pattern}

iso_keys = IsoKeys:new(5,3,8,7)
iso_keys.note_on = function (note, vel)
  --local hz = musicutil.note_num_to_freq(note)
  --engine.hz(hz)
  --mxsynths:play({synth="piano",note=note,velocity=80,attack=0.1,release=0.1})
  engine.mx_note_on(note,vel/127,600)
  
  if selected_step > 0 then
    print("add", note)
    tracks[selected_track]:add(selected_step, note)
  end
end
iso_keys.note_off = function (note, vel)
  engine.mx_note_off(note)
end

g = grid.connect()

g.key = function(x,y,z)
  local track = tracks[selected_track]
  
  if pattern.state and x>5 and x<12 and y>2 then
    tracks[x-5].current_clip = y-2
  else
    iso_keys:key(x,y,z)
  end
  
  for _,button in ipairs(buttons) do
    button:key(x,y,z,selected_step > 0 or shift.state)
  end
  
  if y <= 2 then
    if page.state then
      track:set_clip_length(x + (y - 1) * 16)
    else
      selected_step = z == 1 and (x + (y - 1) * 16) or 0
      if selected_step > 0 then
        for _, n in pairs(iso_keys.notes) do
          track:add(selected_step, n.note)
        end
      end
    end
  end
  
  grid_dirty = true
  redraw()
end

function init ()
  local mxsynths_=include("mx.synths/lib/mx.synths")
  mxsynths=mxsynths_:new({save=true,previous=true})
  
  engine.mx_set_synth("toshiya")
  
  grid_dirty = true
  grid_redraw_id = clock.run(grid_redraw)
  
  redraw()
end

function enc (n, d)
  local track = tracks[selected_track]
  
  if selected_step > 0 then
    if n == 2 then
      selected_param = util.clamp(selected_param + d, 1, 3)
    elseif n == 3 then
      local params = {"note","mode","condition","probability"}
      track:change_param(selected_step, params[selected_param], d)
    end
  end
  print("selected_param", selected_param)
  redraw()
end

function draw_step_values (step)
  if step then
    screen.level(15)
    
    local notes = ""
    for i, n in ipairs(step.notes) do
      notes = notes..(i==1 and "" or ", ")..n
    end
    
    local values = {
      {label = "note", value = notes},
      {label = "mode", value = step.mode},
      {label = "condition", value = CONDITIONS[step.condition].label},
      {label = "probability", value = step.probability}
    }
    
    for i,param in ipairs(values) do
      screen.level(i == selected_param and 15 or 5)
      local y = 20 + 12 * (i-1)
      screen.move(8, y)
      screen.text(param.label..":")
      screen.move(64, y)
      screen.text(param.value)
      i = i + 1
    end
  end
end

function redraw()
  screen.clear()
  
  local track = tracks[selected_track]

  draw_step_values(track:get_step(selected_step))
  
  screen.update()
end

function grid_redraw ()
  while true do
    clock.sleep(1/50)
    if grid_dirty then
      draw_grid()
      grid_dirty = false
    end
  end
end

function draw_grid ()
  g:all(0)
  
  local track = tracks[selected_track]
  
  -- TRACK
  for i=1, 32 do
    local x = i % 16
    local y = math.ceil(i / 16)
    local l = #track:get_step(i).notes == 0 and 2 or 5
    l = i == selected_step and 10 or l
    g:led(x,y,l)
  end
  g:led(track.playhead % 16, math.ceil(track.playhead / 16), 15)
  
  if pattern.state then
    -- PATTERN MATRIX
    for x = 6, 11 do
      for y = 3, 8 do
        local l = x-5 == selected_track and 10 or 3
        l = y - 2 == tracks[x-5].current_clip and 15 or l
        g:led(x, y, l)
      end
    end
  else
    -- KEYS
    local visible_notes = selected_step ~= 0 and track:get_step(selected_step).notes or played_notes
    iso_keys:draw(g, visible_notes)
  end
  
  -- UI
  for _,button in ipairs(buttons) do
    button:show(g)
  end
  
  g:refresh()
end

function cleanup ()
  transport:destroy()
end