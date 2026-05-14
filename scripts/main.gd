# Dig Me Out 80 BPM, min note is a sixteenth note (0.0625). Puzzle can be 1 block or two measures

# Guitar (Red box)
# Ee, Ee, De, De, Ee, Ee, De, Ee, Be, Be, Be, Be, Be, Be, Be, Be
# DR, DR, R, R, DR, DR, R, DR, U, U, U, U, U, U, U, U

# Bass (Yellow box)
# De, De, De, De, De, De, De, De, Be, Be, Be, Be, Be, Be, Be, Be
# R, R, R, R, R, R, R, R, U, U, U, U, U, U, U, U

# Drums (Blue box)
# NOTE: We should separate into two tracks, one for snare/bass drum and one for crash cymbal and high hats as they could be played independently and combined
#
# Combined: 
# Be&Ce, Be&Ce, Fe&Ce, Fe&Ce, Be&Ce, Be&Ce, Fe&Ce, Fe&Ce, Be&Ce, Be&Ce, Fe&Ce, Fe&xe, Be&Ce, Be&xe, Fe&xe, Fs&xe, Fs&xe 
# UR, UR, UL, UL, UR, UR, UL, UL, UR, UR, UL, L, UR, R, L, L, L
#
# Bass/Snare:
# Be, Be, Fe, Fe, Be, Be, Fe, Fe, Be, Be, Fe, Fe, Be, Be, Fe, Fs, Fs
# R, R, L, L, R, R, L, L, R, R, L, L, R, R, L, L, L
# 
# Crash/High-hat
# Ce, Ce, Ce, Ce, Ce, Ce, Ce, Ce, Ce, Ce, Ce, xe, Ce, xe, xe, xe
# U, U, U, U, U, U, U, U, U, U, U, x, U, x, x, x


extends Node2D

const TILE_WIDTH: int = 256

# NOTE: All durations are measured in seconds as godot delta is measured in seconds

const NUM_NOTES: int = 10
var CURRENT_TIME: float = -1
var LAST_BEAT: int = -1
var BEATS_PER_MINUTE: int = 80
var BEATS_PER_MEASURE: int = 4
var MIN_NOTE_TYPE: float =  0.0625
# Assuming for now that time signature is 4/4 and minimum note is a quarter note
var MIN_NOTE_DURATION: float = ((MIN_NOTE_TYPE * BEATS_PER_MEASURE) * 60) / BEATS_PER_MINUTE
var DURATION: float = NUM_NOTES * MIN_NOTE_DURATION

var GUITAR_NOTES: Array[String] = ["R", "D", "UR", "D", "L"]
var GUITAR_NOTES_DURATIONS: Array[float] = [1, 2, 1, 4, 2]
var GUITAR_NEXT_BEAT: int = 0
var GUITAR_BEAT_SUM: float = 0

var BASS_NOTES: Array[String] = ["R", "L", "R", "L", "R", "L", "R", "L", "R", "L", "R", "L"]
var BASS_NOTES_DURATIONS: Array[float] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
var BASS_NEXT_BEAT: int = 0
var BASS_BEAT_SUM: float = 0

@onready var GUITAR_CHARACTER:= $RedBox
@onready var GUITAR_LABEL:= $RedBox/Label
@onready var BASS_CHARACTER:= $YellowBox
@onready var BASS_LABEL:= $YellowBox/Label

var GUITAR_CHARACTER_STARTING_POSITION: Vector2 = Vector2(0, 0)
var BASS_CHARACTER_STARTING_POSITION: Vector2 = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var total: float = 0
	# Validate duration for GUITAR
	for i in range(GUITAR_NOTES_DURATIONS.size()):
		GUITAR_NOTES_DURATIONS[i] *= MIN_NOTE_DURATION
		total += GUITAR_NOTES_DURATIONS[i]
	
	print("Expected: " + str(DURATION) + " | Calculated: " + str(total))
	GUITAR_CHARACTER_STARTING_POSITION = GUITAR_CHARACTER.global_position
	print(GUITAR_CHARACTER_STARTING_POSITION)
	
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
	GUITAR_CHARACTER.global_position = GUITAR_CHARACTER_STARTING_POSITION
	CURRENT_TIME = -1
	LAST_BEAT = -1
	GUITAR_NEXT_BEAT = 0
	GUITAR_BEAT_SUM = 0
	GUITAR_LABEL.text = "NT"
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
	
	if GUITAR_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		match GUITAR_NOTES[GUITAR_NEXT_BEAT]:
			"R":
				GUITAR_CHARACTER.global_position.x += TILE_WIDTH
				GUITAR_LABEL.text = "R"
			"UR":
				GUITAR_CHARACTER.global_position.x += TILE_WIDTH
				GUITAR_CHARACTER.global_position.y -= TILE_WIDTH
				GUITAR_LABEL.text = "UR"
			"D":
				GUITAR_CHARACTER.global_position.y += TILE_WIDTH
				GUITAR_LABEL.text = "D"
			"L":
				GUITAR_LABEL.text = "L"
				GUITAR_CHARACTER.global_position.x -= TILE_WIDTH
		GUITAR_BEAT_SUM += GUITAR_NOTES_DURATIONS[GUITAR_NEXT_BEAT]
		GUITAR_NEXT_BEAT += 1
	else:
		GUITAR_LABEL.text = "H"

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
