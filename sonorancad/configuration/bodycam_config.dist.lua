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

    -- Changes the command used to enable bodycam.
    command="bodycam",

    -- Enables / Disables animations.
    enableAnimation = true,

    -- Enables / Disables the overlay.
    enableOverlay = true,

    -- The Overylay Location in CSS Style.
    overlayLocation = 'top-right',

    --[[
        Native or NUI Sounds.
        
        Native uses GTAv Audios. *CAN NOT CHANGE VOLUME*

        NUI uses Custom Streamed Sound.
    ]]
    soundType = "native",

    -- Enable / Disable Beeps.
    enableBeeps = true,

    --[[
        Beep Frequancy

        How Often beeps happen.
    ]]
    beepFreq = 10000,

    --[[
        Beep Range

        How far people can hear it.
    ]] 
    beepRange = 19.99,

    --[[
        Default Keybind Settings

        For More Info Checkout

        https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/

    ]]
    defaultKeyMapper="keyboard",
    defaultKeyParameter="O",

    --[[
        Turn Bodycam on

        with Lights in Police Vehicles.
    ]]
    autoEnableWithLights = true,

    --[[
        Turn on Bodycam when

        weapon is drawn.
    ]]
    autoEnableWithWeapons = true,

    --[[
        Forces to use clothing 

        to enable BodyCam.
    ]]
    enableWhitelist = false,

    --[[
        Clothing for

        enableWhitelist

        as well as animations.
    ]]
    clothing = {
        { ped = "mp_m_freemode_01" },
        {
            ped = "mp_m_freemode_01",
            component=8,
            drawable=148,
            texture={2,4}
        }
    },

    --[[
        Weapons supported

        for autoEnableWithWeapons.
    ]]
    weapons = {
        "weapon_pistol"
    }
}
if config.enabled then Config.RegisterPluginConfig(config.pluginName, config) end