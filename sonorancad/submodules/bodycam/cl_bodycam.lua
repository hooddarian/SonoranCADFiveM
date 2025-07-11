isOn = false
doAnimation = true
screenshotFreq = 2000
soundPercent = 30
CreateThread(function()
    Config.LoadPlugin("bodycam", function(pluginConfig)
        if pluginConfig.enabled then
            function isWearingBodycam()
                local ped = PlayerPedId()
                local pedModel = GetEntityModel(ped)
                -- Allow all if clothing table is empty or nil
                if not pluginConfig.clothing or #pluginConfig.clothing == 0 then
                    return true
                end
                for _, item in ipairs(pluginConfig.clothing) do
                    if not item.ped or pedModel == GetHashKey(item.ped) then
                        if item.component and item.drawable then
                            local compDrawable = GetPedDrawableVariation(ped, item.component)
                            if compDrawable == item.drawable then
                                if item.texture then
                                    local compTexture = GetPedTextureVariation(ped, item.component)
                                    for _, tex in ipairs(item.texture) do
                                        if compTexture == tex then
                                            return true
                                        end
                                    end
                                else
                                    return true
                                end
                            end
                        elseif item.component then
                            return true
                        elseif item.ped then
                            return true
                        end
                    end
                end
                return false
            end

            function PlaySound()
                if pluginConfig.soundType == 'native' then
                    TriggerServerEvent('SonoranCAD::bodycam::RequestSound')
                    local coord = GetEntityCoords(GetPlayerPed(PlayerId()))
                    PlaySoundFromCoord(-1, 'Beep_Red', coord.x, coord.y, coord.z,
                        'DLC_HEIST_HACKING_SNAKE_SOUNDS', false, 0, false)
                    Wait(pluginConfig.beepFreq)
                else
                    TriggerServerEvent('SonoranCAD::bodycam::RequestSound')
                    SendNUIMessage({
                        type = 'playSound',
                        transactionFile = 'sounds/beeps.mp3',
                        transactionVolume = (soundPercent / 100)
                    })
                    Wait(pluginConfig.beepFreq)
                end
            end

            doAnimation = pluginConfig.enableAnimation
            AddEventHandler('playerSpawned', function()
                TriggerServerEvent('SonoranCAD::bodycam::Request')
            end)
            TriggerEvent('chat:addSuggestion', '/' .. pluginConfig.command, '',
                { { name = "[freq|sound|anim]", help = "Subcommand" } })
            RegisterCommand('SonoranCAD::bodycam::Keybind', function()
                TriggerEvent('SonoranCAD::bodycam::Toggle', true)
            end, false)
            RegisterKeyMapping('SonoranCAD::bodycam::Keybind', "Toggle BodyCam", pluginConfig.defaultKeyMapper,
                pluginConfig.defaultKeyParameter)

            CreateThread(function()
                while pluginConfig.autoEnableWithWeapons do
                    Wait(1)
                    local ped = PlayerPedId()
                    local weapon = GetSelectedPedWeapon(ped)
                    if not isOn and pluginConfig.weapons then
                        for _, weaponName in ipairs(pluginConfig.weapons) do
                            if weapon == GetHashKey(weaponName) then
                                if pluginConfig.enableWhitelist then
                                    if isWearingBodycam() then
                                        TriggerEvent('SonoranCAD::bodycam::Toggle', false)
                                    end
                                else
                                    TriggerEvent('SonoranCAD::bodycam::Toggle', false)
                                end
                                break
                            end
                        end
                    end
                end
            end)

            CreateThread(function()
                while pluginConfig.autoEnableWithLights do
                    Wait(1)
                    local ped = PlayerPedId()
                    local veh = GetVehiclePedIsIn(ped, false)
                    -- Only check if player is in a vehicle and is the driver
                    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped and GetVehicleClass(veh) == 18 then
                        if IsVehicleSirenOn(veh) then
                            if not isOn then
                                TriggerEvent('SonoranCAD::bodycam::Toggle', false)
                            end
                        else
                            if isOn then
                                TriggerEvent('SonoranCAD::bodycam::Toggle', false)
                            end
                        end
                    end
                end
            end)

            CreateThread(function()
                while true do
                    Wait(1)
                    if isOn then
                        TriggerServerEvent('SonoranCAD::bodycam::TakeScreenshot')
                        Wait(screenshotFreq)
                    end
                end
            end)

            CreateThread(function()
                while true do
                    Wait(1)
                    if pluginConfig.enableBeeps then
                        if isOn then PlaySound() end
                    end
                end
            end)

            RegisterNetEvent('SonoranCAD:bodycam::Animation', function()
                if doAnimation then
                    doAnimation = false
                else
                    doAnimation = true
                end
            end)

            RegisterNetEvent('SonoranCAD::bodycam::GiveSound', function(serverId, serverCoords)
                if GetPlayerFromServerId(serverId) ~= PlayerId() and GetDistanceBetweenCoords(GetEntityCoords(GetPlayerPed(PlayerId())), serverCoords, true) < pluginConfig.beepRange then
                    if pluginConfig.soundType == "native" then
                        PlaySoundFromCoord(-1, 'Beep_Red', serverCoords.x, serverCoords.y, serverCoords.z,
                            'DLC_HEIST_HACKING_SNAKE_SOUNDS', false, 0, false)
                    else
                        SendNUIMessage({
                            type = 'playSound',
                            transactionFile = 'sounds/beeps.mp3',
                            transactionVolume = (soundPercent / 100)
                        })
                    end
                end
            end)

            RegisterNetEvent('SonoranCAD::bodycam::Init', function(isReady, apiVersion)
                if isReady == 0 then
                    CreateThread(function()
                        debugLog('Bodycam not ready, retrying in 10s')
                        Wait(10000)
                        TriggerServerEvent('SonoranCAD::bodycam::Request')
                    end)
                    return
                end
                if apiVersion ~= -1 then
                    Config.apiVersion = apiVersion
                end
                RegisterNetEvent('SonoranCAD::bodycam::Toggle', function(manualActivation)
                    if pluginConfig.enableWhitelist and not isWearingBodycam() then
                        TriggerEvent('chat:addMessage',
                            { args = { 'Sonoran Bodycam', 'You must be wearing a bodycam to activate it.' } })
                        return
                    end

                    if manualActivation and doAnimation and isWearingBodycam() then
                        local ped = PlayerPedId()
                        RequestAnimDict("clothingtie")
                        while not HasAnimDictLoaded("clothingtie") do
                            Wait(10)
                        end
                        TaskPlayAnim(ped, "clothingtie", "outro", 8.0, 2.0, 1880, 51, 2.0, false, false, false)
                        Wait(1880)
                    end

                    if isOn then
                        isOn = false
                        if pluginConfig.enableOverlay then
                            SendNUIMessage({
                                type = 'toggleGif',
                                location = pluginConfig.overlayLocation
                            })
                        end
                        TriggerServerEvent('SonoranCAD::core::bodyCamOff')
                        TriggerEvent('chat:addMessage',
                            { args = { 'Sonoran Bodycam', 'Bodycam disabled' } })
                        PlaySound()
                    else
                        isOn = true
                        if pluginConfig.enableOverlay then
                            SendNUIMessage({
                                type = 'toggleGif',
                                location = pluginConfig.overlayLocation
                            })
                        end
                        TriggerEvent('chat:addMessage',
                            { args = { 'Sonoran Bodycam', 'Bodycam enabled' } })
                        PlaySound()
                    end
                end)
                RegisterNetEvent('SonoranCAD::bodycam::SetFreq', function(freq)
                    if freq then
                        freq = tonumber(freq)
                        if not freq or freq <= 0 or freq > 10 then
                            errorLog('Frequency must be a number greater than 0 and less then 10 seconds.')
                            TriggerEvent('chat:addMessage', {
                                args = { 'Sonoran Bodycam', 'Frequency must be a number greater than 0 and less then 10 seconds.' }
                            })
                            return
                        end

                        screenshotFreq = (tonumber(freq) * 1000)
                        TriggerEvent('chat:addMessage',
                            { args = { 'Sonoran Bodycam', ('Frequency set to %s'):format((screenshotFreq / 1000)) } })
                    else
                        TriggerEvent('chat:addMessage', {
                            args = { 'Sonoran Bodycam', ('Current frequency is %s'):format((screenshotFreq / 1000)) }
                        })
                    end
                end)
                RegisterNetEvent('SonoranCAD::bodycam::SetSound', function(level)
                    if level then
                        level = tonumber(level)
                        if not level or level <= 0 or level > 100 then
                            errorLog('Sound must be a number greater than 0 and less then 100 percent.')
                            TriggerEvent('chat:addMessage', {
                                args = { 'Sonoran Bodycam', 'Frequency must be a number greater than 0 and less then 100 percent.' }
                            })
                            return
                        end
                        soundPercent = (tonumber(level) * 1000)
                        TriggerEvent('chat:addMessage',
                            { args = { 'Sonoran Bodycam', ('Sound set to %s'):format(soundPercent) } })
                    else
                        TriggerEvent('chat:addMessage', {
                            args = { 'Sonoran Bodycam', ('Current frequency is %s'):format((soundPercent)) }
                        })
                    end
                end)
            end)
        end
    end)
end)
