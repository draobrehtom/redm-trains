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