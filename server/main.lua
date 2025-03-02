lib.callback.register('neon_anpr:fetchVehicleData', function(source, plate)
    local framework = Config.Framework
    local owner, name, warrant = nil, nil, false

    if framework == 'QB' then
        local result = exports.oxmysql:executeSync('SELECT citizenid FROM player_vehicles WHERE plate = ?', { plate })
        if result and result[1] then
            owner = result[1].citizenid

            local row = exports.oxmysql:executeSync('SELECT * FROM players WHERE citizenid = ?', { owner })
            if row and row[1] then
                local info = json.decode(row[1].charinfo)
                name = '' .. info.firstname .. ' ' .. info.lastname .. ''
            end

            if Config.Flags.wanted then
                if Config.MDT == 'al_mdt' then
                    local row2 = exports.oxmysql:executeSync('SELECT * FROM mdt_warrants WHERE targetIdentifier = ?', { owner })
                    if row2 and row2[1] then
                        warrant = true
                    end
                elseif Config.MDT == 'redutzu-mdt' then
                    local row2 = exports.oxmysql:executeSync('SELECT * FROM mdt_warrants WHERE players = ?', { owner })
                    if row2 and row2[1] then
                        warrant = true
                    end
                elseif Config.MDT == 'lb-tablet' then
                    local row2 = exports.oxmysql:executeSync('SELECT * FROM lbtablet_police_warrants WHERE linked_profile_id = ?', { owner })
                    if row2 and row2[1] then
                        warrant = true
                    end
                end
            end
        end
    elseif framework == 'ESX' then
        local result = exports.oxmysql:executeSync('SELECT owner FROM owned_vehicles WHERE plate = ?', { plate })
        if result and result[1] then
            owner = result[1].owner

            local row = exports.oxmysql:executeSync('SELECT * FROM users WHERE identifier = ?', { owner })
            if row and row[1] then
                name = '' .. row[1].firstname .. ' ' .. row[1].lastname .. ''
            end

            if Config.Flags.wanted then
                if Config.MDT == 'al_mdt' then
                    local row2 = exports.oxmysql:executeSync('SELECT * FROM mdt_warrants WHERE targetIdentifier = ?', { owner })
                    if row2 and row2[1] then
                        warrant = true
                    end
                elseif Config.MDT == 'redutzu-mdt' then
                    local row2 = exports.oxmysql:executeSync('SELECT * FROM mdt_warrants WHERE players = ?', { owner })
                    if row2 and row2[1] then
                        warrant = true
                    end
                elseif Config.MDT == 'lb-tablet' then
                    local row2 = exports.oxmysql:executeSync('SELECT * FROM lbtablet_police_warrants WHERE linked_profile_id = ?', { owner })
                    if row2 and row2[1] then
                        warrant = true
                    end
                end
            end
        end
    end

    return owner and {
        name = name,
        warrant = warrant
    } or false
end)