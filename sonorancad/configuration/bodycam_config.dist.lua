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

    -- The command name to toggle your body camera on or off.
    command="bodycam",

    -- Enables or disables animations on start up
    enableAnimation = true,

    -- Enables or disables the blinking body camera image on screen when enabled.
    enableOverlay = true,

    --[[ 
        The position (corner) of the screen where the body camera image is displayed.
    
        Options:
        - top-left
        - top-right
        - bottom-left
        - bottom-right
    ]]
    overlayLocation = 'top-right',

    -- Enables or disables the body camera beeping when turned on.
    enableBeeps = true,

    --[[
        Type of audio that the beeps use.
        
        native: GtaV Native Sounds

        nui/custom: Custom Sound File
    ]]
    beepType = "nui",

    -- Adjusts the frequency at which unit body camera beeps when turned on(in milliseconds).
    beepFrequency = 10000,

    -- Adjusts the range at which a person can hear the bodycam beeps
    beepRange = 19.99,

    -- Adjusts the frequency at which unit body cameras update (in milliseconds).
    screenshotFrequency=2000,

    -- The default keybind for toggling the bodycam.
    defaultKeybind="O",

    -- Automaticlly enable bodycam when lights are enabled / disabled
    autoEnableWithLights = true,

    -- Automaticlly enable bodycam when a weapon is drawn.
    autoEnableWithWeapons = true,

    -- Enable Clothing / Ped whitelist for bodycams.
    enableClothingWhitelist = false,

    -- Clothing / Peds that have bodycams.
    clothing = {
        { ped = "mp_m_freemode_01" },
        {
            ped = "mp_m_freemode_01",
            component=8,
            drawable=148,
            texture={2,4}
        }
    },

    -- Weapons that when drawn enable bodycam.
    weapons = {
        "weapon_pistol"
    }
}
if config.enabled then Config.RegisterPluginConfig(config.pluginName, config) end