PlayerJob = nil
local bodycam = nil
local targetPed = nil
local targetPedId = nil
local goBackCoords = nil
local PlyInCam = false
local PlyInSelfCam = false
local bcamstate = false
local carCam = false

-- for prop and ped
local propNetID = nil
local pedProps = {}
local charPed = {}

--------Resource Start
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
	PlayerJob = GetPlayerDataCore().job
end)
AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() == resourceName then
        if PlyInCam then 
            ForceQuitBodyCam()
        end
        if PlyInSelfCam then
            ForceQuitBodyCamSelf()
        end
        for k,v in pairs(pedProps)do
            if v and DoesEntityExist(v) then
                DeleteEntity(v)
            end
        end
        for k,v in pairs(charPed)do
            if v then 
                if DoesEntityExist(v) then
                    DeleteEntity(v)
                end
            end
        end
    end 
end)
  
if Config.Framework == 'qb' then 
    ---------PlayerLoaded
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	    PlayerJob = GetPlayerDataCore().job
    end)	

    ---------Job Update
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
	    PlayerJob = JobInfo
    end)
else
	-- PlayerLoaded
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded',function(xPlayer, isNew, skin)
        PlayerJob = xPlayer.job
    end)
        
    -- Job Update
    RegisterNetEvent('esx:setJob')
    AddEventHandler('esx:setJob', function(JobInfo)
        PlayerJob = JobInfo
    end)
end


RegisterNetEvent('spy-bodycam:startWatching',function(targetId)
    local ownId = GetPlayerServerId(PlayerId())
    if targetId == ownId then return TriggerEvent('spy-bodycam:startSelfWatching',targetId) end
    local targetCoords = lib.callback.await('spy-bodycam:servercb:getPedCoords', false, targetId)
    if not targetCoords then return NotifyPlayer('Player not found!', 'error', 2500) end
    targetPedId = targetId
    LocalPlayer.state:set("inv_busy", true, true) TriggerEvent('inventory:client:busy:status', true) TriggerEvent('canUseInventoryAndHotbar:toggle', false)
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(100)
    end
    FreezeEntityPosition(cache.ped, true)
    SetEntityVisible(cache.ped, false) -- Set invisible
    SetEntityCollision(cache.ped, false, false) -- Set collision
    SetEntityInvincible(cache.ped, true) -- Set invincible
    NetworkSetEntityInvisibleToNetwork(cache.ped, true) -- Set invisibility
    SetEntityCoords(cache.ped, targetCoords.x, targetCoords.y, targetCoords.z - 100.0)
    TriggerServerEvent('spy-bodycam:server:ReqDecoyPed',GetPlayerDataCore().citizenid,goBackCoords)
    Wait(500)
    local targetPlayer = GetPlayerFromServerId(targetId)
    targetPed = GetPlayerPed(targetPlayer)
    bodycam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
    AttachCamToPedBone(bodycam, targetPed, 46240, 0.1, 0.025, 0.1, true)
	SetCamFov(bodycam, 100.0)
    pedHeading = GetEntityHeading(targetPed)
    PlyInCam = true
    SetCamRot(bodycam, 0, 0, pedHeading, 2)
	RenderScriptCams(true, false, 0, 1, 0)
    ShakeCam(bodycam, "HAND_SHAKE", 1.0) 
    SetCamShakeAmplitude(bodycam, 2.0) 
    SetTimecycleModifier(Config.CameraEffect)
    SetTimecycleModifierStrength(0.5)
    DoScreenFadeIn(1000)
    Citizen.CreateThread(function()
        SetPlayerNearTarget()
    end)
    Citizen.CreateThread(function()
        SetCamRotation()
    end)
    Citizen.CreateThread(function()
        SetCarCam()
    end)
end)


RegisterNetEvent('spy-bodycam:startSelfWatching',function(targetId)
    targetPed = cache.ped
    targetPedId = targetId
    LocalPlayer.state:set("inv_busy", true, true) TriggerEvent('inventory:client:busy:status', true) TriggerEvent('canUseInventoryAndHotbar:toggle', false)
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(100)
    end
    PlayWatchAnim(cache.ped,true)
    FreezeEntityPosition(targetPed, true)
    Wait(500)
    bodycam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
    AttachCamToPedBone(bodycam, targetPed, 46240, 0.1, 0.025, 0.1, true)
	SetCamFov(bodycam, 100.0)
    pedHeading = GetEntityHeading(targetPed)
    PlyInSelfCam = true
    SetCamRot(bodycam, 0, 0, pedHeading, 2)
	RenderScriptCams(true, false, 0, 1, 0)
    ShakeCam(bodycam, "HAND_SHAKE", 1.0) 
    SetCamShakeAmplitude(bodycam, 2.0) 
    SetTimecycleModifier('Island_CCTV_ChannelFuzz')
    SetTimecycleModifierStrength(0.5)
    DoScreenFadeIn(1000)
end)

