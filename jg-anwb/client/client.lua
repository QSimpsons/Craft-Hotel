print('^2[jg-anwb] client.lua v5 geladen (kleedkamer in 1 file)^7')

ESX = nil

Citizen.CreateThread(function()
    ESX = exports["es_extended"]:getSharedObject()

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()

	DrawBlips()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(PlayerData)
	ESX.PlayerData = PlayerData
	ESX.PlayerLoaded = true
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(Job)
	ESX.PlayerData.job = Job
	ESX.SetPlayerData('job', Job)
end)

-- Nooit crashen als giveCarKeys ontbreekt in jg-carkeys / andere key-resources.
SafeGiveCarKeys = function(vehicle, plate, props)
	if vehicle and vehicle ~= 0 then
		plate = plate or GetVehicleNumberPlateText(vehicle)
		if (not props or type(props) ~= 'table') and ESX and ESX.Game then
			props = ESX.Game.GetVehicleProperties(vehicle)
		end
	end

	local function tryExport(resource, method)
		if type(resource) ~= 'string' or resource == '' then
			return false
		end
		if GetResourceState(resource) ~= 'started' then
			return false
		end
		local ok = pcall(function()
			exports[resource][method](plate, props, vehicle)
		end)
		return ok
	end

	if tryExport('jg-givekey', 'giveCarKeys') then return true end
	if Config and tryExport(Config.Carkeys, 'giveCarKeys') then return true end
	if tryExport('jg-carkeys', 'giveCarKeys') then return true end
	if tryExport('jg-givekey', 'GiveKeys') then return true end
	if Config and tryExport(Config.Carkeys, 'GiveKeys') then return true end
	if tryExport('qs-vehiclekeys', 'GiveKeys') then return true end
	if tryExport('wasabi_carlock', 'GiveKey') then return true end

	pcall(function()
		TriggerEvent('jg-givekey:client:giveCarKeys', plate, props, vehicle)
		TriggerEvent('jg-carkeys:client:giveKeys', plate, props, vehicle)
		TriggerEvent('vehiclekeys:client:SetOwner', plate)
		TriggerEvent('cd_garage:AddKeys', plate)
	end)
	return false
end

SafeSetFuel = function(vehicle, amount)
	amount = amount or 100.0
	if Config and Config.Benzine then
		local ok = pcall(function()
			exports[Config.Benzine]:setFuel(vehicle, amount)
		end)
		if ok then return true end
	end
	pcall(function()
		SetVehicleFuelLevel(vehicle, amount + 0.0)
	end)
	return true
end

-- Config werd eerder geladen dan deze functies, daardoor was functionDefine nil.
RunLocationAction = function(location, locType, locId)
	if type(location) ~= 'table' then
		return
	end

	local handlers = {
		OpenGarage = OpenGarage,
		DeleteVehicle = DeleteVehicle,
		CloakroomMenu = CloakroomMenu,
		OnOffDuty = OnOffDuty,
		GetGear = GetGear,
		OpenManagement = OpenManagement,
		ManagementMenu = OpenManagement,
		['Garage'] = OpenGarage,
		['Voertuig wegzetten'] = DeleteVehicle,
		['Omkleden'] = CloakroomMenu,
		['In-/uitklokken'] = OnOffDuty,
		['Werkspullen pakken'] = GetGear,
		['Baas acties'] = OpenManagement,
	}

	local fn = location.functionDefine
	if type(fn) == 'string' then
		fn = handlers[fn] or _G[fn]
	end
	if type(fn) ~= 'function' then
		fn = handlers[location.drawText]
	end
	if type(fn) == 'function' then
		fn(locType or location.type or 'default', locId)
	end
end

DrawBlips = function()
	for i=1, #Config.Blips, 1 do
		local v = Config.Blips[i]
		local blip = AddBlipForCoord(v.Coords)
		SetBlipSprite(blip, Config.BlipSprite)
		SetBlipDisplay(blip, Config.BlipDisplay)
		SetBlipScale(blip, Config.BlipScale)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(v.BlipLabel)
		EndTextCommandSetBlipName(blip)
	end
end

IsPlayerJob = function()
	local bool = ESX.PlayerData.job.name == 'mechanic' and true or ESX.PlayerData.job.name == 'offmechanic' and true or false
	return bool
end

IsPlayerOnDuty = function()
	local bool = ESX.PlayerData.job.name == 'mechanic' and true or false
	return bool
