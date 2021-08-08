extends Node

const BOARD_SIZE : float = 4.0
const BOARD_STEP : float = BOARD_SIZE / 16
const PROYECTION_PLANE_Y : float = -0.2
const DROP_PLANE : Plane = Plane(Vector3(0, 1, 0), PROYECTION_PLANE_Y)
const HEIGHT : float = 0.2
const ERROR_MARGIN : float = 0.005

const STATE_MAP = {1.75 : 0,  1.25 : 1,  0.75 : 2,  0.25 : 3, -0.25 : 4, -0.75 : 5, -1.25 : 6, -1.75 : 7}
const DISCARDED_TRAP_VECTOR = Vector3(-99, -99, -99)

const SPEED : float =  32.0 # base * speed_factor = 8.0 * 4.0
const SPEED_FACTOR : float = 4.0

const MAX_HEALTH : float = 100.0
const MAX_BOMB = 13

const MAX_COIN_SPAWN : int = 20
const MAX_COINSTACK_SPAWN : int = 10
const MAX_BRAIN_SPAWN : int = 7
const MAX_HEART_SPAWN : int = 2
const MAX_TIMEBOMB_SPAWN: int = 5
const MAX_STAR_SPAWN : int = 1

const STAR_IMMUNITY_DURATION : float = 10.0 / SPEED_FACTOR
const GENERIC_INSTANCE_DURATION : float = 10.0 / SPEED_FACTOR
const TIMEBOMB_DURATION : float = 5.0 / SPEED_FACTOR
const MIN_SPAWN_DELAY : float  = 4.0 / SPEED_FACTOR
const MAX_SPAWN_DELAY : float = 16.0 / SPEED_FACTOR
const ONE_SECOND_DELAY : float = 1.0 / SPEED_FACTOR

const COIN_INCREASE : int = 1
const COIN_STACK_INCREASE : int = COIN_INCREASE * 5
const BRAIN_INCREASE : int = 1
const HEART_INCREASE : int = 10

const SAVE_FILENAME : String = 'user_data.save'

enum GameEntities {EMPTY, PLAYER, CPU, COIN, COINSTACK, HEART, BRAIN, STAR, BOMB, TIMEBOMB}

var force_ortho = true
var sound_enabled : bool = false
var music_enabled : bool = false
var explosions_enabled : bool = false
var instance_rotation_enabled : bool = false

var game_over : bool = false
var turn : int = 1 # 0 = cpu, 1 = player, 2 = bomb

var current_player_position : Vector3
var player_health : float = MAX_HEALTH
var is_player_moving : bool =  false
var is_player_mirroring : bool =  false
var is_player_immune : bool = false

var player_coins = 0
var player_hearts = 0
var player_brains = 0

var player_bomb_count : int = 0
var is_player_bomb_moving = false
var player_bomb_instance : Array = []
var player_bomb_target_position = Vector3(0, 0, 0)

var current_cpu_position : Vector3
var cpu_health : float = MAX_HEALTH
var is_cpu_moving : bool = false
var is_cpu_mirroring : bool = false
var is_cpu_immune : bool = false

var cpu_coins = 0
var cpu_hearts = 0
var cpu_brains = 0

var cpu_bomb_count : int = 0
var is_cpu_bomb_moving = false
var cpu_bomb_instance : Array = []
var cpu_bomb_target_position = Vector3(0, 0, 0)

var collider_id_duplicate_filter : Array = []

var explosion_counter : int = 0
var explosion_particle_instance : Array = []

var game_state = [[0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0]]

var coin_spawn_counter : int = 0
var coinstack_spawn_counter : int = 0
var brain_spawn_counter : int = 0
var heart_spawn_counter : int = 0
var star_spawn_counter : int  = 0
var timebomb_spawn_counter : int  = 0

var current_entity_position = Vector3(0, 0, 0)	

# NEURAL NET VARIABLES

const TRAINING_FILENAME_JSON : String = 'training_data.json'
const TRAINING_FILENAME_CSV : String = 'training_entangled.csv'

var player_health_sample : float = 0
var cpu_health_sample : float = 0
var game_state_sample
var target_output_sample = Vector2(0, 0)

