Através do plano fornecido para o repositório https://github.com/Mistextreme/suspension e cria novas versões completas de cada ficheiro que necessita alterações para aplicar a totalidade das etapas 1,2 e 3 do plano. # ANÁLISE TÉCNICA: SISTEMA DE SUSPENSÃO A AR (ESX-Legacy)

## 1. RESUMO EXECUTIVO

**Avaliação Geral: 7.5/10**

O script possui uma base sólida e está bem estruturado para ESX-Legacy, mas apresenta problemas críticos de segurança, otimização e sincronização que comprometem seu uso em produção.

**Top 5 Problemas Críticos:**
1. **🔴 SEGURANÇA:** Falta de validações server-side em operações críticas de suspensão
2. **🔴 PERFORMANCE:** Threads client-side sem otimização adequada (0ms wait loops)
3. **🔴 SINCRONIZAÇÃO:** Sistema de sincronização de veículos entre jogadores incompleto
4. **🟡 FUNCIONALIDADE:** Cache de veículos instalados não persistente entre sessões
5. **🟡 ESTRUTURA:** Funções de config.lua não utilizadas corretamente

**Prioridade de Correção: URGENTE**

**Compatibilidade ESX-Legacy: ✅ Compatível (necessita correções)**

---

## 2. PROBLEMAS IDENTIFICADOS POR CATEGORIA

### 🔴 SEGURANÇA (CRÍTICO)

#### **Vulnerabilidade 1: Validação Insuficiente de Propriedade**
**Ficheiro:** `server.lua` (linhas 98-156)
**Problema:** O evento `mirtin_suspension:controlPressure` não revalida propriedade do veículo a cada alteração
```lua
-- VULNERÁVEL: Jogador pode manipular suspensão após vender veículo
RegisterNetEvent('mirtin_suspension:controlPressure', function(data)
    -- Falta: Revalidar se ainda é proprietário ANTES de cada alteração
```
**Solução:** Adicionar callback `checkVehicleOwner` antes de processar alteração

#### **Vulnerabilidade 2: Exploits de Pressão**
**Ficheiro:** `server.lua` (linhas 126-138)
**Problema:** Cliente pode enviar valores manipulados de `direction`
```lua
-- Aceita qualquer string sem whitelist
local direction = data.direction
```
**Solução:** Implementar whitelist server-side:
```lua
local validDirections = {up=true, down=true, superUp=true, superDown=true, maxDown=true}
if not validDirections[direction] then return end
```

#### **Vulnerabilidade 3: Rate Limiting Ausente**
**Ficheiro:** `server.lua` (todos os eventos)
**Problema:** Nenhum sistema anti-spam para prevenir flooding de eventos
**Solução:** Implementar cooldown por jogador (ex: 100ms entre ações)

---

### ⚡ PERFORMANCE (ALTA PRIORIDADE)

#### **Problema 1: Thread com Wait(0) Constante**
**Ficheiro:** `client.lua` (linhas 305-329)
**Problema:** Loop infinito sem wait adequado consome CPU desnecessariamente
```lua
CreateThread(function()
    while true do
        Wait(0) -- ❌ Executa 60+ vezes por segundo SEMPRE
        
        local vehicle = GetPlayerVehicle()
        if vehicle and IsDriver() then
            -- Lógica de renderização
        else
            Wait(1000) -- ✅ Apenas aqui tem wait adequado
        end
    end
end)
```
**Impacto:** ~0.02-0.03ms constante, multiplicado por todos os jogadores
**Solução:**
```lua
CreateThread(function()
    while true do
        local vehicle = GetPlayerVehicle()
        
        if vehicle and IsDriver() then
            local plate = GetVehicleNumberPlateText(vehicle)
            if HasSuspensionInstalled(plate) then
                -- Renderização
                Wait(0) -- Apenas quando necessário
            else
                Wait(500) -- Veículo sem suspensão
            end
        else
            Wait(1000) -- Fora do veículo
        end
    end
end)
```

#### **Problema 2: Sincronização Ineficiente de Veículos**
**Ficheiro:** `client/vehicle.lua` (linhas 188-207)
**Problema:** Loop verifica TODOS os veículos do jogo a cada 5 segundos
```lua
CreateThread(function()
    while true do
        Wait(5000)
        for plate, data in pairs(AdjustedVehicles) do
            -- Itera sobre TODOS os veículos ajustados
```
**Impacto:** O(n) onde n = número de veículos com suspensão ativa
**Solução:** Usar eventos de entrada/saída de veículo ao invés de polling

