extends RichTextLabel

func _process(delta):
	set_text("--COMMANDS--")
	newline()
	newline()
	add_text("SPACEBAR: Generate new floor")
	newline()
	add_text("TAB: Draw floor - draw new paths")
	newline()
	add_text("P: Show only the map")
	newline()
	newline()
	add_text("Left: Decrease number of max rooms")
	newline()
	add_text("Right: Increase number of max rooms")
	pass
