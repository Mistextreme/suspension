
-- =====================================================
-- CLIENT MAIN - SUSPENSION SYSTEM
-- Lógica principal do cliente
-- =====================================================

local ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}

-- =====================================================
-- VARIÁVEIS GLOBAIS
-- =====================================================

local Config = Config or {}
local isInstalling = false
local hasPermission = false
local installedVehicles = {} -- Cache local de veículos com suspensão

-- =====================================================
-- INICIALIZAÇÃO ESX
-- =====================================================

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    
    -- Solicita sincronização de configurações
    TriggerServerEvent('mirtin_suspension:requestSync')
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    PlayerData = {}
    UIManager.Close()
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
end)

-- =====================================================
-- SINCRONIZAÇÃO DE CONFIGURAÇÕES
-- =====================================================

RegisterNetEvent('mirtin_suspension:syncConfig', function(config)
    Config = config
    print('[SUSPENSION] Configurações sincronizadas')
end)

-- =====================================================
-- FUNÇÕES AUXILIARES
-- =====================================================

--- Verifica se jogador está em um veículo
-- @return number|nil - Handle do veículo ou nil
local function GetPlayerVehicle()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        return nil
    end
    
    return vehicle
end

--- Verifica se jogador é o motorista
-- @return boolean
local function IsDriver()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        return false
    end
    
    return GetPedInVehicleSeat(vehicle, -1) == playerPed
end

--- Verifica se veículo tem suspensão instalada (cache local)
-- @param plate string - Matrícula do veículo
-- @return boolean
local function HasSuspensionInstalled(plate)
    return installedVehicles[plate] == true
end

--- Adiciona veículo ao cache local
-- @param plate string - Matrícula do veículo
local function AddToCache(plate)
    installedVehicles[plate] = true
end

--- Remove veículo do cache local
-- @param plate string - Matrícula do veículo
local function RemoveFromCache(plate)
    installedVehicles[plate] = nil
end

-- =====================================================
-- FUNÇÃO: Abrir controle de suspensão
-- =====================================================

local function OpenSuspensionControl()
    local vehicle = GetPlayerVehicle()
    
    if not vehicle then
        Config.Langs['noProximityVehicle']()
        return
    end
    
    if not IsDriver() then
        ESX.ShowNotification('Você precisa ser o motorista!', 'error')
        return
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    
    -- Verifica se veículo tem suspensão instalada
    ESX.TriggerServerCallback('mirtin_suspension:hasSuspension', function(hasSuspension, data)
        if not hasSuspension then
            Config.Langs['notOwnerOrNotInstalled']()
            return
        end
        
        -- Adiciona ao cache
        AddToCache(plate)
        
        -- Verifica se precisa de item
        if Config.SuspensionConfig.requireItem.active then
            ESX.TriggerServerCallback('mirtin_suspension:checkItem', function(hasItem)
                if not hasItem then
                    ESX.ShowNotification('Você precisa de um ' .. Config.SuspensionConfig.requireItem.item, 'error')
                    return
                end
                
                -- Abre UI
                UIManager.Open(data.pressure, data.cylinder)
                VehicleControl.CurrentPressure = data.pressure
            end, Config.SuspensionConfig.requireItem.item)
        else
            -- Verifica permissão VIP se configurado
            if Config.SuspensionConfig.permissions.vip_permission then
                ESX.TriggerServerCallback('mirtin_suspension:checkVipPermission', function(hasVip)
                    if not hasVip and Config.SuspensionConfig.requireItem.active == false then
                        ESX.ShowNotification('Você precisa de VIP ou do item!', 'error')
                        return
                    end
                    
                    -- Abre UI
                    UIManager.Open(data.pressure, data.cylinder)
                    VehicleControl.CurrentPressure = data.pressure
                end)
            else
                -- Abre UI diretamente
                UIManager.Open(data.pressure, data.cylinder)
                VehicleControl.CurrentPressure = data.pressure
            end
        end
    end, plate)
end

-- =====================================================
-- FUNÇÃO: Iniciar instalação de suspensão
-- =====================================================

