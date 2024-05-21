extends Node2D

enum BIOMES {
	OCEAN,
	BEACH,
	SCORCHED,
	BARE,
	TUNDRA,
	SNOW,
	TEMPERATE_DESERT,
	SHRUBLAND,
	TAIGA,
	GRASSLAND,
	TEMPERATE_DECIDIOUS_FOREST,
	TEMPERATE_RAIN_FOREST,
	SUBTROPICAL_DESERT,
	TROPICAL_SEASONAL_FOREST,
	TROPICAL_RAIN_FOREST
}

var neighbors = []
var centroid : Vector2
var isLand = true # True means Land False means Water
var elevation = 0
var moisture = 0
var biome : BIOMES

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func rgb_to_color(r : float,g : float,b : float) -> Color:
	return Color(r/255.0,g/255.0,b/255.0)

func set_biome(e : float,m : float):
	elevation = e
	moisture = m
	# Increase the Exponent to make more provinces ocean
	elevation = pow(elevation,3.0)
	var nx = (2 * centroid.x / 1920) - 1
	var ny = (2 * centroid.y / 1080) - 1
	var square_bump = 1 - ((1-pow(nx,2)) * (1-pow(ny,2)))
	var euclidian_squared = min(1,(pow(nx,2) + pow(ny,2))/sqrt(2.0))
	elevation = linear_interpolation(elevation,1-euclidian_squared,0.5)
	biome = calc_biome()
	$shape.color = calc_terrain_color()

func calc_biome() -> BIOMES:
	if elevation < 0.10:
		isLand = false
		return BIOMES.OCEAN
	if elevation < 0.12:
		isLand = false
		return BIOMES.BEACH
	
	if elevation > 0.8:
		if moisture < 0.1:
			return BIOMES.SCORCHED
		if moisture < 0.2:
			return BIOMES.BARE
		if moisture < 0.5:
			return BIOMES.TUNDRA
		return BIOMES.SNOW
		
	if elevation > 0.6:
		if moisture < 0.33:
			return BIOMES.TEMPERATE_DESERT
		if moisture < 0.66:
			return BIOMES.SHRUBLAND
		return BIOMES.TAIGA
		
	if elevation > 0.3:
		if moisture < 0.16:
			return BIOMES.TEMPERATE_DESERT
		if moisture < 0.5:
			return BIOMES.GRASSLAND
		if moisture < 0.83:
			return BIOMES.TEMPERATE_DECIDIOUS_FOREST
		return BIOMES.TEMPERATE_RAIN_FOREST
	
	if moisture < 0.16:
		return BIOMES.SUBTROPICAL_DESERT
	if moisture < 0.33:
		return BIOMES.GRASSLAND
	if moisture < 0.66:
		return BIOMES.TROPICAL_SEASONAL_FOREST
	return BIOMES.TROPICAL_RAIN_FOREST
	
func calc_terrain_color() -> Color:
	var return_val : Color
	match biome:
		BIOMES.OCEAN:
			return_val = rgb_to_color(22,41,73)
		BIOMES.BEACH:
			return_val = rgb_to_color(204,177,122)
		BIOMES.SCORCHED:
			return_val = rgb_to_color(119,12,2)
		BIOMES.BARE:
			return_val = rgb_to_color(104,94,82)
		BIOMES.TUNDRA:
			return_val = rgb_to_color(109,115,177)
		BIOMES.SNOW:
			return_val = rgb_to_color(224,223,218)
		BIOMES.TEMPERATE_DESERT:
			return_val = rgb_to_color(160,103,48)
		BIOMES.SHRUBLAND:
			return_val = rgb_to_color(197,177,91)
		BIOMES.TAIGA:
			return_val = rgb_to_color(60,81,100)
		BIOMES.GRASSLAND:
			return_val = rgb_to_color(67,127,13)
		BIOMES.TEMPERATE_DECIDIOUS_FOREST:
			return_val = rgb_to_color(154,125,31)
		BIOMES.TEMPERATE_RAIN_FOREST:
			return_val = rgb_to_color(40,53,9)
		BIOMES.SUBTROPICAL_DESERT:
			return_val = rgb_to_color(227,177,114)
		BIOMES.TROPICAL_SEASONAL_FOREST:
			return_val = rgb_to_color(68,97,39)
		BIOMES.TROPICAL_RAIN_FOREST:
			return_val = rgb_to_color(33,46,28)
	return return_val

func linear_interpolation(v0 : float, v1 : float, v2 : float):
	return ((1 - v2) * v0 + v2 * v1)
