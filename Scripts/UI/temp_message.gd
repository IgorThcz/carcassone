class_name TempMessage extends Panel

enum TEMP_MESSAGE_TYPE {SUCESS, WARNING, ERROR}

@onready var rich_text_label = $RichTextLabel

func configure(_type : TEMP_MESSAGE_TYPE, message : String):
	rich_text_label.text = message

func _on_timer_timeout():
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	await tween.finished
	queue_free()
