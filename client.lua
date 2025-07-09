RegisterNetEvent("r01:inventory:sendNuiMessage")

local fastSlots = {}

AddEventHandler("r01:inventory:sendNuiMessage", function(...)
    SendNUIMessage(...)
end)

RegisterNuiCallback('setFocus', function(data, cb)
    SetNuiFocus(data[1], data[1])
    
    cb('ok')
end)

local Drops = {}

RegisterCommand('r01ScriptsOpenInventory', function()
    local second = "drop-new"
    local pCoords = GetEntityCoords(PlayerPedId())

    for _, v in pairs(Drops) do
        local dist = #(pCoords - v.coords)

        if dist <= 2 then
            second = v.id
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

local uiLink = {
    .throwItem,
    .moveItem,

    .takeItem,
    .moveItemSecond,

    .destroyItem,

    .useItem,
    .giveItem
}

for k in pairs(uiLink) do
    RegisterNuiCallback('inventory:'..k, function(data, cb)
        TriggerServerEvent('r01:inventory:'..k, table.unpack(data))

        cb('ok')
    end)
end

RegisterNuiCallback("inventory:setFastSlot", function(data, cb)
    fastSlots[data[1]] = data[2]
    print(data[1], data[2])
    TriggerServerEvent("r01:inventory:setFastSlot", data[1], data[2])
    cb('ok')
end)

RegisterNuiCallback("inventory:useCloth", function(data, cb)
    ExecuteCommand(data[1])
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
                DrawMarker(20, v.coords.x, v.coords.y, v.coords.z - 0.8, .0, .0, .0, 180.0, .0, .0, .35, .35, .35, 132, 102, 226, 150, 1, 0, 0, 1)
            end
        end

        Wait(tks)
    end
end)

Citizen.CreateThread(function ()
	while true do
        Citizen.Wait(1)
		BlockWeaponWheelThisFrame()
        HudWeaponWheelIgnoreSelection()
	end
end)

-- tab preview
RegisterCommand('r01ScriptsShowFastSlots', function()
    SendNUIMessage({event = 'showFastSlotsPreview', data = fastSlots})
end)

RegisterKeyMapping('r01ScriptsShowFastSlots', 'Arata sloturile rapide', 'keyboard', Config.showFastSlotsKeyBind)