end

Citizen.CreateThread(function()
	while not ESX.PlayerLoaded do Wait(0) end

	DrawBlips()

	for i=1, #Config.Peds do
		local ped = Config.Peds[i]
		local script = GetCurrentResourceName()
		ESX.CreateFreezedPed(ped.model, ped.coords, ped.heading, ped.scenario, script)
	end

	for k,v in pairs(Config.Vehicles.cars) do 
		for l,v in pairs(v.vehicles) do
			AddTextEntry(v.spawnName, v.name)
		end	
	end
    
    while true do
		if type(BindAnwbLocationActions) == 'function' then
			BindAnwbLocationActions()
		end
		local sleep = 500
		if IsPlayerOnDuty() then
			local playerPed = PlayerPedId()
			local coords = GetEntityCoords(playerPed)

			for k,v in pairs(Config.Locations) do
				if v.rank == nil then v.rank = 0 end
				if v.rank <= tonumber(ESX.PlayerData.job.grade) and (v.target == nil or v.target == false) then
					if (v.drawText == 'Voertuig wegzetten' and IsPedInAnyVehicle(playerPed, true)) or v.drawText ~= 'Voertuig wegzetten' then
						local dist = #(coords - v.coords)
						if dist <= 20.0 and dist > 1.0 then
							sleep = 0
							if v.drawText == 'Voertuig wegzetten' then
								if v.deleteType == 'heli' then
									if IsPedInAnyHeli(playerPed) then
										ESX.DrawBasicMarker(v.coords, 255, 0, 0)
									end
								else
									ESX.DrawBasicMarker(v.coords, 255, 0, 0)
								end
							else
								ESX.DrawBasicMarker(v.coords, 242, 170, 0)
							end
						elseif dist < 1.0 then
							sleep = 0
							if v.drawText ~= nil then
								if v.drawText == 'Voertuig wegzetten' then
									if v.deleteType == 'heli' then
										if IsPedInAnyHeli(playerPed) then
											exports[''..Config.interaction..'']:Interaction('error', '[E] - ' .. v.drawText, v.coords, 2.5, GetCurrentResourceName() .. '-action-' .. tostring(k))
											ESX.DrawBasicMarker(v.coords, 255, 0, 0)
										end
									else
										exports[''..Config.interaction..'']:Interaction('error', '[E] - ' .. v.drawText, v.coords, 2.5, GetCurrentResourceName() .. '-action-' .. tostring(k))
										ESX.DrawBasicMarker(v.coords, 255, 0, 0)
									end
								else
									exports[''..Config.interaction..'']:Interaction({r = '242', g = '170', b = '0'}, '[E] - ' .. v.drawText, v.coords, 2.5, GetCurrentResourceName() .. '-action-' .. tostring(k))
									ESX.DrawBasicMarker(v.coords, 242, 170, 0)
								end
								if IsControlJustReleased(0, 38) then
									if v.type == nil then v.type = 'default' end

									RunLocationAction(v, v.type, k)
								end
							end
						end
					end
				end
			end
		elseif IsPlayerJob() then
			local playerPed = PlayerPedId()
			local coords = GetEntityCoords(playerPed)
			
			for k,v in pairs(Config.Locations) do
				if v.drawText == 'In-/uitklokken' then
					local dist = #(coords - v.coords)
					if dist <= 20.0 and dist > 1.0 then
						sleep = 0
						ESX.DrawBasicMarker(v.coords, 242, 170, 0)
					elseif dist < 1.0 then
						sleep = 0
						if v.drawText ~= nil then
							
							exports[''..Config.interaction..'']:Interaction({r = '242', g = '170', b = '0'}, '[E] - ' .. v.drawText, v.coords, 2.5, GetCurrentResourceName() .. '-action-' .. tostring(k))
							ESX.DrawBasicMarker(v.coords, 242, 170, 0)

							if IsControlJustReleased(0, 38) then
								if v.type == nil then v.type = 'default' end

								RunLocationAction(v, v.type, k)
							end
						end
					end
				end
			end
		end

		Wait(sleep)
    end
end)

