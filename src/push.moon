recorders = {}


mt = 
  __tostring: => "Property " .. @name .. ": " .. tostring(@__value)
  __call: (nv) =>
    if nv != nil and nv != @__value
      @__value = nv
      p nv for p in pairs @__tos
    else if nv == nil
      r @ for r in pairs recorders
    return @__value
  __index:
    push_to: (pushee) => 
      @__tos[pushee] = pushee
      return -> @__tos[pushee] = nil -- remover
    peek: => @__value
    writeproxy: (proxy) =>
      setmetatable {},
        __tostring: (t) -> "(proxied) " .. tostring @
        __index: @
        __call: (t, nv) -> 
          if nv != nil then @ proxy nv else @!


property = (v, name="<unnamed>") ->
  return setmetatable {
    __value: v
    __tos: {}
    :name
  }, mt


record_pulls = (f) ->
  sources = {}
  rec = (p) -> sources[p] = p
  recorders[rec] = rec
  status, res = pcall f
  recorders[rec] = nil
  if not status
    false, res
  else
    sources, res


readonly = => 
  @writeproxy (nv) ->
    error "attempted to set readonly property '" .. tostring(@) .. "' with value " .. tostring(nv)


computed = (reader, writer, name = "<unnamed>") ->
  p = property nil, name
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
      for f in pairs newfroms
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
      if status then res else error res

return with {}
  .property = property
  .name_of = name_of
  .readonly = readonly
  .computed = computed
  .record_pulls = record_pulls