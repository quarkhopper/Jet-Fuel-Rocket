#include "script/Utils.lua"
#include "script/Defs.lua"
#include "script/Types.lua"
#include "script/GameOptions.lua"
#include "script/Init.lua"
#include "script/Simulation.lua"

plantRate = 0.3
plantTimer = 0
editingOptions = false
infuseInProgress = false
selectedOption = nil
selectedIndex = nil
newOptionValue = nil
editingValue = ""
enteredValue = nil
keypadKeybinds = 
{
	{"0", "0"},
	{"1", "1"},
	{"2", "2"},
	{"3", "3"},
	{"4", "4"},
	{"5", "5"},
	{"6", "6"},
	{"7", "7"},
	{"8", "8"},
	{"9", "9"},
	{"backspace", "<-"},
	{"delete", "X"},
	{".", "."}
}


function handleInput(dt)
	if editingOptions == true then return end
	plantTimer = math.max(plantTimer - dt, 0)
	local jetMode = InputDown(KEY.JET_MODE.key)

	if GetString("game.player.tool") == REG.TOOL_KEY then
		-- commands you can't do in a vehicle
		if GetPlayerVehicle() == 0 then 

			-- targeting - done every tick for aim highlighting and actions
			local camera = GetPlayerCameraTransform()
			local shoot_dir = TransformToParentVec(camera, Vec(0, 0, -1))
			local hit, dist, normal, shape = QueryRaycast(camera.pos, shoot_dir, 100, 0, true)
			
			if infuseMode and hit then 
				-- in infuse mode, highlight what you're about to infuse
				if IsShapeBroken(shape) then 
					DrawShapeHighlight(shape, 0.5)
				else
					DrawShapeOutline(shape, 1)
				end
			end

			-- options menus
			if InputPressed(KEY.OPTIONS.key) then
				editingOptions = true
			end


			-- plant bomb / infuse item. NOTE: you can hold it down
			if InputDown(KEY.PLANT.key) and 
			GetPlayerGrabShape() == 0 
			and	plantTimer == 0 
			then
				if not stickyMode and not infuseMode then
					local drop_pos = VecAdd(camera.pos, VecScale(shoot_dir, 2))
					if jetMode then
						local jet = createJetInst(Spawn("MOD/prefab/Jet.xml", Transform(drop_pos), false, false)[2])
						table.insert(jets, jet)
					else
						local bomb = createBombInst(Spawn("MOD/prefab/Decoder.xml", Transform(drop_pos), false, false)[2])
						table.insert(bombs, bomb)
					end
					plantTimer = plantRate
				elseif hit then 
					local bomb = nil
					if not infuseMode then 
						-- stick it to a surface
						local normal_q = quat_between_vecs(Vec(0,1,0), normal)
						local drop_pos = VecAdd(camera.pos, VecScale(shoot_dir, dist))
						if jetMode then 
							local jet = createJetInst(Spawn("MOD/prefab/Jet.xml", Transform(drop_pos, normal_q), false, true)[2])
							jet.dir = normal
							table.insert(jets, jet)
						else
							local bomb = createBombInst(Spawn("MOD/prefab/Decoder.xml", Transform(drop_pos, normal_q), false, true)[2])
							bomb.dir = normal
							table.insert(bombs, bomb)
						end
						plantTimer = plantRate
					elseif infuseInProgress == false then -- unlocked on key up
						-- sabotaging a shape
						local index = getIndexByShape(shape, bombs) or getIndexByShape(shape, jets)
						local isBomb = index ~= nil and bombs[index] ~= nil and bombs[index].shape == shape
						if index == nil then
							if not IsShapeBroken(shape) then 
								-- infuse it
								if jetMode then 
									local jet = createJetInst(shape)
									table.insert(jets, jet)
								else
									local bomb = createBombInst(shape)
									table.insert(bombs, bomb)
								end
								infuseInProgress = true
							end
						else 
							-- un-infuse it
							if isBomb then 
								local removeMe = bombs[index]
								Delete(removeMe)
								table.remove(bombs, index)
							else
								local removeMe = jets[index]
								Delete(removeMe)
								table.remove(jets, index)
							end
							infuseInProgress = true
						end
					end
				end
			end


		end
		-- commands you CAN do in a vehicle

		if InputPressed(KEY.CLEAR.key) then
			-- clear all bombs and jets
			local shapes = FindShapes("decoder", true)
			for i=1, #shapes do
				local shape = shapes[i]
				Delete(shape)
			end
			shapes = FindShapes("jet", true)
			for i=1, #shapes do
				local shape = shapes[i]
				Delete(shape)
			end
			bombs = {}
			toDetonate = {}
			jets = {}
			activeJets = {}
			allSparks = {}
		end

		if InputPressed(KEY.INFUSE_MODE.key) then
			infuseMode = not infuseMode
		end

		if InputPressed(KEY.SINGLE_MODE.key) then
			singleMode = not singleMode
		end

		if InputPressed(KEY.REVERSE_MODE.key) then
			reverseMode = not reverseMode
		end

		if InputPressed(KEY.STICKY_MODE.key) then
			stickyMode = not stickyMode
		end

		if InputPressed(KEY.DETONATE.key) and
		GetPlayerGrabShape() == 0 then
			if singleMode and #bombs > 0 then
				local index = 1 
				if reverseMode then
					index = #bombs		 
				end
				local bomb = bombs[index]
				table.insert(toDetonate, bombs[index])
				table.remove(bombs, index)
			elseif jetMode then 
				toggleAllJets()
			else
				if reverseMode then
					detonateAll(true)
				else
					detonateAll()
				end
			end
		end

		if InputReleased(KEY.PLANT.key) then 
			infuseInProgress = false
		end
	end
end
