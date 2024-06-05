extends Node2D

@export var province_count = 1000
@export var max_amplitude = 10
@export var max_noise_border = 2
const RELAXATION = 2
var province = preload("res://Provinces/province.tscn")
@onready var elevetion_noise = $"../Noise"
@onready var moisture_noise = $"../Moisture"
@onready var cellular_automata = $"../Cellular_Automata"
var elevation_noise_data : Noise
var moisture_noise_data : Noise

const MAP_WIDTH = 1920
const MAP_HEIGHT = 1080
# Called when the node enters the scene tree for the first time.
func _ready():
	print("Provinces Started")
	randomize()
	elevation_noise_data = elevetion_noise.texture.get_noise()
	moisture_noise_data = moisture_noise.texture.get_noise()
	create_provinces()
	cellular_automata.ordered_list = []
	cellular_automata.next_itr = []
	# noisy_borders() Need to revisit. I was not cooking with this one
	print("Provinces Ended")

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
		if child.polygon.size() <= 0:
			remove_child(child)
			continue
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
			new_province.centroid = centroid(new_province.get_child(0).polygon)
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
		new_province.set_biome(biome_info.x,biome_info.y,calculate_iswater(new_province.centroid))
		provinces.append(new_province)

# Relaxes the centroids of the polygons n number of times
func loyds_relaxation(relax : int):
	for i in range(relax):
		var del = Delaunay.new()
		for child in get_children():
			if child.polygon.size() == 0:
				remove_child(child)
				continue
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

func calculate_iswater(location: Vector2):
	var x_val : int = location.x / 10
	var y_val : int = location.y / 10
	return(cellular_automata.ordered_list[x_val + (y_val * cellular_automata.X_SIZE)])

# Makes the borders not a single straight line
func noisy_borders():
	var provinces = get_children()
	for i1 in provinces.size():
		var province = provinces[i1]
		var neighbors = province.neighbors
		i1 += 1
		for j in neighbors.size():
			var neighbor = neighbors[j]
			j += 1
			# Checks to see if theres already a noisy border between these two
			if neighbor.noisy_border:
				continue
			# Finds the 2 points that marks the edges of the borders
			var prov_index = []
			var neighbor_index = []
			for point in neighbor.get_child(0).polygon:
				if province.get_child(0).polygon.has(point):
					prov_index.append(province.get_child(0).polygon.find(point))
					neighbor_index.append(neighbor.get_child(0).polygon.find(point))
			var new_border = []
			if prov_index.size() < 2:
				continue
			new_border.append(province.get_child(0).polygon[prov_index[0]])
			new_border.append(province.get_child(0).polygon[prov_index[1]])
			# iterates over how fine you want the borders to be
			for i in max_noise_border:
				var next_border_itr = []
				var index = 0
				while index < new_border.size() - 1:
					next_border_itr.append(new_border[index])
					next_border_itr.append(gen_noisy_point(new_border[index],new_border[index+1]))
					index += 1
				next_border_itr.append(new_border[-1])
				new_border = next_border_itr
			# updates the polygons to the new shape
			if prov_index.size() > 2 or neighbor_index.size() > 2:
				continue
			var diff_index = [prov_index[1]-prov_index[0],neighbor_index[1]-neighbor_index[0]]
			print(prov_index,neighbor_index,diff_index)
			var provpackedarr = province.get_child(0).polygon
			var neighpackedarr = neighbor.get_child(0).polygon
			if diff_index == [-1,1]:
				print(neighpackedarr)
				print(new_border)
				new_border.pop_front()
				new_border.pop_back()
				var index = neighbor_index[0] + 1
				for p in new_border:
					neighpackedarr.insert(index,p)
					index += 1
				new_border.reverse()
				index = prov_index[1] + 1
				for p in new_border:
					provpackedarr.insert(index,p)
					index += 1
				print(neighpackedarr)
			else:
				continue
			province.get_child(0).polygon = provpackedarr
			neighbor.get_child(0).polygon = neighpackedarr
		province.noisy_border = true
	pass

# Given 2 points, generates a third point at a random location perpendicular to the midpoint
func gen_noisy_point(p1 : Vector2, p2 : Vector2) -> Vector2:
	var midpoint = Vector2((p1.x + p2.x)/2,(p1.y + p2.y)/2)
	var angle = randi_range(0,max_amplitude+1)
	var magnitude = sqrt(pow(p2.x-p1.x,2)+pow(p2.y-p1.y,2))
	var unit_vector = Vector2((p2.x-p1.x)/magnitude,(p2.y-p1.y)/magnitude)
	unit_vector = Vector2(unit_vector.y,-unit_vector.x)
	var halfway_distance = sqrt(pow(midpoint.x-p1.x,2)+pow(midpoint.y-p1.y,2))
	var adjustment = halfway_distance * tan(angle)
	unit_vector = unit_vector * adjustment
	var left_or_right = randi_range(0,1)
	if left_or_right == 0:
		unit_vector *= -1
	return midpoint + unit_vector
