#include "script/Utils.lua"
#include "script/Defs.lua"
#include "script/Types.lua"
#include "script/Simulation.lua"
#include "script/Weapons.lua"

fireTimer = 0
altFireTimer = 0
fuseDistances = { 0, 0.1, 0.5, 1, 2, 3, 5, 10 }
fuseIndex = 1
explosionSizes = { 300, 500, 800, 1000, 1500, 2000 }
sizeIndex = 2
simSize = explosionSizes[sizeIndex]
hidingTool = false

function handleInput(dt)
	fireTimer = math.max(fireTimer - dt, 0)
	altFireTimer = math.max(fireTimer - dt, 0)

	if GetString("game.player.tool") == REG.TOOL_KEY then
		-- commands you can't do in a vehicle
		if GetPlayerVehicle() == 0 then 
			-- fire rocket
			if InputDown(KEY.FIRE.key) and 
			not InputDown(KEY.ALT_FIRE.key) and
			GetPlayerGrabShape() == 0 and
			fireTimer == 0 
			then
				simSize = explosionSizes[sizeIndex]
				fire_rocket()
				fireTimer = ROCKET.FIRE_DELAY
			end

			-- fire jet beam
			if InputDown(KEY.ALT_FIRE.key) and 
			not InputDown(KEY.FIRE.key) and
			GetPlayerGrabShape() == 0 and
			altFireTimer == 0 
			then
				simSize = JET.SIM_SIZE
				fire_jet()
				altFireTimer = JET.FIRE_DELAY
			end

			-- hide weapon
			if InputPressed("F10") then
				hidingTool = not hidingTool
			end
			if hidingTool then
				SetToolTransform(Transform(Vec(0,-100,0), QuatEuler(0,0,0)))
			end
		end
		-- commands you CAN do in a vehicle
		if InputPressed(KEY.CYCLE_FUSE.key) then
			fuseIndex = fuseIndex + 1
			if fuseIndex > #fuseDistances then fuseIndex = 1 end
		end

		if InputPressed(KEY.CYCLE_EXPLOSION.key) then
			sizeIndex = sizeIndex + 1
			if sizeIndex > #explosionSizes then sizeIndex = 1 end
			simSize = explosionSizes[sizeIndex]
		end
	end
end
