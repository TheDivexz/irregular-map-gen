extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	var noise_data = NoiseTexture2D.new()
	var noise_type : FastNoiseLite = FastNoiseLite.new()
	noise_type.set_noise_type(FastNoiseLite.TYPE_PERLIN)
	noise_type.set_seed(randi())
	noise_data.set_noise(noise_type)
	set_texture(noise_data)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