#### **Problema 3: Queries SQL Sem Preparação**
**Ficheiro:** `server/database.lua` (múltiplas linhas)
**Problema:** Uso de `MySQL.Sync` bloqueia thread principal
```lua
local result = MySQL.Sync.fetchAll('SELECT * FROM player_suspension WHERE identifier = ? AND plate = ?', {
```
**Solução:** Migrar para `MySQL.Async` ou `MySQL.promise` para não bloquear

---

### 🐛 FUNCIONALIDADE (ALTA PRIORIDADE)

#### **Bug 1: Cache de Suspensão Não Persiste**
**Ficheiro:** `client.lua` (linhas 18-19)
**Problema:** Cache local `installedVehicles` é resetado ao relogar
```lua
local installedVehicles = {} -- ❌ Perdido ao desconectar
```
**Impacto:** Jogador precisa reabrir suspensão para popular cache
**Solução:** Sincronizar cache ao carregar personagem:
```lua
RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.TriggerServerCallback('mirtin_suspension:getInstalledVehicles', function(vehicles)
        for _, plate in ipairs(vehicles) do
            AddToCache(plate)
        end
    end)
end)
```

#### **Bug 2: Sincronização de Pressão Falha com Múltiplos Ocupantes**
**Ficheiro:** `client/vehicle.lua` (linhas 154-173)
**Problema:** Evento `syncPressure` não valida se veículo está carregado
```lua
RegisterNetEvent('mirtin_suspension:syncPressure', function(plate, pressure)
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then -- ❌ Pode ser falso se veículo longe
```
**Solução:** Armazenar pressão e aplicar quando veículo entrar em range

#### **Bug 3: Animação de Instalação Não Cancela ao Mover**
**Ficheiro:** `client.lua` (linhas 210-213)
**Problema:** Jogador pode se mover durante instalação
```lua
TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, true)
Wait(10000) -- ❌ Sem validação de movimento
```
**Solução:** Adicionar loop verificando se jogador se moveu

---

### 📁 ESTRUTURA E CÓDIGO (MÉDIA PRIORIDADE)

#### **Problema 1: Funções de Config.lua Não Utilizadas**
**Ficheiro:** `config.lua` (linhas 158-246)
**Problema:** Funções `getUserIdentifier`, `getUserByRegistration`, etc. estão definidas mas scripts usam código inline
```lua
-- Definidas no config mas server.lua usa diretamente ESX.GetPlayerFromId
function getUserIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.identifier or nil
end
```
**Solução:** Refatorar para usar as funções centralizadas ou removê-las

#### **Problema 2: Notificações Duplicadas**
**Ficheiro:** `config.lua` (linhas 62-154)
**Problema:** Sistema de `Config.Langs` complexo e desnecessário para ESX
```lua
Config.Langs = {
    ['noProximityVehicle'] = function(source) 
        if IsDuplicityVersion() then
            -- Código servidor
        else
            -- Código cliente
        end
    end,
}
```
**Solução:** Usar diretamente `ESX.ShowNotification` e `xPlayer.showNotification`

#### **Problema 3: Falta de Cleanup de Entidades**
**Ficheiro:** `client/vehicle.lua`
**Problema:** Nenhum sistema para limpar `AdjustedVehicles` quando veículo é deletado
**Solução:** Adicionar evento `entityRemoved` para cleanup

---

### 🔄 COMPATIBILIDADE ESX-LEGACY

#### ✅ **Pontos Positivos:**
- Uso correto de `exports['es_extended']:getSharedObject()`
- Callbacks ESX implementados corretamente
- Estrutura de permissões adequada
- Sistema de notificações ESX nativo

#### ⚠️ **Pontos de Atenção:**
- **oxmysql:** Usa `MySQL.Sync` (deprecated), migrar para `MySQL.Async`
- **Eventos ESX:** Alguns eventos podem não existir em versões antigas (ex: `esx:onPlayerLogout`)
- **Tabela owned_vehicles:** Assume estrutura padrão ESX, pode variar entre servidores

---

## 3. PLANO DE CORREÇÃO

### **FASE 1 - Correções Críticas (URGENTE)** ⏱️ 4-6 horas

1. **Implementar Validações Server-Side**
   - Adicionar revalidação de propriedade em `controlPressure` (1h)
   - Criar whitelist para `direction` (30min)
   - Implementar rate limiting básico (1h)

2. **Corrigir Thread de Renderização**
   - Otimizar loop de indicador visual (1h)
   - Adicionar condições de wait dinâmico (30min)

