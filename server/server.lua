ESX = nil

local litrosLeche = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('leche:sumar') 
AddEventHandler('leche:sumar', function()
	local source_ = source
	if not litrosLeche[source_] then
		litrosLeche[source_] = 0
	end
	litrosLeche[source_] = litrosLeche[source_] + 1
	TriggerClientEvent('Notify', source_, 'importante', _U('entregado', litrosLeche[source_]))
end)

RegisterServerEvent('leche:vender') 
AddEventHandler('leche:vender', function()
	local source_ = source
	if not litrosLeche[source_] then
		litrosLeche[source_] = 0
	end
	if litrosLeche[source_] == 0 then
		TriggerClientEvent('Notify', source_, 'negado', _U('ninguna'))
	else
		local xPlayer = ESX.GetPlayerFromId(source_)
		if xPlayer then
			local total = Config.Price * litrosLeche[source_]
			xPlayer.addMoney(total)
			TriggerClientEvent('Notify', source_, 'sucesso', _U('vendido', litrosLeche[source_], total))
			litrosLeche[source_] = 0
		else
			TriggerClientEvent('Notify', source_, 'importante', "WTF this error, report to Discord")
		end
	end
end)