OpenGarage = function(type, id)

	local configType = Config.Vehicles.cars
	if type == 'airport' then 
		configType = Config.Vehicles.air
	end
	local categories = {}

	for i=1, #configType do
		if configType[i].rank <= tonumber(ESX.PlayerData.job.grade) then
			categories[#categories+1] = {
				title = configType[i].category,
				description = configType[i].description,
				arrow = true,
				onSelect = function(args)
					OpenVehiclesMenu(type, configType, args)
				end,
				args = { category = i, garageIndex = id }
			}
		end
	end

	lib.registerContext({
		id = 'anwb:garage-menu',
		title = 'ANWB: Garage',
		options = categories
	})

	lib.showContext('anwb:garage-menu')
end

OpenVehiclesMenu = function(type, configType, data)
	local vehicles = {}

	for i=1, #configType[data.category].vehicles do 
		vehicles[#vehicles+1] = {
			title = configType[data.category].vehicles[i].name,
			event = 'jg-anwb:client:spawn:vehicle',
			args = { vehicleName = configType[data.category].vehicles[i].spawnName, garageIndex = data.garageIndex}
		}
	end

	lib.registerContext({
		id = 'anwb:garage-menu:vehicles',
		title = configType[data.category].category,
		onExit = function()
			OpenGarage(type, data.garageIndex)
		end,
		options = vehicles
	})

	lib.showContext('anwb:garage-menu:vehicles')
end

DeleteVehicle = function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= 0 then
		RemoveJobVehicleKeys(vehicle)
		ESX.Game.DeleteVehicle(vehicle)
    end
end

RemoveVehicle = function(vehicle)
	ESX.Game.DeleteVehicle(vehicle)
end

GetGear = function()
	TriggerServerEvent('jg-anwb:server:getGear', false)
end

-- Kleedkamer/duty helpers staan in client.lua zelf, zodat een oude fxmanifest
-- zonder clothing.lua niet meer crasht op nil globals.
local function AnwbResourceStarted(name)
	return type(name) == 'string' and name ~= '' and GetResourceState(name) == 'started'
end

if type(SafeCallExport) ~= 'function' then
	SafeCallExport = function(resource, method, ...)
		if not AnwbResourceStarted(resource) then
			return false
		end
		local args = { ... }
		local ok = pcall(function()
			exports[resource][method](table.unpack(args))
		end)
		return ok
	end
end

if type(SafeNotify) ~= 'function' then
	SafeNotify = function(nType, message, duration)
		if SafeCallExport(Config.Notify, 'Notify', nType, message, duration or 4000) then
			return true
		end
		if ESX and ESX.ShowNotification then
			ESX.ShowNotification(message)
			return true
		end
		return true
	end
end

local function IsFemalePed(ped)
	return GetEntityModel(ped) == `mp_f_freemode_01`
end

ApplyAnwbOutfit = function(outfit)
	if type(outfit) ~= 'table' then
		return false
	end
	local ped = PlayerPedId()
	local genderData = IsFemalePed(ped) and (outfit.female or outfit.male) or (outfit.male or outfit.female)
	if type(genderData) ~= 'table' then
		return false
	end
	if type(genderData.components) == 'table' then
		for _, comp in pairs(genderData.components) do
			if type(comp) == 'table' and comp.component_id ~= nil then
				SetPedComponentVariation(ped, tonumber(comp.component_id) or 0, tonumber(comp.drawable) or 0, tonumber(comp.texture) or 0, 0)
			end
		end
	end
	if type(genderData.props) == 'table' then
		for _, prop in pairs(genderData.props) do
			if type(prop) == 'table' and prop.prop_id ~= nil then
				local propId = tonumber(prop.prop_id) or 0
				local drawable = tonumber(prop.drawable) or -1
				if drawable < 0 then
					ClearPedProp(ped, propId)
				else
					SetPedPropIndex(ped, propId, drawable, tonumber(prop.texture) or 0, true)
				end
			end
		end
	end
	return true
end

setClothing = function(item, reset)
	if reset then
		TriggerEvent('skinchanger:getSkin', function(skin)
			TriggerEvent('skinchanger:loadSkin', skin)
		end)
		return true
	end
	if type(item) == 'table' then
		return ApplyAnwbOutfit(item)
	end
	return false
end

