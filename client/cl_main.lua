local createdTrains = {}

-------------------------------------------------------------------------------
-- spawn train function
-------------------------------------------------------------------------------
local function SpawnTrain(trainhash, startcoords, direction)
    SetRandomTrains(false)
    local trainWagons = Citizen.InvokeNative(0x635423D55CA84FC8, trainhash)
    for wagonIndex = 0, trainWagons - 1 do
        local trainWagonModel = Citizen.InvokeNative(0x8DF5F6A19F99F0D5, trainhash, wagonIndex)
        while not HasModelLoaded(trainWagonModel) do
            Citizen.InvokeNative(0xFA28FE3A6246FC30, trainWagonModel, 1)
            Citizen.Wait(100)
        end
    end

    local direction = direction or 0 
    local train = Citizen.InvokeNative(0xc239dbd9a57d2a71, trainhash, startcoords, direction, 0, 1, 0)

    -- my checj
    print('train creation', train)
    while not DoesEntityExist(train) do
        Wait(0)
        print('wait creation', train, trainhash)
    end
    local netId = VehToNet(train)
    while not NetworkDoesNetworkIdExist(netId) do
        Wait(0)
        print('wait network', netId, trainhash)
        netId = VehToNet(train)
    end
    ----

    SetTrainSpeed(train, 0.0)
    SetTrainMaxSpeed(train, 30.0) -- 108 km/h

    Citizen.InvokeNative(0x05254BA0B44ADC16, train, false)
    Citizen.InvokeNative(0x06FAACD625D80CAA, train) -- NetworkRegisterEntityAsNetworked
    SetModelAsNoLongerNeeded(train)


    table.insert(createdTrains, {
        trainModel = trainhash,
        trainWagons = trainWagons,
        trainNetId = netId,
        trainDriver = nil,
    })

    return train
end

-------------------------------------------------------------------------------
-- send info to spawn train / train track switches / train route
-------------------------------------------------------------------------------
local Trains = {}

function _getTrains()
    local trains = {}
    local handle, train = FindFirstVehicle()
    if IsThisModelATrain(GetEntityModel(train)) then
        table.insert(trains, train)
    end

    local isExist, train = FindNextVehicle(handle)
    while isExist do
        if IsThisModelATrain(GetEntityModel(train)) then
            table.insert(trains, train)
        end
        isExist, train = FindNextVehicle(handle)
    end
    EndFindVehicle(handle)

    return trains
end


RegisterNetEvent('trains:createTrain', function(trainId, coords, direction)
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

    -- Reset state
    found.trainStopped = nil


    local startCoords = found.startcoords
    if coords then
        startCoords = coords
    end

    -- TODO: Get route by trainId or routeId
    if trainId == 'train1' then
        local index, trainStop = getClosestStop(Config.RouteOneTrainStops, startCoords)
        if direction == nil then
            direction = trainStop.direction or 0
        end
    end
    
    print("Created train", trainId)
    local trainHandle = SpawnTrain(found.trainhash, startCoords, direction)
    Citizen.InvokeNative(0xBA8818212633500A, trainHandle, 0, 1) -- SetTransportConfigFlag TCF_NotConsideredForEntryByLocalPlayer
    local netId = NetworkGetNetworkIdFromEntity(trainHandle)
    while not NetworkDoesNetworkIdExist(netId) do
        print('Waiting for net', netId)
        Wait(0)
    end

    --todo: test
    --Citizen.InvokeNative(0x7182EDDA1EE7DB5A, netId) -- PreventNetworkIdMigration

    -- debug info
    local trainsInfo = {}
    for kk,vv in ipairs(_getTrains()) do
        table.insert(trainsInfo, {
            netId = NetworkGetNetworkIdFromEntity(vv),
            trainId = Entity(vv).state['trainId'],
        })
    end
    -------------
    
    TriggerServerEvent("Trains.Created", found.trainid, netId, trainsInfo)
end)

