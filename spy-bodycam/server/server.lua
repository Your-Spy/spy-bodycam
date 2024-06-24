PlayerOnBodycam = {}
GlobalState.PlayerOnBodycam = PlayerOnBodycam

lib.callback.register('spy-bodycam:servercb:getPedCoords', function(source, targetId)
    local targetPed = GetPlayerPed(targetId)
    if targetPed == 0 then return false end
    local targetCoords = GetEntityCoords(targetPed)
    if targetCoords then return targetCoords end

end)

RegisterNetEvent('spy-bodycam:server:toggleList',function(bool)
    local src = source
    if bool then 
        if Config.Framework == 'qb' then 
            local Player = QBCore.Functions.GetPlayer(src)
            local Name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            local Job = Player.PlayerData.job.label
            local Rank = Player.PlayerData.job.grade.name
            PlayerOnBodycam[src] = {
                name = Name,
                jobkey = Player.PlayerData.job.name,
                job = Job,
                rank = Rank,
            }
        else
            local xPlayer  = ESX.GetPlayerFromId(src)
            local Name = xPlayer.getName()
            local Job = xPlayer.getJob().label
            local Rank = xPlayer.getJob().grade_label
            PlayerOnBodycam[src] = {
                name = Name,
                jobkey = xPlayer.getJob().name,
                job = Job,
                rank = Rank,
            }
        end

        GlobalState.PlayerOnBodycam = PlayerOnBodycam
    else
        PlayerOnBodycam[src] = nil
        GlobalState.PlayerOnBodycam = PlayerOnBodycam
    end
    SetTimeout(1000, function()
        TriggerClientEvent('spy-bodycam:updatelisteffect',-1) 
    end)

end)

RegisterNetEvent('spy-bodycam:server:ReqDeleteDecoyPed',function()
    if not Config.Dependency.UseAppearance then return end
    local src = source
    TriggerClientEvent('spy-bodycam:client:deleteDecoyPed',-1,src)
end)

RegisterNetEvent('spy-bodycam:server:ReqDecoyPed', function(cid, pedCoords)
    if not Config.Dependency.UseAppearance then return end
    local src = source
    local function handleDecoyPed(model, skin, pedCoords, src)
        local nPlayers = lib.getNearbyPlayers(vector3(pedCoords.x, pedCoords.y, pedCoords.z), 150)
        if nPlayers then
            for i = 1, #nPlayers do
                TriggerClientEvent('spy-bodycam:client:createDecoyPed', nPlayers[i].id, model, skin, pedCoords, src)
            end
        end
    end
    local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', {cid, 1})
    if result[1] ~= nil then
        local skinData = json.decode(result[1].skin)
        if Config.Dependency.UseAppearance == 'qb' then
            handleDecoyPed(tonumber(result[1].model), skinData, pedCoords, src)
        elseif Config.Dependency.UseAppearance == 'illenium' then
            handleDecoyPed(joaat(skinData.model), skinData, pedCoords, src)
        end
    end
end)

if Config.Framework == 'qb' then
    QBCore.Functions.CreateUseableItem('bodycam', function(source, item)
        TriggerClientEvent('spy-bodycam:bodycamstatus',source)
    end)
    
else
    ESX.RegisterUsableItem('bodycam', function(playerId) 
        TriggerClientEvent('spy-bodycam:bodycamstatus', playerId) 
    end)
end

