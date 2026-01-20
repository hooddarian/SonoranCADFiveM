--[[
    Sonoran Plugins

    Plugin Configuration

    Put all needed configuration in this file.
]]
local config = {
    enabled = true,
    pluginName = "callcommands", -- name your plugin here
    pluginAuthor = "SonoranCAD", -- author
    configVersion = "2.3",
    -- put your configuration options below
    callTypes = {
        {
            command = "911",
            isEmergency = true,
            suggestionText = "Sends a emergency call to your SonoranCAD",
            descriptionPrefix = ""
        }, {
            command = "311",
            isEmergency = false,
            suggestionText = "Sends a non-emergency call to your SonoranCAD",
            descriptionPrefix = "(311)"
        }, {
            command = "511",
            isEmergency = true,
            suggestionText = "Sends a call for a towing service.",
            descriptionPrefix = "(511)"
        }
    },
    enablePanic = true,
    -- adds an emergency call when panic button is pressed
    addPanicCall = true,

    usePositionForMetadata = false,
    useCallLocation = false, -- If true, the postal of the call with be used as the call location. If false, the player's current postal will be used.

    --[[
        notifyMethod: how should the caller be notified?
            none: disable notification
            auto: Will automatically detect the system to use
            chat: Sends a message in chat
            pnotify: Uses pNotify to show a notification
            ox_lib: Uses ox_lib to show a notification
            lation_ui: Uses lation_ui to show a notification
    ]]
    callerNotifyMethod = "auto",
}

if config.enabled then Config.RegisterPluginConfig(config.pluginName, config) end