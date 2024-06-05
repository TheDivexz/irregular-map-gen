extends Node

const MAP_WIDTH = 1920
const MAP_HEIGHT = 1080
const X_SIZE : int = MAP_WIDTH/10
const Y_SIZE : int = MAP_HEIGHT/10

@export var threshold = 0.6
@export var iterations = 15

var ordered_list = []
var next_itr = []
# Called when the node enters the scene tree for the first time.
func _ready():
	print("Cellular Automata Started")
	for y in Y_SIZE:
		for x in X_SIZE:
			var val = randf()
			ordered_list.append(val < threshold)
	for i in iterations:
		next_round()
	print("Cellular Automata Ended")

func next_round():
	next_itr = []
	for y in Y_SIZE:
		for x in X_SIZE:
			# if it's on an edge its a wall
			if (x == 0) or (x == X_SIZE-1) or (y == 0) or (y == Y_SIZE-1):
				next_itr.append(true)
				continue
			# count how many neighbors are walls
			var walls = 0
			for dy in range(-1,2):
				for dx in range(-1,2):
					if (ordered_list[(x + dx) + ((y + dy) * X_SIZE)]) and  (not ((dy == dx) and (dy == 0))):
						walls += 1
			next_itr.append(walls > 4)
	update_cells()

func update_cells():
	var index = 0
	while index < ordered_list.size():
		ordered_list[index] = next_itr[index]
		index += 1
