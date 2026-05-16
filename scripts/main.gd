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

@onready var GUITAR_SCENE: PackedScene = load("res://scenes/red-box.tscn")
@onready var GUITAR_SPAWNER:= $"Red-Spawner"
var GUITAR_INSTANCE: StaticBody2D = null
var GUITAR_LABEL: Label = null
var GUITAR_AUDIO: AudioStreamPlayer2D = null

@onready var BASS_SCENE:= load("res://scenes/yellow-box.tscn")
@onready var BASS_SPAWNER:= $"Yellow-Spawner"
var BASS_INSTANCE: StaticBody2D = null
var BASS_LABEL: Label = null
var BASS_AUDIO: AudioStreamPlayer2D = null

@onready var DRUM_SCENE:= load("res://scenes/blue-box.tscn")
@onready var DRUM_SPAWNER:= $"Blue-Spawner"
var DRUM_INSTANCE: StaticBody2D = null
var DRUM_LABEL: Label = null
var DRUM_AUDIO: AudioStreamPlayer2D = null
var CYMBAL_AUDIO: AudioStreamPlayer2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	var total: float = 0
	# Validate duration for Guitar
	for i in range(GUITAR_NOTES_DURATIONS.size()):
		GUITAR_NOTES_DURATIONS[i] *= MIN_NOTE_DURATION
		total += GUITAR_NOTES_DURATIONS[i]
	
	assert(DURATION == total, "Guitar Validation | Expected: " + str(DURATION) + " | Calculated: " + str(total))
	
	total = 0
	# Validate duration for Bass
	for i in range(BASS_NOTES_DURATIONS.size()):
		BASS_NOTES_DURATIONS[i] *= MIN_NOTE_DURATION
		total += BASS_NOTES_DURATIONS[i]
	
	assert(DURATION == total, "Bass Validation | Expected: " + str(DURATION) + " | Calculated: " + str(total))
	
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
		
	print("Minimum note duration: " + str(MIN_NOTE_DURATION))

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and CURRENT_TIME <= 0:
		print("Starting the dance....")
		CURRENT_TIME = DURATION
		GUITAR_INSTANCE = GUITAR_SCENE.instantiate()
		GUITAR_SPAWNER.add_child(GUITAR_INSTANCE)
		GUITAR_LABEL = get_node("Red-Spawner/RedBox/Label")
		GUITAR_AUDIO = get_node("Red-Spawner/RedBox/AudioStreamGuitar")
		
		BASS_INSTANCE = BASS_SCENE.instantiate()
		BASS_SPAWNER.add_child(BASS_INSTANCE)
		BASS_LABEL = get_node("Yellow-Spawner/YellowBox/Label")
		BASS_AUDIO = get_node("Yellow-Spawner/YellowBox/AudioStreamBass")
		
		DRUM_INSTANCE = DRUM_SCENE.instantiate()
		DRUM_SPAWNER.add_child(DRUM_INSTANCE)
		DRUM_LABEL = get_node("Blue-Spawner/BlueBox/Label")
		DRUM_AUDIO = get_node("Blue-Spawner/BlueBox/AudioStreamDrums")
		CYMBAL_AUDIO = get_node("Blue-Spawner/BlueBox/AudioStreamCymbals")
		#GUITAR_AUDIO.play()
		#GUITAR_AUDIO.seek(6)
		#BASS_AUDIO.seek(6)
		#DRUM_AUDIO.play(27)
		#CYMBAL_AUDIO.play(27)

# If called with topOfSong as true, reset to play the song again, otherwise
#  reset object so it will not attempt to continue to play
func resetGuitar(topOfSong: bool):
	if GUITAR_INSTANCE != null:
		GUITAR_INSTANCE.queue_free()
		GUITAR_INSTANCE = null
		GUITAR_LABEL = null
		GUITAR_AUDIO = null
	GUITAR_NEXT_BEAT = 0 if topOfSong else int(DURATION)
	GUITAR_BEAT_SUM = 0 if topOfSong else int(DURATION)

# If called with topOfSong as true, reset to play the song again, otherwise
#  reset object so it will not attempt to continue to play
func resetBass(topOfSong: bool):
	if BASS_INSTANCE != null:
		BASS_INSTANCE.queue_free()
		BASS_INSTANCE = null
		BASS_LABEL = null
		BASS_AUDIO = null
	BASS_NEXT_BEAT = 0 if topOfSong else int(DURATION)
	BASS_BEAT_SUM = 0 if topOfSong else int(DURATION)

