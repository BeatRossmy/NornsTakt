local Button = {}

function Button:key (x,y,z,shift)
  if self.x == x and self.y == y then
    self.state = z == 1
    if self.state then
      self[shift and "shift_action" or "action"]()
    end
  end
end

function Button:new (x, y, action, shift_action)
  b = {
    state = false,
    x = x,
    y = y,
    action = action or function () end,
    shift_action = shift_action or function () end
  }
  
  setmetatable(b, self)
  self.__index = self
  
  return b
end

function Button:show (grid)
  g:led(self.x,self.y,self.state and 15 or 5)
end

return Button