-- =====================================================
-- DATABASE MODULE - SUSPENSION SYSTEM
-- Gerenciamento de operações de banco de dados
-- =====================================================

Database = {}

-- =====================================================
-- FUNÇÕES DE SUSPENSÃO
-- =====================================================

--- Verifica se um veículo tem suspensão instalada
-- @param identifier string - Identifier do jogador (ESX)
-- @param plate string - Matrícula do veículo
-- @return table|nil - Dados da suspensão ou nil se não existir
function Database.GetVehicleSuspension(identifier, plate)
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_suspension WHERE identifier = ? AND plate = ?', {
        identifier,
        plate
    })
    
    if result and #result > 0 then
        return result[1]
    end
    
    return nil
end

--- Instala suspensão em um veículo
-- @param identifier string - Identifier do jogador
-- @param plate string - Matrícula do veículo
-- @param vehicleModel string - Modelo do veículo (hash ou nome)
-- @return boolean - true se instalado com sucesso
function Database.InstallSuspension(identifier, plate, vehicleModel)
    local existing = Database.GetVehicleSuspension(identifier, plate)
    
    if existing then
        print(('[SUSPENSION] Veículo %s já possui suspensão instalada'):format(plate))
        return false
    end
    
    local affected = MySQL.Sync.execute([[
        INSERT INTO player_suspension (identifier, plate, pressure, cylinder, installed)
        VALUES (?, ?, ?, ?, 1)
    ]], {
        identifier,
        plate,
        15.0, -- Pressão inicial padrão
        150.0 -- Cilindro cheio (valor do config)
    })
    
    if affected > 0 then
        print(('[SUSPENSION] Suspensão instalada no veículo %s para %s'):format(plate, identifier))
        return true
    end
    
    return false
end

--- Atualiza a pressão das bolsas de ar
-- @param identifier string - Identifier do jogador
-- @param plate string - Matrícula do veículo
-- @param pressure number - Nova pressão
-- @return boolean - true se atualizado com sucesso
function Database.UpdatePressure(identifier, plate, pressure)
    local affected = MySQL.Sync.execute([[
        UPDATE player_suspension 
        SET pressure = ?
        WHERE identifier = ? AND plate = ?
    ]], {
        pressure,
        identifier,
        plate
    })
    
    return affected > 0
end

--- Atualiza o nível do cilindro de ar
-- @param identifier string - Identifier do jogador
-- @param plate string - Matrícula do veículo
-- @param cylinder number - Novo nível do cilindro
-- @return boolean - true se atualizado com sucesso
function Database.UpdateCylinder(identifier, plate, cylinder)
    local affected = MySQL.Sync.execute([[
        UPDATE player_suspension 
        SET cylinder = ?
        WHERE identifier = ? AND plate = ?
    ]], {
        cylinder,
        identifier,
        plate
    })
    
    return affected > 0
end

--- Atualiza pressão e cilindro simultaneamente
-- @param identifier string - Identifier do jogador
-- @param plate string - Matrícula do veículo
-- @param pressure number - Nova pressão
-- @param cylinder number - Novo nível do cilindro
-- @return boolean - true se atualizado com sucesso
function Database.UpdateSuspensionState(identifier, plate, pressure, cylinder)
    local affected = MySQL.Sync.execute([[
        UPDATE player_suspension 
        SET pressure = ?, cylinder = ?
        WHERE identifier = ? AND plate = ?
    ]], {
        pressure,
        cylinder,
        identifier,
        plate
    })
    
    return affected > 0
end

--- Remove suspensão de um veículo
-- @param identifier string - Identifier do jogador
-- @param plate string - Matrícula do veículo
-- @return boolean - true se removido com sucesso
function Database.RemoveSuspension(identifier, plate)
    local affected = MySQL.Sync.execute([[
        DELETE FROM player_suspension 
        WHERE identifier = ? AND plate = ?
    ]], {
        identifier,
        plate
    })
    
    -- Remove também os presets associados
    MySQL.Sync.execute([[
        DELETE FROM suspension_presets 
        WHERE identifier = ? AND plate = ?
    ]], {
        identifier,
        plate
    })
    
    return affected > 0
end

-- =====================================================
-- FUNÇÕES DE PRESETS
-- =====================================================

