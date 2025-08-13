extends PanelContainer


func _process(delta):
	if visible:
		pass

func add_property(title : String, value, order : int): # This can either be called once for a static property or called every frame for a dynamic property
	var target
	target = $MarginContainer/VBoxContainer.find_child(title, true, false) # I have no idea what true and false does here, the function should be more specific
	if !target:
		target = Label.new() # Debug lines are of type Label
		$MarginContainer/VBoxContainer.add_child(target)
		target.name = title
		target.text = title + ": " + str(value)
	elif visible:
		target.text = title + ": " + str(value)
		var size = $MarginContainer/VBoxContainer.get_child_count()
		if order > size:
			order = size
		$MarginContainer/VBoxContainer.move_child(target, order)
