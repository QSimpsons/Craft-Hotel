-- Laadt als laatste client-script en zet Config.Locations.functionDefine
-- naar echte functies. Daardoor crasht ook de oude regel:
--   v['functionDefine'](v.type, k)

CreateThread(function()
    for _ = 1, 100 do
        if type(BindAnwbLocationActions) == 'function' then
            if BindAnwbLocationActions() then
                return
            end
        elseif type(OpenGarage) == 'function' and type(Config) == 'table' and Config.Locations then
            for _, loc in pairs(Config.Locations) do
                if type(loc.functionDefine) ~= 'function' then
                    if loc.drawText == 'Garage' then loc.functionDefine = OpenGarage end
                    if loc.drawText == 'Voertuig wegzetten' then loc.functionDefine = DeleteVehicle end
                    if loc.drawText == 'Omkleden' then loc.functionDefine = CloakroomMenu end
                    if loc.drawText == 'In-/uitklokken' then loc.functionDefine = OnOffDuty end
                    if loc.drawText == 'Werkspullen pakken' then loc.functionDefine = GetGear end
                    if loc.drawText == 'Baas acties' then loc.functionDefine = OpenManagement end
                end
            end
            return
        end
        Wait(100)
    end
end)
