-- =====================================================
-- VEHICLE MODULE - SUSPENSION CONTROL
-- Controle de altura da suspensão do veículo
-- =====================================================

local ESX = exports['es_extended']:getSharedObject()

-- =====================================================
-- VARIÁVEIS GLOBAIS
-- =====================================================

VehicleControl = {}
VehicleControl.CurrentVehicle = nil
VehicleControl.CurrentPressure = 0
VehicleControl.IsAdjusting = false

-- Tabela de veículos com suspensão ajustada (sincronização)
local AdjustedVehicles = {}

-- =====================================================
-- FUNÇÕES DE CONTROLE DE SUSPENSÃO
-- =====================================================

--- Aplica a pressão na suspensão do veículo
-- @param vehicle number - Handle do veículo
-- @param pressure number - Pressão (PSI)
function VehicleControl.ApplyPressure(vehicle, pressure)
    if not DoesEntityExist(vehicle) then
        return
    end
    
    local model = GetEntityModel(vehicle)
    local vehicleConfig = GetVehicleConfig(model)
    
    if not vehicleConfig then
        return
    end
    
    -- Normaliza pressão entre min e max
    local normalizedPressure = (pressure - vehicleConfig.min) / (vehicleConfig.max - vehicleConfig.min)
    normalizedPressure = math.max(0.0, math.min(1.0, normalizedPressure))
    
    -- Converte para altura da suspensão (-1.0 a 1.0)
    -- Pressão baixa = suspensão baixa (-1.0)
    -- Pressão alta = suspensão alta (1.0)
    local suspensionHeight = (normalizedPressure * 2.0) - 1.0
    
    -- Aplica a altura
    SetVehicleSuspensionHeight(vehicle, suspensionHeight)
    
    -- Salva na tabela de sincronização
    local plate = GetVehicleNumberPlateText(vehicle)
    AdjustedVehicles[plate] = {
        vehicle = vehicle,
        pressure = pressure,
        height = suspensionHeight
    }
end

--- Obtém configuração do veículo
-- @param model number - Hash do modelo
-- @return table - Configuração do veículo
function GetVehicleConfig(model)
    if Config.SuspensionConfig.vehicles.list[model] then
        return Config.SuspensionConfig.vehicles.list[model]
    end
    
    return Config.SuspensionConfig.vehicles.default
end

--- Reseta suspensão para padrão
-- @param vehicle number - Handle do veículo
function VehicleControl.ResetSuspension(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end
    
    SetVehicleSuspensionHeight(vehicle, 0.0)
    
    local plate = GetVehicleNumberPlateText(vehicle)
    AdjustedVehicles[plate] = nil
end

--- Verifica se veículo suporta suspensão ajustável
-- @param vehicle number - Handle do veículo
-- @return boolean - true se suporta
function VehicleControl.CanAdjustSuspension(vehicle)
    if not DoesEntityExist(vehicle) then
        return false
    end
    
    -- Verifica se é um veículo terrestre
    local vehicleClass = GetVehicleClass(vehicle)
    
    -- Classes que não suportam: Aviões (15), Helicópteros (16), Barcos (14), Bicicletas (13)
    local unsupportedClasses = {13, 14, 15, 16}
    
    for _, class in ipairs(unsupportedClasses) do
        if vehicleClass == class then
            return false
        end
    end
    
    return true
end

--- Anima ajuste da suspensão (transição suave)
-- @param vehicle number - Handle do veículo
-- @param targetPressure number - Pressão alvo
-- @param duration number - Duração da animação (ms)
function VehicleControl.AnimatePressure(vehicle, targetPressure, duration)
    if VehicleControl.IsAdjusting then
        return
    end
    
    VehicleControl.IsAdjusting = true
    
    local startPressure = VehicleControl.CurrentPressure
    local startTime = GetGameTimer()
    
    CreateThread(function()
        while GetGameTimer() - startTime < duration do
            local elapsed = GetGameTimer() - startTime
            local progress = elapsed / duration
            
            -- Interpolação linear
            local currentPressure = startPressure + (targetPressure - startPressure) * progress
            
            VehicleControl.ApplyPressure(vehicle, currentPressure)
            VehicleControl.CurrentPressure = currentPressure
            
            Wait(Config.SuspensionConfig.itens.block.wait or 80)
        end
        
        -- Garante que chegou ao valor final
        VehicleControl.ApplyPressure(vehicle, targetPressure)
        VehicleControl.CurrentPressure = targetPressure
        VehicleControl.IsAdjusting = false
    end)
end

-- =====================================================
-- EVENTOS
-- =====================================================

--- Sincroniza pressão de outros jogadores
RegisterNetEvent('mirtin_suspension:syncPressure', function(plate, pressure)
    local playerPed = PlayerPedId()
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)
    local playerPlate = playerVehicle ~= 0 and GetVehicleNumberPlateText(playerVehicle) or nil
    
    -- Não sincroniza o próprio veículo
    if playerPlate == plate then
        return
    end
    
    -- Procura veículo próximo com essa matrícula
    local vehicles = GetGamePool('CVehicle')
    
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            local vehiclePlate = GetVehicleNumberPlateText(vehicle)
            
            if vehiclePlate == plate then
                VehicleControl.ApplyPressure(vehicle, pressure)
                break
            end
        end
    end
end)

