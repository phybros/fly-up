extends Node

@onready var player: AudioStreamPlayer = $"Music Intro"

var looping_track: Resource
var intro_track: Resource

var intro = true


func _ready():
	intro_track = preload("res://Fly Up.mp3")
	looping_track = preload("res://Fly Up Looping.mp3")


func _on_music_intro_finished():
	if intro:
		intro = false
		player.stream = looping_track
