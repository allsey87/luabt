-- load module
luabt = require('luabt')

-- global location and target vectors
location = {x = 0, y = 0}
target = {x = 10, y = 10}

-- define a walker behavior tree
walker_root_node = {
   type = "sequence",
   children = {
      -- action leaf, print the current location to the output
      function()
         local str = string.format("location = %.2f, %.2f", location.x, location.y)
         print(str)
         return false, true -- (not running, success)
      end,
      {
         type = "selector",
         children = {
            -- condition leaf, is our location within a threshold of the target?
            function()
               if math.abs(location.x - target.x) < 0.005 and 
                  math.abs(location.y - target.y) < 0.005 then
                  return false, true -- (not running, success)
               else
                  return false, false -- (not running, fail)
               end
            end,
            -- action leaf, move towards target
            function()
               -- calculate error
               local err = {
                  x = target.x - location.x,
                  y = target.y - location.y,
               }
               -- move
               location.x = location.x + 1.5 * err.x
               location.y = location.y + 1.5 * err.y
               return true -- (running)
            end,
         }
      }
   }
}
 
-- instantiate a behavior tree
walker_bt = luabt.create(walker_root_node)

-- tick the behavior tree until it has finished (running == false)
while walker_bt() do end
