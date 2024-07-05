PlayerJob = nil
local bodycam = nil
local targetPed = nil
local targetPedId = nil
local goBackCoords = nil
local PlyInCam = false
local PlyInSelfCam = false
local PlyInCarCam = false
local bcamstate = false
local carCam = false
local onRec = false

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
        if PlyInCam or PlyInCarCam then 
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

RegisterNetEvent('spy-bodycam:startWatchingDashcam',function(netId)
    local targetCoords = lib.callback.await('spy-bodycam:servercb:getCarCoords', false, netId)
    if not targetCoords then
        NotifyPlayer('Car not found!', 'error', 2500) 
        SetTimeout(3000, function() 
            OpenWatch(false) 
        end)
        return  
    end
    targetPedId = netId
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
    bodycam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
    targetPed = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(targetPed) then
        local boneIndex = GetEntityBoneIndexByName(vehicle, "windscreen") 
        local vehOffset = Config.VehCamOffset[GetEntityModel(targetPed)]
        if vehOffset then 
            AttachCamToVehicleBone(bodycam, targetPed, boneIndex, true, 0.0, 0.0, 0.0, vehOffset[1], vehOffset[2], vehOffset[3], true) 
        else
            AttachCamToVehicleBone(bodycam, targetPed, boneIndex, true, 0.0, 0.0, 0.0, 0.000000, 0.350000, 0.790000, true) 
        end

    end
    SetCamFov(bodycam,80.0)
    PlyInCarCam = true
    RenderScriptCams(true, false, 0, 1, 0)
    SetTimecycleModifier(Config.CameraEffect.dashcam)
    SetTimecycleModifierStrength(1.0)
    DoScreenFadeIn(1000)
    Citizen.CreateThread(function()
        SetPlayerNearTarget()
    end) 
    if Config.DebugCamera then 
        Citizen.CreateThread(function()
            local offsetX, offsetY, offsetZ = 0.000000, 0.350000, 0.790000
            while PlyInCarCam do
                Citizen.Wait(0)
                DisableAllControlActions(0)
                if IsDisabledControlJustReleased(0, 35) then -- A
                    offsetX = offsetX + 0.01
                end
                if IsDisabledControlJustReleased(0, 34) then -- D
                    offsetX = offsetX - 0.01
                end
                if IsDisabledControlJustReleased(0, 44) then -- Q
                    offsetY = offsetY + 0.01
                end
                if IsDisabledControlJustReleased(0, 38) then -- E
                    offsetY = offsetY - 0.01
                end
                if IsDisabledControlJustReleased(0, 32) then -- W
                    offsetZ = offsetZ + 0.01
                end
                if IsDisabledControlJustReleased(0, 33) then -- S
                    offsetZ = offsetZ - 0.01
                end
                AttachCamToVehicleBone(bodycam, targetPed, boneIndex, true, 0.0, 0.0, 0.0, offsetX, offsetY, offsetZ, true)
            end
            print(string.format("[`putspawncode`] =  {%f, %f, %f},", offsetX, offsetY, offsetZ))
        end)
    end  
end)

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
    SetTimecycleModifier(Config.CameraEffect.bodycam)
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
    SetTimecycleModifier(Config.CameraEffect.bodycam)
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
            disable = {
                combat = true,
            },
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
            else
                SendNUIMessage({action = "cancel_rec_force"})
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
            else
                SendNUIMessage({action = "cancel_rec_force"})
            end
        end, function()
            StopAnimTask(cache.ped, 'clothingtie', 'try_tie_positive_a', 1.0)
            NotifyPlayer('Cancelled!', 'error')
        end)
    end
end)

