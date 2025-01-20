#include "Utils.lua"
#include "Defs.lua"

rockets = {}
launch_sound = LoadSound("MOD/snd/rocket_launch.ogg")

function inst_rocket(body, dir)
    local inst = {}
    inst.body = body
    inst.trans = GetBodyTransform(inst.body)
    inst.dir = dir
    inst.speed = 1
    inst.dist_left = 100
    inst.fuseDist = 0
    return inst
end

function fire_rocket()
    local camera = GetPlayerCameraTransform()
	local gun_end = TransformToParentPoint(camera, Vec(0.2, -0.2, -2))
    local forward = TransformToParentPoint(camera, Vec(0, 0, -10))
    local rocket_rot = QuatLookAt(gun_end, forward)
    local rocket_body = Spawn("MOD/prefab/rocket.xml", Transform(gun_end, rocket_rot))[1]
    local rocket_dir = VecNormalize(VecSub(forward, camera.pos))
    local rocket = inst_rocket(rocket_body, rocket_dir)
    rocket.speed = TOOL.ROCKET.speed.value
    rocket.dist_left = TOOL.ROCKET.max_dist.value
    table.insert(rockets, rocket)
    PlaySound(launch_sound, gun_end, 10)
end

function rocket_tick(dt)
    local default_fuse = 0.1
    if TOOL.ROCKET.fuse ~= nil then 
        default_fuse = TOOL.ROCKET.fuse.value
    end
    local rockets_next_tick = {}
    for i = 1, #rockets do
        local rocket = rockets[i]
        local hit, dist = QueryRaycast(rocket.trans.pos, rocket.dir, rocket.speed, 0.025)
        if rocket.fuse > 0 then -- > 0 means the fuse is lit
            rocket.fuse = math.max(rocket.fuse - dt, 0)
        end
        if hit then 
            -- break a hole and on the next tick explode
            if rocket.fuse < 0 then 
                rocket.fuse = default_fuse 
            end
            for i = 1, rocket.speed * 10 do -- make a train of holes
                local offset = i * 0.1
                MakeHole(VecAdd(rocket.trans.pos, VecScale(rocket.dir, offset)), 1, 1, 1)
            end
            -- check again in case we're hitting the ground
            local hit, dist = QueryRaycast(rocket.trans.pos, rocket.dir, rocket.speed, 0.025)
            if hit then 
                -- just blow the charge. You can't bust this.
                rocket.fuse = 0
            end
        end
        if rocket.fuse == 0 then 
            SetBodyDynamic(rocket, true)
            Explosion(rocket.trans.pos, 1)
            local pos = rocket.trans.pos
        elseif rocket.dist_left <= 0 then 
            -- ran out of fuel
            Explosion(rocket.trans.pos, 1)
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

function fire_charge(rocket)
       
end