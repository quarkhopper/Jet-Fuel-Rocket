#include "Utils.lua"
#include "Defs.lua"

rockets = {}
toDetonate {}
launch_sound = LoadSound("MOD/snd/rocket_launch.ogg")

function inst_rocket()
    local inst = {}
    inst.trans = nil
    inst.dir = nil
    inst.body = nil
	inst.shape = nil
    inst.speed = JETFUEL.ROCKET_SPEED
    inst.dist_left = JETFUEL.ROCKET_MAX_DIST
    inst.fuseDist = fuseDistances[fuseIndex]
    inst.position = Vec() -- set when ready to detonate
	inst.impulse = JETFUEL.IMPULSE_POWER
	inst.sparkCount = JETFUEL.BOMB_SPARKS
	inst.splitSpeed = JETFUEL.SPLIT_SPEED
	inst.fizzleFreq = JETFUEL.FIZZLE_FREQ
	inst.splitCount = math.ceil((JETFUEL.BOMB_ENERGY * 10^2)/inst.sparkCount)
	inst.fireballRadius = JETFUEL.FIREBALL_RADIUS
	inst.fireballSparksMax = JETFUEL.FIREBALL_SPARKS_MAX
	inst.torusMag = JETFUEL.TORUS_PRESSURE
	inst.vacuumMag = JETFUEL.VACUUM_PRESSURE
	inst.inflationMag = JETFUEL.INFLATION_PRESSURE
    return inst
end

function fire_rocket()
    local camera = GetPlayerCameraTransform()
	local gun_end = TransformToParentPoint(camera, Vec(0.2, -0.2, -2))
    local forward = TransformToParentPoint(camera, Vec(0, 0, -10))
    local rocket_rot = QuatLookAt(gun_end, forward)
    local rocket_prefab = Spawn("MOD/prefab/rocket.xml", Transform(gun_end, rocket_rot))
    local rocket = inst_rocket()
    local rocket.body = prefab[1]
    local rocket.shape = prefab[2]
    local rocket.dir = VecNormalize(VecSub(forward, camera.pos))
    table.insert(rockets, rocket)
    PlaySound(launch_sound, gun_end, 10)
end

function scanBrokenTick(dt)
	local intactRockets = {}
	for i=1, #rockets do
		local rocket = rockets[i]
		if IsShapeBroken(rocket.shape) then
			table.insert(toDetonate, rocket)
		else
			table.insert(intactRockets, rocket)
		end
	end
	rockets = intactRockets
end

function detonationTick(dt)
    for i=1, #toDetonate do
        createExplosion(toDetonate[i])
    end
    toDetonate = {}
end

function rocketTick(dt)
    local rockets_next_tick = {}
    for i = 1, #rockets do
        local rocket = rockets[i]
        local hit, dist = QueryRaycast(rocket.trans.pos, rocket.dir, rocket.speed, 0.025)
        if hit then 
            table.insert(toDetonate, rocket)
            local hit, dist = QueryRaycast(rocket.trans.pos, rocket.dir, rocket.speed, 0.025)
            if hit then 
                -- just blow the charge. You can't bust this.
                table.insert(toDetonate, rocket)
            end
        elseif rocket.dist_left <= 0 then 
            table.insert(toDetonate, rocket)
        else
            local advance = VecScale(rocket.dir, rocket.speed)
            rocket.trans.pos = VecAdd(rocket.trans.pos, advance)
            SetBodyTransform(rocket.body, rocket.trans)
            SetBodyDynamic(rocket.body, false)
            rocket.dist_left = rocket.dist_left - rocket.speed
            table.insert(rockets_next_tick, rocket)
            local light_point = TransformToParentPoint(rocket.trans, Vec(0, 0, 2))
            for i = 1, 20 do
                ParticleReset()
                ParticleType("smoke")
                ParticleAlpha(0.5, 0.9, "linear", 0.05, 0.5)
                ParticleRadius(0.2, 0.5)
                ParticleTile(5)
                local smoke_color = HSVToRGB(Vec(0, 0, 0.5))
                ParticleColor(smoke_color[1], smoke_color[2], smoke_color[3])
                local smoke_point = VecAdd(rocket.trans.pos, VecScale(rocket.dir, -1 * (rocket.speed / i)))
                SpawnParticle(smoke_point, Vec(), 0.3)
            end
            PointLight(light_point, 1, 0, 0, 0.1)
        end
    end
    rockets = rockets_next_tick
end
