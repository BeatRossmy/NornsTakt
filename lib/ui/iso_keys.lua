local tabutil = require("tabutil")

local iso_keys = {}

function iso_keys:calc_note (x,y)
  local row = self.area.h - y + (self.area.y - 1)
  local col = x - self.area.x
  local note = self.root + row * self.interval + col
  return note
end

function iso_keys:in_area (x,y)
  local in_cols = x >= self.area.x and x < self.area.x + self.area.w
  local in_rows = y >= self.area.y and y < self.area.y + self.area.h
  return in_cols and in_rows
end

function iso_keys:key (x,y,z)
  if self:in_area(x,y) ~= true then
    return
  end
  local note = self:calc_note(x,y)
  if z==1 then
    self.notes[note] = {
      note = note,
      x = x,
      y = y
    }
    self.note_on(note, 100)
  else
    self.notes[note] = nil
    self.note_off(note, 0)
  end
end

function iso_keys:draw (g, notes)
  notes = notes == nil and {} or notes
  
  for x = self.area.x, self.area.x + self.area.w - 1 do
    for y = self.area.y, self.area.y + self.area.h - 1 do
      local note = self:calc_note(x,y)
      local l = note % 12 == 0 and 6 or 3
      l = tabutil.contains(notes,note) and 10 or l
      g:led(x, y, l)
    end
  end
  for _, note in pairs(self.notes) do
    g:led(note.x, note.y, 15)
  end
end

function iso_keys:new (x,y,w,h,r,i)
  i = {
    mode = "isometric",
    notes = {},
    area = {
      x = x or 1,
      y = y or 1,
      w = w or 16,
      h = h or 8
    },
    root = 60 or r,
    interval = 5 or i,
    note_on = function (note, velocity) end,
    note_off = function (note, velocity) end,
  }
  
  setmetatable(i, self)
  self.__index = self
  
  return i
end

return iso_keys