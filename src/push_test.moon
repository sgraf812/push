push = require "push"

do -- property
  p = push.property!
  assert p! == nil
  assert p.name == "<unnamed>"
  p = push.property "bar", "name"
  assert p! == "bar"
  assert p.name == "name"
  assert p("foo") == "foo"
  assert p! == "foo"

do -- readonly
  both = push.property!
  get = push.readonly both
  assert get! == nil
  assert both("foo") == "foo"
  assert get! == "foo"
  assert not pcall get, "bar"
  assert get! == "foo"

do -- subscribtion
  p = push.property!
  val = nil
  remove = p\push_to (nv) -> val = nv
  p("hi!")
  assert val == "hi!"
  remove!
  p("hello!")
  assert val == "hi!"

do -- record_pulls
  a = push.property true
  b = push.property 5
  unused = push.property!
  func = -> if a! then b! else unused!
  pulls, result = push.record_pulls func
  assert result == b!
  assert pulls[a] == a
  assert pulls[b] == b
  assert pulls[unused] == nil

do -- computed reader
  p = push.property 1
  run = 0
  c = push.computed -> 
    run += 1
    p! + 2
  -- assertions  
  check = (val, r) -> 
    assert c! == val, c!
    assert run == r, run
  check 3, 1
  check 3, 1 -- cached, not run again
  p(5)
  check 7, 2
  p(-4)
  check -2, 3

do -- computed reader updates
  a = push.property 5
  b = push.property true
  p = push.property 0
  run = 0
  c = push.computed ->
    if b! 
      run += 1
      return a! + 2
    return p\peek!
  -- assertions 
  check = (val, r) -> 
    assert c! == val, c!
    assert run == r, run
  check 7, 1
  b(false)
  check 0, 1
  p(1)
  check 0, 1
  a(134)
  check 0, 1
  b(true)
  check 136, 2
  b(false)
  check 1, 2
  assert not pcall push.computed, -> error "msg" -- computed reader throws

do -- computed writer
  first = push.property "john"
  last = push.property "doe"
  reader = -> first! .. " " .. last!
  writer = (nv) ->
    f, l = nv\gmatch("(%w+) (%w+)")!
    first f or ""
    last l or ""
    nv
  full = push.computed reader, writer
  changes = 0
  full\push_to (nv) -> changes += 1
  -- assertions 
  check = (val, c) -> 
    assert full! == val, full!
    assert changes == c, changes
  check "john doe", 0
  check full("mike foe"), 1
  first("john")
  check "john foe", 2
  full("asfd")
  assert first! == ""
  assert last! == ""

  print "All tests passed!"