# If called with topOfSong as true, reset to play the song again, otherwise
#  reset object so it will not attempt to continue to play
func resetDrums(topOfSong: bool):
	if DRUM_INSTANCE != null:
		DRUM_INSTANCE.queue_free()
		DRUM_INSTANCE = null
		DRUM_LABEL = null
		DRUM_AUDIO = null
		CYMBAL_AUDIO = null
	DRUM_NEXT_BEAT = 0 if topOfSong else int(DURATION)
	CYMBAL_NEXT_BEAT = 0 if topOfSong else int(DURATION)
	DRUM_BEAT_SUM = 0 if topOfSong else int(DURATION)
	CYMBAL_BEAT_SUM = 0 if topOfSong else int(DURATION)

func resetToStart():
	resetGuitar(true)
	resetBass(true)
	resetDrums(true)
	
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
	
	if instrument != DRUM_INSTANCE:
		label.text = directional

func moveCharacters(beat: int):
	var directional: String = ""
	if GUITAR_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		directional = GUITAR_NOTES[GUITAR_NEXT_BEAT]
		moveCharacter(GUITAR_INSTANCE, GUITAR_LABEL, directional)
		GUITAR_BEAT_SUM += GUITAR_NOTES_DURATIONS[GUITAR_NEXT_BEAT]
		GUITAR_NEXT_BEAT += 1
	elif GUITAR_INSTANCE != null:
		GUITAR_LABEL.text = "H"
	
	directional = ""
	if BASS_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		directional = BASS_NOTES[BASS_NEXT_BEAT]
		moveCharacter(BASS_INSTANCE, BASS_LABEL, directional)
		BASS_BEAT_SUM += BASS_NOTES_DURATIONS[BASS_NEXT_BEAT]
		BASS_NEXT_BEAT += 1
	elif BASS_INSTANCE != null:
		BASS_LABEL.text = "H"
	
	directional = ""
	var drumText: String = "H"
	if DRUM_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		directional = DRUM_NOTES[DRUM_NEXT_BEAT]
		moveCharacter(DRUM_INSTANCE, DRUM_LABEL, directional)
		DRUM_BEAT_SUM += DRUM_NOTES_DURATIONS[DRUM_NEXT_BEAT]
		DRUM_NEXT_BEAT += 1
		drumText = directional
	
	if CYMBAL_BEAT_SUM <= (beat * MIN_NOTE_DURATION):
		directional = CYMBAL_NOTES[CYMBAL_NEXT_BEAT]
		moveCharacter(DRUM_INSTANCE, DRUM_LABEL, directional)
		CYMBAL_BEAT_SUM += CYMBAL_NOTES_DURATIONS[CYMBAL_NEXT_BEAT]
		CYMBAL_NEXT_BEAT += 1
		if directional != "Re":
			if drumText == "H":
				drumText = directional
			else:
				drumText = directional + drumText
	
	if DRUM_INSTANCE != null:
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
		var guitarCollision: bool = false
		var bassCollision: bool = false
		var drumCollision: bool = false
		# TODO: Add collision detection for boundaries
		if GUITAR_INSTANCE != null:
			if BASS_INSTANCE != null:
				if GUITAR_INSTANCE.global_position == BASS_INSTANCE.global_position:
					guitarCollision = true
					bassCollision = true
			if DRUM_INSTANCE != null:
				if GUITAR_INSTANCE.global_position == DRUM_INSTANCE.global_position:
					guitarCollision = true
					drumCollision = true
		if BASS_INSTANCE != null and bassCollision == false:
			if DRUM_INSTANCE != null:
				if BASS_INSTANCE.global_position == DRUM_INSTANCE.global_position:
					bassCollision = true
					drumCollision = true
		
		if guitarCollision:
			resetGuitar(false)
		if bassCollision:
			resetBass(false)
		if drumCollision:
			resetDrums(false)
		LAST_BEAT = index

	var oldTime = CURRENT_TIME
	CURRENT_TIME -= delta
	
	if oldTime >= 0 and CURRENT_TIME <= 0:
		print("Dance finished!")
		resetToStart()
