# Dig Me Out 80 BPM, min note is a sixteenth note (0.0625). Puzzle can be 1 block or two measures
extends Node2D

const TILE_WIDTH: int = 64

# NOTE: All durations are measured in seconds as godot delta is measured in seconds

const NUM_NOTES: int = 32
var CURRENT_TIME: float = -1
var LAST_BEAT: int = -1
var BEATS_PER_MINUTE: int = 160
var BEATS_PER_MEASURE: int = 4
var MIN_NOTE_TYPE: float =  0.0625
# Assuming for now that time signature is 4/4 and minimum note is a quarter note
var MIN_NOTE_DURATION: float = ((MIN_NOTE_TYPE * BEATS_PER_MEASURE) * 60) / BEATS_PER_MINUTE
var DURATION: float = NUM_NOTES * MIN_NOTE_DURATION

# Guitar (Red box)
# Ee, Ee, De, De, Ee, Ee, De, Ee, Be, Be, Be, Be, Be, Be, Be, Be
# DR, DR, R, R, DR, DR, R, DR, U, U, U, U, U, U, U, U
var GUITAR_NOTES: Array[String] = [
	"DR", "DR", "R", "R", "DR", "DR", "R", "DR",
	"U", "U", "U", "U", "U", "U", "U", "U"
]
var GUITAR_NOTES_DURATIONS: Array[float] = [
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2
]
var GUITAR_NEXT_BEAT: int = 0
var GUITAR_BEAT_SUM: float = 0

# Bass (Yellow box)
# De, De, De, De, De, De, De, De, Be, Be, Be, Be, Be, Be, Be, Be
# R, R, R, R, R, R, R, R, U, U, U, U, U, U, U, U
var BASS_NOTES: Array[String] = [
	"R", "R", "R", "R", "R", "R", "R", "R",
	"U", "U", "U", "U", "U", "U", "U", "U"
]
var BASS_NOTES_DURATIONS: Array[float] = [
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2
]
var BASS_NEXT_BEAT: int = 0
var BASS_BEAT_SUM: float = 0

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
var DRUM_NOTES: Array[String] = [
	"R", "R", "L", "L", "R", "R", "L", "L",
	"R", "R", "L", "L", "R", "R", "L", "L", "L"
]
var DRUM_NOTES_DURATIONS: Array[float] = [
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 1, 1
]
var DRUM_NEXT_BEAT: int = 0
var DRUM_BEAT_SUM: float = 0

# Crash/High-hat
# Ce, Ce, Ce, Ce, Ce, Ce, Ce, Ce, Ce, Ce, Ce, xe, Ce, xe, xe, xe
# U, U, U, U, U, U, U, U, U, U, U, x, U, x, x, x
var CYMBAL_NOTES: Array[String] = [
	"U", "U", "U", "U", "U", "U", "U", "U",
	"U", "U", "U", "Re", "U", "Re"
]
var CYMBAL_NOTES_DURATIONS: Array[float] = [
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 6
]
var CYMBAL_NEXT_BEAT: int = 0
var CYMBAL_BEAT_SUM: float = 0

@onready var GUITAR_CHARACTER:= $RedBox
@onready var GUITAR_LABEL:= $RedBox/Label
@onready var GUITAR_AUDIO:= $RedBox/AudioStreamGuitar

@onready var BASS_CHARACTER:= $YellowBox
@onready var BASS_LABEL:= $YellowBox/Label
@onready var BASS_AUDIO:= $YellowBox/AudioStreamBass

@onready var DRUM_CHARACTER:= $BlueBox
@onready var DRUM_LABEL:= $BlueBox/Label
@onready var DRUM_AUDIO:= $BlueBox/AudioStreamDrums
@onready var CYMBAL_AUDIO:= $BlueBox/AudioStreamCymbals

