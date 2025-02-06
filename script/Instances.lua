#include "Utils.lua"
#include "Types.lua"
#include "Defs.lua"
#include "HSVRGB.lua"

function createFireballInst()
	local inst = {}
	inst.sparks = {}
	inst.center = Vec()
	inst.dir = Vec()
	inst.impulse = nil
	inst.sparksMax = nil
	inst.radius = nil
	return inst
end

function createSparkInst(source)
	local inst = {}
	inst.pos = Vec() -- set on init
	inst.speed = 0 -- set on init
	inst.dir = source.dir or random_vec(1)
	inst.splitsRemaining = source.splitCount or source.splitsRemaining
	inst.impulse = source.impulse
	inst.fizzleFreq = source.fizzleFreq
	inst.splitSpeed = source.splitSpeed
	inst.splitFreq = source.splitFreq
	inst.fireballRadius = source.fireballRadius
	inst.fireballSparksMax = source.fireballSparksMax
	inst.torusMag = source.torusMag
	inst.vacuumMag = source.vacuumMag
	inst.inflationMag = source.inflationMag
	inst.fromJet = false

	-- below are set per tick
	inst.distanceFromOrigin = 0
	inst.distance_n = 1
	inst.vectorFromOrigin = 0
	inst.inverseVector = Vec()
	inst.lookOriginDir = nil
	return inst
end

function createRocketInst()
    local inst = {}
    inst.trans = nil
    inst.position = nil
	inst.detPosition = nil
    inst.dir = nil
    inst.body = nil
	inst.shape = nil
    inst.speed = ROCKET.ROCKET_SPEED
	inst.distFlown = 0
    inst.fuseDist = fuseDistances[fuseIndex]
    inst.position = Vec() -- set when ready to detonate
	inst.impulse = ROCKET.IMPULSE_POWER
	inst.sparkCount = ROCKET.BOMB_SPARKS
	inst.splitSpeed = ROCKET.SPLIT_SPEED
	inst.splitFreq = ROCKET.SPLIT_FREQ_START
	inst.fizzleFreq = ROCKET.FIZZLE_FREQ
	inst.splitCount = math.ceil((ROCKET.BOMB_ENERGY * 10^2)/inst.sparkCount)
	inst.fireballRadius = ROCKET.FIREBALL_RADIUS
	inst.fireballSparksMax = ROCKET.FIREBALL_SPARKS_MAX
	inst.torusMag = ROCKET.TORUS_PRESSURE
	inst.vacuumMag = ROCKET.VACUUM_PRESSURE
	inst.inflationMag = ROCKET.INFLATION_PRESSURE
    return inst
end

function createJetInst()
    local inst = createRocketInst()
	inst.impulse = JET.IMPULSE_POWER
	inst.splitSpeed = JET.SPLIT_SPEED
	inst.splitFreq = JET.SPLIT_FREQ_START
	inst.fizzleFreq = JET.FIZZLE_FREQ
	inst.fireballRadius = JET.FIREBALL_RADIUS
	inst.fireballSparksMax = JET.FIREBALL_SPARKS_MAX
	inst.torusMag = JET.TORUS_PRESSURE
	inst.vacuumMag = JET.VACUUM_PRESSURE
	inst.inflationMag = JET.INFLATION_PRESSURE
    return inst
end