OpenSavedOutfitsMenu = function()
	local clothing = Config and Config.Kleding or 'jg-clothingmenu'
	local methods = { 'openSavedOutfits', 'OpenSavedOutfits', 'openOutfitMenu', 'OpenOutfitMenu', 'showOutfitMenu' }
	for i = 1, #methods do
		if SafeCallExport(clothing, methods[i]) then
			return true
		end
	end
	if SafeCallExport('ox_appearance', 'showOutfitMenu') then return true end
	if SafeCallExport('illenium-appearance', 'openOutfitMenu') then return true end
	if SafeCallExport('fivem-appearance', 'openOutfitMenu') then return true end
	pcall(function()
		TriggerEvent('ox_appearance:outfitMenu')
		TriggerEvent('illenium-appearance:client:openOutfitMenu')
		TriggerEvent('fivem-appearance:client:openOutfitMenu')
		TriggerEvent('qb-clothing:client:openOutfitMenu')
		TriggerEvent('esx_skin:openSaveableMenu')
	end)
	SafeNotify('error', 'Geen kledingmenu gevonden. Zet Config.Kleding in config.lua.', 5000)
	return false
end

local function OpenOutfitCategory(categoryName, outfits)
	local options = {}
	for outfitName, outfitData in pairs(outfits) do
		options[#options + 1] = {
			title = outfitName,
			onSelect = function()
				if ApplyAnwbOutfit(outfitData) then
					SafeNotify('success', ('Outfit aangetrokken: %s'):format(outfitName), 3500)
				else
					SafeNotify('error', 'Deze outfit heeft geen data voor jouw ped.', 4000)
				end
			end
		}
	end
	table.sort(options, function(a, b) return a.title < b.title end)
	lib.registerContext({
		id = 'anwb:job-outfits:' .. tostring(categoryName),
		title = tostring(categoryName),
		menu = 'anwb:job-outfits',
		options = options
	})
	lib.showContext('anwb:job-outfits:' .. tostring(categoryName))
end

OpenJobOutfitMenu = function(outfits)
	outfits = outfits or (Config and Config.Outfits) or {}
	local jobsmenu = Config and Config.Jobsmenu or 'jg-jobsmenu'
	if SafeCallExport(jobsmenu, 'OpenOutfitMenu', outfits) then return true end
	if SafeCallExport(jobsmenu, 'openOutfitMenu', outfits) then return true end

	local categories = {}
	for categoryName, categoryOutfits in pairs(outfits) do
		if type(categoryOutfits) == 'table' then
			categories[#categories + 1] = {
				title = categoryName,
				arrow = true,
				onSelect = function()
					OpenOutfitCategory(categoryName, categoryOutfits)
				end
			}
		end
	end
	if #categories == 0 then
		SafeNotify('error', 'Geen ANWB outfits in config/outfits.lua.', 4000)
		return false
	end
	table.sort(categories, function(a, b) return a.title < b.title end)
	lib.registerContext({
		id = 'anwb:job-outfits',
		title = 'ANWB outfits',
		options = categories
	})
	lib.showContext('anwb:job-outfits')
	return true
end

SafeToggleDuty = function()
	local jobName = ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name
	local jobsmenu = Config and Config.Jobsmenu or 'jg-jobsmenu'
	if SafeCallExport(jobsmenu, 'ToggleDuty', jobName) then return true end
	if SafeCallExport(jobsmenu, 'toggleDuty', jobName) then return true end
	TriggerServerEvent('jg-anwb:server:toggleDuty')
	return true
end

SafeOpenManagement = function()
	local jobName = ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name or 'mechanic'
	local jobsmenu = Config and Config.Jobsmenu or 'jg-jobsmenu'
	if SafeCallExport(jobsmenu, 'OpenManagementMenu', jobName) then return true end
	if SafeCallExport(jobsmenu, 'openManagementMenu', jobName) then return true end
	pcall(function()
		TriggerEvent('esx_society:openBossMenu', 'mechanic', function() end, { wash = false })
	end)
	return true
end

OnOffDuty = function()
	SafeToggleDuty()
end

OpenManagement = function()
	SafeOpenManagement()
end

RegisterNetEvent('jg-anwb:client:own:cloakroom')
AddEventHandler('jg-anwb:client:own:cloakroom', function()
	if ESX.PlayerData.job.name == 'mechanic' then
		OpenSavedOutfitsMenu()
	end
end)

RegisterNetEvent('jg-anwb:client:anwb:cloakroom')
AddEventHandler('jg-anwb:client:anwb:cloakroom', function()
	if ESX.PlayerData.job.name == 'mechanic' then
		OpenJobOutfitMenu(Config.Outfits)
	end
end)

