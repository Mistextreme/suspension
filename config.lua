-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CONFIGS
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Config = {
     SuspensionConfig = { -- Configuração dos leveis da suspensão a AR
         command = 'ar', -- Para abrir controle da suspensao a AR
         install_command = 'instalar_suspensao', -- Para instalar a suspensao a AR ( Uso para mecanicos )
 
         permissions = {
             vip_permission = 'perm.suspension', -- Permissao para abrir a suspensao a AR sem precisar ser instalada ( Uso para beneficios VIP )
             install_permission = 'mirtin_suspension.install', -- Permissao para instalar a suspensao a AR ( Uso para mecanicos )
         },
 
         requireItem = { -- Precisa de item para abrir a suspensao a AR
             active = false, -- true se precisa false se não precisa ( Caso tenha permissão de Beneficio não precisa do item )
             item = 'controle_ar', -- spawn do item
         },
 
         itens = {
             ['cylinder'] = { -- Configuração do cilindro
                 value = 150, -- Quantidade maxima de ar no cilindro
             },
 
             ['compressor'] = { -- Configuração do compressor
                 secondsToAir = 2, -- Delay em segundos para carregar o compressor
                 value = 2 -- Quantidade de ar que vai ser carregado por secondsToAir
             },
 
             ['block'] = { -- Configuração do bloco para suspensão subir mais rápido
                 wait = 80, -- Delay em ms que vai subir ou descer a suspensao
                 pressure = 0.0010 -- Quantidade de ar vai injetar por wait
             },
         },
 
         vehicles = { -- Caso queira definir tamanhos padroes por veiculos adicionar aqui.
             default = { -- Padrao Pre definido para todos os veiculos que não tiver configurado na lista abaixo
                 default = 15, -- Valor padrao ja da altura do carro
                 min = 0, -- Minimo de 0 PSI Por Bolsa de Ar
                 max = 17, -- Maximo de 10 PSI Por Bolsa de Ar
             },
 
             list = {	
                -- [`t20`] = {
                --     default = 5, -- Valor padrao ja da altura do carro
                --     min = -5, -- Minimo de 0 PSI Por Bolsa de Ar
                --     max = 15, -- Maximo de 10 PSI Por Bolsa de Ar
                -- },
                --  [`adder`] = {
                --      default = 5, -- Valor padrao ja da altura do carro
                --      min = 0, -- Minimo de 0 PSI Por Bolsa de Ar
                --      max = 15, -- Maximo de 10 PSI Por Bolsa de Ar
                --  },
             }
         }
     }
 }
 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LANGS
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Config.Langs = {
    ['noProximityVehicle'] = function(source) 
        if IsDuplicityVersion() then -- SERVER
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Nenhum veículo próximo', 'error')
            end
        else -- CLIENT
            ESX.ShowNotification('Nenhum veículo próximo', 'error')
        end
    end,
    
    ['notVehicleOwner'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Você não é o proprietário desse veículo', 'error')
            end
        else
            ESX.ShowNotification('Você não é o proprietário desse veículo', 'error')
        end
    end,
    
    ['suspensionNotConfigured'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Suspensão a AR não configurada para esse veículo', 'error')
            end
        else
            ESX.ShowNotification('Suspensão a AR não configurada para esse veículo', 'error')
        end
    end,
    
    ['vehicleAlreadyInstalled'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Veículo já possui suspensão a AR instalada', 'error')
            end
        else
            ESX.ShowNotification('Veículo já possui suspensão a AR instalada', 'error')
        end
    end,
    
    ['vehicleNotFound'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Veículo não encontrado', 'error')
            end
        else
            ESX.ShowNotification('Veículo não encontrado', 'error')
        end
    end,
    
    ['vehicleNotFoundPlayer'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Veículo não encontrado na garagem', 'error')
            end
        else
            ESX.ShowNotification('Veículo não encontrado na garagem', 'error')
        end
    end,
    
    ['noAirInCylinder'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Sem ar no cilindro', 'error')
            end
        else
            ESX.ShowNotification('Sem ar no cilindro', 'error')
        end
    end,
    
    ['maxLimitReached'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Limite máximo atingido', 'info')
            end
        else
            ESX.ShowNotification('Limite máximo atingido', 'info')
        end
    end,
    
    ['minLimitReached'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Limite mínimo atingido', 'info')
            end
        else
            ESX.ShowNotification('Limite mínimo atingido', 'info')
        end
    end,
    
    ['notAirInBag'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Você precisa no mínimo de 50 de AR no cilindro', 'error')
            end
        else
            ESX.ShowNotification('Você precisa no mínimo de 50 de AR no cilindro', 'error')
        end
    end,
    
    ['waitThis'] = function(source) 
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Aguarde para fazer isso', 'error')
            end
        else
            ESX.ShowNotification('Aguarde para fazer isso', 'error')
        end
    end,
    
    ['exitVehicleToInstall'] = function(source)
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Saia do veículo para instalar a suspensão', 'error')
            end
        else
            ESX.ShowNotification('Saia do veículo para instalar a suspensão', 'error')
        end
    end,
    
    ['nearHoodToInstall'] = function(source)
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Aproxime-se do capô do veículo', 'error')
            end
        else
            ESX.ShowNotification('Aproxime-se do capô do veículo', 'error')
        end
    end,
    
    ['installingSuspension'] = function(source)
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Instalando suspensão a AR...', 'info')
            end
        else
            ESX.ShowNotification('Instalando suspensão a AR...', 'info')
        end
    end,
    
    ['waitToExecute'] = function(source)
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Aguarde para executar', 'error')
            end
        else
            ESX.ShowNotification('Aguarde para executar', 'error')
        end
    end,
    
    ['notOwnerOrNotInstalled'] = function(source)
        if IsDuplicityVersion() then
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification('Você não é proprietário ou não possui suspensão instalada', 'error')
            end
        else
            ESX.ShowNotification('Você não é proprietário ou não possui suspensão instalada', 'error')
        end
    end
}

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FUNCTIONS ESX-LEGACY
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if IsDuplicityVersion() then -- SERVER
    ESX = exports['es_extended']:getSharedObject()
    
    function getUserIdentifier(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    end
    
    function getUserByRegistration(plate)
        -- Remove espaços e normaliza a matrícula
        plate = string.gsub(plate, '%s+', '')
        plate = string.upper(plate)
        
        local result = MySQL.Sync.fetchAll('SELECT owner FROM owned_vehicles WHERE plate = @plate', {
            ['@plate'] = plate
        })
        
        if result and #result > 0 then
            return result[1].owner
        end
        
        return false
    end
    
    function hasPermission(source, permission)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        
        -- Verifica por grupo de admin/moderador
        if permission == 'perm.suspension' then
            return xPlayer.getGroup() == 'admin' or 
                   xPlayer.getGroup() == 'superadmin' or 
                   xPlayer.getGroup() == 'mod' or
                   xPlayer.getGroup() == 'vip' or
                   xPlayer.getGroup() == 'vip_plus'
        end
        
        -- Permissão de instalação (mecânicos + admins)
        if permission == 'mirtin_suspension.install' then
            local isAdmin = xPlayer.getGroup() == 'admin' or 
                           xPlayer.getGroup() == 'superadmin' or 
                           xPlayer.getGroup() == 'mod'
            
            local isMechanic = xPlayer.job.name == 'mechanic' or 
                              xPlayer.job.name == 'mecano' or 
                              xPlayer.job.name == 'bennys'
            
            return isAdmin or isMechanic
        end
        
        return false
    end
    
    function getInventoryItem(source, item)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return 0 end
        
        local itemData = xPlayer.getInventoryItem(item)
        return itemData and itemData.count or 0
    end
    
    function getVehicleName(model, modelName)
        -- Retorna o hash do modelo como string
        -- Você pode customizar isso para buscar em sua lista de veículos
        return tostring(model)
    end
    
else -- CLIENT
    ESX = exports['es_extended']:getSharedObject()
    
    function playAnim(dict, anim)
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Wait(10)
        end
        TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
    end
end