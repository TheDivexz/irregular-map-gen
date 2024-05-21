extends Node2D

@export var province_count = 1000
const RELAXATION = 2
var province = preload("res://Provinces/province.tscn")
@onready var elevetion_noise = $"../Noise"
@onready var moisture_noise = $"../Moisture"
var elevation_noise_data : Noise
var moisture_noise_data : Noise

const MAP_WIDTH = 1920
const MAP_HEIGHT = 1080
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	elevation_noise_data = elevetion_noise.texture.get_noise()
	moisture_noise_data = moisture_noise.texture.get_noise()
	create_provinces()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Creates the borders for every single province
func create_provinces():
	var rand = RandomNumberGenerator.new()
	var max_x = MAP_WIDTH
	var max_y = MAP_HEIGHT
	var del : Delaunay = Delaunay.new()
	# Generate All the Points
	for i in range(province_count):
		var point_loc = Vector2(randi_range(0,max_x),randi_range(0,max_y))
		del.add_point(point_loc)
	
	# Create Delaunay diagram
	var trianglulate = del.triangulate()
	var voronai = del.make_voronoi(trianglulate)
	for v in voronai:
		var new_poly = Polygon2D.new()
		new_poly.polygon = v.polygon
		add_child(new_poly)
		
	# Impliments Loyd's Relaxation
	loyds_relaxation(RELAXATION)
	# Makes provinces
	generate_provinces()

# Estimates the Centroid of a polygon
func centroid(corners : PackedVector2Array) -> Vector2:
	var x = 0
	var y = 0
	var count = corners.size()
	for corner in corners:
		x += corner.x
		y += corner.y
	return Vector2(x/count,y/count)

# Generates the provinces
func generate_provinces():
	var provinces = []
	# Takes all the polygons and turns them into provinces
	for child in get_children():
		var new_province = province.instantiate()
		new_province.get_child(0).polygon = child.polygon
		new_province.get_child(0).color = Color(randf(),randf(),randf(),1.0)
		new_province.get_child(1).get_child(0).polygon = child.polygon
		new_province.centroid = centroid(child.polygon)
		remove_child(child)
		# Checks if the corners are out of bounds
		var isoutside = 0
		for corner in new_province.get_child(0).polygon:
			if corner.x > MAP_WIDTH or corner.x < 0:
				isoutside += 1
			elif corner.y > MAP_HEIGHT or corner.y < 0:
				isoutside += 1
		# if the whole province is out the borders get rid of it
		if isoutside >= len(new_province.get_child(0).polygon):
			continue
		# if only part of it is outside then fixes it
		if isoutside > 0:
			var corners = new_province.get_child(0).polygon
			var index = 0
			while index < len(corners):
				if corners[index].x < 0:
					corners[index].x = 0
				elif corners[index].x > MAP_WIDTH:
					corners[index].x = MAP_WIDTH
				if corners[index].y < 0:
					corners[index].y = 0
				elif corners[index].y > MAP_HEIGHT:
					corners[index].y = MAP_HEIGHT
				index += 1
			new_province.get_child(0).polygon = corners
		add_child(new_province)
		# calculates the neighbors
		for p in provinces:
			var corners = new_province.get_child(0).polygon
			for corner in corners:
				if corner in p.get_child(0).polygon:
					p.neighbors.append(new_province)
					new_province.neighbors.append(p)
		# Determine Elevation of the province
		var biome_info = calculate_biome(new_province.centroid)
		new_province.set_biome(biome_info.x,biome_info.y)
		provinces.append(new_province)

# Relaxes the centroids of the polygons n number of times
func loyds_relaxation(relax : int):
	for i in range(relax):
		var del = Delaunay.new()
		for child in get_children():
			del.add_point(centroid(child.polygon))
			remove_child(child)
		var trianglulate = del.triangulate()
		var voronai = del.make_voronoi(trianglulate)
		for v in voronai:
			var new_poly = Polygon2D.new()
			new_poly.polygon = v.polygon
			add_child(new_poly)

# calcuates the elevation
func calculate_biome(location : Vector2) -> Vector2:
	var elevation = elevation_noise_data.get_noise_2dv(location) + 0.5
	var moisture = moisture_noise_data.get_noise_2dv(location) + 0.5
	return(Vector2(elevation,moisture))
