Config = Config or {}

Config.Framework = 'qb' -- qb | esx  

if Config.Framework == 'qb' then
    QBCore = exports["qb-core"]:GetCoreObject()
elseif Config.Framework == 'esx' then
    ESX = exports.es_extended:getSharedObject()
end

Config.Dependency = {
    UseInventory = 'qb',         -- qb | ox             *[ESX SUPPORT IS THROUGH ox-inv | ox-lib]
    UseProgress = 'qb',          -- qb | ox                     
    UseMenu = 'ox',              -- qb | ox 
    UseNotify = 'ox',            -- qb | ox
    UseAppearance = 'illenium',       -- qb | illenium | false 
}

Config.ExitCamKey = 'E' -- Edit in HTML for ui change :)
Config.CameraEffect = 'Island_CCTV_ChannelFuzz'

Config.AllowedJobs = { -- Only these jobs can use bodycam item.
    'police',
    'ambulance',
}

Config.PropLoc = {  -- Change prop position according to ur clothing pack.
    male = {
        bone = 24818,
        pos = vector3(0.16683200771922, 0.11320925137666, 0.11986595654326),
        rot = vector3(-14.502323044318, 82.191095946679, -164.22066869048),
    },
    female = {
        bone = 24818,
        pos = vector3(0.16683200771922, 0.11320925137666, 0.11986595654326),
        rot = vector3(-14.502323044318, 82.191095946679, -164.22066869048),
    },
}

Config.WatchLoc = {
    [1] = {
        coords = vector3(440.149445, -979.437378, 30.453491), 
        rad = 0.3, 
        debug= false,
        jobCam = {'police','ambulance'} -- false = able to view all the cams

    },  -- You can add more locations 
}