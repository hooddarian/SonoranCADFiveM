--[[
    Sonoran Plugins

    Plugin Configuration

    Put all needed configuration in this file.

]]
local config = {
    enabled = true,
    pluginName = "bodycam", -- name your plugin here
    pluginAuthor = "digitalfire", -- author
    configVersion = "1.0",

    command="bodycam",
    enableAnimation = true,
    enableOverlay = true,
    overlayLocation = 'top-right',
    enableBeeps = true,
    beepType = "native", -- nui / custom
    beepFrequency = 10000,
    beepRange = 19.99,
    screenshotFrequency=2000,
    defaultKeybind="O",
    autoEnableWithLights = true,
    autoEnableWithWeapons = true,
    enableClothingWhitelist = false,
    clothing = {
        { ped = "mp_m_freemode_01" },
        {
            ped = "mp_m_freemode_01",
            component=8,
            drawable=148,
            texture={2,4}
        }
    },
    weapons = {
        "weapon_pistol"
    }
}
if config.enabled then Config.RegisterPluginConfig(config.pluginName, config) end