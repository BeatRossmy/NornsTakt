tabutil = require("tabutil")

local Condition = {
  label = "1:1",
  A = 1,
  B = 1,
  NOT = false,
  evaluate = function (self, a)
    return (a % self.B) == (self.A - 1)
  end
}

function Condition:new (l,a,b,n)
  o = {}
  o.label = l
  o.A = a
  o.B = b
  o.NOT = n
  setmetatable(o, self)
  self.__index = self
  return o
end

CONDITIONS = {}

for b=1, 8 do
  for a=1, b do
   table.insert(CONDITIONS, Condition:new(a..":"..b,a,b,false));
  end
end

local Step = {}

function Step:poly (notes)
  return type(notes) ~= "table" and {} or notes
end

function Step:random (notes)
  notes = type(notes) ~= "table" and {} or notes
  return {notes[math.random(1,#notes)]}
end

function Step:play (tick, loop_length)
  if #self.notes == 0 then
    return
  end
  
  local played_notes = {}
  
  -- CONDITION
  local A = math.floor(tick / loop_length)
  local trig = CONDITIONS[self.condition]:evaluate(A)
  if not trig then return played_notes end
  
  local notes = self[self.mode](self, self.notes)
  local duration = clock.get_beat_sec()/4
  
  if math.random() < self.probability then
    for _,note in ipairs(notes) do
      --local hz = musicutil.note_num_to_freq(note)
      --engine.hz(hz)
      --mxsynths:play({synth="piano",note=note,velocity=80,attack=0.1,release=0.1})
      engine.mx_note_on(note,100/127,duration)
    end
    played_notes = notes
  end
  
  return played_notes
end

function Step:add_note (note)
  local key = tabutil.key(self.notes,note)
  if key == nil then
    table.insert(self.notes,note)
  else
    table.remove(self.notes,key)
  end
  print("notes",#self.notes)
end

function Step:new (o)
  s = {
    notes = {},
    mode = "poly",
    condition = 1,
    probability = 1,
    fill = false,
    pitch_offset = 0,
    pitch_offset_increment = 1,
    pitch_offset_chance = 0,
    retrig_interval = 0.25,
    retrig_chance = 0
  }
  if o then
    tabutil.update(s,o)
    s.notes = {}
    for i,n in ipairs(o.notes) do
      s.notes[i] = n
    end
  end
  setmetatable(s, self)
  self.__index = self
  return s
end

return Step