CloakroomMenu = function()
	if ESX.PlayerData.job.name == 'mechanic' then
		local options = {
			[1] = {
				['title'] = 'Persoonlijke kleedkamer',
				['description'] = 'Bekijk je eigen outfits',
				['event'] = 'jg-anwb:client:own:cloakroom'
			},
			[2] = {
				['title'] = 'Algemene kleedkamer',
				['description'] = 'Bekijk de ANWB outfits',
				['event'] = 'jg-anwb:client:anwb:cloakroom'
			},
		}

		lib.registerContext({
			id = 'anwb:check-cloakroom',
			title = 'ANWB: Bekijk opties van Kleedkamer',
			options = options
		})
		
		lib.showContext('anwb:check-cloakroom')
	end
end

local CurrentlyTowedVehicle

RegisterNetEvent('jg-anwb:client:spawn:vehicle')
AddEventHandler('jg-anwb:client:spawn:vehicle', function(data)
	local garage = Config.Locations[data.garageIndex]
	local vehicle = data.vehicleName
	local foundPoint = false
	local props = {['plate'] = 'ANWB' .. math.random(111111, 999999)}

	for i=1, #garage.spawnPoints, 1 do 
		if ESX.Game.IsSpawnPointClear(vector3(garage.spawnPoints[i].x, garage.spawnPoints[i].y, garage.spawnPoints[i].z), 2.0) then 
			ESX.Game.SpawnVehicle(vehicle, vector3(garage.spawnPoints[i].x, garage.spawnPoints[i].y, garage.spawnPoints[i].z), garage.spawnPoints[i].w, function(veh)
				TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
				SetVehicleNumberPlateText(veh, props.plate)
				local plate = GetVehicleNumberPlateText(veh)
				local vehicleProps = ESX.Game.GetVehicleProperties(veh)
				-- pcall: oude jg-carkeys heeft geen giveCarKeys export
				if type(GiveJobVehicleKeys) == 'function' then
					GiveJobVehicleKeys(veh, plate, vehicleProps)
				else
					SafeGiveCarKeys(veh, plate, vehicleProps)
				end
				if type(SetJobVehicleFuel) == 'function' then
					SetJobVehicleFuel(veh, 100.0)
				else
					SafeSetFuel(veh, 100.0)
				end
			end, true, props)
			foundPoint = true 
			break
		end
	end

	if not foundPoint then
		exports[''..Config.Notify..'']:Notify('error', 'Er zijn geen lege parkeerplekken!', 5000)
	end
end)

