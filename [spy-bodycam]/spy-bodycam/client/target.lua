CreateThread(function()
	if Config.Dependency.UseTarget == 'qb' then
		for k,v in ipairs(Config.WatchLoc) do
			exports['qb-target']:AddCircleZone("spycam_watch"..k,v.coords,v.rad, { 
				name = "spycam_watch"..k,
				useZ=true,
				debugPoly = v.debug,
			}, {
				options = {
					{
						type = "client",
						icon = "fas fa-sign-in-alt",
						label = 'Open Camera Portal',
						action = function(entity)
							TriggerEvent('spy-bodycam:openActiveMenu',k) 
						  end,
						canInteract = function(entity)
							return targetAuth(k,PlayerJob.name)
						end,
						
					},
					{
						type = "client",
						icon = "fas fa-list",
						label = 'Records Database',
						action = function(entity)
							TriggerServerEvent('spy-bodycam:server:showrecordingUI') 
						  end,
						canInteract = function(entity)
							return targetAuth(k,PlayerJob.name)
						end,
						
					},
				},
				distance = 2.5
			 })
		end 
	else
		for k,v in ipairs(Config.WatchLoc) do
			exports.ox_target:addSphereZone(
				{
					coords = v.coords,
					radius = v.rad,
					debug = v.debug,
					drawSprite = false,
					options = {
						{
							name = "spycam_watch"..k,
							label = 'Open Camera Portal',
							icon = "fas fa-sign-in-alt",
							distance = 2.5,
							onSelect = function(data)
								TriggerEvent('spy-bodycam:openActiveMenu',k) 
							end,
							canInteract = function(entity, distance, coords, name, bone)
								return targetAuth(k,PlayerJob.name)
							end,
						},
						{
							name = "spycam_watch"..k,
							label = 'Records Database',
							icon = "fas fa-list",
							distance = 2.5,
							onSelect = function(data)
								TriggerServerEvent('spy-bodycam:server:showrecordingUI') 
							end,
							canInteract = function(entity, distance, coords, name, bone)
								return targetAuth(k,PlayerJob.name)
							end,
						},
					}
				}
			)
		end 
	end
end)

AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() == resourceName then
		if Config.Dependency.UseTarget == 'qb' then
			for k,v in ipairs(Config.WatchLoc) do
				exports['qb-target']:RemoveZone("spycam_watch"..k)
			end
		end
    end 
end)