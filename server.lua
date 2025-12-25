-- =====================================================
-- SERVER MAIN - SUSPENSION SYSTEM
-- Lógica principal do servidor
-- =====================================================

local ESX = exports['es_extended']:getSharedObject()

-- =====================================================
-- TABELA DE ESTADOS ATIVOS
-- Armazena estados temporários dos veículos em uso
-- =====================================================

local ActiveVehicles = {}

-- =====================================================
-- FUNÇÕES AUXILIARES
-- =====================================================

--- Formata matrícula (remove espaços e converte para maiúsculas)
-- @param plate string - Matrícula do veículo
-- @return string - Matrícula formatada
local function FormatPlate(plate)
    if not plate then return nil end
    plate = string.gsub(plate, '%s+', '')
    return string.upper(plate)
end

--- Obtém configuração do veículo do config.lua
-- @param model string - Modelo do veículo
-- @return table - Configuração do veículo
local function GetVehicleConfig(model)
    if not model then
        return Config.SuspensionConfig.vehicles.default
    end
    
    local modelHash = type(model) == 'number' and model or GetHashKey(model)
    
    if Config.SuspensionConfig.vehicles.list[modelHash] then
        return Config.SuspensionConfig.vehicles.list[modelHash]
    end
    
    return Config.SuspensionConfig.vehicles.default
end

--- Calcula nova pressão baseada na direção
-- @param currentPressure number - Pressão atual
-- @param currentCylinder number - Cilindro atual
-- @param direction string - Direção (up, down, superUp, superDown, maxDown)
-- @param vehicleConfig table - Configuração do veículo
-- @return number, number - Nova pressão e novo cilindro
local function CalculateNewPressure(currentPressure, currentCylinder, direction, vehicleConfig)
    local newPressure = currentPressure
    local newCylinder = currentCylinder
    
    local block = Config.SuspensionConfig.itens.block
    local pressureChange = block.pressure
    
    if direction == 'up' then
        -- Subir suspensão (aumenta pressão)
        if newCylinder >= pressureChange then
            newPressure = math.min(newPressure + pressureChange, vehicleConfig.max)
            newCylinder = newCylinder - pressureChange
        end
        
    elseif direction == 'down' then
        -- Descer suspensão (diminui pressão)
        newPressure = math.max(newPressure - pressureChange, vehicleConfig.min)
        newCylinder = math.min(newCylinder + pressureChange, Config.SuspensionConfig.itens.cylinder.value)
        
    elseif direction == 'superUp' then
        -- Subir rápido (2x)
        local change = pressureChange * 2
        if newCylinder >= change then
            newPressure = math.min(newPressure + change, vehicleConfig.max)
            newCylinder = newCylinder - change
        end
        
    elseif direction == 'superDown' then
        -- Descer rápido (2x)
        local change = pressureChange * 2
        newPressure = math.max(newPressure - change, vehicleConfig.min)
        newCylinder = math.min(newCylinder + change, Config.SuspensionConfig.itens.cylinder.value)
        
    elseif direction == 'maxDown' then
        -- Descer totalmente
        newCylinder = math.min(newCylinder + newPressure, Config.SuspensionConfig.itens.cylinder.value)
        newPressure = vehicleConfig.min
    end
    
    -- Arredonda para 2 casas decimais
    newPressure = math.floor(newPressure * 100) / 100
    newCylinder = math.floor(newCylinder * 100) / 100
    
    return newPressure, newCylinder
end

-- =====================================================
-- EVENTO: Instalar suspensão em veículo
-- =====================================================

RegisterNetEvent('mirtin_suspension:installSuspension', function(plate, vehicleModel)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        Config.Langs['vehicleNotFound'](source)
        return
    end
    
    plate = FormatPlate(plate)
    
    if not plate then
        Config.Langs['vehicleNotFound'](source)
        return
    end
    
    -- Verifica se já tem suspensão instalada
    local existing = Database.GetVehicleSuspension(xPlayer.identifier, plate)
    if existing and existing.installed == 1 then
        Config.Langs['vehicleAlreadyInstalled'](source)
        return
    end
    
    -- Instala suspensão
    local success = Database.InstallSuspension(xPlayer.identifier, plate, vehicleModel)
    
    if success then
        TriggerClientEvent('mirtin_suspension:suspensionInstalled', source, plate)
        
        -- Notifica sucesso
        xPlayer.showNotification('Suspensão a AR instalada com sucesso!', 'success')
        
        print(('[SUSPENSION] Suspensão instalada - Jogador: %s | Veículo: %s'):format(xPlayer.getName(), plate))
    else
        Config.Langs['vehicleNotFound'](source)
    end
end)

