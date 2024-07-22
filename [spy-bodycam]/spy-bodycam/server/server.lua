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

lib.callback.register('spy-bodycam:servercb:getNamESX', function(source)
    local xPlayer  = ESX.GetPlayerFromId(source)
    local Name = xPlayer.getName()
    if Name then return Name end
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
    local result
    local function handleDecoyPed(model, skin, pedCoords, src)
        local nPlayers = lib.getNearbyPlayers(vector3(pedCoords.x, pedCoords.y, pedCoords.z), 150)
        if nPlayers then
            for i = 1, #nPlayers do
                TriggerClientEvent('spy-bodycam:client:createDecoyPed', nPlayers[i].id, model, skin, pedCoords, src)
            end
        end
    end
    if Config.Framework == 'qb' then
        result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', {cid, 1})
        if result[1] ~= nil then
            local skinData = json.decode(result[1].skin)
            if Config.Dependency.UseAppearance == 'qb' then
                handleDecoyPed(tonumber(result[1].model), skinData, pedCoords, src)
            elseif Config.Dependency.UseAppearance == 'illenium' then
                handleDecoyPed(joaat(skinData.model), skinData, pedCoords, src)
            end
        end
    elseif Config.Framework == 'esx' then
        result = MySQL.single.await("SELECT skin FROM users WHERE identifier = ?", {cid})
        if result then
            local skinData = json.decode(result.skin)
            if Config.Dependency.UseAppearance == 'illenium' then
                handleDecoyPed(joaat(skinData.model), skinData, pedCoords, src)
            end
        end
    end
end)

Citizen.CreateThread(function()
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
end)

