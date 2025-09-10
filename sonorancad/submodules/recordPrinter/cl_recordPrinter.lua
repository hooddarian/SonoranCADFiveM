--[[
    Sonaran CAD Plugins

    Plugin Name: ersintegration
    Creator: Sonoran Software
    Description: Integrates Knight ERS callouts to SonoranCAD
]]
CreateThread(function() Config.LoadPlugin("recordPrinter", function(pluginConfig)
    local printQueue = {}
    RegisterNetEvent('SonoranCAD::recordPrinter:PrintQueue', function(data)
        table.insert(printQueue, data)
        -- Check queue size
        if #printQueue > pluginConfig.maxPrintsPerQueue then
            -- Remove the oldest (first) entry
            table.remove(printQueue, 1)
        end
        TriggerEvent('chat:addMessage', {
            color = { 0, 255, 0},
            multiline = true,
            args = {
                "Record Printer",
                "You have a new record to print. Use /" .. pluginConfig.printQueueCommand .. " to view queue."
            }
        })
    end)
    RegisterCommand(pluginConfig.printQueueCommand, function()
        for i, url in ipairs(printQueue) do
            TriggerEvent('chat:addMessage', {
                color = { 0, 255, 0},
                multiline = true,
                args = {"Record Printer", "Record " .. i .. ": " .. url}
            })
        end
    end, false)
    RegisterCommand(pluginConfig.clearPrintQueueCommand, function()
        printQueue = {}
        TriggerEvent('chat:addMessage', {
            color = { 0, 255, 0},
            multiline = true,
            args = {"Record Printer", "Print queue cleared."}
        })
    end, false)
    local function isNearPrinterObject(radius)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        radius = radius or 3.5

        for _, modelName in ipairs(pluginConfig.printerObjects or {}) do
            local hash = GetHashKey(modelName)
            -- Look for the object close to the player
            local obj = GetClosestObjectOfType(pCoords.x, pCoords.y, pCoords.z, radius, hash, false, false, false)
            if obj and obj ~= 0 then
                return true
            end
        end
        return false
    end

    local function isAtPrinterCoord(radius)
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        radius = radius or 3.5

        for _, c in ipairs(pluginConfig.printerCoords or {}) do
            local target = vector3(c.x or 0.0, c.y or 0.0, c.z or 0.0)
            if #(pCoords - target) <= radius then
                return true
            end
        end
        return false
    end

    local function isInVehicleWithPrinter()
        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then return false end

        local veh = GetVehiclePedIsIn(ped, false)
        if not veh or veh == 0 then return false end

        local model = GetEntityModel(veh)

        -- Must be an emergency vehicle
        local vClass = GetVehicleClass(veh)
        if vClass ~= 18 then
            return false
        end

        -- Check whitelist logic
        local modelName = GetDisplayNameFromVehicleModel(model):lower()
        local allowed = false
        for _, v in ipairs(pluginConfig.vehicleConfig.whitelist or {}) do
            if modelName == v:lower() then
                allowed = true
                break
            end
        end

        if pluginConfig.vehicleConfig.reverseWhitelist then
            -- Blacklist: fail if it's in the whitelist
            return not allowed
        else
            -- Whitelist: only succeed if it's in the whitelist
            return allowed
        end
    end

    local function nearAnyPrinter()
        -- Succeeds if: in vehicle AND printer nearby, OR on foot and near a printer object, OR at a configured coord
        return isInVehicleWithPrinter(4.0) or isNearPrinterObject(3.5) or isAtPrinterCoord(3.5)
    end

    local function sendChat(color, msg)
        TriggerEvent('chat:addMessage', {
            color = color or {255,255,255},
            multiline = true,
            args = {"Record Printer", msg}
        })
    end

    RegisterCommand(pluginConfig.printCommand, function(source, args, raw)
        -- Basic validations
        if type(printQueue) ~= "table" or #printQueue == 0 then
            sendChat({255, 100, 100}, "Your print queue is empty.")
            return
        end

        local idx = tonumber(args[1] or "")
        if not idx then
            sendChat({255, 200, 0}, "Usage: /" .. pluginConfig.printCommand .. " <queue index>")
            return
        end
        if idx < 1 or idx > #printQueue then
            sendChat({255, 100, 100}, ("Invalid position. Queue has %d item(s)."):format(#printQueue))
            return
        end

        -- Printer proximity check (vehicle printer OR nearby object OR at printer coords)
        if not nearAnyPrinter() then
            sendChat({255, 200, 0}, "You're not near a printer or inside a vehicle that has a printer.")
            return
        end

        -- Fetch URL from queue
        local url = printQueue[idx]
        if not url or url == "" then
            sendChat({255, 100, 100}, "That queue entry is invalid.")
            return
        end

        -- Do the actual print action (replace with your real print logic)
        -- Example: trigger your record-printer flow with the selected URL
        -- If your printing is server-side:
        -- TriggerServerEvent('SonoranCAD::recordPrinter:StartPrint', url)
        -- If it's client-side:
        -- exports['recordPrinter']:Print(url)

        -- For now, just notify and remove it from the queue after "printing"
        sendChat({0, 255, 0}, ("Printing: queue #%d"):format(idx))
        table.remove(printQueue, idx)
    end, false)
    -- State
    local holdingDoc = false
    local doc_link = nil
    local WorldDocs = {}  -- [{ pdf_link=string, Position={x,y,z}, entityObject=entity }, ...]

    -- Props/Anims for “holding” a doc while UI is open
    local mapModel = 'prop_tourist_map_01'
    local animDict = 'amb@world_human_tourist_map@male@base'
    local animName = 'base'
    local map_net = nil

    -- Fallback translations (safe defaults)
    if not pluginConfig.translations then
        pluginConfig.translations = {
            placedInPocketPutCamAway = 'Document placed in pocket!',
            placedInPocket = 'Document placed in pocket!',
            putAwayCamera = 'Put away the document with: ~INPUT_LOOK_RIGHT_ONLY~',
            imageDropped = 'Document dropped!',
            uploadCadPrintCancel = 'Press ~INPUT_REPLAY_SCREENSHOT~ to Upload PDF to CAD\nPress ~INPUT_VEH_HEADLIGHT~ to Print PDF\n Press ~INPUT_REPLAY_NEWMARKER~ to Cancel',
            uploadedCad = '~g~PDF Uploaded To CAD!',
            photoPrinting = '~y~PDF Printing!',
            pressToDrop = '~y~Press ~INPUT_FRONTEND_RRIGHT~ to drop document!',
            photoDeleted = '~r~PDF Deleted!',
            printCancel = 'Press ~INPUT_VEH_HEADLIGHT~ to Print PDF\n Press ~INPUT_REPLAY_NEWMARKER~ to Cancel',
            notePadText = '~g~E~s~ to pickup PDF, ~g~G~s~ to destroy PDF',
            putPhotoAway = '~y~Press ~INPUT_FRONTEND_RRIGHT~ to close',
            couldNotHold = 'You could not hold that.',
            photoDescription = 'A printed PDF document'
        }
    end

    local NotepadText = pluginConfig.translations.notePadText

    -- =========================
    -- Tiny helpers
    -- =========================
    local function DisplayNotification(msg)
        SetTextComponentFormat('STRING')
        AddTextComponentString(msg)
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)
    end

    local function DrawText3Ds(x, y, z, text)
        local onScreen, _x, _y = World3dToScreen2d(x, y, z)
        local px, py, pz = table.unpack(GetGameplayCamCoords())
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry('STRING')
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end

    -- =========================
    -- World doc spawn/update
    -- =========================
    RegisterNetEvent('SonoranPDF:client:updatePDFs', function(serverDocs)
        -- serverDocs: array of { pdf_link, Position={x,y,z} }
        WorldDocs = serverDocs or {}

        local hash = GetHashKey('prop_notepad_01')
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(50) end

        -- Destroy any existing entities we might still hold (fresh rebuild keeps it simple)
        -- If you prefer incremental updates, you can diff instead.
        -- (This approach keeps things predictable.)
        for i = 1, #WorldDocs do
            if WorldDocs[i].entityObject and DoesEntityExist(WorldDocs[i].entityObject) then
                DeleteEntity(WorldDocs[i].entityObject)
                WorldDocs[i].entityObject = nil
            end
        end

        for i = 1, #WorldDocs do
            local e = CreateObject(hash, WorldDocs[i].Position.x, WorldDocs[i].Position.y, WorldDocs[i].Position.z - 0.2, true, true, false)
            WorldDocs[i].entityObject = e
        end
    end)

    -- Ask server for all existing docs on start
    AddEventHandler('onClientResourceStart', function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end
        TriggerServerEvent('SonoranPDF:Server:RequestAll')
    end)

    -- =========================
    -- World interactions (pickup/destroy)
    -- =========================
    CreateThread(function()
        while true do
            Wait(1)
            if #WorldDocs == 0 then
                Wait(1000)
            else
                local ply = PlayerPedId()
                local plyLoc = GetEntityCoords(ply)

                local closestDist, closestId = 900.0, 0
                for i = 1, #WorldDocs do
                    local p = WorldDocs[i].Position
                    local d = #(plyLoc - vector3(p.x, p.y, p.z))
                    if d < 10.0 then
                        DrawMarker(27, p.x, p.y, p.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 2.0, 255, 255, 150, 75, 0, 0, 2, 0, 0, 0, 0)
                    end
                    if d < closestDist then closestDist, closestId = d, i end
                end

                if closestDist > 100.0 then
                    Wait(math.ceil(closestDist * 10))
                end

                local e = WorldDocs[closestId]
                if e ~= nil then
                    local d2 = #(plyLoc - vector3(e.Position.x, e.Position.y, e.Position.z))
                    if d2 < 2.0 then
                        DrawMarker(27, e.Position.x, e.Position.y, e.Position.z - 0.8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 2.0, 255, 255, 155, 75, 0, 0, 2, 0, 0, 0, 0)
                        DrawText3Ds(e.Position.x, e.Position.y, e.Position.z - 0.4, NotepadText)

                        -- E: pickup & open viewer (does NOT add to inventory automatically)
                        if IsControlJustReleased(0, 38) then
                            if e.entityObject and DoesEntityExist(e.entityObject) then
                                DeleteEntity(e.entityObject)
                            end
                            TriggerServerEvent('SonoranPDF:destroyWorldPDF', closestId)
                            SendNuiMessage(json.encode({ action = 'openui', link = e.pdf_link, first = false, type = 'pdf' }))
                            ToggleDocHold(true)
                            SetNuiFocusKeepInput(true)
                            table.remove(WorldDocs, closestId)
                            DisplayNotification(pluginConfig.translations.putPhotoAway)
                        end

                        -- G: destroy in world
                        if IsControlJustReleased(0, 47) then
                            if e.entityObject and DoesEntityExist(e.entityObject) then
                                DeleteEntity(e.entityObject)
                            end
                            TriggerServerEvent('SonoranPDF:destroyWorldPDF', closestId)
                            table.remove(WorldDocs, closestId)
                        end
                    end
                end
            end
        end
    end)

    -- =========================
    -- Inventory open (QB/ESX)
    -- =========================
    RegisterNetEvent('sonoran:lookpdf:qbcore', function(item)
        -- QB: item.info.pdf_link
        local link = (item and item.info and item.info.pdf_link) or nil
        if not link or link == '' then return end
        SendNuiMessage(json.encode({ action = 'openui', link = link, first = false, type = 'pdf' }))
        ToggleDocHold(true)
        SetNuiFocusKeepInput(true)
        DisplayNotification(pluginConfig.translations.putPhotoAway)
    end)

    RegisterNetEvent('sonoran:lookpdf:esx', function(item)
        -- ESX (ox): entry.metadata.pdf_link
        local link = (item and item.metadata and item.metadata.pdf_link) or nil
        if not link or link == '' then return end
        SendNuiMessage(json.encode({ action = 'openui', link = link, first = false, type = 'pdf' }))
        ToggleDocHold(true)
        SetNuiFocusKeepInput(true)
        DisplayNotification(pluginConfig.translations.putPhotoAway)
    end)

    -- Optional: direct open (e.g., when a brand-new PDF is produced and you want it to be “First” so putting away adds to inventory)
    RegisterNetEvent('SonoranPDF:Open', function(url)
        if not url or url == '' then return end
        doc_link = url
        SendNuiMessage(json.encode({ action = 'openui', link = url, first = true, type = 'pdf' })) -- first=true -> inventory put-away
        ToggleDocHold(true)
        SetNuiFocusKeepInput(true)
        DisplayNotification(pluginConfig.translations.pressToDrop)
    end)

    -- =========================
    -- NUI close / put-away / drop
    -- =========================
    RegisterNUICallback('CloseUI', function(data, cb)
        -- data.link (pdf url), data.first (bool), type='pdf'
        local link = data and data.link or nil
        local isFirst = data and data.first or false

        if pluginConfig.frameworks.use_qbcore and not pluginConfig.frameworks.use_quasar_inventory then
            if isFirst then
                SetNuiFocus(false, false)
                TriggerServerEvent('SonoranPDF:PutAway:QB:First', link)
                if cb then cb() end
                DisplayNotification(pluginConfig.translations.placedInPocketPutCamAway)
            else
                SetNuiFocus(false, false)
                if cb then cb() end
                DisplayNotification(pluginConfig.translations.placedInPocket)
            end

        elseif pluginConfig.frameworks.use_esx and pluginConfig.frameworks.use_esx_ox_inventory then
            if isFirst then
                SetNuiFocus(false, false)
                TriggerServerEvent('SonoranPDF:PutAway:ESX:First', link)
                if cb then cb() end
                DisplayNotification(pluginConfig.translations.placedInPocketPutCamAway)
            else
                SetNuiFocus(false, false)
                if cb then cb() end
                DisplayNotification(pluginConfig.translations.placedInPocket)
            end

        elseif pluginConfig.frameworks.use_custom_inventory then
            if isFirst then
                SetNuiFocus(false, false)
                TriggerServerEvent('SonoranPDF:PutAway:Custom:First', link)
                if cb then cb() end
                DisplayNotification(pluginConfig.translations.placedInPocketPutCamAway)
            else
                SetNuiFocus(false, false)
                if cb then cb() end
                DisplayNotification(pluginConfig.translations.placedInPocket)
            end

        elseif pluginConfig.frameworks.use_quasar_inventory and pluginConfig.frameworks.use_qbcore then
            if isFirst then
                SetNuiFocus(false, false)
                TriggerServerEvent('SonoranPDF:PutAway:Quasar:First', link)
                if cb then cb() end
                DisplayNotification(pluginConfig.translations.placedInPocketPutCamAway)
            else
                SetNuiFocus(false, false)
                if cb then cb() end
                DisplayNotification(pluginConfig.translations.placedInPocket)
            end

        else
            -- No inventory: drop to world if “first”
            SetNuiFocus(false, false)
            if isFirst then
                local pos = GetEntityCoords(PlayerPedId())
                TriggerServerEvent('SonoranPDF:SaveToWorld', link, pos.x, pos.y, pos.z - 0.8)
                DisplayNotification(pluginConfig.translations.putAwayCamera)
            else
                DisplayNotification(pluginConfig.translations.imageDropped)
            end
            if cb then cb() end
        end

        ToggleDocHold(false)
    end)

    -- =========================
    -- Held-doc prop while UI open
    -- =========================
    CreateThread(function()
        while true do
            Wait(1)
            if holdingDoc then
                DisableControlAction(0, 202, true) -- BACK
                if IsDisabledControlJustPressed(0, 202) then
                    SendNuiMessage(json.encode({ action = 'closeui' }))
                    DisableControlAction(0, 202, false)
                    SetNuiFocus(false, false)
                end
            end
        end
    end)

    function ToggleDocHold(shouldHold)
        if shouldHold and not holdingDoc then
            holdingDoc = true
            local model = GetHashKey(mapModel)
            RequestModel(model)
            while not HasModelLoaded(model) do Wait(50) end
            RequestAnimDict(animDict)
            while not HasAnimDictLoaded(animDict) do Wait(50) end

            ClearPedSecondaryTask(PlayerPedId())
            local plyCoords = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 0.0, -5.0)
            local obj = CreateObject(model, plyCoords.x, plyCoords.y, plyCoords.z, 1, 1, 1)
            Wait(250)
            local netid = ObjToNet(obj)
            SetNetworkIdExistsOnAllMachines(netid, true)
            NetworkSetNetworkIdDynamic(netid, true)
            SetNetworkIdCanMigrate(netid, false)
            AttachEntityToEntity(obj, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
            TaskPlayAnim(PlayerPedId(), animDict, animName, 1.0, -1, -1, 50, 0, 0, 0, 0)
            map_net = netid

        elseif not shouldHold and holdingDoc then
            holdingDoc = false
            ClearPedSecondaryTask(PlayerPedId())
            if map_net then
                local o = NetToObj(map_net)
                if o and o ~= 0 then
                    DetachEntity(o, 1, 1)
                    DeleteEntity(o)
                end
            end
            map_net = nil
        end
    end
end) end)