RegisterNetEvent('spy-bodycam:bodycamstatus',function()
    local isJobUse = CheckAllowedJob()
    if not isJobUse then return NotifyPlayer('You are not authorized!', 'error', 2500) end
    local acvstring
    if bcamstate then acvstring = 'Deactivating' else acvstring = 'Activating' end
    if Config.Dependency.UseProgress == 'ox' then
        if lib.progressBar({
            duration = 2500,
            label = acvstring..' Bodycam...',
            useWhileDead = false,
            canCancel = true,
            anim = {
                dict = 'clothingtie',
                clip = 'try_tie_positive_a'
            },
        })  then
            bcamstate = not bcamstate
            BodyOverlay(bcamstate)
            TriggerServerEvent('spy-bodycam:server:toggleList',bcamstate)
            toggleProp(bcamstate)
            if bcamstate then 
                Citizen.CreateThread(function()
                    CheckForItem()
                end)
            end
            else
            NotifyPlayer('Cancelled!', 'error')
        end   
    else
        QBCore.Functions.Progressbar('spy_bdycam', acvstring..' Bodycam...', 2500, false, true, {
            disableMovement = false,
            disableCarMovement = false,
            disableMouse = false,
            disableCombat = true,
        }, {
            animDict = 'clothingtie',
            anim = 'try_tie_positive_a',
            flags = 49
        }, {}, {}, function() -- Done
            StopAnimTask(cache.ped, 'clothingtie', 'try_tie_positive_a', 1.0)
            bcamstate = not bcamstate
            BodyOverlay(bcamstate)
            TriggerServerEvent('spy-bodycam:server:toggleList',bcamstate)
            toggleProp(bcamstate)
            if bcamstate then 
                Citizen.CreateThread(function()
                    CheckForItem()
                end)
            end
        end, function()
            StopAnimTask(cache.ped, 'clothingtie', 'try_tie_positive_a', 1.0)
            NotifyPlayer('Cancelled!', 'error')
        end)
    end
end)

RegisterNetEvent('spy-bodycam:updatelisteffect',function()
    if PlyInSelfCam or PlyInCam then
        if (not GlobalState.PlayerOnBodycam[targetPedId]) then 
            if PlyInSelfCam then
                QuitBodyCamSelf()
            elseif PlyInCam then
                QuitBodyCam()
            end
        end
    end
end)