--- Busca um preset específico
-- @param identifier string - Identifier do jogador
-- @param plate string - Matrícula do veículo
-- @param slot number - Slot do preset (1, 2 ou 3)
-- @return table|nil - Dados do preset ou nil
function Database.GetPreset(identifier, plate, slot)
    local result = MySQL.Sync.fetchAll([[
        SELECT * FROM suspension_presets 
        WHERE identifier = ? AND plate = ? AND preset_slot = ?
    ]], {
        identifier,
        plate,
        slot
    })
    
    if result and #result > 0 then
        return result[1]
    end
    
    return nil
end

--- Busca todos os presets de um veículo
-- @param identifier string - Identifier do jogador
-- @param plate string - Matrícula do veículo
-- @return table - Array de presets
function Database.GetAllPresets(identifier, plate)
    local result = MySQL.Sync.fetchAll([[
        SELECT * FROM suspension_presets 
        WHERE identifier = ? AND plate = ?
        ORDER BY preset_slot ASC
    ]], {
        identifier,
        plate
    })
    
    return result or {}
end

--- Salva ou atualiza um preset
-- @param identifier string - Identifier do jogador
-- @param plate string - Matrícula do veículo
-- @param slot number - Slot do preset (1, 2 ou 3)
-- @param pressure number - Pressão a salvar
-- @return boolean - true se salvo com sucesso
function Database.SavePreset(identifier, plate, slot, pressure)
    -- Valida slot
    if slot < 1 or slot > 3 then
        print(('[SUSPENSION] Slot inválido: %s'):format(slot))
        return false
    end
    
    local affected = MySQL.Sync.execute([[
        INSERT INTO suspension_presets (identifier, plate, preset_slot, pressure)
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE pressure = VALUES(pressure)
    ]], {
        identifier,
        plate,
        slot,
        pressure
    })
    
    if affected > 0 then
        print(('[SUSPENSION] Preset %d salvo para veículo %s: %.2f PSI'):format(slot, plate, pressure))
        return true
    end
    
    return false
end

--- Remove um preset específico
-- @param identifier string - Identifier do jogador
-- @param plate string - Matrícula do veículo
-- @param slot number - Slot do preset (1, 2 ou 3)
-- @return boolean - true se removido com sucesso
function Database.DeletePreset(identifier, plate, slot)
    local affected = MySQL.Sync.execute([[
        DELETE FROM suspension_presets 
        WHERE identifier = ? AND plate = ? AND preset_slot = ?
    ]], {
        identifier,
        plate,
        slot
    })
    
    return affected > 0
end

-- =====================================================
-- FUNÇÕES AUXILIARES
-- =====================================================

--- Busca todos os veículos com suspensão de um jogador
-- @param identifier string - Identifier do jogador
-- @return table - Array de veículos
function Database.GetPlayerVehicles(identifier)
    local result = MySQL.Sync.fetchAll([[
        SELECT * FROM player_suspension 
        WHERE identifier = ? AND installed = 1
    ]], {
        identifier
    })
    
    return result or {}
end

--- Limpa dados de suspensão de um jogador (usado ao sair do servidor)
-- @param identifier string - Identifier do jogador
-- @return boolean - true se resetado com sucesso
function Database.ResetPlayerData(identifier)
    local affected = MySQL.Sync.execute([[
        UPDATE player_suspension 
        SET pressure = 15.0, cylinder = 150.0
        WHERE identifier = ?
    ]], {
        identifier
    })
    
    return affected > 0
end

--- Verifica se o banco de dados está acessível
-- @return boolean - true se conectado
function Database.TestConnection()
    local success = pcall(function()
        MySQL.Sync.fetchAll('SELECT 1', {})
    end)
    
    if success then
        print('[SUSPENSION] Conexão com banco de dados: OK')
    else
        print('[SUSPENSION] ERRO: Falha na conexão com banco de dados!')
    end
    
    return success
end

-- =====================================================
-- INICIALIZAÇÃO
-- =====================================================

-- Testa conexão ao iniciar o recurso
CreateThread(function()
    Wait(1000) -- Aguarda oxmysql carregar
    Database.TestConnection()
end)

print('[SUSPENSION] Módulo de banco de dados carregado')