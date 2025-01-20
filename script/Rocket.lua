#include "Utils.lua"
#include "Defs.lua"
#include "Instances.lua"

rockets = {}
launchSound = LoadSound("MOD/snd/rocket_launch.ogg")

function fire_rocket()
    local camera = GetPlayerCameraTransform()
	local gunEnd = TransformToParentPoint(camera, Vec(0.1, -0.1, -2))
    local forward = TransformToParentPoint(camera, Vec(0, 0, -10))
    local rocketRot = QuatLookAt(gunEnd, forward)
    local rocket = createRocketInst()
    rocket.trans = Transform(gunEnd, rocketRot)
    local prefab = Spawn("MOD/prefab/rocket.xml", rocket.trans)
    rocket.body = prefab[1]
    rocket.shape = prefab[2]
    rocket.dir = VecNormalize(VecSub(forward, camera.pos))
    table.insert(rockets, rocket)
    PlaySound(launchSound, gunEnd, 10)
end

function rocketFlyTick(dt)
    for i = 1, #rockets do
        local rocket = rockets[i]
        local advance = VecScale(rocket.dir, rocket.speed)
        rocket.trans.pos = VecAdd(rocket.trans.pos, advance)
        rocket.position = rocket.trans.pos -- to make this work with the jet fuel sim
        SetBodyTransform(rocket.body, rocket.trans)
        SetBodyDynamic(rocket.body, false)
        local lightPoint = TransformToParentPoint(rocket.trans, Vec(0, 0, 2))
        for i = 1, 10 do
            ParticleReset()
            ParticleType("smoke")
            ParticleAlpha(0.5, 0.8, "linear", 0.05, 0.5)
            ParticleRadius(0.2, 0.5)
            ParticleTile(5)
            local smokeColor = HSVToRGB(Vec(0, 0, 0.5))
            ParticleColor(smokeColor[1], smokeColor[2], smokeColor[3])
            local smokePoint = VecAdd(rocket.trans.pos, VecScale(rocket.dir, (-1 * (rocket.speed / i)) - 1))
            local smokePoint = VecAdd(random_vec(0.1), smokePoint)
            SpawnParticle(smokePoint, Vec(), 0.2)
        end
        PointLight(lightPoint, 5, 0, 0, 0.1)
    end
end

function detonationTick(dt)
	local intactRockets = {}
    local toDetonate = {}

    -- make sure rockets do not trigger other rockets to detonate
    local rejectShapes = {}
    for i=1, #rockets do
        local rocket = rockets[i]
        local shapes = GetBodyShapes(rocket.body)
        for s=1, #shapes do
            table.insert(rejectShapes, shapes[s])
        end
    end    
    
	for i=1, #rockets do
		local rocket = rockets[i]
        local rocketDetonated = false
        local rocketAborted = false
        rocket.distFlown = rocket.distFlown + rocket.speed
        if rocket.distFlown > JETFUEL.ROCKET_MAX_DIST then 
            rocket.detPosition = rocket.trans.pos
            rocketAborted = true
        end
        
        if not rocketDetonated and IsShapeBroken(rocket.shape) then
            rocket.detPosition = rocket.trans.pos
            rocketDetonated = true
        end
        
        local distFromPlayer = VecLength(VecSub(GetPlayerTransform().pos, rocket.trans.pos))
        -- if not rocketDetonated and rocket.distFlown > JETFUEL.ROCKET_SAFE_DIST then 
        if not rocketDetonated and distFromPlayer > JETFUEL.ROCKET_SAFE_DIST then 
            -- check if near enough to something to detonate
            QueryRejectShapes(rejectShapes)
            local near_hit, near_pos, near_normal, near_shape = QueryClosestPoint(rocket.trans.pos, fuseDistances[fuseIndex])
            if near_hit then 
                rocket.detPosition = rocket.trans.pos
                rocketDetonated = true
            end
        end 

        if not rocketDetonated then 
            -- we don't check for safe distance in the forward direction. If you've fired at a 
            -- wall in front of you it WILL explode in your face!
            -- check if about to hit
            QueryRejectShapes(rejectShapes)
            local hit, dist = QueryRaycast(rocket.trans.pos, rocket.dir, rocket.speed + 0.1, 0.025)
            if hit then
                local remainingDist = dist - fuseDistances[fuseIndex]
                -- actually set to explode where it should considering the fuse
                rocket.detPosition = VecAdd(rocket.trans.pos, VecScale(rocket.dir, dist - fuseDistances[fuseIndex]))
                rocketDetonated = true
            end
        end

        if rocketDetonated then 
            table.insert(toDetonate, rocket)
        elseif rocketAborted then
            Delete(rocket.body)
            Explosion(rocket.trans.pos, 1)
        else
            table.insert(intactRockets, rocket)
        end
	end
	rockets = intactRockets

    for i=1, #toDetonate do
        local rocket = toDetonate[i]
        createExplosion(rocket)
        Delete(rocket.body)
    end
end