RegisterNetEvent('spy-bodycam:toggleCarCam', function()
    local isJobUse = CheckAllowedJob()
    if not isJobUse then return NotifyPlayer('You are not authorized!', 'error', 2500) end
    if not IsPedInAnyVehicle(cache.ped, false) then return NotifyPlayer('Not in a vehicle!', 'error') end
    local veh = GetVehiclePedIsIn(cache.ped, false)
    local driverPed = GetPedInVehicleSeat(veh, -1)
    if driverPed ~= cache.ped then return NotifyPlayer('Not in the driver\'s seat!', 'error') end
    if not isCarAuth(veh) then return NotifyPlayer('Vehicle not authorized!', 'error') end
    if DoesEntityExist(veh) then 
        local netId = NetworkGetNetworkIdFromEntity(veh)
        local acvstring = GlobalState.CarsOnBodycam[netId] and 'Deactivating' or 'Activating'
        local donestr = GlobalState.CarsOnBodycam[netId] and 'Deactivated' or 'Activated'
        
        if Config.Dependency.UseProgress == 'ox' then
            if lib.progressBar({
                duration = 2500,
                label = acvstring .. ' Dashcam...',
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                    sprint = true,
                },
                anim = {
                    dict = 'veh@submersible@ds@base',
                    clip = 'change_station',
                    flags = 49
                },
            }) then
                ToggleCarCam(netId, veh)
                NotifyPlayer('Dashcam '..donestr, 'success')
            else
                NotifyPlayer('Cancelled!', 'error')
            end   
        else
            QBCore.Functions.Progressbar('spy_bdycam', acvstring .. ' Dashcam...', 2500, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {
                animDict = 'veh@submersible@ds@base',
                anim = 'change_station',
                flags = 49
            }, {}, {}, function()
                ToggleCarCam(netId, veh)
                StopAnimTask(cache.ped, 'veh@submersible@ds@base', 'change_station', 1.0)
                NotifyPlayer('Dashcam '..donestr, 'success')
            end, function()
                StopAnimTask(cache.ped, 'veh@submersible@ds@base', 'change_station', 1.0)
                NotifyPlayer('Cancelled!', 'error')
            end)
        end
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

RegisterNetEvent('spy-bodycam:updatelisteffectcar',function()
    if PlyInCarCam then
        if (not GlobalState.CarsOnBodycam[targetPedId]) then 
            QuitBodyCam()
        end
    end
end)

