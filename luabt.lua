-- create a table for the module
local luabt = {}

-- define the create function
function luabt.create(node)
   -- execution node
   if type(node) == "function" then
      return node
   -- control flow node
   elseif type(node) == "table" then
      local children = {}
      -- recursively construct child nodes
      for index, child in ipairs(node.children) do
         children[index] = luabt.create(child)
      end
      if node.type == "negate" then
         -- return a negate decorator node
         return function()
            child = children[1]
            running, success = child()
            if running then
               return true
            else
               return false, not success
            end
         end
      elseif node.type == "sequence" then
         -- return a sequence control flow node
         return function()
            for index, child in ipairs(children) do
               running, success = child()
               if running then
                  return true -- child running
               elseif success == false then
                  return false, false -- child not running, failed
               end
            end
            return false, true -- not running, all children succeeded
         end
      elseif node.type == "sequence*" then
         -- return a sequence control flow node with memory
         local states = {}
         return function()
            for index, child in ipairs(children) do
               if states[index] == nil then
                  running, states[index] = child()
                  if running then
                     return true -- child running
                  elseif states[index] == false then
                     -- child failed, clear states and return the failure
                     states = {}
                     return false, false
                  end
               end
            end
            -- all children succeeded, clear states and return success
            states = {}
            return false, true
         end
      elseif node.type == "selector" then
         -- return a selector control flow node
         return function()
            for index, child in ipairs(children) do
               running, success = child()
               if running then
                  return true -- child running
               elseif success == true then
                  return false, true -- child not running, succeeded
               end
            end
            return false, false -- not running, all children failed
         end
      elseif node.type == "selector*" then
         -- return a selector control flow node with memory
         local states = {}
         return function()
            for index, child in ipairs(children) do
               if states[index] == nil then
                  running, states[index] = child()
                  if running then
                     return true -- child running
                  elseif states[index] == true then
                     -- child suceeded, clear states and return the success
                     states = {}
                     return false, true -- child not running, succeeded
                  end
               end
            end
            -- all children failed, clear states and return failure
            states = {}
            return false, false
         end
      end
   end
end

-- return the module
return luabt;
