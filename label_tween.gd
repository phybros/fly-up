extends Label

class_name LabelTween

var current_val: int = 0
var target_val: int = 0


func _process(delta):
	text = str(current_val)


func update_val(new_val: int) -> void:
	target_val = new_val

	# Create a tween
	var tween = create_tween()
	tween.tween_property(self, "current_val", target_val, 1)
