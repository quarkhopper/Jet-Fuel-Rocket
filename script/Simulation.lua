#include "Utils.lua"
#include "Types.lua"
#include "Defs.lua"
#include "HSVRGB.lua"
#include "Instances.lua"

-- sounds used. Don't ask about the toilet.
boomSound = LoadSound("MOD/snd/toiletBoom.ogg")
rumbleSound = LoadSound("MOD/snd/rumble.ogg")

-- any shape that can explode
bombs = {}

-- all sparks in the simulation, regardless of where they're assigned
allSparks = {}

-- dead sparks that are simulated as smoke puffs separate from the rest of the sim 
-- for performance. The "crust" on the fireball
smoke = {}

-- heat centers with sparks assigned to them. One center potentialy forms one torus.
fireballs = {}

-- bombs actually waiting to be detonated when appropriate
toDetonate = {}

-- bombs that are still alive (intact shapes). If bombs
-- are found to be broken shapes, they're added to the
-- toDetonate table
function scanBrokenTick(dt)
	local unbrokenBombs = {}
	for i=1, #bombs do
		local bomb = bombs[i]
		if IsShapeBroken(bomb.shape) then
			table.insert(toDetonate, bomb)
		else
			table.insert(unbrokenBombs, bomb)
		end
	end
	bombs = unbrokenBombs
end

-- analyze all sparks to determine fireball centers
function fireballCalcTick(dt)
	fireballs = {}
	newSparks = {}
	local unassignedSparks = copyTable(allSparks)
	while #unassignedSparks > 0 do
		local fireball = createFireballInst()
		local positions = {}
		local dirs = {}
		local newUnassigned = {}
		for i=1, #unassignedSparks do
			local spark = unassignedSparks[i]
			if #fireball.sparks == 0 then 
				fireball.center = spark.pos
				fireball.impulse = spark.impulse
				fireball.radius = spark.fireballRadius
				fireball.sparksMax = spark.fireballSparksMax
			end
			spark.vectorFromOrigin = VecSub(spark.pos, fireball.center)
			spark.distanceFromOrigin = VecLength(spark.vectorFromOrigin)
			if #fireball.sparks <= fireball.sparksMax and
			spark.distanceFromOrigin < fireball.radius then 
				spark.distance_n = math.min(1, 1/(1 + spark.distanceFromOrigin))
				spark.inverseVector = VecScale(spark.vectorFromOrigin, -1)
				spark.lookOriginDir = VecNormalize(spark.inverseVector)
				table.insert(fireball.sparks, spark)
				table.insert(positions, spark.pos)
				table.insert(dirs, spark.dir)
			else
				table.insert(newUnassigned, spark)
			end
		end
		fireball.center = average_vec(positions)
		fireball.dir = VecNormalize(average_vec(dirs))
		table.insert(fireballs, fireball)
		for s=1, #fireball.sparks do
			table.insert(newSparks, fireball.sparks[s])
		end
		unassignedSparks = newUnassigned
	end
	allSparks = newSparks
end

function smokeTick(dt)
	for s = 1, #smoke do
		makeSmoke(smoke[s])
	end
	smoke = {}
end

