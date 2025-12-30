extends Control



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init_ui():
	$VBoxContainer/ScrollContainer.visible = false
	$VBoxContainer/UrlPanel.visible = false
	$VBoxContainer/ScrollContainer/DescPanel/MarginContainer/Description.text=""
	$VBoxContainer/UrlPanel/URL.uri=""
	$VBoxContainer/UrlPanel/URL.disabled = true
	$VBoxContainer/DateTimePanel/DateTimeLabel.update_text() 
	

func show_event(event:Dictionary):
	var text = ""

	
	if event.has("title"):
		$VBoxContainer/ScrollContainer.visible = true
		text = "[b]{title}[/b]\n".format({"title":event.title})
	
	if event.has("desc"):
		$VBoxContainer/ScrollContainer.visible = true
		text += "{desc}".format({"desc":event.desc})
		
	if event.has("title") or event.has("desc"):
		$VBoxContainer/ScrollContainer.visible = true
		$VBoxContainer/ScrollContainer/DescPanel/MarginContainer/Description.text =  text
		
	if event.has("url"):
		$VBoxContainer/UrlPanel.visible = true
		var url = event.url
		$VBoxContainer/UrlPanel/URL.uri= url
		$VBoxContainer/UrlPanel/URL.disabled = false
	
	#$VBoxContainer/DateTimePanel.visible = true
	
	



func select_city_by_name(target_name):
	# Получить количество пунктов в OptionButton
	var option_button = $VBoxContainer/Cities
	var count = option_button.get_item_count()
	# Цикл по всем пунктам
	for i in range(count):
		# Получаем текст текущего пункта
		var text = option_button.get_item_text(i)
		# Проверяем совпадение с искомым именем
		if text == target_name:
			option_button.select(i)
	return -1  # Если элемент не найден, возвращаем -1
	
	
func get_selected_city_name():
	# Получить количество пунктов в OptionButton
	var option_button = $VBoxContainer/Cities
	var selected = option_button.selected
	var city = {"city": option_button.get_item_text(selected)}
	return city


func _on_cities_item_selected(index: int) -> void:
	init_ui()
