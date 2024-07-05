PlayerOnBodycam = {}
GlobalState.PlayerOnBodycam = PlayerOnBodycam
CarsOnBodycam = {}
GlobalState.CarsOnBodycam = CarsOnBodycam

lib.callback.register('spy-bodycam:servercb:getPedCoords', function(source, targetId)
    local targetPed = GetPlayerPed(targetId)
    if targetPed == 0 then return false end
    local targetCoords = GetEntityCoords(targetPed)
    if targetCoords then return targetCoords end

end)

lib.callback.register('spy-bodycam:servercb:getCarCoords', function(source, netId)
    local veh = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(veh) then
        local targetCoords = GetEntityCoords(veh)
        if targetCoords then return targetCoords end
    else
        CarsOnBodycam[netId] = nil
        GlobalState.CarsOnBodycam = CarsOnBodycam
        return false 
    end
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

RegisterNetEvent('spy-bodycam:server:toggleListCars',function(bool,entityId,carPlate,carName,carClass)
    local src = source
    if bool then 
        local veh = NetworkGetEntityFromNetworkId(entityId)
        if DoesEntityExist(veh) then
            local jobkey
            local Name 
            if Config.Framework == 'qb' then
                local Player = QBCore.Functions.GetPlayer(src)
                jobkey = Player.PlayerData.job.name 
                Name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
            else
                local xPlayer  = ESX.GetPlayerFromId(src)
                jobkey = xPlayer.getJob().name
                Name = xPlayer.getName()
            end
            CarsOnBodycam[entityId] = {
                plate = carPlate,
                carname = carName,
                name = Name,
                jobkey = jobkey,
                carclass = carClass,
            }
            GlobalState.CarsOnBodycam = CarsOnBodycam
        else
            CarsOnBodycam[entityId] = nil
            GlobalState.CarsOnBodycam = CarsOnBodycam
        end
    else
        CarsOnBodycam[entityId] = nil
        GlobalState.CarsOnBodycam = CarsOnBodycam
    end
    SetTimeout(1000, function()
        TriggerClientEvent('spy-bodycam:updatelisteffectcar',-1) 
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
    QBCore.Functions.CreateUseableItem('dashcam', function(source, item)
        TriggerClientEvent('spy-bodycam:toggleCarCam',source)
    end)
else
    ESX.RegisterUsableItem('bodycam', function(playerId) 
        TriggerClientEvent('spy-bodycam:bodycamstatus', playerId) 
    end)
    ESX.RegisterUsableItem('dashcam', function(playerId) 
        TriggerClientEvent('spy-bodycam:toggleCarCam', playerId) 
    end)
end

RegisterNetEvent('spy-bodycam:server:logVideoDetails', function(videoUrl)
    local src = source
    local offName 
    local offJob  
    local offRank 
    local jobKey 
    
    if Config.Framework == 'qb' then 
        local Player = QBCore.Functions.GetPlayer(src)
        offName = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
        offJob = Player.PlayerData.job.label
        offRank = Player.PlayerData.job.grade.name
        jobKey = Player.PlayerData.job.name
    else
        local xPlayer  = ESX.GetPlayerFromId(src)
        offName = xPlayer.getName()
        offJob = xPlayer.getJob().label
        offRank = xPlayer.getJob().grade_label
        jobKey = xPlayer.getJob().name
    end
    
    local defwebhook
    local author
    
    if Webhook.JobUploads[jobKey] then 
        defwebhook = Webhook.JobUploads[jobKey].webhook
        author = Webhook.JobUploads[jobKey].author
    else
        defwebhook = Webhook.DefaultHook 
        author = Webhook.DefaultAuthor
    end
    
    local embedData = {
        {
            title = Webhook.Title,
            color = 16761035, 
            fields = {
                { name = "Name:", value = offName, inline = false },
                { name = "Job:", value = offJob, inline = false },
                { name = "Job Rank:", value = offRank, inline = false },
            },
            footer = {
                text =  "Date: " .. os.date("!%Y-%m-%d %H:%M:%S", os.time()),
                icon_url = "https://i.imgur.com/CuSyeZT.png",
            },
            author = author
        }
    }
    PerformHttpRequest(defwebhook, function() end, 'POST', json.encode({ username = Webhook.Username, embeds = embedData}), { ['Content-Type'] = 'application/json' })
end)

lib.addCommand('recordcam', {
    help = 'Record bodycam footage.',
    restricted = false
}, function(source, args, raw)
    local src = source
    if PlayerOnBodycam[src] then
        local jobKey 
        if Config.Framework == 'qb' then 
            local Player = QBCore.Functions.GetPlayer(src)
            jobKey = Player.PlayerData.job.name
        else
            local xPlayer  = ESX.GetPlayerFromId(src)
            jobKey = xPlayer.getJob().name
        end
        local defwebhook
        if Webhook.JobUploads[jobKey] then 
            defwebhook = Webhook.JobUploads[jobKey].webhook
        else
            defwebhook = Webhook.DefaultHook 
        end
        TriggerClientEvent('spy-bodycam:client:startRec',src,defwebhook)
    else
        NotifyPlayerSv('Bodycam not turned on!','error',3000,src)
    end

end)

function NotifyPlayerSv(msg,type,time,src)
    if Config.Dependency.UseNotify == 'ox' then
        TriggerClientEvent('ox_lib:notify', src, { type = type or "success", title = '', description = msg, duration = time })      
    else
        TriggerClientEvent("QBCore:Notify", src, msg, type,time)
    end
end

-- You can remove this if u want more optimization from the script.
-- If the vehicle is deleted or send to garage it removes it from the list.
Citizen.CreateThread(function()
    while true do
        for entityId, _ in pairs(CarsOnBodycam) do
            local veh = NetworkGetEntityFromNetworkId(entityId)
            if not DoesEntityExist(veh) then
                CarsOnBodycam[entityId] = nil
                GlobalState.CarsOnBodycam = CarsOnBodycam
            end
        end
        Citizen.Wait(60000) -- Wait for 1 min before checking again
    end
end)