RegisterNetEvent('spy-bodycam:openActiveMenu', function(locId)
    local optionsMenu = {}
    if Config.Dependency.UseMenu == 'qb' then
        optionsMenu[#optionsMenu+1] = { header = 'Active Bodycams',isMenuHeader = true}
        optionsMenu[#optionsMenu+1] = { icon = "fas fa-circle-xmark", header = "Close", params = { event = "spy:close" } }
    end
    for k, v in pairs(GlobalState.PlayerOnBodycam) do
        if Config.WatchLoc[locId].jobCam then  
            if isLocFilterTrue(locId,v.jobkey) then 
                if Config.Dependency.UseMenu == 'ox' then 
                    optionsMenu[#optionsMenu+1] = {
                        title = v.name,
                        description = v.job.." | "..v.rank,
                        icon = 'video',
                        onSelect = function()
                            TriggerEvent('spy-bodycam:startWatching',k)
                            local coord = GetEntityCoords(cache.ped)
                            goBackCoords = vector4(coord.x, coord.y, coord.z -1 , GetEntityHeading(cache.ped))
                            SetTimeout(2000, function()
                                OpenWatch(true,k,v.name)
                            end)
                        end
                    }
                else
                    optionsMenu[#optionsMenu+1] = { 
                        header = v.name,
                        txt = v.job.." | "..v.rank,
                        icon = 'fas fa-video',
                        params = {
                            isAction = true,
                            event = function()
                                TriggerEvent('spy-bodycam:startWatching',k)
                                local coord = GetEntityCoords(cache.ped)
                                goBackCoords = vector4(coord.x, coord.y, coord.z -1 , GetEntityHeading(cache.ped))
                                SetTimeout(2000, function()
                                    OpenWatch(true,k,v.name)
                                end)
                            end
                        } 
                    }
                end
            end
        else
            if Config.Dependency.UseMenu == 'ox' then 
                optionsMenu[#optionsMenu+1] = {
                    title = v.name,
                    description = v.job.." | "..v.rank,
                    icon = 'video',
                    onSelect = function()
                        TriggerEvent('spy-bodycam:startWatching',k)
                        local coord = GetEntityCoords(cache.ped)
                        goBackCoords = vector4(coord.x, coord.y, coord.z -1 , GetEntityHeading(cache.ped))
                        SetTimeout(2000, function()
                            OpenWatch(true,k,v.name)
                        end)
                    end
                }
            else
                optionsMenu[#optionsMenu+1] = { 
                    header = v.name,
                    txt = v.job.." | "..v.rank,
                    icon = 'fas fa-video',
                    params = {
                        isAction = true,
                        event = function()
                            TriggerEvent('spy-bodycam:startWatching',k)
                            local coord = GetEntityCoords(cache.ped)
                            goBackCoords = vector4(coord.x, coord.y, coord.z -1 , GetEntityHeading(cache.ped))
                            SetTimeout(2000, function()
                                OpenWatch(true,k,v.name)
                            end)
                        end
                    } 
                }
            end
        end
    end
    if Config.Dependency.UseMenu == 'ox' then
        lib.registerContext({
            id = 'spy_bcam_list',
            title = 'Active Bodycams',
            options = optionsMenu
        })
        lib.showContext('spy_bcam_list')
    else
        exports['qb-menu']:openMenu(optionsMenu)
    end
end)



RegisterNetEvent('spy-bodycam:client:createDecoyPed', function(model, data, pVec4, plyId)
    if not Config.Dependency.UseAppearance then return end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) and timeout < 500 do
        Wait(10)
        timeout = timeout + 1
    end
    if not HasModelLoaded(model) then
        print('Error: Model could not be loaded:', model)
        return
    end
    -- Create the ped
    charPed[plyId] = CreatePed(2, model, pVec4.x, pVec4.y, pVec4.z, pVec4.w, false, true)
    if not DoesEntityExist(charPed[plyId]) then
        print('Error: Ped could not be created.')
        return
    end
    SetPedComponentVariation(charPed[plyId], 0, 0, 0, 2)
    FreezeEntityPosition(charPed[plyId], true)
    SetEntityInvincible(charPed[plyId], true)
    SetBlockingOfNonTemporaryEvents(charPed[plyId], true)
    if data then
        if Config.Dependency.UseAppearance == 'qb' then
            TriggerEvent('qb-clothing:client:loadPlayerClothing', data, charPed[plyId])
        elseif Config.Dependency.UseAppearance == 'illenium' then
            exports['illenium-appearance']:setPedAppearance(charPed[plyId], data)
        end
    end


    PlayWatchAnim(charPed[plyId],false)
end)

RegisterNetEvent('spy-bodycam:client:deleteDecoyPed',function(plyId)
    if not Config.Dependency.UseAppearance then return end
    if charPed[plyId] then 
        if DoesEntityExist(charPed[plyId]) then
            StopWatchAnim(charPed[plyId])
            DeleteEntity(charPed[plyId])
            charPed[plyId] = nil
        end
    end
end)

RegisterKeyMapping('bodycamexit', 'Exit bodycam spectate', 'keyboard', Config.ExitCamKey)
RegisterCommand('bodycamexit', function()
    if PlyInCam then
        QuitBodyCam()
    elseif PlyInSelfCam then
        QuitBodyCamSelf()
    end
end)

--- STANDALONE FUNCTIONS
function SetCamRotation()
    while PlyInCam do 
        SetCamRot(bodycam, 0, 0, GetEntityHeading(targetPed), 2)
        Wait(1)
    end
end

function SetCarCam()
    while PlyInCam or PlyInSelfCam do 
        if (IsPedInAnyVehicle(targetPed,false) and not carCam) then 
            AttachCamToPedBone(bodycam, targetPed, 46240, 0.1, 0.25, -0.1, true)
            carCam = true
        elseif (not IsPedInAnyVehicle(targetPed,false) and carCam) then
            AttachCamToPedBone(bodycam, targetPed, 46240, 0.1, 0.025, 0.1, true)
            carCam = false
        end
        Wait(2000)
    end
end

function SetPlayerNearTarget()
    while PlyInCam do
        local ownCoords = GetEntityCoords(cache.ped)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(ownCoords - targetCoords)
        
        if distance > 150 then
            SetEntityCoords(cache.ped, targetCoords.x, targetCoords.y, targetCoords.z - 100.0, false, false, false, true)
        end
        
        Wait(2500) -- Check the distance every given second
    end
end

function QuitBodyCamSelf()
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(100)
    end
    OpenWatch(false)
    StopWatchAnim(cache.ped)
    FreezeEntityPosition(cache.ped, false)
    RenderScriptCams(false, false, 0, 1, 0)
    SetTimecycleModifier('default')
    SetTimecycleModifierStrength(1.0)
    PlyInSelfCam = false
    DoScreenFadeIn(1000)
    LocalPlayer.state:set("inv_busy", false, true) TriggerEvent('inventory:client:busy:status', false) TriggerEvent('canUseInventoryAndHotbar:toggle', true)
end

function QuitBodyCam()
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(100)
    end
    OpenWatch(false)
    TriggerServerEvent('spy-bodycam:server:ReqDeleteDecoyPed')
    SetEntityVisible(cache.ped, true) -- Set invisible
    SetEntityCollision(cache.ped, true, true) -- Set collision
    SetEntityInvincible(cache.ped, false) -- Set invincible
    NetworkSetEntityInvisibleToNetwork(cache.ped, false) -- Set invisibility
    FreezeEntityPosition(cache.ped, false)
    SetEntityCoords(cache.ped, goBackCoords.x, goBackCoords.y, goBackCoords.z)
    SetEntityHeading(cache.ped, goBackCoords.w)
    RenderScriptCams(false, false, 0, 1, 0)
    SetTimecycleModifier('default')
    SetTimecycleModifierStrength(1.0)
    PlyInCam = false
    DoScreenFadeIn(1000)
    LocalPlayer.state:set("inv_busy", false, true) TriggerEvent('inventory:client:busy:status', false) TriggerEvent('canUseInventoryAndHotbar:toggle', true)
end

function ForceQuitBodyCamSelf()
    OpenWatch(false)
    StopWatchAnim(cache.ped)
    FreezeEntityPosition(cache.ped, false)
    RenderScriptCams(false, false, 0, 1, 0)
    SetTimecycleModifier('default')
    SetTimecycleModifierStrength(1.0)
    LocalPlayer.state:set("inv_busy", false, true) TriggerEvent('inventory:client:busy:status', false) TriggerEvent('canUseInventoryAndHotbar:toggle', true)
end

function ForceQuitBodyCam()
    SetEntityVisible(cache.ped, true) -- Set invisible
    SetEntityCollision(cache.ped, true, true) -- Set collision
    SetEntityInvincible(cache.ped, false) -- Set invincible
    NetworkSetEntityInvisibleToNetwork(cache.ped, false) -- Set invisibility
    FreezeEntityPosition(cache.ped, false)
    SetEntityCoords(cache.ped, goBackCoords.x, goBackCoords.y, goBackCoords.z)
    SetEntityHeading(cache.ped, goBackCoords.w)
    RenderScriptCams(false, false, 0, 1, 0)
    SetTimecycleModifier('default')
    SetTimecycleModifierStrength(1.0)
    LocalPlayer.state:set("inv_busy", false, true) TriggerEvent('inventory:client:busy:status', false) TriggerEvent('canUseInventoryAndHotbar:toggle', true)
end

function BodyOverlay(bool)
    if bool then
        if Config.Framework == 'qb'  then
            local bodyId = GetPlayerServerId(PlayerId())
            local playerName = GetPlayerDataCore().charinfo.firstname .. " " .. GetPlayerDataCore().charinfo.lastname
            local randomBodyNum = "BODY "..bodyId.. " | ".."X"..tostring(math.random(100000, 999999)) .. "N"
            local callsign = "("..GetPlayerDataCore().metadata["callsign"]..") "  .. playerName
            SendNUIMessage({
                action = 'open',
                bodyname = randomBodyNum,
                callsign = callsign,
            })
        else
            local bodyId = GetPlayerServerId(PlayerId())
            local playerName = GetPlayerDataCore().firstName .. " " .. GetPlayerDataCore().lastName
            local randomBodyNum = "BODY "..bodyId.. " | ".."X"..tostring(math.random(100000, 999999)) .. "N"
            local callsign = "("..GetPlayerDataCore().job.grade_label..") "  .. playerName
            SendNUIMessage({
                action = 'open',
                bodyname = randomBodyNum,
                callsign = callsign,
            })
        end

    else
        SendNUIMessage({
            action = 'close'
        })
    end 
end

function OpenWatch(bool,bodyId,name)
    if bool then
        SendNUIMessage({
            action = 'openWatch',
            bodyId = bodyId,
            name = name,
            exitKey = Config.ExitCamKey,
        })
    else
        SendNUIMessage({
            action = 'closeWatch'
        })
    end 
end

function PlayWatchAnim(ped,isNet)
    local x, y, z = table.unpack(GetEntityCoords(ped))
    local tabletprop = `prop_cs_tablet`
    RequestModel(tabletprop)
    while not HasModelLoaded(tabletprop) do
        Citizen.Wait(10)
    end
    local prop = CreateObject(tabletprop, x, y, z + 0.2, isNet, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    local animDict = 'amb@code_human_in_bus_passenger_idles@female@tablet@idle_a'
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(10)
    end
    TaskPlayAnim(ped, animDict, "idle_a", 3.0, -8.0, -1, 49, 0, false, false, false)
    pedProps[ped] = prop
end


function StopWatchAnim(ped)
    local prop = pedProps[ped]
    ClearPedTasks(ped)
    if prop and DoesEntityExist(prop) then
        DetachEntity(prop, true, true)
        DeleteEntity(prop)
    else
        print("Error: Prop does not exist or is not attached to the ped.")
    end
    pedProps[ped] = nil
end


function toggleProp(state)
    local gender = nil
    local coords = nil
    local rotation = nil
    local boneId = nil
    local propName = "rj_bodycam"
    if Config.Framework == 'qb' then
        local Player = GetPlayerDataCore()
        gender = Player.charinfo.gender
    else
        local xPlayer = GetPlayerDataCore()
        gender = xPlayer.sex
    end
    if gender == 0 or gender == 'm' then
        coords = Config.PropLoc.male.pos
        rotation = Config.PropLoc.male.rot
        boneId = Config.PropLoc.male.bone
    else
        coords = Config.PropLoc.female.pos
        rotation = Config.PropLoc.female.rot
        boneId = Config.PropLoc.female.bone
    end
    if state then
        if not propNetID or not DoesEntityExist(NetworkGetEntityFromNetworkId(propNetID)) then
            RequestModel(propName)
            while not HasModelLoaded(propName) do
                Wait(1)
            end
            local propEntity = CreateObject(GetHashKey(propName), 0.0, 0.0, 0.0, true, true, true)
            AttachEntityToEntity(propEntity, cache.ped, GetPedBoneIndex(cache.ped, boneId), coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, true, true, false, true, 1, true)
            propNetID = NetworkGetNetworkIdFromEntity(propEntity)
            SetNetworkIdExistsOnAllMachines(propNetID, true)
        end
    else
        if propNetID and DoesEntityExist(NetworkGetEntityFromNetworkId(propNetID)) then
            local propEntity = NetworkGetEntityFromNetworkId(propNetID)
            DeleteEntity(propEntity)
            propNetID = nil
        end
    end
end

--- FRAMEWORK FUNCTIONS
function CheckForItem()
    while bcamstate do 
        local hasItem = HasItemsCheck('bodycam')
        if not hasItem then
            TriggerServerEvent('spy-bodycam:server:toggleList',false)
            BodyOverlay(false)
            toggleProp(false)
            bcamstate = false
            break
        end
        Wait(2500)
    end
end

function CheckAllowedJob()
    for k,v in ipairs(Config.AllowedJobs) do
        if PlayerJob.name == v then return true end
    end
    return false
end

function isLocFilterTrue(locId,jobkey)
    if not Config.WatchLoc[locId].jobCam then return true end
    for k,v in ipairs(Config.WatchLoc[locId].jobCam) do
        if jobkey == v then return true end
    end
    return false
end

function NotifyPlayer(msg,type,time)
    if Config.Dependency.UseNotify == 'ox' then
        lib.notify({
            title = '',
            description = msg,
            duration = time,
            type = type
        })        
    else
        QBCore.Functions.Notify(msg,type,time)
    end
end

function GetPlayerDataCore()
    if Config.Framework == 'qb'  then
        if QBCore.Functions.GetPlayerData() then
            return QBCore.Functions.GetPlayerData()
        else
            return false
        end
    elseif Config.Framework == 'esx' then
        if ESX.GetPlayerData()then
            return ESX.GetPlayerData()
        else
            return false
        end
    end
end

function HasItemsCheck(itemname)
    if Config.Dependency.UseInventory == 'qb' then
        return QBCore.Functions.HasItem(itemname)
    elseif Config.Dependency.UseInventory == 'ox' then
        local chkItem = exports.ox_inventory:Search('count', itemname)
        if type(chkItem) == 'table' then
            for _, v in pairs(chkItem) do
                if v >= 1 then
                    return true
                end
            end
        else
            return chkItem >= 1
        end
    end
    return false
end
