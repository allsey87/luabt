# A behavior tree based on Lua closures

## Description
This repository provides an implementation of a behavior tree based on [Lua closures](https://www.lua.org/pil/6.1.html). The module consists of a single file: [luabt.lua](luabt.lua), which when loaded returns a single table, containing a single function called `create`.

When provided with a description of a behavior tree, the `create` function will recursively build a closure-based behavior tree that can be ticked by executing it. The description of a behavior tree is represented by a table that specifies the nodes and their arrangement. All nodes can return up to two boolean values. The first returned boolean value indicates whether or not the node is currently running. The second boolean, which is only valid if the first boolean is false, indicates whether the node succeeded or failed. There are three types of nodes: leaf nodes, decorator nodes, and composite nodes. Leaf nodes are represented as functions (or closures) which typically either test conditions or execute actions. Decorator nodes are nodes with a single child and implement unary logic operations such as negation. 

Composite nodes consist of child nodes and an execution policy. There are two types of composite nodes: selector and sequence. The execution policy of the selector node is such that it passes its tick sequentially to each child node until it finds a child that is running or that has succeeded. If such a child is found, then the selector node returns the state of this child to its parent. If all children have finished running and have failed, the selector node also returns failed. The execution policy of the sequence node is such that it passes its tick sequentially to each of its children until it finds a child that is running or that has failed. If such a child is found, then the sequence node returns the state of this child to its parent. If all children have finished running and have succeeded, the sequence node also returns success. There is a variant on the selector and sequence composite nodes named selector\* and sequence\*. These nodes remember the state of their children for the next tick when a child returns running. Once the sequence\* node finds a child that fails and is about to return failed to its parent (or conversely, once the selector node finds a child that succeeds and is about to return success to its parent), the states of the children are reset and node will attempt to rerun the first child next time it is ticked.

Internally, composite nodes use [ipairs](https://pgl.yoyo.org/luai/i/ipairs) to iterate over their children. For this reason, it is recommended not to explicitly set the keys in the tables and to allow Lua to assign them automatically (i.e., 1, 2, ... n).

### Basic Example
A basic example is provided in [basic_example.lua](basic_example.lua). It can be run by issuing the command, `lua basic_example.lua`. This example shows how an agent can approach a target location in a two-dimensional plane.

```lua
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
      end,
      {
         type = "selector",
         children = {
            -- condition leaf, is our location within a threshold of the target?
            function()
               if math.abs(location.x - target.x) < 0.005 and 
                  math.abs(location.y - target.y) < 0.005 then
                  return false, true
               else
                  return false, false
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
               return true
            end,
         }
      }
   }
}
 
-- instantiate a behavior tree
walker_bt = luabt.create(walker_root_node)

-- tick the behavior tree until it has finished (running == false)
while walker_bt() do end
```

### Advanced Example
The example in [advanced_example.lua](advanced_example.lua) demonstrates the use of the sequence\* node to remember the state of its children. Note that the nodes created by create\_timer\_node are non-blocking. This example also demonstrates the use of local memory via closures. The function create\_timer\_node creates the local variable _timer_ which alongside the parameter _seconds_, are used as upvalues for the returned closure. The closure then uses _timer_ and _seconds_ to set/reset the timer and to determine when to return running or not running and success.

```lua
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
```
