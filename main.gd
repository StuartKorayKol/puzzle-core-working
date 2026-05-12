extends Node2D

const TILE_WIDTH: int = 256

# NOTE: All durations are measured in seconds as godot delta is measured in seconds

const NUM_NOTES: int = 10
var CURRENT_TIME: float = -1
var LAST_BEAT: int = -1
var BEATS_PER_MINUTE: int = 120
var BEATS_PER_MEASURE: int = 4
var MIN_NOTE_TYPE: float = 0.125
# Assuming for now that time signature is 4/4 and minimum note is a quarter note
var MIN_NOTE_DURATION: float = ((MIN_NOTE_TYPE * BEATS_PER_MEASURE) * 60) / BEATS_PER_MINUTE
var DURATION: float = NUM_NOTES * MIN_NOTE_DURATION

var MELODY_NOTES: Array[String] = ["R", "D", "UR", "D", "L"]
var MELODY_NOTES_DURATIONS: Array[float] = [1, 2, 1, 4, 2]
var MELODY_NEXT_BEAT: int = 0
var MELODY_BEAT_SUM: float = 0

var BASS_NOTES: Array[String] = ["R", "L", "R", "L", "R", "L", "R", "L", "R", "L", "R", "L"]
var BASS_NOTES_DURATIONS: Array[float] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
var BASS_NEXT_BEAT: int = 0
var BASS_BEAT_SUM: float = 0

@onready var MELODY_CHARACTER:= $RedBox
@onready var MELODY_LABEL:= $RedBox/Label
@onready var BASS_CHARACTER:= $YellowBox
@onready var BASS_LABEL:= $YellowBox/Label

var MELODY_CHARACTER_STARTING_POSITION: Vector2 = Vector2(0, 0)
var BASS_CHARACTER_STARTING_POSITION: Vector2 = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var total: float = 0
	# Validate duration for melody
	for i in range(MELODY_NOTES_DURATIONS.size()):
		MELODY_NOTES_DURATIONS[i] *= MIN_NOTE_DURATION
		total += MELODY_NOTES_DURATIONS[i]
	
	print("Expected: " + str(DURATION) + " | Calculated: " + str(total))
	MELODY_CHARACTER_STARTING_POSITION = MELODY_CHARACTER.global_position
	print(MELODY_CHARACTER_STARTING_POSITION)
	
	total = 0
	# Validate duration for bass
	for i in range(BASS_NOTES_DURATIONS.size()):
		BASS_NOTES_DURATIONS[i] *= MIN_NOTE_DURATION
		total += BASS_NOTES_DURATIONS[i]
	
	print("Expected: " + str(DURATION) + " | Calculated: " + str(total))
	BASS_CHARACTER_STARTING_POSITION = BASS_CHARACTER.global_position
	print(BASS_CHARACTER_STARTING_POSITION)
	print("Minimum note duration: " + str(MIN_NOTE_DURATION))

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and CURRENT_TIME <= 0:
		print("Starting the dance....")
		CURRENT_TIME = DURATION

func resetToStart():
	BASS_CHARACTER.global_position = BASS_CHARACTER_STARTING_POSITION
	MELODY_CHARACTER.global_position = MELODY_CHARACTER_STARTING_POSITION
	CURRENT_TIME = -1
	LAST_BEAT = -1
	MELODY_NEXT_BEAT = 0
	MELODY_BEAT_SUM = 0
	MELODY_LABEL.text = "NT"
	BASS_NEXT_BEAT = 0
	BASS_BEAT_SUM = 0
	BASS_LABEL.text = "NT"

func moveCharacters(beat: int):
	# Just move bass character for now since there are edge cases in moving multi-beat notes
	match BASS_NOTES[beat]:
		"R":
			BASS_CHARACTER.global_position.x += TILE_WIDTH
			BASS_LABEL.text = "R"
		"L":
			BASS_CHARACTER.global_position.x -= TILE_WIDTH
			BASS_LABEL.text = "L"
	
	if MELODY_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		match MELODY_NOTES[MELODY_NEXT_BEAT]:
			"R":
				MELODY_CHARACTER.global_position.x += TILE_WIDTH
				MELODY_LABEL.text = "R"
			"UR":
				MELODY_CHARACTER.global_position.x += TILE_WIDTH
				MELODY_CHARACTER.global_position.y -= TILE_WIDTH
				MELODY_LABEL.text = "UR"
			"D":
				MELODY_CHARACTER.global_position.y += TILE_WIDTH
				MELODY_LABEL.text = "D"
			"L":
				MELODY_LABEL.text = "L"
				MELODY_CHARACTER.global_position.x -= TILE_WIDTH
		MELODY_BEAT_SUM += MELODY_NOTES_DURATIONS[MELODY_NEXT_BEAT]
		MELODY_NEXT_BEAT += 1
	else:
		MELODY_LABEL.text = "H"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var index: int = int((DURATION - CURRENT_TIME) / MIN_NOTE_DURATION)
	if CURRENT_TIME > 0 and index > LAST_BEAT:
		moveCharacters(index)
		LAST_BEAT = index

	var oldTime = CURRENT_TIME
	CURRENT_TIME -= delta
	
	if oldTime >= 0 and CURRENT_TIME <= 0:
		print("Dance finished!")
		resetToStart()