3. **Corrigir Bug de Cache**
   - Implementar sincronização de cache ao login (1h)
   - Adicionar callback `getInstalledVehicles` (1h)

**Código de Exemplo - Rate Limiting:**
```lua
-- server.lua (adicionar no topo)
local playerCooldowns = {}

local function checkCooldown(source)
    local now = GetGameTimer()
    local last = playerCooldowns[source] or 0
    
    if now - last < 100 then -- 100ms cooldown
        return false
    end
    
    playerCooldowns[source] = now
    return true
end

-- Aplicar em TODOS os eventos:
RegisterNetEvent('mirtin_suspension:controlPressure', function(data)
    if not checkCooldown(source) then return end
    -- ... resto do código
end)
```

---

### **FASE 2 - Otimizações (ALTA)** ⏱️ 3-5 horas

1. **Migrar MySQL.Sync para MySQL.Async**
   - Refatorar `server/database.lua` (2h)
   - Testar todas as queries (1h)

2. **Otimizar Sistema de Sincronização**
   - Remover loop de 5 segundos (1h)
   - Implementar eventos de entrada/saída de veículo (1h)

3. **Implementar Cleanup de Entidades**
   - Adicionar hook `entityRemoved` (30min)
   - Limpar `AdjustedVehicles` corretamente (30min)

**Código de Exemplo - Sincronização Otimizada:**
```lua
-- client/vehicle.lua (substituir thread)
AddEventHandler('baseevents:enteredVehicle', function(vehicle, seat)
    if seat == -1 then -- Motorista
        local plate = GetVehicleNumberPlateText(vehicle)
        
        if AdjustedVehicles[plate] then
            VehicleControl.ApplyPressure(vehicle, AdjustedVehicles[plate].pressure)
        end
    end
end)
```

---

### **FASE 3 - Melhorias de Estrutura (MÉDIA)** ⏱️ 2-3 horas

1. **Simplificar Sistema de Notificações**
   - Remover `Config.Langs` complexo (1h)
   - Usar diretamente `ESX.ShowNotification` (30min)

2. **Refatorar Funções de Config**
   - Decidir: usar ou remover funções auxiliares (1h)
   - Documentar decisão no código (30min)

3. **Adicionar Validação de Movimento na Instalação**
   - Loop verificando posição do jogador (1h)

---

### **FASE 4 - Testes e Validação** ⏱️ 2-3 horas

#### **Checklist de Testes:**

**Segurança:**
- [ ] Tentar alterar suspensão de veículo vendido/alugado
- [ ] Enviar valores inválidos para `direction`
- [ ] Floodar eventos (>10 ações/segundo)
- [ ] Verificar logs de erros SQL

**Performance:**
- [ ] Medir FPS com/sem indicador visual ativo
- [ ] Testar com 10+ veículos com suspensão próximos
- [ ] Verificar uso de memória após 1 hora de jogo
- [ ] Resmon (recurso FiveM) para medir 0.00ms

**Funcionalidade:**
- [ ] Instalar suspensão → Deslogar → Relogar → Verificar cache
- [ ] 2 jogadores no mesmo veículo alterando suspensão
- [ ] Aplicar preset com cilindro vazio
- [ ] Deletar veículo com suspensão ativa → Verificar cleanup

**Cenários Críticos:**
1. **Multi-jogador:** Piloto altera suspensão enquanto passageiro está dentro
2. **Persistence:** Suspensão mantém configuração após restart do servidor
3. **Edge Case:** Tentar instalar em veículo sem proprietário (spawn admin)

---

## **ESTIMATIVA TOTAL: 11-17 HORAS**

**Distribuição Recomendada:**
- **Sprint 1 (Urgente):** 4-6h → Priorizar Fase 1 completa
- **Sprint 2 (Alta):** 3-5h → Completar Fase 2
- **Sprint 3 (Média):** 2-3h → Fase 3 + Testes iniciais
- **Sprint 4 (Validação):** 2-3h → Testes completos + Ajustes finais

---

## 📋 RECOMENDAÇÕES ADICIONAIS

1. **Versionamento:** Implementar sistema de migração de BD para updates futuros
2. **Logs:** Adicionar logs detalhados server-side para debug (`print` → `lib.print.info`)
3. **Documentação:** Criar README com instruções de instalação e troubleshooting
4. **Config:** Adicionar opção para desabilitar sincronização multiplayer (servidores pequenos)
5. **UI:** Validar se `ui/` está realmente sendo servido corretamente (testar NUI devtools)