--[[
    Sonaran CAD Plugins

    Plugin Name: ersintegration
    Creator: Sonoran Software
    Description: Integrates SonoranCAD PDFs in-game.
]]
CreateThread(function() Config.LoadPlugin("recordPrinter", function(pluginConfig)
    TriggerEvent('SonoranCAD::RegisterPushEvent', 'EVENT_PRINT_RECORD', function(data)
        local printData = data.data
        local userId = GetUnitById(printData.unitId).userId
        local pdfDirectory = exports['sonorancad']:createPDFDirectory(printData.unitId)
        local filename = printData.url:match("^.+/(.+)$")
        local filePath = pdfDirectory .. '/' .. filename
        local pdfName = exports['sonorancad']:savePdfFromUrl(printData.url, filePath)
        TriggerClientEvent('SonoranCAD::recordPrinter:PrintQueue', userId, pdfName)
    end)
    local Docs = {}
    local ESX = nil
    local QBCore = nil

    if pluginConfig.frameworks.use_qbcore then
        QBCore = exports['qb-core']:GetCoreObject()
    end
    if pluginConfig.frameworks.use_esx then
        ESX = exports['es_extended']:getSharedObject()
    end

    if not pluginConfig.translations then
        pluginConfig.translations = {
            placedInPocketPutCamAway = 'Document placed in pocket!',
            placedInPocket = 'Document placed in pocket!',
            putAwayCamera = 'Put away the document with: ~INPUT_LOOK_RIGHT_ONLY~',
            imageDropped = 'Document dropped!',
            photoPrinting = '~y~PDF Printing!',
            pressToDrop = '~y~Press ~INPUT_FRONTEND_RRIGHT~ Drop Document!',
            photoDeleted = '~r~PDF Deleted!',
            printCancel = 'Press ~INPUT_VEH_HEADLIGHT~ To Print PDF\n Press ~INPUT_REPLAY_NEWMARKER~ To Cancel',
            notePadText = '~g~E~s~ To Pickup PDF, ~g~G~s~ To Destroy PDF',
            lookThroughCamera = '',
            putPhotoAway = '~y~Press ~INPUT_FRONTEND_RRIGHT~ to close',
            couldNotHold = 'You could not hold that.',
            photoDescription = 'A printed PDF document'
        }
    end

    local function loadConfig()
        local loaded = LoadResourceFile(GetResourcePath(GetCurrentResourceName()),'/submodules/recordPrinter/pdfs.json')
        if loaded and loaded ~= '' then
            Docs = json.decode(loaded) or {}
        else
            Docs = {}
            SaveResourceFile(GetResourcePath(GetCurrentResourceName()),'/submodules/recordPrinter/pdfs.json', json.encode(Docs), -1)
        end
    end

    local function saveDocs()
        SaveResourceFile(GetResourcePath(GetCurrentResourceName()),'/submodules/recordPrinter/pdfs.json', json.encode(Docs), -1)
    end

    ---------------------------------------
    -- Events - Don't Touch (Use Config) --
    ---------------------------------------

    -- Drop/save a PDF into the world at given coords
    RegisterNetEvent('SonoranPDF:SaveToWorld', function(pdfUrl, x, y, z)
        local newDoc = { ['pdf_link'] = pdfUrl, ['Position'] = { ['x'] = x, ['y'] = y, ['z'] = z } }
        table.insert(Docs, newDoc)
        saveDocs()
        TriggerEvent('SonoranPDF:Server:BroadcastDocs')
    end)

    -- Inventory put-away: QB
    RegisterNetEvent('SonoranPDF:PutAway:QB:First', function(pdfUrl)
        if not pluginConfig.frameworks.use_qbcore then return end
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return end
        local info = {}
        info.pdf_link = pdfUrl
        Player.Functions.AddItem('sonoran_evidence_pdf', 1, nil, info)
    end)

    -- Inventory put-away: Quasar
    RegisterNetEvent('SonoranPDF:PutAway:Quasar:First', function(pdfUrl)
        TriggerEvent('qs-inventory:addItem', source, 'sonoran_evidence_pdf', 1, false, { pdf_link = pdfUrl })
    end)

    -- Inventory put-away: ESX + ox_inventory
    RegisterNetEvent('SonoranPDF:PutAway:ESX:First', function(pdfUrl)
        if not pluginConfig.frameworks.use_esx then return end
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return end
        local ox_inventory = exports.ox_inventory
        local info = { pdf_link = pdfUrl }

        if ox_inventory:CanCarryItem(source, 'sonoran_evidence_pdf', 1) then
            ox_inventory:AddItem(source, 'sonoran_evidence_pdf', 1, info, nil, function(success, reason) end)
        else
            xPlayer.showNotification(pluginConfig.translations.couldNotHold)
            return
        end

        -- ensure metadata is set
        local item = ox_inventory:Search(source, 1, 'sonoran_evidence_pdf')
        for _, v in pairs(item) do
            item = v
            break
        end
        if item and item.slot and item.metadata then
            item.metadata.pdf_link = pdfUrl
            ox_inventory:SetMetadata(source, item.slot, item.metadata)
        end
    end)

    -- ox_inventory export handler for using the PDF item (ESX)
    exports('sonoran_evidence_pdf', function(event, item, inventory, slot, data)
        if event == 'usingItem' then
            local link = inventory.items[slot].metadata.pdf_link
            TriggerClientEvent('sonoran:lookpdf:esx', inventory.player.source, { metadata = { pdf_link = link } })
        end
    end)

    -- Broadcast updated world docs to all clients
    RegisterNetEvent('SonoranPDF:Server:BroadcastDocs', function()
        if #Docs ~= 0 then
            TriggerClientEvent('SonoranPDF:client:updatePDFs', -1, Docs)
        end
    end)

    -- Provide current world docs to a single client
    RegisterNetEvent('SonoranPDF:Server:RequestAll', function()
        if #Docs ~= 0 then
            TriggerClientEvent('SonoranPDF:client:updatePDFs', source, Docs)
        end
    end)

    -- Destroy a world PDF by index
    RegisterNetEvent('SonoranPDF:destroyWorldPDF', function(docID)
        if Docs[docID] ~= nil then
            table.remove(Docs, docID)
            saveDocs()
            TriggerEvent('SonoranPDF:Server:BroadcastDocs')
        end
    end)

    -----------------------------------------
    -- Handlers - Don't Touch (Use Config) --
    -----------------------------------------

    AddEventHandler('onServerResourceStart', function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end

        loadConfig()

        -- push existing docs to clients on start
        TriggerEvent('SonoranPDF:Server:BroadcastDocs')
        TriggerEvent(GetCurrentResourceName() .. '::StartUpdateLoop') -- keep if used elsewhere

        -- QB item
        if pluginConfig.frameworks.use_qbcore then
            exports['qb-core']:AddItem('sonoran_evidence_pdf', {
                name = 'sonoran_evidence_pdf',
                label = 'Evidence PDF',
                weight = 0,
                type = 'item',
                image = 'evidence.png',
                unique = true,
                useable = true,
                shouldClose = false,
                combinable = nil,
                description = pluginConfig.translations.photoDescription
            })
            QBCore.Functions.CreateUseableItem('sonoran_evidence_pdf', function(source, item)
                -- item.info.pdf_link
                TriggerClientEvent('sonoran:lookpdf:qbcore', source, item)
            end)
        end

        -- ESX items (keep camera item registration removed; only PDF)
        if pluginConfig.frameworks.use_esx then
            ESX.RegisterUsableItem('sonoran_evidence_pdf', function(source)
                local ox_inventory = exports.ox_inventory
                local results = ox_inventory:Search(source, 1, 'sonoran_evidence_pdf')
                local entry
                for _, v in pairs(results) do entry = v; break end
                if entry then
                    TriggerClientEvent('sonoran:lookpdf:esx', source, entry)
                end
            end)
        end
    end)

end) end)