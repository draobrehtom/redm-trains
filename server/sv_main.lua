-- trainId -> { netId = engine net id, cars = { every car net id, engine included } }
-- The server cannot walk a train (RDR3 train sync node is not parsed, every
-- train helper in ServerGameState is #ifdef STATE_FIVE), so the cars reported
-- by the client are the only way to reach them.
Trains = {}

local ORPHAN_DELETE_ON_OWNER_DISCONNECT = 1

function getTrainEngine(trainId)
    local train = Trains[trainId]
    if not train then return nil end

    local handle = NetworkGetEntityFromNetworkId(train.netId)
    if handle == 0 or not DoesEntityExist(handle) then return nil end

    return handle
end

-- DELETE_TRAIN only reaches the engine on RDR3 (carriage recursion is
-- STATE_FIVE), so every car goes separately.
function deleteTrainEntities(trainId)
    local train = Trains[trainId]
    if not train then return 0 end

    local deleted = 0
    for _, netId in ipairs(train.cars) do
        local handle = NetworkGetEntityFromNetworkId(netId)
        if handle ~= 0 and DoesEntityExist(handle) then
            DeleteEntity(handle)
            deleted = deleted + 1
        end
    end

    return deleted
end

function checkTrains()
    print('[xx] Check other trains:')
    for k,v in ipairs(GetAllVehicles()) do
        local trainId = Entity(v).state['trainId']
        if trainId ~= nil then
            local owner = NetworkGetEntityOwner(v)
            local playerName = GetPlayerName(owner)
            print('- id', trainId, 'handle', v, 'net', NetworkGetNetworkIdFromEntity(v), 'owner', owner, playerName, 'coords', GetEntityCoords(v))
        end
    end
    print('All vehicles', json.encode(GetAllVehicles()))
end

RegisterNetEvent("Trains.Created", function(trainId, netId, carNetIds, trainsClientInfo)
    local playerId = source

    local handle = 0
    while handle == 0 do
        Wait(0)
        handle = NetworkGetEntityFromNetworkId(netId)
        print('... Get handle from net id', netId)
    end

    if getTrainEngine(trainId) then
        print('Cancel train creation due to that train already exists', trainId)
        for _, carNetId in ipairs(carNetIds) do
            local car = NetworkGetEntityFromNetworkId(carNetId)
            if car ~= 0 and DoesEntityExist(car) then DeleteEntity(car) end
        end
        return
    end

    print('[--------')
    print('Created train by player', playerId, GetPlayerName(playerId), 'TrainId and NetId', trainId, netId, 'cars', json.encode(carNetIds))
    print('Client trains', json.encode(trainsClientInfo))

    -- Per car: the train lives exactly as long as its creator (a migrated clone
    -- has no carriages and a wrong position, so it is recreated instead), and
    -- stays inside the creator's culling range so the server never hands it over.
    for _, carNetId in ipairs(carNetIds) do
        local car = NetworkGetEntityFromNetworkId(carNetId)
        if car ~= 0 and DoesEntityExist(car) then
            SetEntityOrphanMode(car, ORPHAN_DELETE_ON_OWNER_DISCONNECT)
            SetEntityDistanceCullingRadius(car, Config.CullingRadius)
        end
    end

    Entity(handle).state:set('trainId', trainId, true)

    Trains[trainId] = { netId = netId, cars = carNetIds }

    print('Server Trains', json.encode(Trains))
    print('--------]')

    CreateThread(function()
        local lastOwner = NetworkGetEntityOwner(handle)
        local newOwner = lastOwner

        local previousCoords = GetEntityCoords(handle)
        sendToDiscordDebugInfo(nil, ('Train **%s** spawned (%s)[%s]'):format(trainId, GetPlayerName(newOwner), newOwner))
        sendToDiscordDebugInfo(nil, ('**[Request]** Trailers info from **%s** [Owner: %s]'):format(trainId, newOwner))
        TriggerClientEvent('trains:requestTrailersInfo', newOwner, NetworkGetNetworkIdFromEntity(handle))
        
        local prevAt = GetGameTimer()
        local trainMigrated = false
        local lastNormalCoords = previousCoords
        while DoesEntityExist(handle) do
            newOwner = NetworkGetEntityOwner(handle)
            local coords = GetEntityCoords(handle)

            if GetGameTimer() - prevAt > 1000 then
                TriggerClientEvent('rsg-trains:client:trackswithches', newOwner, trainId, netId, 1000)
                TriggerClientEvent('rsg-trains:client:startroute', newOwner, trainId, netId, 1000)
                TriggerClientEvent('---', newOwner)
                prevAt = GetGameTimer()
            end

            -- A clone on another owner has no carriages and sits on track node 0
            -- (engine-level, see Config.CullingRadius). Whatever slipped past the
            -- guards is recreated, not kept.
            if lastOwner ~= newOwner then
                sendToDiscordDebugInfo(nil, ('Train **%s** changed owner from (%s)**[%s]** to (%s)**[%s]**\n\nLast owner **[%s]** at %s\nNew owner **[%s]** at %s'):format(
                    trainId,
                    GetPlayerName(lastOwner),
                    lastOwner,
                    GetPlayerName(newOwner),
                    newOwner,
                    lastOwner, GetEntityCoords(GetPlayerPed(lastOwner)),
                    newOwner, GetEntityCoords(GetPlayerPed(newOwner))
                ))
                print('- Recreating train (1): owner changed')
                deleteTrainEntities(trainId)
                trainMigrated = true
            end

            local dist = #(previousCoords - coords)
            if dist > 400.0 then
                print('- Train position suddenly changed for more than 400.0 units.', coords)
                local msg = ('Train **%s** position suddenly changed for more than 400.0 (%s) units (%s -> %s)'):format(trainId, dist, previousCoords, coords)
                sendToDiscordDebugInfo(nil, msg)
                print('- Recreating train (2):')
                deleteTrainEntities(trainId)
                trainMigrated = true
            end

            if GetPlayerRoutingBucket(lastOwner) ~= Config.RoutingBucket then
                print(('- Train owner quit from Routing Bucket #%s'):format(Config.RoutingBucket))
                local msg = ('Train **%s** owner (%s)[%s] quit from Routing Bucket #%s'):format(trainId, GetPlayerName(lastOwner), lastOwner, Config.RoutingBucket)
                sendToDiscordDebugInfo(nil, msg)
                deleteTrainEntities(trainId)
                trainMigrated = true
            end

            lastNormalCoords = previousCoords
            previousCoords = coords
            lastOwner = newOwner

            if trainMigrated then
                break
            end

            Wait(0)
        end
        print('(Loop) Stopped (not existing or migrated):', trainId)
        print('(Loop) Train migrated:', trainMigrated)
        
        -- Train owner changed / bug-teleported
        local trainRecreationStarted = false
        if trainMigrated then
            while DoesEntityExist(handle) do
                print('- Waiting for train deletion')
                Wait(0)
            end

            if DoesPlayerExist(newOwner) and GetPlayerRoutingBucket(newOwner) == Config.RoutingBucket then
                -- Recreated train on new owner 
                spawnTrainOnPlayer(lastOwner, trainId, lastNormalCoords, getDirectionFromClosestSimulatedStop(Config.RouteOnePoints, lastNormalCoords))
                print('- Re-spawning train on last owner')
                trainRecreationStarted = true
            else
                -- Recreate train on some other player
                print(('- Previous owner doesnt exist / not in routing bucket #%s'):format(Config.RoutingBucket))
                local playerId = getSomePlayer()
                if playerId then
                    spawnTrainOnPlayer(playerId, trainId, lastNormalCoords, getDirectionFromClosestSimulatedStop(Config.RouteOnePoints, lastNormalCoords))
                    print('- Re-spawning train on new player')
                    trainRecreationStarted = true
                else
                    print('- No other players found for recreation of train')
                end
            end

            print('- Train recreation started', trainRecreationStarted)
        end

        -- No players online / in routing bucket / no migration happened
        -- Recreate train.
        if not trainRecreationStarted then
            print('- Waiting for new players connecting to server')
            local playerId = nil

            --
            local trainConfig = nil
            for k,v in ipairs(Config.TrainSetup) do
                if v.trainid == trainId then
                    trainConfig = v
                    break
                end
            end
            trainConfig.lastCoords = lastNormalCoords

            while playerId == nil do
                playerId = getSomePlayer()
                if playerId then
                    break
                end

                -- Simulate train movement
                trainConfig.lastCoords, trainConfig.direction = simulationTick(trainId, trainConfig.lastCoords, trainConfig.direction)

                Wait(200)
            end
            print('- Some player connected -  recreate train', trainId, playerId, GetPlayerName(playerId))
            spawnTrainOnPlayer(playerId, trainId, trainConfig.lastCoords, trainConfig.direction)
        end

    end)
end)

AddEventHandler('entityRemoved', function(handle)
    local trainId = Entity(handle).state['trainId']
    if trainId == nil then
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(handle)
    local entityOwner = NetworkGetEntityOwner(handle)
    print('[x] entityRemoved: ', trainId, netId, '[x] entityOwner: ', trainId, entityOwner, GetPlayerName(entityOwner))
    Trains[trainId] = nil
    sendToDiscordDebugInfo(nil, ('Train **%s** de-spawned (%s)[%s]'):format(trainId, GetPlayerName(entityOwner), entityOwner))

    local firstEntityOwner = NetworkGetFirstEntityOwner(handle)
    if entityOwner ~= firstEntityOwner then
        print('[x] First entity owner', firstEntityOwner, GetPlayerName(firstEntityOwner))
    else
        print('[x] First entity owner same as current one', firstEntityOwner, GetPlayerName(firstEntityOwner))
        -- Train deleted from first entity owner in next cases:
        -- 1) Train was deleted manually
        -- 2) Train was unexpectetly deleted (need research)
        -- 3) Train before was migrated from other owner (despite the fact it was migrated to first owner).
        -- Golden rule: If train was migrated, then it will be deleted as soon as it will go outside of SCOPE
    end

    if entityOwner == -1 then
        -- Owner disconnected
    end
