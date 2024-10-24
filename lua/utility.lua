--- @generic V
--- @generic K
--- @param tables {[K]: V}[]
--- @return {[K]: V}
local function mergeTables(tables)
    local res = {}
    for _, t in pairs(tables) do
        for k, v in pairs(t) do
            res[k] = v
        end
    end

    return res
end

--- Doubly linked list based queue
--- @class Queue
--- @field private first any
--- @field private last any
--- @field private size integer
local Queue = {}

--- @return Queue
function Queue:new()
    local mt = { size = 0 }
    setmetatable(mt, self)
    self.__index = self
    self.__len = function (tbl) return tbl.size end
    return mt
end

--- @param item any
function Queue:enqueue(item)
    if self.size == 0 then
        self.first = { val = item }
        self.last = self.first
    else
        self.last.next = { val = item, prev = self.last }
        self.last = self.last.next
    end
    
    self.size = self.size + 1
end

--- @return any
function Queue:dequeue()
    local val = self.first.val
    self.first = self.first.next

    self.size = self.size - 1
    return val
end

return {mergeTables = mergeTables, Queue = Queue}
