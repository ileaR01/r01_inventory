RegisterNetEvent("r01:inventory:sendNuiMessage")

AddEventHandler("r01:inventory:sendNuiMessage", function(...)
    SendNUIMessage(...)
end)

RegisterNuiCallback('setFocus', function(data, cb)
    SetNuiFocus(data[1], data[1])
    
    cb('ok')
end)

local fastSlots = {}
local Drops = {}
local needToCloseCar
local uiLink = {
    .throwItem,
    .moveItem,

    .takeItem,
    .moveItemSecond,

    .destroyItem,

    .useItem,
    .giveItem
}
local backEngines = {
    [`ninef`] = true,
    [`adder`] = true,
    [`vagner`] = true,
    [`t20`] = true,
    [`infernus`] = true,
    [`zentorno`] = true,
    [`reaper`] = true,
    [`comet2`] = true,
    [`comet3`] = true,
    [`jester`] = true,
    [`jester2`] = true,
    [`cheetah`] = true,
    [`cheetah2`] = true,
    [`prototipo`] = true,
    [`turismor`] = true,
    [`pfister811`] = true,
    [`ardent`] = true,
    [`nero`] = true,
    [`nero2`] = true,
    [`tempesta`] = true,
    [`vacca`] = true,
    [`bullet`] = true,
    [`osiris`] = true,
    [`entityxf`] = true,
    [`turismo2`] = true,
    [`fmj`] = true,
    [`re7b`] = true,
    [`tyrus`] = true,
    [`italigtb`] = true,
    [`penetrator`] = true,
    [`monroe`] = true,
    [`ninef2`] = true,
    [`stingergt`] = true,
    [`surfer`] = true,
    [`surfer2`] = true,
    [`gp1`] = true,
    [`autarch`] = true,
    [`tyrant`] = true,
    [`coquette4`] = true,
}

local GetClosestVehicle = function(coords)
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1

    if coords then
        coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords
    else
        coords = GetEntityCoords(ped)
    end

    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)

        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end
    
    return closestVehicle, closestDistance
end

local loadAnimDict = function(dict)
    if HasAnimDictLoaded(dict) then return end

    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end


RegisterCommand('r01ScriptsOpenInventory', function()
    local second = "drop-new"
    local pPed = PlayerPedId()
    local pCoords = GetEntityCoords(pPed)

    for _, v in pairs(Drops) do
        local dist = #(pCoords - v.coords)

        if dist <= 2 then
            second = v.id
        end
    end

    local userVehicle = GetVehiclePedIsUsing(pPed)
    if userVehicle ~= 0 then
        second = "G-"..string.gsub(GetVehicleNumberPlateText(userVehicle), '^%s*(.-)%s*$', '%1')
    else
        local vehicle, dist = GetClosestVehicle(pCoords)

        if vehicle ~= 0 and vehicle ~= nil then
            local dimensionMin, dimensionMax = GetModelDimensions(GetEntityModel(vehicle))
            local trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (dimensionMin.y), 0.0)

            if (backEngines[GetEntityModel(vehicle)]) then
                trunkpos = GetOffsetFromEntityInWorldCoords(vehicle, 0.0, (dimensionMax.y), 0.0)
            end

            if #(pCoords - trunkpos) < 1.5 and not IsPedInAnyVehicle(pPed) then
                if GetVehicleDoorLockStatus(vehicle) < 2 then
                    second = "T-"..string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')

                    loadAnimDict("amb@prop_human_bum_bin@idle_b")
                    TaskPlayAnim(pPed, "amb@prop_human_bum_bin@idle_b", "idle_d", 4.0, 4.0, -1, 50, 0, false, false, false)

                    SetVehicleDoorOpen(vehicle, 5, false, false)
                    needToCloseCar = vehicle
                end
            end

        end
    end

    TriggerServerEvent('r01:inventory:open', second)
end)

RegisterKeyMapping('r01ScriptsOpenInventory', 'Acceseaza inventarul', 'keyboard', Config.openKeyBind)

for i = 1, 5 do
    RegisterCommand('useR01fastItem_'..i, function()
        local selected = tostring(i - 1)
        if fastSlots[selected] then
            TriggerServerEvent('r01:inventory:useItem', fastSlots[selected])
        end
    end)

    RegisterKeyMapping('useR01fastItem_'..i, 'Foloseste slorul '..i, 'keyboard', i)
end

for k in pairs(uiLink) do
    RegisterNuiCallback('inventory:'..k, function(data, cb)
        TriggerServerEvent('r01:inventory:'..k, table.unpack(data))

        cb('ok')
    end)
end

RegisterNuiCallback("inventory:setFastSlot", function(data, cb)
    fastSlots[data[1]] = data[2]
    TriggerServerEvent("r01:inventory:setFastSlot", data[1], data[2])
    cb('ok')
end)

RegisterNuiCallback("inventory:useCloth", function(data, cb)
    ExecuteCommand(data[1])
    cb('ok')
end)

RegisterNuiCallback("inventory:closeInventory", function(data, cb)
    local ped = PlayerPedId()
    SetNuiFocus(false, false)
    
    if needToCloseCar then
        local vehicle = needToCloseCar
        
        SetVehicleDoorShut(vehicle, 5, false)
        ClearPedTasks(ped)
        needToCloseCar = nil
    end

    cb('ok')
end)

RegisterNuiCallback("inventory:getItemData", function(data, cb)
    local itemData = GlobalState['r01:inventoryItems'][data[1].item:lower()]

    cb(
        {
            label = itemData.label,
            item = data[1].item,
            desc = itemData.desc,
            weight = itemData.weight * data[1].amount,
            amount = data[1].amount,
        }
    )
end)

RegisterNetEvent('r01:client:createDrop')
AddEventHandler('r01:client:createDrop', function(data)
    table.insert(Drops, data)
end)

RegisterNetEvent('r01:client:removeDrop')
AddEventHandler('r01:client:removeDrop', function(theId)    
    for k, v in pairs(Drops) do
        if v.id == theId then
            table.remove(Drops, k)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local tks = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        for _, v in pairs(Drops) do
            local dist = #(pCoords - v.coords)
            if dist <= 20 then
                tks = 1
                DrawMarker(20, v.coords.x, v.coords.y, v.coords.z - 0.8, .0, .0, .0, 180.0, .0, .0, .35, .35, .35, 130, 226, 102, 150, 1, 0, 0, 1)
            end
        end

        Wait(tks)
    end
end)


Citizen.CreateThread(function()
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
	SetPedConfigFlag(ped, 48, 1)
	SetPedCanSwitchWeapon(ped, 0)
	SetWeaponsNoAutoreload(1)
	SetWeaponsNoAutoswap(1)

    while true do
        DisableControlAction(0, 37, true) -- TAB
        Citizen.Wait(25)
    end
end)

-- tab preview
RegisterCommand('r01ScriptsShowFastSlots', function()
    SendNUIMessage({event = 'showFastSlotsPreview', data = fastSlots})
end)

RegisterKeyMapping('r01ScriptsShowFastSlots', 'Arata sloturile rapide', 'keyboard', Config.showFastSlotsKeyBind)