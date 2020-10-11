extends RichTextLabel

func _process(delta):
	set_text("--INFO--")
	newline()
	newline()
	add_text("Max rooms: " + str(get_parent().maxrooms))
	pass
