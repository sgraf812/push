local push = require("push")
do
  local p = push.property()
  assert(p() == nil)
  assert(p.name == "<unnamed>")
  p = push.property("bar", "name")
  assert(p() == "bar")
  assert(p.name == "name")
  assert(p("foo") == "foo")
  assert(p() == "foo")
end
do
  local both = push.property()
  local get = push.readonly(both)
  assert(get() == nil)
  assert(both("foo") == "foo")
  assert(get() == "foo")
  assert(not pcall(get, "bar"))
  assert(get() == "foo")
end
do
  local p = push.property()
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
  local p = push.property(1)
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
  local a = push.property(5)
  local b = push.property(true)
  local p = push.property(0)
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
  local result, err = pcall(push.computed, function()
    return error("msg")
  end)
end
do
  local first = push.property("john")
  local last = push.property("doe")
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
