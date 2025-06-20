-- Track current state
local currentMotionSetting = nil
local currentPowerSource = nil

function updateAccessibilitySettings()
  local powerSource = hs.battery.powerSource()
  if powerSource == currentPowerSource then return end  -- no change, exit early

  currentPowerSource = powerSource
  local onBattery = (powerSource == "Battery Power")
  local desiredMotion = onBattery
  local changed = false

  if currentMotionSetting ~= desiredMotion then
    hs.execute("defaults write com.apple.universalaccess reduceMotion -bool " .. tostring(desiredMotion), true)
    currentMotionSetting = desiredMotion
    changed = true
  end

  if changed then
    hs.task.new("/usr/bin/killall", nil, function() return false end, { "Dock" }):start()
    hs.alert.show("Running on " .. (onBattery and "battery" or "AC"))
  end
end

-- Use older, compatible battery watcher
powerWatcher = hs.battery.watcher.new(updateAccessibilitySettings)
powerWatcher:start()

-- Run once at startup
updateAccessibilitySettings()