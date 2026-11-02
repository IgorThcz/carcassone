class_name TempMessage extends Panel

enum TEMP_MESSAGE_TYPE {SUCCESS, WARNING, ERROR}

@onready var rich_text_label = $RichTextLabel

func configure(type : TEMP_MESSAGE_TYPE, message : String):
	rich_text_label.text = message
	if type == TEMP_MESSAGE_TYPE.SUCCESS:
		modulate = Color.GREEN
	if type == TEMP_MESSAGE_TYPE.WARNING:
		modulate = Color.YELLOW
	if type == TEMP_MESSAGE_TYPE.ERROR:
		modulate = Color.RED

func _on_timer_timeout():
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	await tween.finished
	queue_free()
