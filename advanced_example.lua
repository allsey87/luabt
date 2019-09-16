-- load module
luabt = require('luabt')

function create_timer_node(seconds)
   local timer = nil
   return function()
      if timer == nil then
         -- reset the timer
         timer = os.clock() + seconds
      end
      -- has the timer expired?
      if os.clock() > timer then
         -- reset timer for next time
         timer = nil
         return false, true
      else
         return true
      end
   end
end

-- define a memory behavior tree
timer_root_node = {
   type = "sequence*",
   children = {
      function()
         print("waiting for one second...")
         return false, true
      end,
      create_timer_node(1),
      function()
         print("waiting for three seconds...")
         return false, true
      end,
      create_timer_node(3),
      function()
         print("waiting for two seconds...")
         return false, true
      end,
      create_timer_node(2),
   }
}
 
-- instantiate a behavior tree
timer_bt = luabt.create(timer_root_node)

-- tick the behavior tree until it has finished (running == false)
while timer_bt() do end