-- =====================================================
-- EVENTO: Controlar pressão da suspensão
-- =====================================================

RegisterNetEvent('mirtin_suspension:controlPressure', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local plate = FormatPlate(data.plate)
    local direction = data.direction
    local vehicleModel = data.vehicleModel
    
    if not plate or not direction then
        return
    end
    
    -- Busca dados atuais
    local suspensionData = Database.GetVehicleSuspension(xPlayer.identifier, plate)
    
    if not suspensionData or suspensionData.installed ~= 1 then
        Config.Langs['notOwnerOrNotInstalled']()
        return
    end
    
    local currentPressure = suspensionData.pressure
    local currentCylinder = suspensionData.cylinder
    
    -- Obtém configuração do veículo
    local vehicleConfig = GetVehicleConfig(vehicleModel)
    
    -- Calcula nova pressão
    local newPressure, newCylinder = CalculateNewPressure(
        currentPressure,
        currentCylinder,
        direction,
        vehicleConfig
    )
    
    -- Validações
    if direction:find('Up') and newCylinder <= 0 then
        Config.Langs['noAirInCylinder']()
        return
    end
    
    if newPressure >= vehicleConfig.max and direction:find('Up') then
        Config.Langs['maxLimitReached']()
        return
    end
    
    if newPressure <= vehicleConfig.min and direction:find('Down') then
        Config.Langs['minLimitReached']()
        return
    end
    
    -- Atualiza no banco de dados
    local success = Database.UpdateSuspensionState(xPlayer.identifier, plate, newPressure, newCylinder)
    
    if success then
        -- Atualiza estado ativo
        ActiveVehicles[plate] = {
            pressure = newPressure,
            cylinder = newCylinder,
            lastUpdate = os.time()
        }
        
        -- Retorna novos valores para o cliente
        TriggerClientEvent('mirtin_suspension:updatePressure', source, {
            pressure = newPressure,
            cylinder = newCylinder
        })
        
        -- Sincroniza com outros jogadores próximos
        TriggerClientEvent('mirtin_suspension:syncPressure', -1, plate, newPressure)
    end
end)

-- =====================================================
-- EVENTO: Salvar preset
-- =====================================================

RegisterNetEvent('mirtin_suspension:savePreset', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local plate = FormatPlate(data.plate)
    local slot = tonumber(data.slot)
    local pressure = tonumber(data.pressure)
    
    if not plate or not slot or not pressure then
        return
    end
    
    -- Valida slot
    if slot < 1 or slot > 3 then
        xPlayer.showNotification('Slot inválido! Use 1, 2 ou 3.', 'error')
        return
    end
    
    -- Salva preset
    local success = Database.SavePreset(xPlayer.identifier, plate, slot, pressure)
    
    if success then
        xPlayer.showNotification(('Preset %d salvo com %.2f PSI'):format(slot, pressure), 'success')
        
        TriggerClientEvent('mirtin_suspension:presetSaved', source, {
            slot = slot,
            pressure = pressure
        })
    else
        xPlayer.showNotification('Erro ao salvar preset', 'error')
    end
end)

-- =====================================================
-- EVENTO: Aplicar preset
-- =====================================================

RegisterNetEvent('mirtin_suspension:applyPreset', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    local plate = FormatPlate(data.plate)
    local slot = tonumber(data.slot)
    
    if not plate or not slot then
        return
    end
    
    -- Busca preset
    local preset = Database.GetPreset(xPlayer.identifier, plate, slot)
    
    if not preset then
        xPlayer.showNotification('Preset não encontrado', 'error')
        return
    end
    
    -- Busca dados atuais
    local suspensionData = Database.GetVehicleSuspension(xPlayer.identifier, plate)
    
    if not suspensionData then
        return
    end
    
    local targetPressure = preset.pressure
    local currentPressure = suspensionData.pressure
    local currentCylinder = suspensionData.cylinder
    
    -- Calcula diferença de pressão
    local pressureDiff = targetPressure - currentPressure
    
    -- Verifica se tem ar suficiente no cilindro
    if pressureDiff > 0 and currentCylinder < pressureDiff then
        Config.Langs['notAirInBag']()
        return
    end
    
    -- Calcula novo cilindro
    local newCylinder = currentCylinder - pressureDiff
    newCylinder = math.max(0, math.min(newCylinder, Config.SuspensionConfig.itens.cylinder.value))
    
    -- Atualiza no banco de dados
    local success = Database.UpdateSuspensionState(xPlayer.identifier, plate, targetPressure, newCylinder)
    
    if success then
        TriggerClientEvent('mirtin_suspension:updatePressure', source, {
            pressure = targetPressure,
            cylinder = newCylinder
        })
        
        TriggerClientEvent('mirtin_suspension:syncPressure', -1, plate, targetPressure)
        
        xPlayer.showNotification(('Preset %d aplicado: %.2f PSI'):format(slot, targetPressure), 'success')
    end
end)

