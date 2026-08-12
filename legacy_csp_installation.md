# Legacy CSP Installation

If you want to use this dashboard without updating to the latest version of Custom Shaders Patch (CSP), some additional steps may be required.
> [IMPORTANT!]\
> CSP updates can overwrite modified Android Auto files. Back up your working `extension/lua/cars/android_auto/` folder before updating CSP or Content Manager.

## Why?

This project modifies CSP's built-in Android Auto system to support the custom split-screen dashboard. Updating CSP can overwrite these modifications with a newer `system.lua`.

Issues encountered after updating CSP have included:

* `system.getApp()` becoming unavailable after the modified `system.lua` was overwritten.
* Custom `widget.lua` support being removed from app registration.
* Missing app properties such as `statusPriority`, causing Android Auto to crash.
* Other changes to CSP's Android Auto framework conflicting with the dashboard modifications.

If you want to remain on an older CSP version, you can manually add the required dashboard functionality to your existing `system.lua`.

---

## 1. Add the Dashboard Helper Functions

Open:

```text
assettocorsa/extension/lua/cars/android_auto/system.lua
```

Find:

```lua
local apps = {}
```

Add the following helper functions somewhere after the app system has been initialized:

```lua
function system.getApp(appID)
  return table.findFirst(apps, function (app)
    return app.id == appID
  end)
end

function system.getWidgetApps()
  return table.filter(apps, function (app)
    return app.widget ~= nil
  end)
end
```

These allow the Dashboard to find other Android Auto apps and access their widget implementations.

---

## 2. Add Widget Support to `local app = { ... }`

In `system.lua`, find the app registration function:

```lua
function system.addApp(...)
```

Inside it, locate:

```lua
local app = {
```

The app table should include support for `widget.lua` as well as the normal CSP app properties.

Make sure it contains:

```lua
local app = {
  id = appID,
  name = manifest:get('ABOUT', 'NAME', appID),

  displays = manifest:get(
    'SCRIPTABLE_DISPLAY',
    'DISPLAY',
    ac.INIConfig.OptionalList
  ),

  dynamicTextures = manifest:get(
    'DYNAMIC_TEXTURE',
    'RENDERING_CAMERA',
    ac.INIConfig.OptionalList
  ),

  icon = appFolderPath..'/icon.png',

  main = io.fileExists(appFolderPath..'/app.lua')
    and appFolder..'/app'
    or nil,

  widget = io.fileExists(appFolderPath..'/widget.lua')
    and appFolder..'/widget'
    or nil,

  status = io.fileExists(appFolderPath..'/status.lua')
    and appFolder..'/status'
    or nil,

  statusPriority = manifest:get(
    'STATUS',
    'BASE_PRIORITY',
    0
  ),

  notificationPriority = manifest:get(
    'NOTIFICATIONS',
    'PRIORITY',
    0
  ),
}
```


Do **not** remove existing properties from your CSP version's `local app` table. If your version contains additional fields, keep them and only add the `widget` property.

## 3. Install the Dashboard

After modifying `system.lua`, install the dashboard files normally into the Android Auto apps directory:

```text
assettocorsa/extension/lua/cars/android_auto/apps/
```

Then restart Assetto Corsa.

If Android Auto stops working after an update, reinstall the dashboard or manually reapply the changes above to the newly installed `system.lua`.
