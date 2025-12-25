-- =====================================================
-- ESX CALLBACKS - SUSPENSION SYSTEM
-- Comunicação segura cliente-servidor
-- =====================================================

local ESX = exports['es_extended']:getSharedObject()

-- =====================================================
-- CALLBACK: Verificar se jogador possui permissão VIP
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:checkVipPermission', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false)
        return
    end
    
    -- Verifica se tem a permissão configurada no config.lua
    local hasPermission = xPlayer.getGroup() == 'admin' or 
                          xPlayer.getGroup() == 'superadmin' or
                          xPlayer.getGroup() == 'mod'
    
    -- Você pode adicionar verificação de grupo VIP customizado:
    -- local hasPermission = xPlayer.getGroup() == 'vip' or xPlayer.getGroup() == 'vip_plus'
    
    cb(hasPermission)
end)

-- =====================================================
-- CALLBACK: Verificar se jogador possui item requerido
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:checkItem', function(source, cb, itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false)
        return
    end
    
    local item = xPlayer.getInventoryItem(itemName)
    
    if item and item.count > 0 then
        cb(true)
    else
        cb(false)
    end
end)

-- =====================================================
-- CALLBACK: Verificar propriedade do veículo
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:checkVehicleOwner', function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false)
        return
    end
    
    -- Remove espaços e converte para maiúsculas
    plate = string.gsub(plate, '%s+', '')
    plate = string.upper(plate)
    
    -- Busca o veículo no banco de dados ESX
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if result and #result > 0 then
            local vehicleOwner = result[1].owner
            
            -- Verifica se o identifier do jogador corresponde
            if vehicleOwner == xPlayer.identifier then
                cb(true)
            else
                cb(false)
            end
        else
            -- Veículo não encontrado no banco de dados
            cb(false)
        end
    end)
end)

-- =====================================================
-- CALLBACK: Verificar permissão de instalação (mecânico)
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:checkInstallPermission', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false)
        return
    end
    
    -- Verifica se tem permissão de admin/moderador
    local isAdmin = xPlayer.getGroup() == 'admin' or 
                    xPlayer.getGroup() == 'superadmin' or
                    xPlayer.getGroup() == 'mod'
    
    if isAdmin then
        cb(true)
        return
    end
    
    -- Verifica se é mecânico (você pode customizar os jobs permitidos)
    local allowedJobs = {
        'mechanic',
        'mecano',
        'bennys'
    }
    
    for _, job in ipairs(allowedJobs) do
        if xPlayer.job.name == job then
            cb(true)
            return
        end
    end
    
    cb(false)
end)

-- =====================================================
-- CALLBACK: Obter dados da suspensão do veículo
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:getSuspensionData', function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(nil)
        return
    end
    
    -- Remove espaços e converte para maiúsculas
    plate = string.gsub(plate, '%s+', '')
    plate = string.upper(plate)
    
    -- Busca dados no banco de dados
    local suspensionData = Database.GetVehicleSuspension(xPlayer.identifier, plate)
    
    if suspensionData then
        -- Busca também os presets
        local presets = Database.GetAllPresets(xPlayer.identifier, plate)
        
        cb({
            pressure = suspensionData.pressure,
            cylinder = suspensionData.cylinder,
            installed = suspensionData.installed == 1,
            presets = presets
        })
    else
        cb(nil)
    end
end)

-- =====================================================
-- CALLBACK: Verificar se veículo tem suspensão instalada
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:hasSuspension', function(source, cb, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false)
        return
    end
    
    -- Remove espaços e converte para maiúsculas
    plate = string.gsub(plate, '%s+', '')
    plate = string.upper(plate)
    
    local suspensionData = Database.GetVehicleSuspension(xPlayer.identifier, plate)
    
    if suspensionData and suspensionData.installed == 1 then
        cb(true, {
            pressure = suspensionData.pressure,
            cylinder = suspensionData.cylinder
        })
    else
        cb(false, nil)
    end
end)

-- =====================================================
-- CALLBACK: Obter preset específico
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:getPreset', function(source, cb, plate, slot)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(nil)
        return
    end
    
    -- Remove espaços e converte para maiúsculas
    plate = string.gsub(plate, '%s+', '')
    plate = string.upper(plate)
    
    -- Valida slot
    if slot < 1 or slot > 3 then
        cb(nil)
        return
    end
    
    local preset = Database.GetPreset(xPlayer.identifier, plate, slot)
    
    if preset then
        cb({
            slot = preset.preset_slot,
            pressure = preset.pressure
        })
    else
        cb(nil)
    end
end)

-- =====================================================
-- CALLBACK: Verificar se jogador está próximo do capô
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:checkNearHood', function(source, cb, coords)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false)
        return
    end
    
    local playerCoords = xPlayer.getCoords(true)
    
    -- Verifica distância entre jogador e coordenadas fornecidas (capô)
    local distance = #(playerCoords - vector3(coords.x, coords.y, coords.z))
    
    -- Permite instalação se estiver a menos de 3 metros
    cb(distance < 3.0)
end)

-- =====================================================
-- CALLBACK: Validar operação de controle de pressão
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:validateControl', function(source, cb, plate, direction)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false, 'Jogador não encontrado')
        return
    end
    
    -- Remove espaços e converte para maiúsculas
    plate = string.gsub(plate, '%s+', '')
    plate = string.upper(plate)
    
    -- Verifica se tem suspensão instalada
    local suspensionData = Database.GetVehicleSuspension(xPlayer.identifier, plate)
    
    if not suspensionData or suspensionData.installed ~= 1 then
        cb(false, 'Suspensão não instalada')
        return
    end
    
    -- Valida direção
    local validDirections = {'up', 'down', 'superUp', 'superDown', 'maxDown'}
    local isValid = false
    
    for _, dir in ipairs(validDirections) do
        if direction == dir then
            isValid = true
            break
        end
    end
    
    if not isValid then
        cb(false, 'Direção inválida')
        return
    end
    
    -- Retorna dados atuais
    cb(true, {
        pressure = suspensionData.pressure,
        cylinder = suspensionData.cylinder
    })
end)

-- =====================================================
-- CALLBACK: Obter todos os veículos com suspensão
-- =====================================================

ESX.RegisterServerCallback('mirtin_suspension:getPlayerVehicles', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({})
        return
    end
    
    local vehicles = Database.GetPlayerVehicles(xPlayer.identifier)
    cb(vehicles or {})
end)

-- =====================================================
-- INICIALIZAÇÃO
-- =====================================================

print('[SUSPENSION] Callbacks ESX registrados com sucesso')