RegisterNetEvent('jg-anwb:client:toggle:flatbed')
AddEventHandler('jg-anwb:client:toggle:flatbed', function(data)
	local playerPed = PlayerPedId()
	
	Citizen.CreateThread(function()
		local attempt = 0
		if liftedVehicle == nil then
			firstvehicle = 0
			secondvehicle = 0
			while true do
				Wait(0)
				local coords = GetEntityCoords(PlayerPedId())
				local veh = ESX.Game.GetClosestVehicle()
				if firstvehicle == 0 then
					if veh ~= 0 and GetEntityModel(veh) == `flatbed` or veh ~= 0 and GetEntityModel(veh) == `flatbed2` or veh ~= 0 and GetEntityModel(veh) == `flatbed4` then
						local vehCoords = GetEntityCoords(veh)
						ESX.Game.Utils.DrawMarker(vehCoords, 2, 0.2, 38, 255, 0)
						ESX.Game.Utils.DrawText(vehCoords.x, vehCoords.y, vehCoords.z + 1.8, '~b~E~w~ - Selecteer Flatbed')
						if IsControlJustReleased(0, 38) then
							firstvehicle = veh
						end
					end
				elseif secondvehicle == 0 then
					if veh ~= 0 and GetEntityModel(veh) ~= `flatbed` and GetEntityModel(veh) ~= `flatbed2`  and GetEntityModel(veh) ~= `flatbed4` then
						local vehCoords = GetEntityCoords(veh)
						ESX.Game.Utils.DrawMarker(vehCoords, 2, 0.2, 38, 255, 0)
						ESX.Game.Utils.DrawText(vehCoords.x, vehCoords.y, vehCoords.z + 1.8, '~b~E~w~ - Selecteer Voertuig')
						if IsControlJustReleased(0, 38) then
							secondvehicle = veh
						end
					end
				else
					while not NetworkHasControlOfEntity(secondvehicle) and attempt < 100 and DoesEntityExist(secondvehicle) do
						Citizen.Wait(100)
						NetworkRequestControlOfEntity(secondvehicle)
						attempt = attempt + 1
					end
					if NetworkHasControlOfEntity(secondvehicle) then
						AttachEntityToEntity(secondvehicle, firstvehicle, 0, 0.0, -2.7, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
						liftedVehicle = secondvehicle
						return
					end
				end
			end
		else
			local coords = GetEntityCoords(PlayerPedId())
			local vehpos = GetEntityCoords(liftedVehicle)
			local distance = GetDistanceBetweenCoords(vehpos, coords, true)
			if distance <= 3.0 then
				while not NetworkHasControlOfEntity(liftedVehicle) and attempt < 100 and DoesEntityExist(liftedVehicle) do
					Citizen.Wait(100)
					NetworkRequestControlOfEntity(liftedVehicle)
					attempt = attempt + 1
				end
				if NetworkHasControlOfEntity(liftedVehicle) then
					AttachEntityToEntity(liftedVehicle, firstvehicle, 20, -0.5, -12.0, 1.0, 0.0, 0.0, 0.0, false, false, false, false, 20, true)
					DetachEntity(liftedVehicle, true, true)
					liftedVehicle = nil
					firstvehicle = 0
					secondvehicle = 0
				end
			end
		end
	end)
end)

Citizen.CreateThread(function()
	exports.qtarget:AddTargetModel(GetHashKey('prop_fncsec_04a'), {
		options = {
			{
				icon = "fa-solid fa-warehouse",
				label = "Pak Dranghek op",
				event = 'jg-resources:client:objDelete:pion',
				job = 'mechanic'
			},
		},
		distance = 2.5
	})

	exports.qtarget:AddTargetModel(GetHashKey('prop_roadcone02b'), {
		options = {
			{
				icon = "fa-solid fa-warehouse",
				label = "Pak Pilon op",
				event = 'jg-resources:client:objDelete:pion',
				job = 'mechanic'
			},
		},
		distance = 2.5
	})

	exports['qtarget']:Vehicle({
		options = {
			{
				event = 'jg-anwb:client:repair:vehicle',
				icon = 'fas fa-screwdriver-wrench',
				label = 'Voertuig repareren',
				item = 'repairkit'
			},
			{
				event = 'jg-anwb:client:wash:vehicle',
				icon = 'fas fa-hand-sparkles',
				label = 'Voertuig schoonmaken',
				item = 'washand'
			},
			{
				event = 'jg-anwb:client:toggle:flatbed',
				icon = 'fa-solid fa-car',
				label = 'Voertuig op flatbed zetten',
				canInteract = function(vehicle)
					local bool = GetEntityModel(vehicle) == GetHashKey('flatbed') and true or false
					return bool
				end,
				job = 'mechanic'
			},
			{
				event = 'jg-anwb:client:repair:vehicle',
				icon = 'fas fa-screwdriver-wrench',
				label = 'Voertuig repareren',
				job = 'mechanic'
			},
			{
				event = 'jg-anwb:client:wash:vehicle',
				icon = 'fas fa-hand-sparkles',
				label = 'Voertuig schoonmaken',
				job = 'mechanic'
			},
			{
				event = 'jg-politie:client:shut:vehicle',
				icon = 'fa-solid fa-car',
				label = 'Voertuig openbreken',
				job = 'mechanic'
			},
			{
				event = 'jg-anwb:client:delete:wok',
				icon = 'fa-solid fa-circle-info',
				label = 'WOK status verwijderen',
				job = 'mechanic'
			},
			{
				event = 'jg-anwb:client:vin',
				icon = 'fa-solid fa-circle-info',
				label = 'VIN nummer achterhalen',
				job = 'mechanic'
			},
		},
		distance = 2
	})

	exports['qtarget']:Player({
		options = {
			{
				event = 'jg-anwb:client:send:factuur',
				icon = 'fa-solid fa-clipboard',
				label = 'Verstuur factuur',
				job = 'mechanic'
			},
		},
		distance = 2
	})
end)

RegisterNetEvent('jg-anwb:client:set:clothing')
AddEventHandler('jg-anwb:client:set:clothing', function(data)
	if not data or not data.item then return end 
	ESX.Game.PlayAnim('missmic4', 'michael_tux_fidget', 8.0, 1500, 51)
	Wait(1500)
	ESX.Game.PlayAnim('clothingtie', 'try_tie_negative_a', 8.0, 1200, 51)
	Wait(1200)
	ESX.Game.PlayAnim('re@construction', 'out_of_breath', 8.0, 1300, 51)
	Wait(1300)
	ESX.Game.PlayAnim('random@domestic', 'pickup_low', 8.0, 1200, 51)
	Wait(1200)
	setClothing(data.item, data.reset)
end)

RegisterNetEvent('jg-anwb:client:repair:vehicle')
AddEventHandler('jg-anwb:client:repair:vehicle', function(data)
	local vehicle = data.entity
	if vehicle ~= nil then 
		if Config.Actions.repairVehicle.actions.animation.enabled then 
			TaskStartScenarioInPlace(PlayerPedId(), Config.Actions.repairVehicle.actions.animation.scenario, 0, true) 
		end
		TriggerServerEvent('jg-anwb:server:repair:vehicle')
		exports[''..Config.Progress..'']:Progress({
			name = 'anwb:repair-vehicle',
			duration = Config.Actions.repairVehicle.actions.animation.duration,
			label = 'Voertuig aan het repareren',
			useWhileDead = false,
			canCancel = true,
			controlDisables = {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
		}, function(cancelled)
			if not cancelled then
				ClearPedTasks(PlayerPedId())
				SetVehicleFixed(vehicle)
				SetVehicleDeformationFixed(vehicle)
				SetVehicleUndriveable(vehicle, false)
				SetVehicleEngineOn(vehicle, true, true)
				SetVehicleOnGroundProperly(vehicle)
			end
		end)
	else
		ESX.ShowNotification('Dit voertuig bestaat niet', 'error')
	end
end)

RegisterNetEvent('jg-anwb:client:delete:wok')
AddEventHandler('jg-anwb:client:delete:wok', function(data)
	local vehicle = data.entity
	if vehicle then
    	local props = ESX.Game.GetVehicleProperties(vehicle)

		TriggerServerEvent('jg-apkwok:server:set:wok:status', ESX.Math.Trim(props.plate), false)
	else
		exports[''..Config.Notify..'']:Notify('error', 'Dit voetuig bestaat niet!', 5000)
	end
end)

RegisterNetEvent('jg-anwb:client:vin')
AddEventHandler('jg-anwb:client:vin', function(data)
	local vehicle = data.entity
	if vehicle then
		local props = ESX.Game.GetVehicleProperties(vehicle)
		exports[''..Config.Progress..'']:Progress({
			name = 'jg-anwb:client:vin',
			duration = 60000,
			label = 'Voertuig controleren op VIN nummer',
			useWhileDead = false,
			canCancel = true,
			controlDisables = {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
			animation = {
				animDict = 'mp_intro_seq@',
				anim = 'mp_mech_fix',
				flags = 0,
			},
		}, function(cancelled)
			if not cancelled then
				ClearPedTasks(PlayerPedId())
				TaskPlayAnim(PlayerPedId(), 'mp_intro_seq@', 'exit', 3.0, 3.0, -1, 1, 0, false, false, false)
				TriggerServerEvent('jg-anwb:server:vin', props.plate)
			else
				ClearPedTasks(PlayerPedId())
				TaskPlayAnim(PlayerPedId(), 'mp_intro_seq@', 'exit', 3.0, 3.0, -1, 1, 0, false, false, false)
			end
		end)
	else
		exports[''..Config.Notify..'']:Notify('error', 'Voertuig niet gevonden!', 5000)
	end
end)

RegisterNetEvent('jg-anwb:client:wash:vehicle')
AddEventHandler('jg-anwb:client:wash:vehicle', function(data)
	local vehicle = data.entity
	if vehicle ~= nil then 
		if Config.Actions.washVehicle.actions.animation.enabled then 
			TaskStartScenarioInPlace(PlayerPedId(), Config.Actions.washVehicle.actions.animation.scenario, 0, true) 
		end
		TriggerServerEvent('jg-anwb:server:wash:vehicle')
		exports[''..Config.Progress..'']:Progress({
			name = 'fitstop:wash-vehicle',
			duration = Config.Actions.washVehicle.actions.animation.duration,
			label = 'Voertuig aan het schoonmaken',
			useWhileDead = false,
			canCancel = true,
			controlDisables = {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
		}, function(cancelled)
			if not cancelled then
				ClearPedTasks(PlayerPedId())
				SetVehicleDirtLevel(vehicle, 0.0)
				exports[''..Config.Notify..'']:Notify('success', 'Je hebt het voertuig gewassen!', 5000)
				xPlayer.removeInventoryItem('washand', 1)
			end
		end)
	else
		exports[''..Config.Notify..'']:Notify('error', 'Dit voetuig bestaat niet!', 5000)
	end
end)

RegisterNetEvent('jg-anwb:client:send:factuur')
AddEventHandler('jg-anwb:client:send:factuur', function(data)
	local entity = data.entity
	local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity))

	if distance < 2.0 then
		local options = {
			{
				['title'] = 'Zoek een dienst',
				['description'] = 'Zoek hiermee sneller een dienst',
				['event'] = 'jg-anwb:client:search:fine:list',
				['args'] = { entity = entity }
			}
		}

		for k,v in pairs(Config.Fines) do
			options[#options+1] = {
				title = k,
				event = 'jg-anwb:client:give:fine:list',
				args = { fineId = k, entity = entity }
			}
		end

		lib.registerContext({
			id = 'ambu:see-fines',
			title = 'ANWB: bekijk diensten',
			options = options
		})

		lib.showContext('ambu:see-fines')
	end
end)

RegisterNetEvent('jg-anwb:client:search:fine:list')
AddEventHandler('jg-anwb:client:search:fine:list', function(data)
	local entity = data.entity
	local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity))

	if distance < 2.0 then
		local input = lib.inputDialog('Zoek een dienst', {'Dienst beschrijving'})
		if input then 
			local reason = input[1]
			local found = {}
			local options = {}

			for k,v in pairs(Config.Fines) do
				for i=1, #Config.Fines[k] do
					if string.find(Config.Fines[k][i].label, reason) then
						found[#found+1] = {
							['label'] = Config.Fines[k][i].label,
							['amount'] = Config.Fines[k][i].amount,
							['fineID'] = k,
							['number'] = i
						}
					end
				end
			end

			for i=1, #found do
				options[#options+1] = {
					title = found[i].label .. ' | € ' .. found[i].amount,
					event = 'jg-anwb:client:give:fine:finalise',
					args = { fineId = found[i].fineID, fine = found[i].number, entity = entity }
				}
			end

			if next(options) then
				lib.registerContext({
					id = 'ambu:searched-fines',
					title = 'Politie: bekijk diensten',
					options = options
				})
		
				lib.showContext('ambu:searched-fines')
			else
				ESX.ShowNotification('error', 'Er zijn geen diensten gevonden..')
			end
		end
	end
end)

