function getClosestStop(trainStops, atCoords)
    local closestStop = {
        dist = math.huge,
        index = nil,
    }
    for k,v in ipairs(trainStops) do
        local distance = #(v.coords - atCoords)
        if distance < closestStop.dist then
            closestStop.dist = distance
            closestStop.index = k
        end
    end
    return closestStop.index, trainStops[closestStop.index]
end

function getDirectionFromClosestSimulatedStop(trainStops, atCoords)
    local closestStop = {
        dist = math.huge,
        index = nil,
    }
    for k,v in ipairs(trainStops) do
        local distance = #(v[1] - atCoords)
        if distance < closestStop.dist then
            closestStop.dist = distance
            closestStop.index = k
        end
    end
    return trainStops[closestStop.index][2]
end