local function StartInstallation()
    if isInstalling then
        Config.Langs['waitToExecute']()
        return
    end
    
    -- Verifica permissão de instalação
    ESX.TriggerServerCallback('mirtin_suspension:checkInstallPermission', function(hasPermission)
        if not hasPermission then
            ESX.ShowNotification('Você não tem permissão para instalar suspensão!', 'error')
            return
        end
        
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        -- Verifica se está em um veículo
        if vehicle ~= 0 then
            Config.Langs['exitVehicleToInstall']()
            return
        end
        
        -- Busca veículo próximo
        local coords = GetEntityCoords(playerPed)
        vehicle = ESX.Game.GetClosestVehicle(coords)
        
        if not vehicle or vehicle == 0 then
            Config.Langs['noProximityVehicle']()
            return
        end
        
        local vehicleCoords = GetEntityCoords(vehicle)
        local distance = #(coords - vehicleCoords)
        
        if distance > 5.0 then
            Config.Langs['noProximityVehicle']()
            return
        end
        
        -- Verifica se está próximo do capô
        local hood = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, 'bonnet'))
        local hoodDistance = #(coords - hood)
        
        if hoodDistance > 3.0 then
            Config.Langs['nearHoodToInstall']()
            return
        end
        
        local plate = GetVehicleNumberPlateText(vehicle)
        
        -- Verifica propriedade
        ESX.TriggerServerCallback('mirtin_suspension:checkVehicleOwner', function(isOwner)
            if not isOwner then
                Config.Langs['notVehicleOwner'](nil)
                return
            end
            
            -- Verifica se já tem suspensão
            ESX.TriggerServerCallback('mirtin_suspension:hasSuspension', function(hasSuspension)
                if hasSuspension then
                    Config.Langs['vehicleAlreadyInstalled'](nil)
                    return
                end
                
                -- Inicia instalação
                isInstalling = true
                Config.Langs['installingSuspension']()
                
                -- Animação de instalação
                TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
                
                -- Aguarda 10 segundos
                Wait(10000)
                
                ClearPedTasksImmediately(playerPed)
                
                -- Envia para servidor
                local vehicleModel = GetEntityModel(vehicle)
                TriggerServerEvent('mirtin_suspension:installSuspension', plate, vehicleModel)
                
                isInstalling = false
            end, plate)
        end, plate)
    end)
end

-- =====================================================
-- EVENTOS
-- =====================================================

--- Evento: Abrir controle
RegisterNetEvent('mirtin_suspension:openControl', function()
    OpenSuspensionControl()
end)

--- Evento: Iniciar instalação
RegisterNetEvent('mirtin_suspension:startInstallation', function()
    StartInstallation()
end)

--- Evento: Suspensão instalada com sucesso
RegisterNetEvent('mirtin_suspension:suspensionInstalled', function(plate)
    AddToCache(plate)
    ESX.ShowNotification('Suspensão instalada com sucesso!', 'success')
end)

--- Evento: Suspensão removida
RegisterNetEvent('mirtin_suspension:suspensionRemoved', function(plate)
    RemoveFromCache(plate)
    
    local vehicle = GetPlayerVehicle()
    if vehicle then
        local vehiclePlate = GetVehicleNumberPlateText(vehicle)
        
        if vehiclePlate == plate then
            VehicleControl.ResetSuspension(vehicle)
            UIManager.Close()
        end
    end
end)

-- =====================================================
-- COMANDO: Abrir controle (registro alternativo)
-- =====================================================

RegisterCommand(Config.SuspensionConfig and Config.SuspensionConfig.command or 'ar', function()
    OpenSuspensionControl()
end, false)

-- =====================================================
-- THREAD: Auto-fechar UI ao sair do veículo
-- =====================================================

CreateThread(function()
    while true do
        Wait(1000)
        
        if UIManager.IsOpen then
            local vehicle = GetPlayerVehicle()
            
            if not vehicle then
                UIManager.Close()
                ESX.ShowNotification('Você saiu do veículo', 'info')
            end
        end
    end
end)

-- =====================================================
-- THREAD: Indicador visual de suspensão instalada
-- =====================================================

CreateThread(function()
    while true do
        Wait(0)
        
        local vehicle = GetPlayerVehicle()
        
        if vehicle and IsDriver() then
            local plate = GetVehicleNumberPlateText(vehicle)
            
            if HasSuspensionInstalled(plate) then
                -- Desenha indicador na tela
                SetTextFont(4)
                SetTextProportional(1)
                SetTextScale(0.35, 0.35)
                SetTextColour(86, 165, 255, 255)
                SetTextDropshadow(0, 0, 0, 0, 255)
                SetTextEdge(1, 0, 0, 0, 255)
                SetTextEntry("STRING")
                AddTextComponentString("~b~Suspensão AR Instalada~w~\nPressione ~INPUT_CONTEXT~ para abrir")
                DrawText(0.85, 0.90)
                
                -- Verifica tecla E
                if IsControlJustReleased(0, 38) then -- E
                    OpenSuspensionControl()
                end
            end
        else
            Wait(1000)
        end
    end
end)

-- =====================================================
-- INICIALIZAÇÃO
-- =====================================================

CreateThread(function()
    Wait(1000)
    print('[SUSPENSION] Cliente iniciado')
    print(('[SUSPENSION] Comando: /%s'):format(Config.SuspensionConfig and Config.SuspensionConfig.command or 'ar'))
end)