var sample_count : int = 0
var sample_history : Array = [] 
var sampling_enabled : bool = false
var training_data : Array = []

const TARGET_MAP = {0.5 : 0, 1.0 : 1, 1.5 : 2, 2.0 : 3, 2.5 : 4, 3.0 : 5, 3.5 : 6}

onready var rnd = RandomNumberGenerator.new()

func _ready():
	
	pass

func new_game():
	reset_variables()
	pass

func restore_game():
	reset_variables()
	pass
	
func set_game_state(position : Vector3 , entity : int):
	game_state[STATE_MAP[position.x]][STATE_MAP[position.z]] = entity
	pass

func get_game_state():
	return game_state
	
func reset_variables():
	
	game_over = false
	turn = 1 # 0 = cpu, 1 = player, 2 = bomb
	
	current_player_position = Vector3(-1.75, HEIGHT, -1.75)
	current_cpu_position = Vector3(1.75, HEIGHT, 1.75)

	player_health = MAX_HEALTH
	is_player_moving =  false
	is_player_mirroring =  false
	is_player_immune = false
	
	player_coins = 0
	player_hearts = 0
	player_brains = 0

	player_bomb_count = 0
	
	explosion_counter = 0
	explosion_particle_instance = []

	is_player_bomb_moving = false
	player_bomb_instance = []
	player_bomb_target_position = Vector3(0, 0, 0)

	cpu_health = MAX_HEALTH
	is_cpu_moving = false
	is_cpu_mirroring = false
	is_cpu_immune = false

	cpu_coins = 0
	cpu_hearts = 0
	cpu_brains = 0

	cpu_bomb_count = 0

	is_cpu_bomb_moving = false
	cpu_bomb_instance = []
	cpu_bomb_target_position = Vector3(0, 0, 0)

	collider_id_duplicate_filter = []

	game_state = [[0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0],
				  [0, 0, 0, 0, 0, 0, 0, 0]]

	coin_spawn_counter = 0
	coinstack_spawn_counter = 0
	brain_spawn_counter = 0
	heart_spawn_counter = 0
	star_spawn_counter = 0
	timebomb_spawn_counter = 0
	current_entity_position = Vector3(0, 0, 0)	
	
	pass

func get_square_center(input : Vector3):
	
	var x : float = input.x
	var z : float = input.z
	var output = Vector3(0, -HEIGHT, 0)
	
	if x >= -2.25 and x < -1.75:
		output.x = -1.75
	if x >= -1.75 and x < -1.25:
		output.x = -1.25
	if x >= -1.25 and x < -0.75:
		output.x = -0.75
	if x >= -0.75 and x < -0.25:
		output.x = -0.25
	if x >= -0.25 and x < 0.25:
		output.x = 0.25	
	if x >= 0.25 and x < 0.75:
		output.x = 0.75
	if x >= 0.75 and x < 1.25:
		output.x = 1.25		
	if x >= 1.25 and x < 2.25:
		output.x = 1.75	
		
	if z >= -2.25 and z < -1.75:
		output.z = -1.75
	if z >= -1.75 and z < -1.25:
		output.z = -1.25
	if z >= -1.25 and z < -0.75:
		output.z = -0.75
	if z >= -0.75 and z < -0.25:
		output.z = -0.25
	if z >= -0.25 and z < 0.25:
		output.z = 0.25	
	if z >= 0.25 and z < 0.75:
		output.z = 0.75
	if z >= 0.75 and z < 1.25:
		output.z = 1.25		
	if z >= 1.25 and z < 2.25:
		output.z = 1.75	

	return output
	
func is_ortoghonal(origin : Vector3, target : Vector3):
	var orthogonal = false
	if force_ortho:
		var result = Vector2(target.x - origin.x, target.z - origin.z).normalized().dot(Vector2(1, 0))
		if result == 1 or result == -1 or result == 0:
			orthogonal = true
	else:
		orthogonal = true
	
	return orthogonal
	
