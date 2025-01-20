#include "ui.lua"
#include "input.lua"
#include "script/Utils.lua"
#include "script/Defs.lua"
#include "script/Types.lua"
#include "script/Simulation.lua"

------------------------------------------------
-- INIT
-------------------------------------------------
function init()
	RegisterTool(REG.TOOL_KEY, TOOL_NAME, nil, 5)
	SetBool("game.tool."..REG.TOOL_KEY..".enabled", true)
	SetFloat("game.tool."..REG.TOOL_KEY..".ammo", 1000)
end

-------------------------------------------------
-- TICK 
-------------------------------------------------

function tick(dt)
	handleInput(dt)
	scanBrokenTick(dt)
	fireballCalcTick(dt)
	smokeTick(dt)
	simulationTick(dt)
	impulseTick(dt)
	if not canInteract(true, false) then 
		-- anytime the tool is not available or interactable
		plantTimer = 0.1
	end

	if GetString("game.player.tool") == REG.TOOL_KEY then 
		-- events that can happen only in the tool, 
		-- but possibly in a vehicle
	end
end

function canInteract(checkCanUseTool, checkInVehicle)
	return GetString("game.player.tool") == REG.TOOL_KEY 
	and (not checkCanUseTool or GetBool("game.player.canusetool"))  
	and (not checkInVehicle or GetPlayerVehicle() == 0)
end