-- simlate all interative effects with sparks and fireballs
function simulationTick(dt)
	local newSparks = {}
	local player_pos = GetPlayerTransform().pos
	for e=1, #fireballs do
		local fireball = fireballs[e]
		for s = 1, #fireball.sparks do
			local spark = fireball.sparks[s]
			local sparkStillAlive = true
			local forceSplit = false
			local hitPoint = nil
			local hit, dist, normal, shape = QueryRaycast(spark.pos, spark.dir, spark.speed + 0.1, 0.025)
			-- Evolve the spark
			-- Fizzling verses splitting are the fundimental opposing lifespan forces
			-- fizzling, when a spark dies spontaneously
			-- the sparks further away from the center of the fireball center will die out
			-- faster than the closer ones
			local chance = math.max(math.ceil(spark.fizzleFreq * (spark.distance_n ^ 0.5)), 1)
			if chance >= 1 and math.random(1, chance) == 1 then
				sparkStillAlive = false
			end
			
			if hit then
				-- hit something, make hole
				MakeHole(spark.pos, JETFUEL.HOLE_VOXEL_SOFT / 10, JETFUEL.HOLE_VOXEL_MEDIUM / 10, JETFUEL.HOLE_VOXEL_HARD / 10)
				Paint(spark.pos, 0.8, "explosion")

				-- hit following
				local body = GetShapeBody(shape)
				if body ~= nil then
					local velocity = GetProperty(body, "velocity")
					if VecLength(velocity) < JETFUEL.SPARK_DEATH_SPEED then
						-- stationary object or it slowed down too much
						-- if the angle is shallow allow a split, otherwise end the spark
						local dot = math.abs(VecDot(normal, spark.dir))
						if (dot < 0.5) then
							spark.dir = VecScale(spark.dir, -1)
							forceSplit = true
						else
							sparkStillAlive = false
						end
					else
						-- moving object, match the speed of it
						local newSpeed = math.min(VecLength(velocity), JETFUEL.HIT_FOLLOW_MAX_SPEED)
						spark.dir = VecNormalize(velocity)
						spark.speed = newSpeed
						forceSplit = true
					end
				else
					-- shape had no body
					spark.dir = VecScale(spark.dir, -1)
				end
			else
				-- spark slows down
				spark.speed = math.max(spark.speed * (1 - JETFUEL.SPARK_SPEED_REDUCTION), JETFUEL.SPARK_DEATH_SPEED)

				-- pressure effects.
				-- Torus effects - Pulling from behind the cloud and pushing from the front
				local pressureDistance_n = spark.distance_n  ^ 0.8
				local angleDot_n = VecDot(spark.lookOriginDir, JETFUEL.FIREBALL_DIR)
				local torus_n = pressureDistance_n * angleDot_n
				local torus_mag = spark.torusMag * VALUES.PRESSURE_EFFECT_SCALE * #fireball.sparks * torus_n
				local torus_vector = VecScale(spark.lookOriginDir, torus_mag)
				pushSparkUniform(spark, torus_vector)

				-- pulling into the center
				local vacuum_mag = spark.vacuumMag * VALUES.PRESSURE_EFFECT_SCALE * #fireball.sparks * pressureDistance_n
				local vacuum_vector = VecScale(spark.lookOriginDir, vacuum_mag ^ 0.5)
				pushSparkUniform(spark, vacuum_vector)

				-- pushing out
				local inflate_mag = spark.inflationMag * VALUES.PRESSURE_EFFECT_SCALE * #fireball.sparks * pressureDistance_n * -1
				local inflate_vector = VecScale(spark.lookOriginDir, inflate_mag)
				pushSparkUniform(spark, inflate_vector)

				-- hurt the player if too close
				local dist = VecLength(VecSub(player_pos, spark.pos))
				local dist_n = dist / JETFUEL.IGNITION_RADIUS
				local hurt_n = 1 - math.min(1, dist_n) ^ 0.5
				if hurt_n > JETFUEL.SPARK_HURT then
					local health = GetPlayerHealth()
					SetPlayerHealth(health - (hurt_n * VALUES.SPARK_HURT_SCALE))
				end

				-- splitting into new sparks
				if spark.splitsRemaining < 1 then 
					sparkStillAlive = false
				elseif math.random(1, spark.splitFreq) == 1 or forceSplit then
					for i=1, math.random(JETFUEL.SPARK_SPAWNS_LOWER, JETFUEL.SPARK_SPAWNS_UPPER) do
						if spark.splitsRemaining > 0 then
							spark.splitsRemaining = spark.splitsRemaining - 1
							local newDir = VecAdd(spark.dir, random_vec(JETFUEL.SPLIT_DIR_VARIATION))
							newDir = VecNormalize(newDir)
							local newSpark = createSparkInst(spark)
							newSpark.pos = spark.pos
							newSpark.dir = newDir
							newSpark.speed = vary_by_percentage(spark.splitSpeed, JETFUEL.SPLIT_SPEED_VARIATION)
							table.insert(newSparks, newSpark) -- will be assigned to a fireball next tick
						end
					end
				end
			end

			-- do some culling
			while #newSparks > JETFUEL.SPARKS_SIMULATION do
				table.remove(newSparks, math.random(1, #newSparks))
			end

			if sparkStillAlive and spark.speed > JETFUEL.SPARK_DEATH_SPEED then
				-- the old spark continues on
				spark.pos = VecAdd(spark.pos, VecScale(spark.dir, spark.speed))
				spark.splitFreq = math.floor(math.min(spark.splitFreq + JETFUEL.SPLIT_FREQ_INCREMENT, JETFUEL.SPLIT_FREQ_END))
				table.insert(newSparks, spark) -- will be assigned to a fireball next tick
				makeSparkEffect(spark)
			else
				-- dies into a puff of trailing smoke
				table.insert(smoke, spark)
			end
		end

		-- spawn fire
		for probe=1, #fireball.sparks do
			if math.random(1, JETFUEL.IGNITION_FREQ) == 1 then
				local ign_probe_dir = random_vec(1)
				local ign_probe_hit, ign_probe_dist, ign_probe_normal, ign_probe_shape = QueryRaycast(fireball.center, ign_probe_dir, JETFUEL.IGNITION_RADIUS)
				if ign_probe_hit then
					local ign_probe_pos = VecAdd(fireball.center, VecScale(ign_probe_dir, ign_probe_dist))
					local mat = GetShapeMaterialAtPosition(ign_probe_shape, ign_probe_pos)
					if mat == "glass" then
						MakeHole(ign_probe_pos, 0.2)
					else
						SpawnFire(ign_probe_pos)
						local ign_dir = random_vec(1)
						local ign_hit, ign_dist = QueryRaycast(ign_probe_pos, ign_dir, JETFUEL.IGNITION_RADIUS)
						if ign_hit then
							local ign_pos = VecAdd(ign_probe_pos, VecScale(ign_dir, ign_dist))
							SpawnFire(ign_pos)
						end
					end
				end
			end
		end
	end
	allSparks = newSparks
end

function impulseTick(dt)
	-- impulse the closest 100 shapes
	for e=1, #fireballs do
		local fireball = fireballs[e]
		if fireball.impulse ~= 0 then 
			local shapesFilter = {}
			for i=1, JETFUEL.IMPULSE_TRIALS do
				QueryRejectShapes(shapesFilter)
				local imp_hit, imp_pos, imp_normal, imp_shape = QueryClosestPoint(fireball.center, JETFUEL.IMPULSE_RADIUS)
				if imp_hit == false then
					break
				end
				table.insert(shapesFilter, imp_shape)
				local imp_body = GetShapeBody(imp_shape)
				if imp_body ~= nil then
					local imp_delta = VecSub(imp_pos, fireball.center)
					local imp_delta_mag = VecLength(imp_delta)
					if imp_delta_mag <= JETFUEL.IMPULSE_RADIUS then
						local imp_dir = VecNormalize(imp_delta)
						local imp_n = 1 - bracket_value(imp_delta_mag/JETFUEL.IMPULSE_RADIUS, 1, 0)
						local impulse_mag = imp_n * fireball.impulse * #fireball.sparks * VALUES.IMPULSE_SCALE
						local impulse = VecScale(imp_dir, impulse_mag)
						ApplyBodyImpulse(imp_body, GetBodyCenterOfMass(imp_body), impulse)
					end
				end
			end
		end
	end
end

function createExplosion(bomb)
	bomb.position = getBombPosition(bomb)
	-- check if the bomb can no longer be 
	-- positioned due to be completely destroyed
	if bomb.position == nil then return false end
	for a=1, bomb.sparkCount do
		throwSpark(bomb)
	end
	return true
end

function throwSpark(bomb)
	local newSpark = createSparkInst(bomb)
	if bomb.jet then 
		newSpark.pos = bomb.position
		newSpark.speed = TOOL.jetSpeed.value
	else
		newSpark.pos = VecAdd(bomb.position, random_vec(0.5))
		newSpark.speed = JETFUEL.BLAST_SPEED
	end
	table.insert(allSparks, newSpark)
end

function pushSparkUniform(spark, effectVector)
	local sparkVector = VecScale(spark.dir, spark.speed)
	local newSparkVector = VecAdd(sparkVector, effectVector)
	spark.dir = VecNormalize(newSparkVector)
	spark.speed = VecLength(newSparkVector)
end

function pushSparkFromOrigin(spark, origin, radius, maxAmount, falloffExponent)
	local distance = VecLength(VecSub(origin, spark.pos))
	if distance < radius and distance > 0 then
		local effect_n = (1 - (distance / radius)) ^ falloffExponent
		local effectVector = VecScale(VecNormalize(VecSub(spark.pos, origin)), maxAmount * effect_n)
		pushSparkUniform(spark, effectVector)
	end
end

function getSparkLife(spark)
	local delta = JETFUEL.SPLIT_SPEED - spark.speed
	local value = delta/(JETFUEL.SPLIT_SPEED - JETFUEL.SPARK_DEATH_SPEED)
	return bracket_value(value, 1, 0)
end

function makeSparkEffect(spark)
	local movement = random_vec(1)
	local gravity = 0
	local colorHSV = JETFUEL.SPARK_COLOR
	local color = HSVToRGB(colorHSV)
	local intensity = JETFUEL.SPARK_LIGHT_INTENSITY
	local puffColor = HSVToRGB(Vec(0, 0, VALUES.PUFF_CONTRAST))
	PointLight(spark.pos, color[1], color[2], color[3], intensity)

	-- fire puff
	ParticleReset()
	ParticleType("smoke")
	ParticleTile(math.random(0,1))
	ParticleRotation(((math.random() * 2) - 1) * 10)
	ParticleDrag(0.25)
	ParticleAlpha(1, 0, "easeout")
	ParticleRadius(math.random(JETFUEL.SPARK_TILE_RAD_MIN, JETFUEL.SPARK_TILE_RAD_MAX) * 0.1)
	ParticleColor(puffColor[1], puffColor[2], puffColor[3])
	ParticleGravity(gravity)
	SpawnParticle(spark.pos, movement, JETFUEL.PUFF_LIFE)
end

function makeSmoke(spark)
	local smokeColor = HSVToRGB(JETFUEL.SMOKE_COLOR)
	ParticleReset()
	ParticleType("smoke")
	ParticleTile(math.random(0,1))
	ParticleRotation(((math.random() * 2) - 1) * 10)
	ParticleDrag(0)
	ParticleAlpha(1, 0, "easeout", 0.1, 0.5)
	ParticleRadius(JETFUEL.SMOKE_TILE_SIZE)
	ParticleColor(smokeColor[1], smokeColor[2], smokeColor[3])
	ParticleGravity(0)
	SpawnParticle(VecAdd(spark.pos, random_vec(0.2)), VecScale(VecAdd(spark.dir, random_vec(0.5)), spark.speed), JETFUEL.SMOKE_LIFE)
end

function getBombPosition(bomb)
	if bomb == nil then return nil end
	local position = get_shape_center(bomb.shape)
	if position == nil then return end -- shape totally destroyed
	return position
end

function getIndexByShape(shape, thingTable)
	for i=1, #thingTable do
		local thing = thingTable[i]
		if thing.shape == shape then return i end
	end
	return nil
end