RegisterNetEvent('spy-bodycam:openActiveMenu', function(locId)
    local optionsMenu = {}
    if Config.Dependency.UseMenu == 'qb' then
        optionsMenu[#optionsMenu+1] = { header = 'Camera Portal',isMenuHeader = true}
        optionsMenu[#optionsMenu+1] = { icon = "fas fa-circle-xmark", header = "Close", params = { event = "spy:close" } }
    end
    if Config.Dependency.UseMenu == 'ox' then 
        optionsMenu[#optionsMenu+1] = {
            title = 'Active Bodycams',
            icon = 'user',
            onSelect = function()
                TriggerEvent('spy-bodycam:openActiveMenuJob', locId)
            end
        }
        optionsMenu[#optionsMenu+1] = {
            title = 'Active Dashcams',
            icon = 'car',
            onSelect = function()
                TriggerEvent('spy-bodycam:openActiveMenuCars', locId)
            end
        }
    else
        optionsMenu[#optionsMenu+1] = { 
            header = 'Active Bodycams',
            icon = 'fas fa-user',
            params = {
                isAction = true,
                event = function()
                    TriggerEvent('spy-bodycam:openActiveMenuJob', locId)
                end
            } 
        }
        optionsMenu[#optionsMenu+1] = { 
            header = 'Active Dashcams',
            icon = 'fas fa-car',
            params = {
                isAction = true,
                event = function()
                    TriggerEvent('spy-bodycam:openActiveMenuCars', locId)
                end
            } 
        }
    end
    if Config.Dependency.UseMenu == 'ox' then
        lib.registerContext({
            id = 'spy_bdcam_list',
            title = 'Camera Portal',
            options = optionsMenu
        })
        lib.showContext('spy_bdcam_list')
    else
        exports['qb-menu']:openMenu(optionsMenu)
    end
end)

RegisterNetEvent('spy-bodycam:openActiveMenuJob', function(locId)
    local optionsMenu = {}
    if Config.Dependency.UseMenu == 'qb' then
        optionsMenu[#optionsMenu+1] = { header = 'Active Bodycams',isMenuHeader = true}
        optionsMenu[#optionsMenu+1] = { icon = "fas fa-circle-xmark", header = "Close", params = { event = "spy:close" } }
        optionsMenu[#optionsMenu+1] = { 
            icon = "fas fa-left-long", 
            header = "Go Back", 
            params = {
                isAction = true,
                event = function()
                    TriggerEvent('spy-bodycam:openActiveMenu',locId)
                end
            } 
        }
    else
        optionsMenu[#optionsMenu+1] = {
            title = 'Go Back',
            icon = 'left-long',
            onSelect = function()
                TriggerEvent('spy-bodycam:openActiveMenu',locId)
            end
        }
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
                                OpenWatch(true,k,v.name,true)
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
                                    OpenWatch(true,k,v.name,true)
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
                            OpenWatch(true,k,v.name,true)
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
                                OpenWatch(true,k,v.name,true)
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

RegisterNetEvent('spy-bodycam:openActiveMenuCars', function(locId)
    local optionsMenu = {}
    if Config.Dependency.UseMenu == 'qb' then
        optionsMenu[#optionsMenu+1] = { header = 'Active Dashcams',isMenuHeader = true}
        optionsMenu[#optionsMenu+1] = { icon = "fas fa-circle-xmark", header = "Close", params = { event = "spy:close" } }
        optionsMenu[#optionsMenu+1] = { 
            icon = "fas fa-left-long", 
            header = "Go Back", 
            params = {
                isAction = true,
                event = function()
                    TriggerEvent('spy-bodycam:openActiveMenu',locId)
                end
            } 
        }
    else
        optionsMenu[#optionsMenu+1] = {
            title = 'Go Back',
            icon = 'left-long',
            onSelect = function()
                TriggerEvent('spy-bodycam:openActiveMenu',locId)
            end
        }
    end
    for k, v in pairs(GlobalState.CarsOnBodycam) do
        if Config.WatchLoc[locId].carCam then  
            if isCarCamJobTrue(locId,v.jobkey) or isCarCamClassTrue(locId,v.carclass) then 
                if Config.Dependency.UseMenu == 'ox' then 
                    optionsMenu[#optionsMenu+1] = {
                        title = v.carname,
                        description = "Plate: "..v.plate.." | "..v.name,
                        icon = 'car',
                        onSelect = function()
                            StartDashCamWatch(k,v.plate,v.carname) 
                        end
                    }
                else
                    optionsMenu[#optionsMenu+1] = { 
                        header = v.carname,
                        txt = "Plate: "..v.plate.." | "..v.name,
                        icon = 'fas fa-car',
                        params = {
                            isAction = true,
                            event = function()
                                StartDashCamWatch(k,v.plate,v.carname) 
                            end
                        } 
                    }
                end
            end
        else
            if Config.Dependency.UseMenu == 'ox' then 
                optionsMenu[#optionsMenu+1] = {
                    title = v.carname,
                    description = "Plate: "..v.plate.." | "..v.name,
                    icon = 'car',
                    onSelect = function()
                        StartDashCamWatch(k,v.plate,v.carname) 
                    end
                }
            else
                optionsMenu[#optionsMenu+1] = { 
                    header = v.carname,
                    txt = "Plate: "..v.plate.." | "..v.name,
                    icon = 'fas fa-car',
                    params = {
                        isAction = true,
                        event = function()
                            StartDashCamWatch(k,v.plate,v.carname) 
                        end
                    } 
                }
            end
        end
    end
    if Config.Dependency.UseMenu == 'ox' then
        lib.registerContext({
            id = 'spy_dcam_list',
            title = 'Active Dashcams',
            options = optionsMenu
        })
        lib.showContext('spy_dcam_list')
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

RegisterNetEvent('spy-bodycam:client:startRec',function(webhook)
    SendNUIMessage({
        action = "toggle_record",
        hook = webhook
    })
    if Config.ForceViewCam then 
        SetTimecycleModifier(Config.CameraEffect.bodycam)
        SetTimecycleModifierStrength(0.5)
        CreateThread(function() 
            onRec = true
            while onRec do
                SetFollowPedCamViewMode(4)
                Wait(0)
            end
        end)
    end
end)

RegisterKeyMapping('bodycamexit', 'Exit bodycam spectate', 'keyboard', Config.ExitCamKey)
RegisterCommand('bodycamexit', function()
    if PlyInCam or PlyInCarCam then
        QuitBodyCam()
    elseif PlyInSelfCam then
        QuitBodyCamSelf()
    end
end)

RegisterNUICallback('exitBodyCam', function(data, cb)
    if not Config.ForceViewCam then return end
    onRec = false
    SetFollowPedCamViewMode(1)
    SetTimecycleModifier('default')
    SetTimecycleModifierStrength(1.0)
end)

RegisterNUICallback('videoLog', function(data, cb)
    if data then 
        local videoUrl = data.vidurl
        TriggerServerEvent('spy-bodycam:server:logVideoDetails', videoUrl)
    end
end)

--- STANDALONE FUNCTIONS
function StartDashCamWatch(k,plate,carname)
    local targetCoords = lib.callback.await('spy-bodycam:servercb:getCarCoords', false, k)
    if not targetCoords then NotifyPlayer('Car not found!', 'error', 2500) return end    
    TriggerEvent('spy-bodycam:startWatchingDashcam',k)
    local coord = GetEntityCoords(cache.ped)
    goBackCoords = vector4(coord.x, coord.y, coord.z -1 , GetEntityHeading(cache.ped))
    SetTimeout(2000, function()
        OpenWatch(true,plate,carname,false)
    end)
end

function isCarAuth(veh)
    local vehClass = GetVehicleClass(veh)
    for k,v in ipairs(Config.AllowedClass) do
        if tonumber(vehClass) == tonumber(v) then return true end
    end
    return false
end

function ToggleCarCam(netId, veh)
    if not GlobalState.CarsOnBodycam[netId] then 
        local carPlate = GetVehicleNumberPlateText(veh)
        local carName = GetVehDisplayName(GetEntityModel(veh))
        local carClass = GetVehicleClass(veh)
        TriggerServerEvent('spy-bodycam:server:toggleListCars', true, netId, carPlate, carName,carClass)
    else
        TriggerServerEvent('spy-bodycam:server:toggleListCars', false, netId)
    end
end

function GetVehDisplayName(model)
    local vehName = GetLabelText(GetDisplayNameFromVehicleModel(model))
    if vehName == 'NULL' then 
        vehName = GetDisplayNameFromVehicleModel(model)
    end 
    return vehName
end

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
    while PlyInCam or PlyInCarCam do
        local ownCoords = GetEntityCoords(cache.ped)
        if DoesEntityExist(targetPed) then 
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(ownCoords - targetCoords)
            
            if distance > 150 then
                SetEntityCoords(cache.ped, targetCoords.x, targetCoords.y, targetCoords.z - 100.0, false, false, false, true)
            end
        else
            QuitBodyCam()
        end
        Wait(2500) -- Check the distance every given second
    end
end

function QuitBodyCamSelf()
    DoScreenFadeOut(1000)
    while not IsScreenFadedOut() do
        Wait(100)
    end
    SetTimeout(1000, function()
        OpenWatch(false)
    end)
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
    SetTimeout(1000, function()
        OpenWatch(false)
    end)
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
    PlyInCarCam = false
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

function OpenWatch(bool,bodyId,name,isbodycam)
    if bool then
        SendNUIMessage({
            action = 'openWatch',
            bodyId = bodyId,
            name = name,
            isbodycam = isbodycam,
            exitKey = Config.ExitCamKey,
            debug = Config.DebugCamera,
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
function isCarCamJobTrue(locId, jobKey)
    if not Config.WatchLoc[locId].carCam.job then return false end
    for _, v in ipairs(Config.WatchLoc[locId].carCam.job) do
        if jobKey == v then
            return true 
        end
    end
    return false  
end

function isCarCamClassTrue(locId, vehClass)
    if not Config.WatchLoc[locId].carCam.class then return false end
    for _, v in ipairs(Config.WatchLoc[locId].carCam.class) do
        if tonumber(vehClass) == tonumber(v) then
            return true 
        end
    end
    return false  
end

function CheckForItem()
    while bcamstate do 
        local hasItem = HasItemsCheck('bodycam')
        if not hasItem then
            TriggerServerEvent('spy-bodycam:server:toggleList',false)
            BodyOverlay(false)
            toggleProp(false)
            bcamstate = false
            SendNUIMessage({action = "cancel_rec_force"})
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

function targetAuth(locId,jobkey)
    if not Config.WatchLoc[locId].targetAuth then return true end
    for k,v in ipairs(Config.WatchLoc[locId].targetAuth) do
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



  