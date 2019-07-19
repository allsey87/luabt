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
            return running, not success
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
      end
   end
end

-- return the module
return luabt;
