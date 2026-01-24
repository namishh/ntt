T = {}

T.__index = T

function T.new()
  local self = setmetatable({}, T)
  self.passed = 0
  self.failed = 0

  return self
end

function T:test(name, fn)
  local ok, _ = pcall(fn)
  if ok then
    self.passed = self.passed + 1
    print("[TEST PASSED]: " .. name)
  else
    self.failed = self.failed + 1
    print("[TEST FAILED]: " .. name)
  end
end

function T.assertsEqual(expected, actual, msg)
  if expected ~= actual then
    error((msg or "Assertion failed") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
  end
end

function T:report()
  print()
  print(string.format("PASSED: %d", self.passed))
  print(string.format("FAILED: %d", self.failed))
  print(string.format("TOTAL:  %d", self.passed + self.failed))
end

function T.assertNotNil(value, msg)
  if value == nil then
    error((msg or "Assertion failed") .. ": expected non-nil value")
  end
end

return T
