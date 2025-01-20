#include "script/Utils.lua"
#include "script/Defs.lua"
#include "script/Types.lua"
#include "script/Simulation.lua"

plantRate = 0.3
plantTimer = 0
fuseDistances = { 0, 0.1, 0.5, 1, 2, 3, 5 }
fuseIndex = 1

function handleInput(dt)
	plantTimer = math.max(plantTimer - dt, 0)

	if GetString("game.player.tool") == REG.TOOL_KEY then
		-- commands you can't do in a vehicle
		if GetPlayerVehicle() == 0 then 
			-- fire rocket
			if InputDown(KEY.FIRE.key) and 
			GetPlayerGrabShape() == 0 
			and	plantTimer == 0 
			then
				fire_rocket()
			end
		end
		-- commands you CAN do in a vehicle
		if InputPressed(KEY.CYCLE_FUSE.key) then
		end
	end
end
