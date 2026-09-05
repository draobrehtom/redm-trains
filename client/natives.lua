function GetNumCarsFromTrainConfig(trainConfig)
    return Citizen.InvokeNative(0x635423D55CA84FC8, trainConfig)
end

function GetTrainModelFromTrainConfigByCarIndex(trainConfig, trainCarIndex)
    return Citizen.InvokeNative(0x8DF5F6A19F99F0D5, trainConfig, trainCarIndex)
end

function CreateMissionTrain(...)
    return Citizen.InvokeNative(0xC239DBD9A57D2A71, ...)
end

function SetTrackSwitch(...)
    return Citizen.InvokeNative(0xC239DBD9A57D2A71, ...)
end

function SetTrainTrackJunctionSwitch(...)
    return Citizen.InvokeNative(0xE6C5E2125EB210C1, ...)
end

function SetTrainMaxSpeed(...)
    Citizen.InvokeNative(0x9F29999DFDF2AEB8, ...)
end

-- Declared as Any: answers with the number 0 while loading, which is truthy in Lua.
function HasTrainLoaded(train)
    local loaded = Citizen.InvokeNative(0xBD3C4A2ED509205E, train)
    return loaded == true or loaded == 1
end

function PreventNetworkIdMigration(netId)
    Citizen.InvokeNative(0x7182EDDA1EE7DB5A, netId)
end