RegisterNetEvent('jg-anwb:client:give:fine:list')
AddEventHandler('jg-anwb:client:give:fine:list', function(data)
	local entity = data.entity
	local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(entity))
	if distance < 2.0 then
		local options = {}
		for i=1, #Config.Fines[data.fineId] do
			options[#options+1] = {
				title = Config.Fines[data.fineId][i].label .. ' | € ' .. Config.Fines[data.fineId][i].amount,
				event = 'jg-anwb:client:give:fine:finalise',
				args = { fineId = data.fineId, fine = i, entity = entity }
			}
		end

		lib.registerContext({
			id = 'ambu:see-fines-list',
			title = 'ANWB: bekijk diensten',
			options = options
		})

		lib.showContext('ambu:see-fines-list')
	end
end)

RegisterNetEvent('jg-anwb:client:give:fine:finalise')
AddEventHandler('jg-anwb:client:give:fine:finalise', function(data)
	local entityPlayer = ESX.Game.GetPlayerFromPed(data.entity)
	local playerid = GetPlayerServerId(entityPlayer)

	TriggerServerEvent('esx_billing:sendBill', playerid, 'society_mechanic', Config.Fines[data.fineId][data.fine].label,Config.Fines[data.fineId][data.fine].amount)
end)

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	local specialContact = {
		name       = 'Anwb',
		number     = 'mechanic',
		base64Icon = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NDFGQTJDRkI0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NDFGQTJDRkM0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo0MUZBMkNGOTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo0MUZBMkNGQTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PoW66EYAAAjGSURBVHjapJcLcFTV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'
	}

	TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

-- don't show dispatches if the player isn't in service
AddEventHandler('esx_phone:cancelMessage', function(dispatchNumber)
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' and ESX.PlayerData.job.name == dispatchNumber then
		-- if esx_service is enabled
		if Config.EnableESXService and not playerInService then
			CancelEvent()
		end
	end
end)