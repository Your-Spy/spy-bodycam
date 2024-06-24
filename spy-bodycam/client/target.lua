CreateThread(function()
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
					label = 'Open Bodycam Portal',
					action = function(entity)
						TriggerEvent('spy-bodycam:openActiveMenu',k) 
					  end,
					canInteract = function(entity)
						return isLocFilterTrue(k,PlayerJob.name)
					end,
					
				},
			},
			distance = 2.5
		 })
	end
end)
AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() == resourceName then
        for k,v in ipairs(Config.WatchLoc) do
            exports['qb-target']:RemoveZone("spycam_watch"..k)
        end
    end 
end)