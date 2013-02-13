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
  local a = push.property(true)
  local b = push.property(5)
  local unused = push.property()
  local func
  func = function()
    if a() then
      return b()
    else
      return unused()
    end
  end
  local pulls, result = push.record_pulls(func)
  assert(result == b())
  assert(pulls[a] == a)
  assert(pulls[b] == b)
  assert(pulls[unused] == nil)
end
do
  local p = push.property(1)
  local run = 0
  local c = push.computed(function()
    run = run + 1
    return p() + 2
  end)
  local check
  check = function(val, r)
    assert(c() == val, c())
    return assert(run == r, run)
  end
  check(3, 1)
  check(3, 1)
  p(5)
  check(7, 2)
  p(-4)
  check(-2, 3)
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
  assert(not pcall(push.computed, function()
    return error("msg")
  end))
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
  local check
  check = function(val, c)
    assert(full() == val, full())
    return assert(changes == c, changes)
  end
  check("john doe", 0)
  check(full("mike foe"), 1)
  first("john")
  check("john foe", 2)
  full("asfd")
  assert(first() == "")
  assert(last() == "")
  return print("All tests passed!")
end