end)

function spawnTrainOnPlayer(hostingPlayerId, trainId, coords, direction)
    if not DoesPlayerExist(hostingPlayerId) then
        print('Failed: Player with hostingPlayerId does not exist')
        return
    end

    local found = false
    for k, v in ipairs(Config.TrainSetup) do
        if v.trainid == trainId then
            found = v
            break
        end
    end
    if not found then
        print('Failed: Train with id not found', trainId)
        return
    end

    -- BUG: If player disonnected during train creation (server didn't receive a response)
    -- Then train will not be re-created anymore
    -- TODO: Wait for response
    TriggerClientEvent('trains:createTrain', hostingPlayerId, trainId, coords, direction)
    local requestTimeoutAt = GetGameTimer() + 30000
end


RegisterCommand('trains', function(source, args)
    local trainId = args[2]
    spawnTrainOnPlayer(tonumber(args[1]), trainId)
end)


RegisterCommand('deltrains', function(source, args)
    for trainId, train in pairs(Trains) do
        print('Delete', trainId, 'net', train.netId, 'cars', deleteTrainEntities(trainId))
    end
end)

-- RegisterCommand('bucket', function(source, args)
--     local players = GetPlayers()
--     if #players == 0 then
--         print('Cant create train - no players on server')
--         return
--     end
--     local playerId = args[1] or players[math.random(#players)]
--     local bucket = tonumber(args[2]) or 0

--     SetPlayerRoutingBucket(playerId, bucket)
--     print('Changed player routing bucket', playerId, GetPlayerName(playerId), bucket)
-- end)

RegisterCommand('checktrains', function(source, args)
    checkTrains()
end)

RegisterCommand('deltrains_2', function(source, args)
    for k,handle in ipairs(GetAllVehicles()) do
        local netId = NetworkGetNetworkIdFromEntity(handle)
        local trainId = Entity(handle).state['trainId']
        if trainId ~= nil then
            DeleteEntity(handle)
            print('Delete', trainId, 'net', netId, 'handle', handle)
        end
    end
end)

--- 

local startedClients = {}

RegisterNetEvent('train:clientStarted', function()
    local playerId = source
    startedClients[tostring(playerId)] = true
end)

AddEventHandler('playerDropped', function()
    local playerId = source
    startedClients[tostring(playerId)] = nil
end)

function isPlayerClientReady(playerId)
    return startedClients[tostring(playerId)] ~= nil
end

function getSomePlayer()
    for k,v in ipairs(GetPlayers()) do
        if isPlayerClientReady(v) and DoesEntityExist(GetPlayerPed(v)) and GetPlayerRoutingBucket(v) == Config.RoutingBucket then
            return v
        end
    end
    return nil
end

local waitEnabled = false
function waitForPlayersThenSpawnTrains()
    if waitEnabled then
        print('Waiting already enabled')
        return
    end
    print('Success: Started waiter')
    waitEnabled = true

    local playerId = nil
    while playerId == nil do
        playerId = getSomePlayer()
        if playerId then
            break
        end

        -- Simulate trains movement
        for k,v in ipairs(Config.TrainSetup) do
            local trainId = v.trainid
            if not v.lastCoords then
                v.lastCoords = v.startcoords
            end
            v.lastCoords, v.direction = simulationTick(trainId, v.lastCoords, v.direction)
        end

        Wait(200)
    end

    waitEnabled = false

    for k,v in ipairs(Config.TrainSetup) do
        local trainId = v.trainid
        local lastCoords = v.lastCoords
        local direction = v.direction



        spawnTrainOnPlayer(playerId, trainId, lastCoords, direction)
    end
end

-- On script started - wait for players
CreateThread(function()
    waitForPlayersThenSpawnTrains()
end)

-- Debug tools:

if Config.Debug then
    -- Disable train creation (use command /trains instead)
    waitEnabled = true
    print('DEBUG: Auto-spawn trains disabled. Use "trains [playerId] [trainId]" command to spawn train manually"')
end

-- Show player blips and radius
CreateThread(function()
    while true do
        
        local players = GetPlayers()
        local data = {
            players = {},
            trains = {},
        }
        for k,v in ipairs(players) do
            table.insert(data.players, {
                playerName = GetPlayerName(v),
                playerCoords = GetEntityCoords(GetPlayerPed(v)),
                playerId = v,
                playerRadius = 424.0,
            })
        end

        if Config.Debug then
            -- Display only entity position
            for trainId in pairs(Trains) do
                local handle = getTrainEngine(trainId)
                if handle then
                    table.insert(data.trains, {
                        trainId = trainId,
                        trainCoords = GetEntityCoords(handle),
                        trainOwner = GetPlayerName(NetworkGetEntityOwner(handle)),
                    })
                end
            end
        else
            -- Display entity position / simulated position
            for k,v in pairs(Config.TrainSetup) do
                local trainId = v.trainid
                local trainCoords = nil
                local trainOwner = '-1'

                local handle = getTrainEngine(trainId)
                if handle then
                    trainCoords = GetEntityCoords(handle)
                    trainOwner = GetPlayerName(NetworkGetEntityOwner(handle))
                else
                    trainCoords = v.lastCoords
                end

                if trainCoords then
                    table.insert(data.trains, {
                        trainId = trainId,
                        trainCoords = trainCoords,
                        trainOwner = trainOwner,
                        trainName = v.trainname,
                    })
                end
            end
        end


       
        local _data = {
            players = Config.Debug and data.players or {}, -- Enable/disable player radius and blips display
            trains = data.trains
        }
        for k,v in ipairs(data.players) do
            TriggerClientEvent('train:updateBlips', v.playerId, {
                trains = GetPlayerRoutingBucket(v.playerId) == Config.RoutingBucket and _data.trains or {}, -- show trains blips only in bucket
                players = _data.players,
            })
        end

        Wait(5000)
    end
end)

RegisterCommand('delveh', function()
    for k,v in ipairs(GetAllVehicles()) do
        DeleteEntity(v)
    end
end)

RegisterNetEvent('trains:trainStopped', function(trainName, stopName)
    sendToDiscord(nil, ('**%s** stopped at **%s** (R)'):format(trainName, stopName))
end)


AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        for trainId in pairs(Trains) do
            print('Delete train', trainId, 'cars', deleteTrainEntities(trainId))
        end
    end
end)

RegisterNetEvent('trains:onRequestedTrailersInfo', function(netId, trailersAmount)
    local playerId = source

    print(netId, trailersAmount)

    local trainId = nil
    for k, train in pairs(Trains) do
        if tostring(train.netId) == tostring(netId) then
            trainId = k
            break
        end
    end
    if not trainId then
        print('Train not found')
        return
    end

    local handle = 0
    local timeoutAt = GetGameTimer() + 30000
    while handle == 0 do
        handle = NetworkGetEntityFromNetworkId(netId)
        Wait(0)
        if GetGameTimer() >= timeoutAt then
            return
        end
    end

    local entityOwner = NetworkGetEntityOwner(handle)
    if tostring(entityOwner) ~= tostring(playerId) then
        return
    end

    sendToDiscordDebugInfo(nil, ('**[Response]** Train **%s** has **%s** trailers [Owner: %s]'):format(trainId, trailersAmount, playerId))
end)

-- RegisterCommand('req', function()
--     local trainId = 'train1'
--     local newOwner = GetPlayers()[1]
--     local handle = NetworkGetEntityFromNetworkId(Trains['train1'])
    
--     sendToDiscordDebugInfo(nil, ('**[Request]** Trailers info from **%s** [Owner: %s]'):format(trainId, newOwner))

--     TriggerClientEvent('trains:requestTrailersInfo', newOwner, NetworkGetNetworkIdFromEntity(handle))
-- end)

CreateThread(function()
    while true do
        Wait(5000)
        if getSomePlayer() then
            for trainId in pairs(Trains) do
                if not getTrainEngine(trainId) then
                    sendToDiscordDebugInfo(nil, ('**[POSSIBLE BUG]** Train **%s** does not exist, despite that there are player candidates for train creation.'):format(trainId))
                end
            end
        end
    end
end)
