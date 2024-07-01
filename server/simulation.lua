local trainArrivesTimestamps = {}
local trainPointsTimestamps = {}

function simulationTick(trainId, lastCoords, direction)
    local trainArrivesAt = trainArrivesTimestamps[trainId] or GetGameTimer()
    local nextPointTickAt = trainPointsTimestamps[trainId] or GetGameTimer()
    if GetGameTimer() < trainArrivesAt then
        return lastCoords, direction
    end
    if GetGameTimer() < nextPointTickAt then
        return lastCoords, direction
    end

    -- if not lastCoords then
    --     lastCoords = Config.RouteOneTrainStops[1].coords
    -- end

    -- TODO: Add all routes
    if trainId ~= 'train1' then
        return lastCoords, direction
    end

    -- Get closest point on route
    local closestPoint = {dist = math.huge, index = nil}
    for k,v in ipairs(Config.RouteOnePoints) do
        local dist = #(lastCoords - v[1])
        if dist < closestPoint.dist then
            closestPoint.dist = dist
            closestPoint.index = k
        end
    end
    local pointIndex = closestPoint.index

    -- Itterate point
    pointIndex = pointIndex + 1
    if pointIndex >= #Config.RouteOnePoints then
        pointIndex = 1
    end

    -- Update train coordinates
    local lastCoords, direction = Config.RouteOnePoints[pointIndex][1], Config.RouteOnePoints[pointIndex][2]
    -- print('Simulation:', trainId, lastCoords)

    -- Check if train is stopped
    local index, trainStop = getClosestStop(Config.RouteOneTrainStops, lastCoords)
    if #(trainStop.coords - lastCoords) <= trainStop.dst2 then
        -- print(trainId .. ' stopped at '.. trainStop.name)
        trainArrivesTimestamps[trainId] = GetGameTimer() + trainStop.waittime

        -- Get train name
        local trainName = nil
        for k,v in ipairs(Config.TrainSetup) do
            if v.trainid == trainId then
                trainName = v.trainname
                break
            end
        end

        sendToDiscord(nil, ('**%s** stopped at **%s** (S)'):format(trainName or trainId, trainStop.name))
    end
    trainPointsTimestamps[trainId] = GetGameTimer() + Config.RouteOnePointTick

    return lastCoords, direction
end