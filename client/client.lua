ESX = nil
local vacas = {}
local playerPed
local playerPedCoords = 0
local distanciaMin
local cercaVacas = false
local cercaTanque = false
local dentroTanque = false
local tanqueID
local tanquePos
local vacaID
local vacaPos
local recolectando = false
local llevaBalde = false
local balde
local cercaVenta = false
local dentroVenta = false
local ventaID
local ventaPos


Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while not ESX.GetPlayerData().job do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)


RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)


-- Spawn the bucket under the cow
local function propRecoleccion()
	ESX.Game.SpawnObject("prop_bucket_02a", {
		x = vacaPos.x,
		y = vacaPos.y,
		z = vacaPos.z
	}, function(obj)
		SetEntityHeading(obj, GetEntityHeading(playerPed))
		PlaceObjectOnGroundProperly(obj)
		Citizen.Wait(Config.ColectionTime)
		DeleteObject(obj)
	end)

	RequestAnimSet( "move_ped_crouched" )
	SetPedMovementClipset( playerPed, "move_ped_crouched", 0.55 )

	TriggerEvent("mythic_progbar:client:progress", {
        name = "ordeñarVaca",
        duration = Config.ColectionTime,
        label = "Ordeñando",
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
        animation = {
            animDict = "anim@heists@heist_safehouse_intro@phone_couch@male",
            anim = "phone_couch_male_idle",
            flags = 49,
			task = nil
        }
    }, function(status)
        recolectando = false
        ResetPedMovementClipset(playerPed)
        llevarBalde()
    end)
end

local function llevarBalde()
	llevaBalde = true
	ESX.Streaming.RequestAnimDict("anim@heists@box_carry@", function()
		TaskPlayAnim( playerPed, "anim@heists@box_carry@", "idle", 3.0, -8, -1, 63, 0, 0, 0, 0 )
	end)
	balde = CreateObject(GetHashKey("prop_bucket_02a"), playerPedCoords.x, playerPedCoords.y, playerPedCoords.z+0.2,  true,  true, true)
	AttachEntityToEntity(balde, playerPed, GetPedBoneIndex(playerPed, 60309), 0.025, -0.24, 0.355, -75.0, 470.0, 0.0, true, true, false, true, 1, true)
end

local function vender()
	ESX.Streaming.RequestAnimDict("misscarsteal4@actor", function()
		TaskPlayAnim(playerPed, "misscarsteal4@actor", "actor_berating_loop", 8.0, -8.0, -1, 0, 0, false, false, false)
	end)
end

-- Stream Cows
Citizen.CreateThread(function()
	RequestModel(GetHashKey("a_c_cow"))
	while not HasModelLoaded(GetHashKey("a_c_cow")) do
		Wait(5)
	end
	for k, v in pairs(Config.Vacas) do
		if vacas[k] then
			DeleteEntity(vacas[k])
		end
		vacas[k] = CreatePed(4, GetHashKey( "a_c_cow" ), v.x, v.y, v.z-1, 0.0, false, true)
		FreezeEntityPosition(vacas[k], true)
	end
end)

-- Distance with markers and cows
Citizen.CreateThread(function()
	local distancia
	if Config.MinimumDrawDist then 
		distanciaMin = Config.MinimumDrawDist
	end

	while true do
		Citizen.Wait(0)
		if ESX.PlayerData.job.name == Config.JobName then
			playerPed = PlayerPedId()
			playerPedCoords = GetEntityCoords(playerPed)
			
			for k, vaca in pairs(Config.Vacas) do
				distancia = #(playerPedCoords - vaca)

				if distancia < distanciaMin then
					cercaVacas = true
					vacaID = k
					vacaPos = vaca
				end
			end
			for k, tanque in pairs(Config.Tanque) do
				distancia = #(playerPedCoords - tanque)

				if distancia < Config.DrawMarkerDist then
					cercaTanque = true
					tanqueID = k
					tanquePos = tanque
				end
			end
			for k, venta in pairs(Config.Venta) do
				distancia = #(playerPedCoords - venta)

				if distancia < Config.DrawMarkerDist then
					cercaVenta = true
					ventaID = k
					ventaPos = venta
				end
			end
			if cercaVacas then
				distancia = #(playerPedCoords - vacaPos)
				if distancia > distanciaMin then
					cercaVacas = false
				end
			end
			if cercaTanque then
				distancia = #(playerPedCoords - tanquePos)
				if distancia > Config.DrawMarkerDist then
					cercaTanque = false
				else
					if distancia < 2 then
						dentroTanque = true
					else
						dentroTanque = false
					end
				end
			end
			if cercaVenta then
				distancia = #(playerPedCoords - ventaPos)
				if distancia > Config.DrawMarkerDist then
					cercaVenta = false
				else
					if distancia < 2 then
						dentroVenta = true
					else
						dentroVenta = false
					end
				end
			end
			Citizen.Wait(200)
		else
			Citizen.Wait(1000)
		end
	end
end)

-- Drawing the "Press E to the cows"
Citizen.CreateThread(function()
	while true do
		if cercaVacas then
			if not recolectando and not llevaBalde then
				ESX.ShowFloatingHelpNotification(_U("ordeñar"), vacaPos)
			end
			if not llevaBalde then
				if IsControlJustPressed(0, 38) then
					if not recolectando then
						recolectando = true
						propRecoleccion()
					end
				end
			end
			Citizen.Wait(0)
		else
			Citizen.Wait(200)
		end
	end
end)

-- Drawing the marker "Press E recolect"
Citizen.CreateThread(function()
	while true do
		if llevaBalde then
			if cercaTanque then
				DrawMarker(27, tanquePos.x, tanquePos.y, tanquePos.z-0.95, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0,  2.0, 2.0, 0, 0, 255, 220, false, true, 2, false, false, false, false)
				if dentroTanque then
					ESX.ShowFloatingHelpNotification(_U("entregar"), tanquePos)
					if IsControlJustPressed(0, 38) then
						cercaTanque = false
						llevaBalde = false
						TriggerServerEvent("leche:sumar")
						ClearPedTasks(playerPed)
						DeleteObject(balde)
					end
				end
			end
			Citizen.Wait(0)
		else
			Citizen.Wait(500)
		end
	end
end)

-- Drawing the marker "Press E sell"
Citizen.CreateThread(function()
	while true do
		if cercaVenta then
			DrawMarker(27, ventaPos.x, ventaPos.y, ventaPos.z-0.95, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 2.0,  2.0, 2.0, 0, 0, 255, 220, false, true, 2, false, false, false, false)
			if dentroVenta then
				ESX.ShowFloatingHelpNotification(_U("vender"), ventaPos)
				if IsControlJustPressed(0, 38) then
					dentroVenta = false
					cercaVenta = false
					vender()
					Citizen.Wait(6000)
					TriggerServerEvent('leche:vender')
				end
			end
			Citizen.Wait(0)
		else
			Citizen.Wait(1000)
		end
	end
end)








Citizen.CreateThread(function()
	if Config.Blips then
		for _, info in pairs(Config.BlipLocations) do
			info.blip = AddBlipForCoord(info.x, info.y, info.z)
	 		SetBlipSprite(info.blip, info.id)
	 		SetBlipDisplay(info.blip, 4)
	 		SetBlipScale(info.blip, 1.0)
	 		SetBlipColour(info.blip, info.colour)
	 		SetBlipAsShortRange(info.blip, true)
	 		BeginTextCommandSetBlipName("STRING")
	 		AddTextComponentString(info.title)
	 		EndTextCommandSetBlipName(info.blip)
		end
	end
end)