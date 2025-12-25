-- =====================================================
-- UI MODULE - NUI MANAGEMENT
-- Gerenciamento da interface React
-- =====================================================

local ESX = exports['es_extended']:getSharedObject()

-- =====================================================
-- VARIÁVEIS GLOBAIS
-- =====================================================

UIManager = {}
UIManager.IsOpen = false
UIManager.CurrentVehicle = nil
UIManager.CurrentPlate = nil

-- =====================================================
-- FUNÇÕES DE CONTROLE DA UI
-- =====================================================

--- Abre a interface NUI
-- @param pressure number - Pressão atual
-- @param cylinder number - Cilindro atual
function UIManager.Open(pressure, cylinder)
    if UIManager.IsOpen then
        return
    end
    
    UIManager.IsOpen = true
    
    -- Envia dados para a UI React
    SendNUIMessage({
        action = 'setVisible',
        data = {
            pressure = pressure or 0,
            cylinder = cylinder or 0
        }
    })
    
    -- Ativa foco NUI
    SetNuiFocus(true, true)
    
    -- Desabilita controles do jogo
    DisableGameControls()
end

--- Fecha a interface NUI
function UIManager.Close()
    if not UIManager.IsOpen then
        return
    end
    
    UIManager.IsOpen = false
    
    -- Fecha UI React
    SendNUIMessage({
        action = 'setVisible',
        data = false
    })
    
    -- Remove foco NUI
    SetNuiFocus(false, false)
    
    -- Reabilita controles
    EnableGameControls()
end

--- Atualiza valores na UI
-- @param pressure number - Pressão atual
-- @param cylinder number - Cilindro atual
function UIManager.UpdateValues(pressure, cylinder)
    if not UIManager.IsOpen then
        return
    end
    
    SendNUIMessage({
        action = 'handlePressure',
        data = {
            pressure = pressure,
            cylinder = cylinder
        }
    })
end

--- Desabilita controles do jogo enquanto UI está aberta
function DisableGameControls()
    CreateThread(function()
        while UIManager.IsOpen do
            Wait(0)
            
            -- Desabilita controles de movimento
            DisableControlAction(0, 30, true) -- MoveLeftRight
            DisableControlAction(0, 31, true) -- MoveUpDown
            DisableControlAction(0, 32, true) -- MoveUp
            DisableControlAction(0, 33, true) -- MoveDown
            DisableControlAction(0, 34, true) -- MoveLeft
            DisableControlAction(0, 35, true) -- MoveRight
            
            -- Desabilita controles de veículo
            DisableControlAction(0, 71, true) -- VehicleAccelerate
            DisableControlAction(0, 72, true) -- VehicleBrake
            DisableControlAction(0, 75, true) -- VehicleExit
        end
    end)
end

--- Reabilita controles do jogo
function EnableGameControls()
    -- Controles são reabilitados automaticamente ao sair do loop
end

-- =====================================================
-- CALLBACKS NUI
-- =====================================================

--- Callback: Fechar UI
RegisterNUICallback('close', function(data, cb)
    UIManager.Close()
    
    -- Envia para servidor que fechou
    TriggerServerEvent('mirtin_suspension:uiClosed')
    
    cb('ok')
end)

--- Callback: Controlar pressão
RegisterNUICallback('controlPressure', function(data, cb)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        cb({success = false, message = 'Você não está em um veículo'})
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local vehicleModel = GetEntityModel(vehicle)
-- Envia para servidor
TriggerServerEvent('mirtin_suspension:controlPressure', {
    plate = plate,
    direction = data.direction,
    vehicleModel = vehicleModel
})

cb({success = true})
end)
--- Callback: Salvar preset
RegisterNUICallback('savePressure', function(data, cb)
local playerPed = PlayerPedId()
local vehicle = GetVehiclePedIsIn(playerPed, false)
if vehicle == 0 then
    cb({success = false})
    return
end

local plate = GetVehicleNumberPlateText(vehicle)

-- Envia para servidor
TriggerServerEvent('mirtin_suspension:savePreset', {
    plate = plate,
    slot = data.set,
    pressure = VehicleControl.CurrentPressure or 0
})

cb({success = true})
end)
--- Callback: Aplicar preset
RegisterNUICallback('setPressure', function(data, cb)
local playerPed = PlayerPedId()
local vehicle = GetVehiclePedIsIn(playerPed, false)
if vehicle == 0 then
    cb({success = false})
    return
end

local plate = GetVehicleNumberPlateText(vehicle)

-- Envia para servidor
TriggerServerEvent('mirtin_suspension:applyPreset', {
    plate = plate,
    slot = data.set
})

cb({success = true})
end)
-- =====================================================
-- EVENTOS
-- =====================================================
--- Evento: Atualizar pressão na UI
RegisterNetEvent('mirtin_suspension:updatePressure', function(data)
UIManager.UpdateValues(data.pressure, data.cylinder)
end)
--- Evento: Cilindro cheio
RegisterNetEvent('mirtin_suspension:cylinderFilled', function(cylinder)
if UIManager.IsOpen then
UIManager.UpdateValues(VehicleControl.CurrentPressure, cylinder)
end
end)
--- Evento: Preset salvo
RegisterNetEvent('mirtin_suspension:presetSaved', function(data)
ESX.ShowNotification(('Preset %d salvo com %.2f PSI'):format(data.slot, data.pressure), 'success')
end)
--- Evento: Forçar fechamento da UI
RegisterNetEvent('mirtin_suspension:forceClose', function()
UIManager.Close()
end)
-- =====================================================
-- TECLA ESC PARA FECHAR
-- =====================================================
CreateThread(function()
while true do
Wait(0)
    if UIManager.IsOpen then
        -- Verifica se pressionou ESC
        if IsControlJustReleased(0, 322) then -- ESC
            UIManager.Close()
        end
    else
        Wait(500)
    end
end
end)
print('[SUSPENSION] Módulo de UI carregado')