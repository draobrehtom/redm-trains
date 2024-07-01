local webhook = 'https://discord.com/api/webhooks/1165775161895690332/em94kr9TQTS41ufhrblIj3pNb01_Xdm7GoOCn9KkCnMvOJCC0JPAvlDfWJOaVqImiDQn'
function sendToDiscordDebugInfo(name, message)
    local footer = 'Date: '.. os.date("%Y-%m-%d %H:%M:%S")
    local embed = {
        {
            ["color"] = 0,
            ["title"] = '',
            ["description"] = message,
            ["footer"] = {
                ["text"] = footer,
            },
        }
    }
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
end

local webhook2 = 'https://discord.com/api/webhooks/1167180021979426896/bWinG18OKDDcb6RFlnhWEHNlliPCENrKLA3y5JprvgISIpYc160NdgtrDZNVbSfxqNAY'
function sendToDiscord(name, message)
    local footer = 'Date: '.. os.date("%Y-%m-%d %H:%M:%S")
    local embed = {
        {
            ["color"] = 0,
            ["title"] = '',
            ["description"] = message,
            ["footer"] = {
                ["text"] = footer,
            },
        }
    }
    PerformHttpRequest(webhook2, function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
end