RegisterNetEvent('spy-bodycam:server:logVideoDetails', function(videoUrl,streetName)
    local src = source
    local offName 
    local offJob  
    local offRank 
    local jobKey 
    local date = os.date('%Y-%m-%d') 

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

    ---SQL UPLOAD
    MySQL.Async.execute('INSERT INTO spy_bodycam (job, videolink, street, date, playername) VALUES (@job, @videolink, @street, @date, @playername)', {
        ['@job'] = jobKey,
        ['@videolink'] = videoUrl,
        ['@street'] = streetName,
        ['@date'] = date,
        ['@playername'] = offName
    }, function(rowsChanged) end)

    if Upload.DiscordLogs.Enabled then 
        local defwebhook
        local author
        if Upload.JobUploads[jobKey] then 
            defwebhook = Upload.JobUploads[jobKey].webhook
            author = Upload.JobUploads[jobKey].author
        else
            defwebhook = Upload.DefaultUploads.webhook
            author = Upload.DefaultUploads.author
        end
        local embedData = {
            {
                title = Upload.DiscordLogs.Title,
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
        PerformHttpRequest(defwebhook, function() end, 'POST', json.encode({ username = Upload.DiscordLogs.Username, embeds = embedData}), { ['Content-Type'] = 'application/json' })
    end
end)

RegisterNetEvent('spy-bodycam:server:deleteVideoDB', function(videoUrl)
    local src = source
    if not videoUrl or videoUrl == '' then return end
    MySQL.Async.execute('DELETE FROM spy_bodycam WHERE videolink = @videolink', {
        ['@videolink'] = videoUrl
    }, function(rowsChanged)
        if rowsChanged > 0 then
            local jobKey
            local isBoss 
            if Config.Framework == 'qb' then 
                local Player = QBCore.Functions.GetPlayer(src)
                jobKey = Player.PlayerData.job.name
                isBoss = Player.PlayerData.job.isboss
            else
                local xPlayer = ESX.GetPlayerFromId(src)
                jobKey = xPlayer.getJob().name
                isBoss = (xPlayer.getJob().grade_name == 'boss')
            end
            MySQL.Async.fetchAll('SELECT * FROM spy_bodycam WHERE job = @job ORDER BY id DESC', {
                ['@job'] = jobKey
            }, function(records)
                TriggerClientEvent('spy-bodycam:client:refreshRecords', src, records, isBoss)
            end)    
        end
    end)
end)

RegisterNetEvent('spy-bodycam:server:showrecordingUI', function()
    local src = source
    local offJob   
    local jobKey
    local isBoss 
    if Config.Framework == 'qb' then 
        local Player = QBCore.Functions.GetPlayer(src)
        offJob = Player.PlayerData.job.label
        jobKey = Player.PlayerData.job.name
        isBoss = Player.PlayerData.job.isboss
    else
        local xPlayer  = ESX.GetPlayerFromId(src)
        offJob = xPlayer.getJob().label
        jobKey = xPlayer.getJob().name
        if xPlayer.getJob().grade_name == 'boss' then isBoss = true else isBoss = false end
    end
    MySQL.Async.fetchAll('SELECT * FROM spy_bodycam WHERE job = @job ORDER BY id DESC', {
        ['@job'] = jobKey
    }, function(records)
        TriggerClientEvent('spy-bodycam:client:openRecords', src, records, offJob, isBoss)
    end)    
end)

lib.addCommand('recordcam', {
    help = 'Record bodycam footage.',
    restricted = false
}, function(source, args, raw)
    local src = source
    if PlayerOnBodycam[src] then
        local defwebhook
        if Upload.ServiceUsed == 'discord' then
            local jobKey 
            if Config.Framework == 'qb' then 
                local Player = QBCore.Functions.GetPlayer(src)
                jobKey = Player.PlayerData.job.name
            else
                local xPlayer  = ESX.GetPlayerFromId(src)
                jobKey = xPlayer.getJob().name
            end
            if Upload.JobUploads[jobKey] then 
                defwebhook = Upload.JobUploads[jobKey].webhook
            else
                defwebhook = Upload.DefaultUploads.webhook
            end
        elseif Upload.ServiceUsed == 'fivemanage' or Upload.ServiceUsed == 'fivemerr'  then
            defwebhook = Upload.Token
        end
        TriggerClientEvent('spy-bodycam:client:startRec',src,defwebhook,Upload.ServiceUsed)
    else
        NotifyPlayerSv('Bodycam not turned on!','error',3000,src)
    end
end)

function NotifyPlayerSv(msg,type,time,src)
    if Config.Dependency.UseNotify == 'ox' then
        TriggerClientEvent('ox_lib:notify', src, { type = type or "success", title = '', description = msg, duration = time })      
    elseif Config.Dependency.UseNotify == 'qb' then
        TriggerClientEvent("QBCore:Notify", src, msg, type,time)
    elseif Config.Dependency.UseNotify == 'esx' then
        TriggerClientEvent("esx:showNotification", src, msg, type)
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

-- Script Version Checker
local localVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
local fxManifestUrl = "https://raw.githubusercontent.com/Your-Spy/spy-bodycam/main/%5Bspy-bodycam%5D/spy-bodycam/fxmanifest.lua"

local function extractVersion(fxManifestContent)
    for line in string.gmatch(fxManifestContent, "[^\r\n]+") do
        if line:find("^version%s+'(.-)'$") then
            return line:match("^version%s+'(.-)'$")
        end
    end
    return nil
end

local function checkForUpdates()
    PerformHttpRequest(fxManifestUrl, function(statusCode, response, headers)
        print([[^4
╔───────────────────────────────────────────────────────────────────────╗
  ____  ______   __          ____   ___  ______   ______    _    __  __ 
 / ___||  _ \ \ / /         | __ ) / _ \|  _ \ \ / / ___|  / \  |  \/  |
 \___ \| |_) \ V /   _____  |  _ \| | | | | | \ V / |     / _ \ | |\/| |
  ___) |  __/ | |   |_____| | |_) | |_| | |_| || || |___ / ___ \| |  | |
 |____/|_|    |_|           |____/ \___/|____/ |_| \____/_/   \_\_|  |_|

╚───────────────────────────────────────────────────────────────────────╝
                        ]])
        if statusCode == 200 then
            local remoteVersion = extractVersion(response)
            if remoteVersion and remoteVersion ~= localVersion then
                print("^2NEW UPDATE: ^2" .. remoteVersion .. "^3 | ^1CURRENT: " .. localVersion.." ^9>> Download new version from github")
            else
                print("^2You are on latest version: ^2" .. localVersion)
            end
        else
            print("^1Failed to check for updates. Status code: " .. statusCode)
        end        
    end, "GET", "", {["Content-Type"] = "text/plain"})
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        checkForUpdates()
    end
end)