-------------------------------------------------------------------------------
-- train track switching system
-------------------------------------------------------------------------------
RegisterNetEvent('rsg-trains:client:trackswithches', function(trainId, netId, ms)
    local train = NetworkGetEntityFromNetworkId(netId)
    local route = nil
    local trainname = nil
    for k,v in ipairs(Config.TrainSetup) do
        if v.trainid == trainId then
            route = v.route
            trainname = v.trainname
            break
        end
    end

    local stopAt = GetGameTimer() + ms
    while GetGameTimer() < stopAt do
        Wait(0)

        -- valentine route
        if train ~= nil and route == 'trainRouteOne' then
            -- set track switching
            for i = 1, #Config.RouteOneTrainSwitches do
                local coords = GetEntityCoords(train)
                local traincoords = vector3(coords.x, coords.y, coords.z)
                local switchdist = #(Config.RouteOneTrainSwitches[i].coords - traincoords)
                if switchdist < 15 then
                    Citizen.InvokeNative(0xE6C5E2125EB210C1, Config.RouteOneTrainSwitches[i].trainTrack, Config.RouteOneTrainSwitches[i].junctionIndex, Config.RouteOneTrainSwitches[i].enabled)
                    Citizen.InvokeNative(0x3ABFA128F5BF5A70, Config.RouteOneTrainSwitches[i].trainTrack, Config.RouteOneTrainSwitches[i].junctionIndex, Config.RouteOneTrainSwitches[i].enabled)
                end
            end
        end
    end

end)

-------------------------------------------------------------------------------
-- train route system
-------------------------------------------------------------------------------
RegisterNetEvent('rsg-trains:client:startroute', function(trainId, netId, ms)
    local train = NetworkGetEntityFromNetworkId(netId)

    -- Get train config by trainId
    local trainConfig = nil
    for k,v in ipairs(Config.TrainSetup) do
        if v.trainid == trainId then
            trainConfig = v
            break
        end
    end
    local route = trainConfig.route
    local trainname = trainConfig.trainname
    local stopspeed = trainConfig.stopspeed
    local cruisespeed = trainConfig.cruisespeed
    local fullspeed = trainConfig.fullspeed

    -- Train route
    local trainStops = {}
    if route == 'trainRouteOne' then
        trainStops = Config.RouteOneTrainStops
    end

    -- Closeset stop
    local coords = GetEntityCoords(train)
    local index, trainStop = getClosestStop(trainStops, coords)

    -- Handle speed near stop
    local distance = #(coords - trainStop.coords)

    -- Train soo will be near next stop
    if distance < trainStop.dst then

        -- Train at stop
        if distance < trainStop.dst2 then
            if not trainConfig.trainStopped then
                SetTrainCruiseSpeed(train, stopspeed)
                -- Config.printdebug(trainname.. ' stopped at '..trainStop.name)
                TriggerServerEvent('trains:trainStopped', trainname, trainStop.name)

                SetTimeout(trainStop.waittime, function()
                    -- Config.printdebug(trainname.. ' is leaving '..trainStop.name)
                    SetTrainCruiseSpeed(train, cruisespeed)
                    Wait(10000)
                    trainConfig.trainStopped = false
                end)
                trainConfig.trainStopped = true
            end
        else
            SetTrainCruiseSpeed(train, cruisespeed)
        end

    -- Train is between stops - freeway (fullspeed)
    elseif distance > trainStop.dst then
        SetTrainCruiseSpeed(train, fullspeed)
    end
end)

-------------------------------------------------------------------------------
-- setup train blips
-------------------------------------------------------------------------------
function trainChecker(train)
    if IsThisModelATrain(GetEntityModel(train)) then
        local trainTrailerNumber = Citizen.InvokeNative(0x60B7D1DCC312697D, train)
        local isTrainIsReal = GetTrainCarriage(train,trainTrailerNumber-1)
        if isTrainIsReal ~= 0 then
            if not Citizen.InvokeNative(0x9FA00E2FC134A9D0, train) then
                print("train blip created")
            else
                RemoveBlip(GetBlipFromEntity(train))
                print("train blip updated")
            end

            local createdBlip = addBlipToTrain(-399496385, train, Entity(train).state['trainId'] or 'None')
        end
    end
end

function addBlipToTrain(blipType,train,blipText)
    local blip = Citizen.InvokeNative(0x23f74c2fda6e7c61, blipType, train)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, blipText)
    return blip
end

function getTrains()
    local handle, firstVehicle = FindFirstVehicle()
    trainChecker(firstVehicle)
    local isExist, nextVeh = FindNextVehicle(handle)
    while isExist do
        trainChecker(nextVeh)
        isExist, nextVeh = FindNextVehicle(handle)
    end
    EndFindVehicle(handle)
