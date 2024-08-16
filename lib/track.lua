local Step = include("lib/step")
tabutil = require("tabutil")

-- CLIP

local Clip = {
  max_length = 32
}

function Clip:move_steps (d)
  if d == 1 then
    local step = Step:new(self.steps[#self.steps])
    table.insert(self.steps, 1, step)
    table.remove(self.steps, #self.steps)
  elseif d == -1 then
    local step = Step:new(self.steps[1])
    table.insert(self.steps, self.max_length + 1, step)
    table.remove(self.steps, 1)
  end
end

function Clip:new (o)
  c = {
    length = o and o.length or 16,
    steps = {}
  }
  
  for i=1, 32 do
    c.steps[i] = Step:new(o and o.steps[i] or nil)
  end
  
  setmetatable(c, self)
  self.__index = self
  return c
end

-- TRACK

local Track = {}

function Track:add (i, note)
  self.clip.steps[i]:add_note(note)
end

function Track:play (tick)
  local played_notes = self.clip.steps[self.playhead]:play(tick, self.clip.length)
  return played_notes or {}
end

function Track:change_param (step, param, d)
  local step = self.clip.steps[step]
  if param == "condition" then
    step[param] = util.clamp(step[param]+d,1,#CONDITIONS)
  elseif param == "probability" then
    step[param] = util.clamp(step[param]+d*0.1,0,1)
  elseif param == "mode" then
    step[param] = d > 0 and "random" or "poly"
  end
end

function Track:move_steps (d)
  self.clip:move_steps(d)
end

function Track:get_step (i)
  return self.clip.steps[i]
end

function Track:set_step (i, s)
  self.clip.steps[i] = s
end

function Track:get_clip_length (l)
  return self.clip.length
end

function Track:set_clip_length (l)
  self.clip.length = l
end

function Track:new (id, transport, played_notes, o)
  local t = {
    id = id,
    transport = transport,
    playhead = 1,
    
    mute = false,
    current_clip = 1,
    clip = Clip:new(o and o.clip or nil)
  }
  
  setmetatable(t, self)
  self.__index = self
  
  t.sprocket = transport:new_sprocket({
    action  = function (pulses)
      local tick = math.floor(pulses / 24)
      t.playhead = tick % t.clip.length + 1
      local notes = t:play(tick)
      if t.id == selected_track then
        if #notes == 0 then
          for i,v in ipairs(played_notes) do
            played_notes[i] = nil 
          end
        else
          tabutil.update(played_notes, notes)
        end
      end
      grid_dirty = true
    end,
    division = 1/16,
    enabled = true
  })
  
  return t
end

return Track