--- Atualiza pressão do veículo atual
RegisterNetEvent('mirtin_suspension:updatePressure', function(data)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        return
    end
    
    VehicleControl.CurrentVehicle = vehicle
    VehicleControl.AnimatePressure(vehicle, data.pressure, 500) -- 500ms de transição
end)

--- Reseta suspensão ao sair do veículo
RegisterNetEvent('mirtin_suspension:resetVehicle', function()
    if VehicleControl.CurrentVehicle and DoesEntityExist(VehicleControl.CurrentVehicle) then
        VehicleControl.ResetSuspension(VehicleControl.CurrentVehicle)
        VehicleControl.CurrentVehicle = nil
        VehicleControl.CurrentPressure = 0
    end
end)

-- =====================================================
-- THREAD: Monitoramento de veículo
-- =====================================================

CreateThread(function()
    while true do
        Wait(1000)
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        -- Jogador saiu do veículo
        if VehicleControl.CurrentVehicle and vehicle == 0 then
            -- Mantém a suspensão ajustada (não reseta automaticamente)
            VehicleControl.CurrentVehicle = nil
        end
        
        -- Jogador entrou em um veículo
        if vehicle ~= 0 and vehicle ~= VehicleControl.CurrentVehicle then
            VehicleControl.CurrentVehicle = vehicle
            
            -- Verifica se veículo tem suspensão salva
            local plate = GetVehicleNumberPlateText(vehicle)
            
            if AdjustedVehicles[plate] then
                VehicleControl.ApplyPressure(vehicle, AdjustedVehicles[plate].pressure)
                VehicleControl.CurrentPressure = AdjustedVehicles[plate].pressure
            end
        end
    end
end)

-- =====================================================
-- THREAD: Sincronização de veículos próximos
-- =====================================================

CreateThread(function()
    while true do
        Wait(5000) -- Verifica a cada 5 segundos
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        -- Aplica suspensão em veículos próximos salvos
        for plate, data in pairs(AdjustedVehicles) do
            if DoesEntityExist(data.vehicle) then
                local vehicleCoords = GetEntityCoords(data.vehicle)
                local distance = #(playerCoords - vehicleCoords)
                
                -- Apenas veículos a menos de 100 metros
                if distance < 100.0 then
                    SetVehicleSuspensionHeight(data.vehicle, data.height)
                end
            else
                -- Remove veículos que não existem mais
                AdjustedVehicles[plate] = nil
            end
        end
    end
end)

print('[SUSPENSION] Módulo de controle de veículo carregado')