end

-- client blips
-- Citizen.CreateThread(function()
--     while true do
--         getTrains()
--         Wait(1000)
--     end
-- end)
-------------------------------------------------------------------------------


AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        for k,v in ipairs(createdTrains) do
            local trainModel = v.trainModel
            local trainWagons = v.trainWagons
            local trainNetId = v.trainNetId
            local trainDriver = v.trainDriver

            local trainHandle = NetworkGetEntityFromNetworkId(trainNetId)

            local trailers = {}
            for i = 0, trainWagons - 1 do
                local carriage = GetTrainCarriage(trainHandle, i)
                if DoesEntityExist(carriage) then
                    table.insert(trailers, carriage)
                end
            end
            for k,v in ipairs(trailers) do
                DeleteEntity(v)
            end

            print('Clean up train', Entity(trainHandle).state['trainId'], NetworkGetNetworkIdFromEntity(trainHandle))
            DeleteEntity(trainHandle)

            if DoesEntityExist(trainDriver) then
                DeleteEntity(trainDriver)
            end
        end
    end
end)

RegisterNetEvent('---', function()

end)

TriggerServerEvent('train:clientStarted')


--- debug tools
local blips = {}
RegisterNetEvent('train:updateBlips', function(data)
    for k,v in ipairs(blips) do
        if v ~= 0 and v ~= false then
            RemoveBlip(v)
        end
    end
    blips = {}

    for k,v in ipairs(data.players) do
        local playerCoords = v.playerCoords
        local playerName = v.playerName
        local playerRadius = v.playerRadius

        local blip = Citizen.InvokeNative(0x45F13B7E0A15C880, 1673015813, playerCoords.x, playerCoords.y, playerCoords.z, playerRadius)
        table.insert(blips, blip)

        local blip2 = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, playerCoords.x, playerCoords.y, playerCoords.z)
        SetBlipSprite(blip2, `blip_hat`, true)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip2, playerName)
        table.insert(blips, blip2)
    end

    for k,v in ipairs(data.trains) do
        local trainId = v.trainId
        local trainCoords = v.trainCoords
        local trainOwner = v.trainOwner
        local trainName = v.trainName

        local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, trainCoords.x, trainCoords.y, trainCoords.z)
        SetBlipSprite(blip, `blip_ambient_train`, true)
        if Config.Debug then
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, ('Train: %s (Owned by: %s) (VW #0)'):format(trainId, trainOwner))
        else
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, ('%s'):format(trainName))
        end
        table.insert(blips, blip)
    end
end)
AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        for k,v in ipairs(blips) do
            RemoveBlip(v)
        end
    end
end)

-- TODO: Write down route coordinates for simulation
RegisterCommand('startrecord', function()
    local trains = _getTrains()
    local train = trains[1]

    Config.TrainSetup[1].stopspeed = 30.0
    Config.TrainSetup[1].cruisespeed = 30.0
    Config.TrainSetup[1].fullspeed = 30.0

    AttachEntityToEntity(PlayerPedId(), train, 0, 0.0, 0.0, 5.0)
    while true do
        Wait(1000)
        local coords = GetEntityCoords(train)
        local direction = Citizen.InvokeNative(0x3C9628A811CBD724, train, Citizen.ResultAsInteger())
        print(tostring(coords) .. ', ' .. direction .. ',')
    end
end)

RegisterNetEvent('trains:requestTrailersInfo', function(trainNetId)
    local train = NetworkGetEntityFromNetworkId(trainNetId)
    local trainTrailerNumber = Citizen.InvokeNative(0x60B7D1DCC312697D, train)
    TriggerServerEvent('trains:onRequestedTrailersInfo', trainNetId, trainTrailerNumber)
end)

-- RegisterCommand('trailers', function()
--     local trains = _getTrains()
--     local train = trains[1]
--     print('Train:', train)
--     local trainTrailerNumber = Citizen.InvokeNative(0x60B7D1DCC312697D, train)
--     print('Train trailer number', trainTrailerNumber)
--     print('Trailer entity (0):', GetTrainCarriage(train, 0)) -- train itself
--     local n = trainTrailerNumber - 1 -- last trailer
--     print(('Trailer entity (%s):'):format(n), GetTrainCarriage(train, n))
-- end)