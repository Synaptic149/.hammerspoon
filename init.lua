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
  local t0 = hs.timer.secondsSinceEpoch()
  print("[HSP] updateAccessibilitySettings: start", t0)

  local powerSource = hs.battery.powerSource()
  print("[HSP] powerSource:", tostring(powerSource), "dt:", hs.timer.secondsSinceEpoch() - t0)

  if powerSource == currentPowerSource then
    print("[HSP] No change, exit early", "dt:", hs.timer.secondsSinceEpoch() - t0)
    return
  end

  currentPowerSource = powerSource
  local onBattery = (powerSource == "Battery Power")
  local desiredMotion = onBattery
  local changed = false

  if currentMotionSetting ~= desiredMotion then
    print("[HSP] Changing reduceMotion...", "dt:", hs.timer.secondsSinceEpoch() - t0)
    hs.execute("defaults write com.apple.universalaccess reduceMotion -bool " .. tostring(desiredMotion), true)
    currentMotionSetting = desiredMotion
    changed = true
    print("[HSP] Changed reduceMotion", "dt:", hs.timer.secondsSinceEpoch() - t0)
  end

  print("[HSP] Changing dock magnification...", "dt:", hs.timer.secondsSinceEpoch() - t0)
  local mag = onBattery and "false" or "true"
  hs.execute("defaults write com.apple.dock magnification -bool " .. mag, true)
  print("[HSP] Changed dock magnification", "dt:", hs.timer.secondsSinceEpoch() - t0)

  if changed then
    hs.alert.show("Running on " .. (onBattery and "battery" or "AC"), 1.5)
  end

  print("[HSP] About to call killDockWhenNoFullscreen", "dt:", hs.timer.secondsSinceEpoch() - t0)
  killDockWhenNoFullscreen()
  print("[HSP] Finished updateAccessibilitySettings", "dt:", hs.timer.secondsSinceEpoch() - t0)
end

-- Use older, compatible battery watcher
powerWatcher = hs.battery.watcher.new(updateAccessibilitySettings)
powerWatcher:start()

-- Run once at startup
updateAccessibilitySettings()