func is_spot_used_by_object(input : Vector3):
	
	var input_to_2D = Vector2(input.x, input.z)
	var is_used = false
	
	for i in range(len(player_bomb_instance)):
		if is_instance_valid(player_bomb_instance[i]):
			if Vector2(player_bomb_instance[i].transform.origin.x, player_bomb_instance[i].transform.origin.z) == input_to_2D:
				is_used = true
			
	for i in range(len(cpu_bomb_instance)):
		if is_instance_valid(cpu_bomb_instance[i]):
			if Vector2(cpu_bomb_instance[i].transform.origin.x, cpu_bomb_instance[i].transform.origin.z) == input_to_2D:
				is_used = true
			
	if Vector2(current_entity_position.x, current_entity_position.z) == input_to_2D:
		is_used = true
		
	return is_used
	
func are_all_traps_discarded():
	
	var all_discarded = false
	
	if len(player_bomb_instance) == 0  and len(cpu_bomb_instance) == 0: 
		all_discarded = true
	
	return all_discarded
	
func restore_training_data():
	
	var data = []
	var file = File.new()
	if ERR_FILE_NOT_FOUND == file.open("user://" + TRAINING_FILENAME_JSON, File.READ):
		print('No training datafile.')
		file.close()
	else:
		while !file.eof_reached():
			data.append(file.get_line())
		file.close()
			
	for i in range(len(data) - 1):
			
		var json_dump = JSON.parse(data[i]).result

		var dict = {
			'input' : json_dump.input,
			'output' : json_dump.output
			#'full_vector' : json_dump.full_vector
		}
			
		sample_history.append(dict)
		
	#print(sample_history[-1], ' ', len(sample_history))
	
	pass
	
func min_max_scaling(input, minimum, maximum):
	return float((input - minimum) / (maximum - minimum))

func save_sample(): 
	
	if sampling_enabled and sample_count <= 30000:
		
		sample_count += 1
		var csv_string = ""
		
		var game_state_normalized : Array = []
		var minimum = 0.0
		var maximum = 1.0 * len(GameEntities)
		var value_axis = 0  # 0: y, 1: x
		var value_sign = 0  # 0: -, 1: +
		var value = 0
		
		if target_output_sample.y == 0:
			value_axis = 1
			if target_output_sample.x > 0:
				value_sign = 1
			else:
				value_sign = 0
				
			value = TARGET_MAP[abs(target_output_sample.x)]
			
		elif target_output_sample.x == 0:
			value_axis = 0
			if target_output_sample.y > 0:
				value_sign = 1
			else:
				value_sign = 0
				
			value = TARGET_MAP[abs(target_output_sample.y)]
				
		var data = {
			'input': game_state_normalized,
			'value_axis' : value_axis,
			'value_sign' : value_sign,
			'value' : value,
			'vector' : target_output_sample
		}
		
		# Construct csv string
		for j in range(8):
			for k in range(8):
				game_state_normalized.append(min_max_scaling(game_state_sample[j][k], minimum, maximum))
				csv_string += str(game_state_normalized[-1]) + ", "
		
		csv_string += str(value_axis) + ", "
		csv_string += str(value_sign) + ", "
		csv_string += str(value)
		
		# Save sample if not already present inside history
		if !sample_history.has(data):
						
			sample_history.append(data)
			
			# training.json
			var save_file = File.new()
			if ERR_FILE_NOT_FOUND == save_file.open("user://" + TRAINING_FILENAME_JSON, File.READ_WRITE):
				print('Creating training.json datafile.')
				save_file.open("user://" + TRAINING_FILENAME_JSON, File.WRITE_READ)
			save_file.seek_end()
			save_file.store_line(JSON.print(data) + "\r")
			save_file.close()

			print('# ',sample_count, ' - ', JSON.print(data))
			
			# training-entangled.csv
			var csv_save_file = File.new()
			if ERR_FILE_NOT_FOUND == csv_save_file.open("user://" + TRAINING_FILENAME_CSV, File.READ_WRITE):
				print('Creating training_entangled.csv datafile.')
				csv_save_file.open("user://" + TRAINING_FILENAME_CSV, File.WRITE_READ)

			csv_save_file.seek_end()
			csv_save_file.store_line(csv_string + "\r")
			csv_save_file.close()

			print(csv_string)
			print(' ')
			
