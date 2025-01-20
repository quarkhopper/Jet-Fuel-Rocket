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
	inst.splitFreq = source.splitFreq or JETFUEL.SPLIT_FREQ_START
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

function createBombInst(shape)
	local inst = {}
	inst.position = Vec() -- set when ready to detonate
	inst.dir = nil
	inst.shape = shape
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
