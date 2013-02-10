module "push", package.seeall

export Property, readonly, record_pulls, computed


Property = setmetatable {}, 
  __call: (t, v, name="<unnamed>") ->
    return setmetatable {
      __value: v
      __tos: {}
      __name: name
    }, t.__mt


Property.__recorders = {}
Property.__mt = 
  __tostring: (t) -> "Property " .. t.__name .. ": " .. tostring(t.__value)
  __call: (nv) =>
    if nv != nil and nv != @__value
      @__value = nv
      p nv for p in pairs @__tos
    else if nv == nil
      r @ for r in pairs Property.__recorders
    return @__value
  __index: 
    push_to: (p, pushee) -> 
      p.__tos[pushee] = pushee
      return -> p.__tos[pushee] = nil -- remover
    peek: (p) -> p.__value
    writeproxy: (p, proxy) ->
      setmetatable {},
        __tostring: (t) -> "(proxied) " .. tostring p
        __index: p
        __call: (nv) => 
          if nv != nil then p proxy nv else p!


record_pulls = (f) ->
  sources = {}
  rec = (p) -> table.insert sources, p
  Property.__recorders[rec] = rec
  status, res = pcall f
  Property.__recorders[rec] = nil
  if not status
    false, res
  else
    sources, res


readonly = (p) -> 
  p\writeproxy (nv) ->
    error "attempted to set readonly property '" .. tostring(p) .. "' with value " .. tostring(nv)


computed = (reader, writer, name = "<unnamed>") ->
  p = Property nil, name
  p.__froms = {}
  update = ->
    if not p.__updating
      p.__updating = true
      newfroms, res = record_pulls reader
      if not newfroms
        p.__updating = false
        error res
      -- remove redundant sources
      for f, remover in pairs p.__froms
        if not newfroms[f]
          p.__froms[f] = nil
          remover!
      -- add Property sources
      for f in *newfroms
        if not p.__froms[f]
          p.__froms[f] = f\push_to update
      p res
      p.__updating = false

  update!
  if not writer then readonly p else p\writeproxy (nv) ->
    if not p.__updating
      p.__updating = true
      status, res = pcall writer, nv
      p.__updating = false
      if not status
        error res
      res


do -- simple
  p = push.Property!
  assert p! == nil
  assert p("foo") == "foo"
  assert p! == "foo"

do -- restricted
  both = push.Property!
  get = readonly both
  assert get! == nil
  assert both("foo") == "foo"
  assert get! == "foo"
  assert not pcall get, "bar"
  assert get! == "foo"

do -- subscribtion
  p = push.Property!
  val = nil
  remove = p\push_to (nv) -> val = nv
  p("hi!")
  assert val == "hi!"
  remove!
  p("hello!")
  assert val == "hi!"

do -- computed reader
  p = push.Property 1
  run = 0
  c = push.computed -> 
    run += 1
    p! + 2
  assert c! == 3
  assert run == 1
  assert c! == 3 -- cached
  assert run == 1
  p(5)
  assert c! == 7
  assert run == 2 
  p(-4)
  assert c! == -2
  assert run == 3 

do -- computed reader updates sources
  a = push.Property 5
  b = push.Property true
  p = push.Property 0
  run = 0
  c = push.computed ->
    if b! 
      run += 1
      return a! + 2
    return p\peek!
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


do -- computed writer
  first = push.Property "john"
  last = push.Property "doe"
  reader = -> first! .. " " .. last!
  writer = (nv) ->
    f, l = nv\gmatch("(%w+) (%w+)")!
    first f or ""
    last l or ""
    nv
  full = push.computed reader, writer
  changes = 0
  full\push_to (nv) -> changes += 1
  
  assert full! == "john doe"
  assert changes == 0, changes
  assert full("mike foe") == "mike foe"
  assert changes == 1, changes
  first("john")
  assert full! == "john foe"
  assert changes == 2, changes
  full("asfd")
  assert first! == ""
  assert last! == ""