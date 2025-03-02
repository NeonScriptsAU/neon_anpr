local QBCore = nil
local ESX = nil

if Config.Framework == 'QB' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'ESX' then
    ESX = exports['es_extended']:getSharedObject()
end

local scanning = false
local snail = "not 🐌"
local displayplate = false
local ScanningDistance = Config.ScanDistance

function HasValue(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

RegisterCommand(Config.Command, function()
    local playerJob = nil

    if Config.Framework == 'QB' then
        local PlayerData = QBCore.Functions.GetPlayerData()
        playerJob = PlayerData.job.name
    elseif Config.Framework == 'ESX' then
        playerJob = ESX.GetPlayerData().job.name
    end

    if not HasValue(Config.Jobs, playerJob) then
        lib.notify({
            id = 'core',
            title = 'Access Denied',
            description = 'You do not have permission to use ANPR.',
                style = { backgroundColor = '#141517', color = '#C1C2C5', ['.description'] = { color = '#909296' } },
            icon = 'x-circle',
            iconColor = '#ffffff'
        })
        return
    end

    if scanning then
        lib.notify({
            id = 'core',
            title = 'ANPR TURNED OFF',
            style = { backgroundColor = '#141517', color = '#C1C2C5', ['.description'] = { color = '#909296' } },
            icon = 'message',
            iconColor = '#d1d1d1'
        })
        scanning = false
        displayplate = false
        snail = "not 🐌"
    else
        lib.notify({
            id = 'core',
            title = 'ANPR TURNED ON',
            style = { backgroundColor = '#141517', color = '#C1C2C5', ['.description'] = { color = '#909296' } },
            icon = 'message',
            iconColor = '#d1d1d1'
        })
        scanning = true
        snail = "🐌"
    end
end)

function GetVehicleInFrontOfPlayer(entity)
    local coords = GetOffsetFromEntityInWorldCoords(entity, 0.0, 1.0, 0.3)
    local coords2 = GetOffsetFromEntityInWorldCoords(entity, 0.0, Config.ScanDistance, 0.0)
    local rayHandle = CastRayPointToPoint(coords, coords2, 10, entity, 0)
    local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

function GetVehicleInFrontRight(entity)
    local coords = GetOffsetFromEntityInWorldCoords(entity, -0.3, 1.0, 0.3)
    local coords2 = GetOffsetFromEntityInWorldCoords(entity, 30.0, Config.ScanDistance, 0.0)
    local rayHandle = CastRayPointToPoint(coords, coords2, 10, entity, 0)
    local _, _, _, _, vehicle = GetRaycastResult(rayHandle)
    return vehicle
end

function RenderVehicleInfo(vehicle)
    if not Config.RenderVehicleInfo then return end

    local model = GetEntityModel(vehicle)
    local vehname = GetLabelText(GetDisplayNameFromVehicleModel(model)) or "Unknown Model"
    local licenseplate = GetVehicleNumberPlateText(vehicle) or "Unknown Plate"
    local passNum = GetVehicleNumberOfPassengers(vehicle)
    local primary = GetVehicleColorName(vehicle)

    if not IsVehicleSeatFree(vehicle, -1) then
        passNum = passNum + 1
    end

    local x = 0.4000
    local y = 0.35
    local scale = 1.40

    displayplate = true

Citizen.CreateThread(function()
        while displayplate do
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(scale, scale)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(2, 2, 0, 0, 0)  
            SetTextEdge(1, 0, 0, 0, 205) 
            SetTextCentre(true)
            SetTextWrap(0.0, 1.0)
            SetTextDropShadow()
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString(licenseplate)
            DrawText(x, y)
            Wait(0)
        end
    end)

Citizen.CreateThread(function()
        while displayplate do
            SetTextFont(0)
            SetTextProportional(1)
            SetTextScale(0.55, 0.55)
            SetTextColour(255, 255, 255, 255)
            SetTextDropshadow(2, 2, 0, 0, 255)
            SetTextEdge(1, 0, 0, 0, 255)
            SetTextCentre(true)
            SetTextWrap(0.0, 1.0)
            SetTextOutline()
            SetTextEntry("STRING")
            AddTextComponentString("Model: "..vehname.."\nPlate: "..licenseplate.."\nColour: "..primary)
            DrawText(0.50, 0.88)
            Wait(0)
        end
    end)
end

function GetVehicleColorName(vehicle)
    local primary, _ = GetVehicleColours(vehicle)
    return Config.ColorNames1[tostring(primary)] or "Unknown"
end

function CheckPlate(vehicle)
    local model = GetEntityModel(vehicle)
    local vehname = GetLabelText(GetDisplayNameFromVehicleModel(model)) or "Unknown Model"
    local licenseplate = GetVehicleNumberPlateText(vehicle) or "Unknown Plate"
    local primary = GetVehicleColorName(vehicle)

    local plateData = lib.callback.await('neon_anpr:fetchVehicleData', false, licenseplate)

    if plateData then
        exports.bulletin:Send({
            message = "~o~ANPR: \n~w~Model: " .. vehname .. "\nPlate: " .. licenseplate .. "\nColour: " .. primary,
            timeout = 8000,
            theme = 'normal',
            position = 'bottomleft',
        })
        local ownerMessage = "~y~Vehicle Owner: ~w~\n" .. (plateData.name or "Unknown")
        exports.bulletin:Send({
            message = ownerMessage,
            timeout = 8000,
            theme = 'normal',
            position = 'bottomleft',
        })
        FlagCheck(vehicle)
        Citizen.Wait(100)
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'mdtbeepbeep', 1.0)
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)

        if vehicle ~= 0 then
            if snail == "🐌" then
                local vehicle_detected = GetVehicleInFrontOfPlayer(vehicle)
                if not DoesEntityExist(vehicle_detected) then
                    vehicle_detected = GetVehicleInFrontRight(vehicle)
                end

                if DoesEntityExist(vehicle_detected) then
                    if not displayplate then
                        displayplate = true
                        RenderVehicleInfo(vehicle_detected)
                    end
                else
                    displayplate = false
                end
            end
        else
            displayplate = false
        end
    end
