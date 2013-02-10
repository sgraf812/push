module("push", package.seeall)
Property = setmetatable({ }, {
  __call = function(t, v, name)
    if name == nil then
      name = "<unnamed>"
    end
    return setmetatable({
      __value = v,
      __tos = { },
      __name = name
    }, t.__mt)
  end
})
Property.__recorders = { }
Property.__mt = {
  __tostring = function(t)
    return t.__name .. ": " .. tostring(t.__value)
  end,
  __call = function(self, nv)
    if nv ~= nil and nv ~= self.__value then
      self.__value = nv
      for p in pairs(self.__tos) do
        p(nv)
      end
    else
      if nv == nil then
        for r in pairs(Property.__recorders) do
          r(self)
        end
      end
    end
    return self.__value
  end,
  __index = {
    push_to = function(p, pushee)
      p.__tos[pushee] = pushee
      return function()
        p.__tos[pushee] = nil
      end
    end,
    peek = function(p)
      return p.__value
    end,
    writeproxy = function(p, proxy)
      return setmetatable({ }, {
        __tostring = function(t)
          return tostring(p)
        end,
        __index = p,
        __call = function(self, nv)
          if nv ~= nil then
            return p(proxy(nv))
          else
            return p()
          end
        end
      })
    end
  }
}
record_pulls = function(f)
  local sources = { }
  local rec
  rec = function(p)
    return table.insert(sources, p)
  end
  Property.__recorders[rec] = rec
  local status, res = pcall(f)
  Property.__recorders[rec] = nil
  if not status then
    return false, res
  else
    return sources, res
  end
end
readonly = function(p)
  return p:writeproxy(function(nv)
    return error("attempted to set readonly property '" .. tostring(p) .. "' with value " .. tostring(nv))
  end)
end
computed = function(reader, writer, name)
  if name == nil then
    name = "<unnamed>"
  end
  local p = Property(nil, name)
  p.__froms = { }
  local update
  update = function()
    if not p.__updating then
      p.__updating = true
      local newfroms, res = record_pulls(reader)
      if not newfroms then
        p.__updating = false
        error(res)
      end
      for f, remover in pairs(p.__froms) do
        if not newfroms[f] then
          p.__froms[f] = nil
          remover()
        end
      end
      local _list_0 = newfroms
      for _index_0 = 1, #_list_0 do
        local f = _list_0[_index_0]
        if not p.__froms[f] then
          p.__froms[f] = f:push_to(update)
        end
      end
      p(res)
      p.__updating = false
    end
  end
  update()
  if not writer then
    return readonly(p)
  else
    return p:writeproxy(function(nv)
      if not p.__updating then
        p.__updating = true
        local status, res = pcall(writer, nv)
        p.__updating = false
        if not status then
          error(res)
        end
        return res
      end
    end)
  end
end
do
  local p = push.Property()
  assert(p() == nil)
  assert(p("foo") == "foo")
  assert(p() == "foo")
end
do
  local both = push.Property()
  local get = readonly(both)
  assert(get() == nil)
  assert(both("foo") == "foo")
  assert(get() == "foo")
  assert(not pcall(get, "bar"))
  assert(get() == "foo")
end
do
  local p = push.Property()
  local val = nil
  local remove = p:push_to(function(nv)
    val = nv
  end)
  p("hi!")
  assert(val == "hi!")
  remove()
  p("hello!")
  assert(val == "hi!")
end
do
  local p = push.Property(1)
  local run = 0
  local c = push.computed(function()
    run = run + 1
    return p() + 2
  end)
  assert(c() == 3)
  assert(run == 1)
  assert(c() == 3)
  assert(run == 1)
  p(5)
  assert(c() == 7)
  assert(run == 2)
  p(-4)
  assert(c() == -2)
  assert(run == 3)
end
do
  local a = push.Property(5)
  local b = push.Property(true)
  local p = push.Property(0)
  local run = 0
  local c = push.computed(function()
    if b() then
      run = run + 1
      return a() + 2
    end
    return p:peek()
  end)
  local check
  check = function(val, r)
    assert(c() == val, c())
    return assert(run == r, run)
  end
  check(7, 1)
  b(false)
  check(0, 1)
  p(1)
  check(0, 1)
  a(134)
  check(0, 1)
  b(true)
  check(136, 2)
  b(false)
  check(1, 2)
end
do
  local first = push.Property("john")
  local last = push.Property("doe")
  local reader
  reader = function()
    return first() .. " " .. last()
  end
  local writer
  writer = function(nv)
    local f, l = nv:gmatch("(%w+) (%w+)")()
    first(f or "")
    last(l or "")
    return nv
  end
  local full = push.computed(reader, writer)
  local changes = 0
  full:push_to(function(nv)
    changes = changes + 1
  end)
  assert(full() == "john doe")
  assert(changes == 0, changes)
  assert(full("mike foe") == "mike foe")
  assert(changes == 1, changes)
  first("john")
  assert(full() == "john foe")
  assert(changes == 2, changes)
  full("asfd")
  assert(first() == "")
  return assert(last() == "")
end
