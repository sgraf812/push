local recorders = { }
local mt = {
  __tostring = function(self)
    return "Property " .. self.name .. ": " .. tostring(self.__value)
  end,
  __call = function(self, nv)
    if nv ~= nil and nv ~= self.__value then
      self.__value = nv
      for p in pairs(self.__tos) do
        p(nv)
      end
    else
      if nv == nil then
        for r in pairs(recorders) do
          r(self)
        end
      end
    end
    return self.__value
  end,
  __index = {
    push_to = function(self, pushee)
      self.__tos[pushee] = pushee
      return function()
        self.__tos[pushee] = nil
      end
    end,
    peek = function(self)
      return self.__value
    end,
    writeproxy = function(self, proxy)
      return setmetatable({ }, {
        __tostring = function(t)
          return "(proxied) " .. tostring(self)
        end,
        __index = self,
        __call = function(t, nv)
          if nv ~= nil then
            return self(proxy(nv))
          else
            return self()
          end
        end
      })
    end
  }
}
local property
property = function(v, name)
  if name == nil then
    name = "<unnamed>"
  end
  return setmetatable({
    __value = v,
    __tos = { },
    name = name
  }, mt)
end
local record_pulls
record_pulls = function(f)
  local sources = { }
  local rec
  rec = function(p)
    sources[p] = p
  end
  recorders[rec] = rec
  local status, res = pcall(f)
  recorders[rec] = nil
  if not status then
    return false, res
  else
    return sources, res
  end
end
local readonly
readonly = function(self)
  return self:writeproxy(function(nv)
    return error("attempted to set readonly property '" .. tostring(self) .. "' with value " .. tostring(nv))
  end)
end
local computed
computed = function(reader, writer, name)
  if name == nil then
    name = "<unnamed>"
  end
  local p = property(nil, name)
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
      for f in pairs(newfroms) do
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
        if status then
          return res
        else
          return error(res)
        end
      end
    end)
  end
end
return (function()
  do
    local _with_0 = { }
    _with_0.property = property
    _with_0.name_of = name_of
    _with_0.readonly = readonly
    _with_0.computed = computed
    _with_0.record_pulls = record_pulls
    return _with_0
  end
end)()