end)

function FlagCheck(vehicle)
    local model = GetEntityModel(vehicle)
    local vehname = GetLabelText(GetDisplayNameFromVehicleModel(model)) or "Unknown Model"
    local licenseplate = GetVehicleNumberPlateText(vehicle) or "Unknown Plate"

    local plateData = lib.callback.await('neon_anpr:fetchVehicleData', false, licenseplate)

    local flags = ""

    if Config.Flags.wanted and plateData and plateData.warrant then
        flags = flags .. "~r~*WANTED* "
    end

    if flags ~= "" then
        exports.bulletin:Send({
            message = "~y~FLAGS:\n" .. flags,
            timeout = 8000,
            theme = 'normal',
            position = 'bottomleft',
        })
    end
end


Citizen.CreateThread(function()
    local lastchecked, lastchecked2, lastchecked3
    local anpr_checked = {}

    while true do
        Citizen.Wait(0)

        local playerVehicle = GetVehiclePedIsIn(PlayerPedId())
        if DoesEntityExist(playerVehicle) and snail == "🐌" then
            local vehicle_detected = GetVehicleInFrontOfPlayer(playerVehicle)
            if not DoesEntityExist(vehicle_detected) then
                vehicle_detected = GetVehicleInFrontRight(GetVehiclePedIsIn(GetPlayerPed(-1)))
            end

            if DoesEntityExist(vehicle_detected) then
                local licenseplate = GetVehicleNumberPlateText(vehicle_detected)
                local plateData = lib.callback.await('neon_anpr:fetchVehicleData', false, licenseplate)

                if plateData and plateData.warrant then
                    if lastchecked ~= vehicle_detected and lastchecked2 ~= vehicle_detected and lastchecked3 ~= vehicle_detected 
                        and (anpr_checked[tostring(vehicle_detected)] == nil or anpr_checked[tostring(vehicle_detected)] <= GetGameTimer() - 10000) then
                        
                        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 0.5, 'platescan', 0.009)
                        CheckPlate(vehicle_detected)
                        lastchecked3 = lastchecked2
                        lastchecked2 = lastchecked
                        lastchecked = vehicle_detected
                        anpr_checked[tostring(lastchecked)] = GetGameTimer()
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerVehicle = GetVehiclePedIsIn(PlayerPedId())
        if DoesEntityExist(playerVehicle) and snail == "🐌" then
            local vehicle_detected = GetVehicleInFrontOfPlayer(playerVehicle)
            if not DoesEntityExist(vehicle_detected) then
                vehicle_detected = GetVehicleInFrontRight(GetVehiclePedIsIn(GetPlayerPed(-1)))
            end

            if IsControlJustPressed(0, Config.ANPRKeybind) and DoesEntityExist(vehicle_detected) then
                CheckPlate(vehicle_detected)
            end
        end
    end
end)