-- =====================================================
-- EVENTO: Encher cilindro (compressor)
-- =====================================================

RegisterNetEvent('mirtin_suspension:fillCylinder', function(plate)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    plate = FormatPlate(plate)
    
    if not plate then
        return
    end
    
    -- Busca dados atuais
    local suspensionData = Database.GetVehicleSuspension(xPlayer.identifier, plate)
    
    if not suspensionData then
        return
    end
    
    local maxCylinder = Config.SuspensionConfig.itens.cylinder.value
    local currentCylinder = suspensionData.cylinder
    
    if currentCylinder >= maxCylinder then
        xPlayer.showNotification('Cilindro já está cheio', 'info')
        return
    end
    
    -- Enche cilindro
    local success = Database.UpdateCylinder(xPlayer.identifier, plate, maxCylinder)
    
    if success then
        TriggerClientEvent('mirtin_suspension:cylinderFilled', source, maxCylinder)
        xPlayer.showNotification('Cilindro enchido com sucesso', 'success')
    end
end)

-- =====================================================
-- EVENTO: Remover suspensão (mecânico/admin)
-- =====================================================

RegisterNetEvent('mirtin_suspension:removeSuspension', function(plate)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    plate = FormatPlate(plate)
    
    if not plate then
        return
    end
    
    -- Remove suspensão
    local success = Database.RemoveSuspension(xPlayer.identifier, plate)
    
    if success then
        ActiveVehicles[plate] = nil
        TriggerClientEvent('mirtin_suspension:suspensionRemoved', source, plate)
        xPlayer.showNotification('Suspensão removida com sucesso', 'success')
        
        print(('[SUSPENSION] Suspensão removida - Jogador: %s | Veículo: %s'):format(xPlayer.getName(), plate))
    else
        xPlayer.showNotification('Erro ao remover suspensão', 'error')
    end
end)

-- =====================================================
-- EVENTO: Jogador entrou no servidor
-- =====================================================

RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
    local source = playerId or source
    
    -- Envia configurações para o cliente
    TriggerClientEvent('mirtin_suspension:syncConfig', source, Config)
end)

-- =====================================================
-- EVENTO: Jogador saiu do servidor
-- =====================================================

AddEventHandler('esx:playerDropped', function(playerId)
    -- Remove estados ativos dos veículos do jogador
    -- (opcional: pode manter se quiser persistência entre sessões)
end)

-- =====================================================
-- COMANDO: Abrir controle (alternativa ao item)
-- =====================================================

RegisterCommand(Config.SuspensionConfig.command, function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    -- Verifica se o jogador está em um veículo
    TriggerClientEvent('mirtin_suspension:openControl', source)
end, false)

-- =====================================================
-- COMANDO: Instalar suspensão (mecânico/admin)
-- =====================================================

RegisterCommand(Config.SuspensionConfig.install_command, function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    TriggerClientEvent('mirtin_suspension:startInstallation', source)
end, false)

-- =====================================================
-- THREAD: Limpeza de estados inativos
-- =====================================================

CreateThread(function()
    while true do
        Wait(300000) -- 5 minutos
        
        local currentTime = os.time()
        
        for plate, data in pairs(ActiveVehicles) do
            -- Remove veículos inativos por mais de 10 minutos
            if currentTime - data.lastUpdate > 600 then
                ActiveVehicles[plate] = nil
                print(('[SUSPENSION] Estado removido (inativo): %s'):format(plate))
            end
        end
    end
end)

-- =====================================================
-- THREAD: Auto-salvamento periódico
-- =====================================================

CreateThread(function()
    while true do
        Wait(60000) -- 1 minuto
        
        -- Salva todos os estados ativos no banco de dados
        for plate, data in pairs(ActiveVehicles) do
            -- Busca proprietário do veículo
            MySQL.Async.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
                ['@plate'] = plate
            }, function(result)
                if result and #result > 0 then
                    Database.UpdateSuspensionState(result[1].owner, plate, data.pressure, data.cylinder)
                end
            end)
        end
    end
end)

-- =====================================================
-- INICIALIZAÇÃO
-- =====================================================

CreateThread(function()
    -- Testa conexão com banco de dados
    Wait(2000)
    Database.TestConnection()
    
    print('[SUSPENSION] Sistema de suspensão iniciado')
    print(('[SUSPENSION] Comando: /%s'):format(Config.SuspensionConfig.command))
    print(('[SUSPENSION] Instalação: /%s'):format(Config.SuspensionConfig.install_command))
end)