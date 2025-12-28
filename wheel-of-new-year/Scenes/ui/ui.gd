extends Control



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init_ui():
	$VBoxContainer/ScrollContainer.visible = false
	#$VBoxContainer/UrlPanel.visible = false
	$VBoxContainer/ScrollContainer/DescPanel/MarginContainer/Description.text=""
	$VBoxContainer/UrlPanel/URL.uri=""
	#$VBoxContainer/UrlPanel/URL.disabled = true
	$VBoxContainer/DateTimePanel/DateTimeLabel.update_text() 
	

func show_event(event:Dictionary):
	$VBoxContainer/ScrollContainer.visible = true
	$VBoxContainer/UrlPanel.visible = true
	$VBoxContainer/DateTimePanel.visible = true
	var text = "[b]{title}[/b] \n{desc}".format({"title":event.title,"desc":event.desc})
	var url = event.url
	print( event.url)
	$VBoxContainer/ScrollContainer/DescPanel/MarginContainer/Description.text =  text
	$VBoxContainer/UrlPanel/URL.uri= url
	$VBoxContainer/UrlPanel/URL.disabled = false



func find_item_by_name(option_button, target_name):
	# Получить количество пунктов в OptionButton

	var count = option_button.get_item_count()
	# Цикл по всем пунктам
	for i in range(count):
		# Получаем текст текущего пункта
		var text = option_button.get_item_text(i)
		# Проверяем совпадение с искомым именем
		if text == target_name:
			return i  # Возвращаем индекс совпадающего пункта
	return -1  # Если элемент не найден, возвращаем -1
