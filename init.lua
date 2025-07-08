-- Track current state
local currentMotionSetting = nil
local currentPowerSource = nil

-- Helper function to check if any app is in fullscreen mode
function hasFullscreenApp()
  local allWindows = hs.window.allWindows()
  for _, window in pairs(allWindows) do
    if window:isFullScreen() then
      return true
    end
  end
  return false
end

-- Helper function to wait for no fullscreen apps and then kill dock
function killDockWhenNoFullscreen()
  if hasFullscreenApp() then
    -- Check again in 15 seconds
    hs.timer.doAfter(15, killDockWhenNoFullscreen)
  else
    -- No fullscreen apps, safe to kill dock
    hs.task.new("/usr/bin/killall", nil, function() return false end, { "Dock" }):start()
  end
end

function updateAccessibilitySettings()
  local powerSource = hs.battery.powerSource()
  if powerSource == currentPowerSource then return end  -- no change, exit early

  currentPowerSource = powerSource
  local onBattery = (powerSource == "Battery Power")
  local desiredMotion = onBattery
  local changed = false

  -- Update motion settings if needed
  if currentMotionSetting ~= desiredMotion then
    hs.execute("defaults write com.apple.universalaccess reduceMotion -bool " .. tostring(desiredMotion), true)
    currentMotionSetting = desiredMotion
    changed = true
  end

  -- Always update dock magnification
  local mag = onBattery and "false" or "true"
  hs.execute("defaults write com.apple.dock magnification -bool " .. mag, true)

  if changed then
    hs.alert.show("Running on " .. (onBattery and "battery" or "AC"), 1.5)
  end
  
  -- Only restart dock once after all settings are updated
  killDockWhenNoFullscreen()
end

-- Use older, compatible battery watcher
powerWatcher = hs.battery.watcher.new(updateAccessibilitySettings)
powerWatcher:start()

-- Run once at startup
updateAccessibilitySettings()