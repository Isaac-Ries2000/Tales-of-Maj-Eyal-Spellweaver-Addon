-- Largely taken from the mana_beam particle
local ray = {}
local tiles = math.ceil(math.sqrt(tx*tx+ty*ty))
local tx = tx * engine.Map.tile_w
local ty = ty * engine.Map.tile_h

local colorRLow = colorRLow or 0
local colorRTop = colorRTop or 0
local colorBLow = colorBLow or 0
local colorBTop = colorBTop or 0
local colorGLow = colorGLow or 0
local colorGTop = colorGTop or 0
local colorALow = colorALow or 0
local colorATop = colorATop or 0
local colorRLowAlt = colorRLowAlt or 0
local colorRTopAlt = colorRTopAlt or 0
local colorBLowAlt = colorBLowAlt or 0
local colorBTopAlt = colorBTopAlt or 0
local colorGLowAlt = colorGLowAlt or 0
local colorGTopAlt = colorGTopAlt or 0
local colorALowAlt = colorALowAlt or 0
local colorATopAlt = colorATopAlt or 0
local colorRV = colorRV or 0
local colorRA = colorRA or 0
local colorBV = colorBV or 0
local colorBA = colorBA or 0
local colorGV = colorGV or 0
local colorGA = colorGA or 0
local colorAV = colorAV or 0
local colorAA = colorAA or 0
local density = density or 1

local breakdir = math.rad(rng.range(-8, 8))
ray.dir = math.atan2(ty, tx)
ray.size = math.sqrt(tx*tx+ty*ty)

-- Populate the beam based on the forks
return { generator = function()
	local a = ray.dir
	local rad = rng.range(-3,3)
	local ra = math.rad(rad)
	local r = rng.range(1, ray.size)
	
	local returnR
	local returnG
	local returnB
	local returnA
	
	if (colorATopAlt == 0) or (rng.percent(50)) then
		returnR = (rng.range(colorRLow, colorRTop))/255
		returnG = (rng.range(colorGLow, colorGTop))/255
		returnB = (rng.range(colorBLow, colorBTop))/255
		returnA = (rng.range(colorALow, colorATop))/255
	else
		returnR = (rng.range(colorRLowAlt, colorRTopAlt))/255
		returnG = (rng.range(colorGLowAlt, colorGTopAlt))/255
		returnB = (rng.range(colorBLowAlt, colorBTopAlt))/255
		returnA = (rng.range(colorALowAlt, colorATopAlt))/255
	end
	
	return {
		life = 14,
		size = rng.range(4, 6), sizev = -0.1, sizea = 0,

		x = r * math.cos(a) + 2 * math.cos(ra), xv = 0, xa = 0,
		y = r * math.sin(a) + 2 * math.sin(ra), yv = 0, ya = 0,
		dir = rng.percent(50) and ray.dir + math.rad(rng.range(50, 130)) or ray.dir - math.rad(rng.range(50, 130)), dirv = 0, dira = 0,
		vel = rng.percent(30) and 1 or 0, velv = -0.1, vela = 0.01,

		r = returnR, rv = colorRV, ra = colorRA,
		g = returnG, gv = colorBV, ga = colorBA,
		b = returnB, bv = colorGV, ba = colorGA,
		a = returnA, av = colorAV, aa = colorAA,
	}
end, },
function(self)
	self.nb = (self.nb or 0) + 1
	if self.nb < 6 then
		self.ps:emit(30*tiles*density)
	end
end,
14*30*tiles,
"particle_torus"