var GUITAR_CHARACTER_STARTING_POSITION: Vector2 = Vector2(0, 0)
var BASS_CHARACTER_STARTING_POSITION: Vector2 = Vector2(0, 0)
var DRUM_CHARACTER_STARTING_POSITION: Vector2 = Vector2(0, 0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var total: float = 0
	# Validate duration for Guitar
	for i in range(GUITAR_NOTES_DURATIONS.size()):
		GUITAR_NOTES_DURATIONS[i] *= MIN_NOTE_DURATION
		total += GUITAR_NOTES_DURATIONS[i]
	
	assert(DURATION == total, "Guitar Validation | Expected: " + str(DURATION) + " | Calculated: " + str(total))
	GUITAR_CHARACTER_STARTING_POSITION = GUITAR_CHARACTER.global_position
	
	total = 0
	# Validate duration for Bass
	for i in range(BASS_NOTES_DURATIONS.size()):
		BASS_NOTES_DURATIONS[i] *= MIN_NOTE_DURATION
		total += BASS_NOTES_DURATIONS[i]
	
	assert(DURATION == total, "Bass Validation | Expected: " + str(DURATION) + " | Calculated: " + str(total))
	BASS_CHARACTER_STARTING_POSITION = BASS_CHARACTER.global_position
	
	total = 0
	# Validate duration for Drum
	for i in range(DRUM_NOTES_DURATIONS.size()):
		DRUM_NOTES_DURATIONS[i] *= MIN_NOTE_DURATION
		total += DRUM_NOTES_DURATIONS[i]
	
	assert(DURATION == total, "Drum Validation | Expected: " + str(DURATION) + " | Calculated: " + str(total))
	
	total = 0
	# Validate duration for Drum
	for i in range(CYMBAL_NOTES_DURATIONS.size()):
		CYMBAL_NOTES_DURATIONS[i] *= MIN_NOTE_DURATION
		total += CYMBAL_NOTES_DURATIONS[i]
	
	assert(DURATION == total, "CYMBAL Validation | Expected: " + str(DURATION) + " | Calculated: " + str(total))
	
	DRUM_CHARACTER_STARTING_POSITION = DRUM_CHARACTER.global_position
	
	print("Minimum note duration: " + str(MIN_NOTE_DURATION))

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and CURRENT_TIME <= 0:
		print("Starting the dance....")
		CURRENT_TIME = DURATION
		GUITAR_AUDIO.play()
		GUITAR_AUDIO.seek(6)
		#BASS_AUDIO.seek(6)
		#DRUM_AUDIO.play(27)
		#CYMBAL_AUDIO.play(27)

func resetToStart():
	GUITAR_CHARACTER.global_position = GUITAR_CHARACTER_STARTING_POSITION
	GUITAR_NEXT_BEAT = 0
	GUITAR_BEAT_SUM = 0
	GUITAR_LABEL.text = "NT"
	
	BASS_CHARACTER.global_position = BASS_CHARACTER_STARTING_POSITION
	BASS_NEXT_BEAT = 0
	BASS_BEAT_SUM = 0
	BASS_LABEL.text = "NT"
	
	DRUM_CHARACTER.global_position = DRUM_CHARACTER_STARTING_POSITION
	DRUM_NEXT_BEAT = 0
	CYMBAL_NEXT_BEAT = 0
	DRUM_BEAT_SUM = 0
	CYMBAL_BEAT_SUM = 0
	DRUM_LABEL.text = "NT"
	
	CURRENT_TIME = -1
	LAST_BEAT = -1
	
	#GUITAR_AUDIO.set_playing(false)
	#BASS_AUDIO.set_playing(false)
	#DRUM_AUDIO.set_playing(false)
	#CYMBAL_AUDIO.set_playing(false)
	
func moveCharacter(instrument: Node2D, label: Label, directional: String):
	if directional.ends_with("R"):
		instrument.global_position.x += TILE_WIDTH
	if directional.ends_with("L"):
		instrument.global_position.x -= TILE_WIDTH
	if directional.begins_with("U"):
		instrument.global_position.y -= TILE_WIDTH
	if directional.begins_with("D"):
		instrument.global_position.y += TILE_WIDTH
	# NOTE: No need to have a statement for Re (Rest) as this implies no movement
	
	if instrument != DRUM_CHARACTER:
		label.text = directional

func moveCharacters(beat: int):
	var directional: String = ""
	if GUITAR_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		directional = GUITAR_NOTES[GUITAR_NEXT_BEAT]
		moveCharacter(GUITAR_CHARACTER, GUITAR_LABEL, directional)
		GUITAR_BEAT_SUM += GUITAR_NOTES_DURATIONS[GUITAR_NEXT_BEAT]
		GUITAR_NEXT_BEAT += 1
	else:
		GUITAR_LABEL.text = "H"
	
	directional = ""
	if BASS_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		directional = BASS_NOTES[BASS_NEXT_BEAT]
		moveCharacter(BASS_CHARACTER, BASS_LABEL, directional)
		BASS_BEAT_SUM += BASS_NOTES_DURATIONS[BASS_NEXT_BEAT]
		BASS_NEXT_BEAT += 1
	else:
		BASS_LABEL.text = "H"
	
	directional = ""
	var drumText: String = "H"
	if DRUM_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		directional = DRUM_NOTES[DRUM_NEXT_BEAT]
		moveCharacter(DRUM_CHARACTER, DRUM_LABEL, directional)
		DRUM_BEAT_SUM += DRUM_NOTES_DURATIONS[DRUM_NEXT_BEAT]
		DRUM_NEXT_BEAT += 1
		drumText = directional
	else:
		drumText = "H"
	
	if CYMBAL_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		directional = CYMBAL_NOTES[CYMBAL_NEXT_BEAT]
		moveCharacter(DRUM_CHARACTER, DRUM_LABEL, directional)
		CYMBAL_BEAT_SUM += CYMBAL_NOTES_DURATIONS[CYMBAL_NEXT_BEAT]
		CYMBAL_NEXT_BEAT += 1
		if directional != "Re":
			if drumText == "H":
				drumText = directional
			else:
				drumText = directional + drumText
	
	DRUM_LABEL.text = drumText

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var index: int = int((DURATION - CURRENT_TIME) / MIN_NOTE_DURATION)
	if CURRENT_TIME > 0 and index > LAST_BEAT:
		moveCharacters(index)
		# TODO: We should check for collisions here and only here because there could be cases where
		#  partial movement (i.e. guitar moves into square occupied by bass, but bass has not moved 
		#  within the same beat). This should NOT be a collision because movement should be
		#  simultaneous
		# TODO: There might be a better implementation for the below...will investigate later
		if GUITAR_CHARACTER.global_position == BASS_CHARACTER.global_position or \
			GUITAR_CHARACTER.global_position == DRUM_CHARACTER.global_position or \
			BASS_CHARACTER.global_position == DRUM_CHARACTER.global_position:
			print("TWO CHARACTERS HAVE COLLIDED ON BEAT: " + str(index))
		LAST_BEAT = index

	var oldTime = CURRENT_TIME
	CURRENT_TIME -= delta
	
	if oldTime >= 0 and CURRENT_TIME <= 0:
		print("Dance finished!")
		resetToStart()
