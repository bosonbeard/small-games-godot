extends Control

var transition_duration = 1.5 # Длительность перехода в секундах
var start_alpha = 0.0  # Начальная прозрачность
var end_alpha = 1  # Конечная прозрачность

## Скрываем и обнулям лишние элементы
func init_ui():
	$VBoxContainer/ScrollContainer.visible = false
	$VBoxContainer/UrlPanel.visible = false
	$VBoxContainer/ScrollContainer/DescPanel/MarginContainer/Description.text=""
	$VBoxContainer/UrlPanel/URL.uri=""
	$VBoxContainer/UrlPanel/URL.disabled = true
	$VBoxContainer/DateTimePanel/DateTimeLabel.update_text() 

## Анимация медленного появления
func show_smoothly(node):
	var tween = create_tween()
	node = get_node(node)
	if node:
		node.modulate.a = 0
		tween.tween_property(node, "modulate:a",  end_alpha, transition_duration)

## Показать событие и ссыоку
func show_event(event:Dictionary):
	var text = ""
	if event.has("title"): #Если титл заполнен формируем жирную строку
		text = "[b]{title}[/b]\n".format({"title":event.title})
	
	if event.has("desc"): # Если описание заполнено добавляем его после титула.
		text += "{desc}".format({"desc":event.desc})
		
	if event.has("title") or event.has("desc"): # Если есть контент для окна с описанеим события отображаем его
		show_smoothly("VBoxContainer/ScrollContainer/DescPanel") # включаем плавное появление описания события
		$VBoxContainer/ScrollContainer.visible = true
		$VBoxContainer/ScrollContainer/DescPanel/MarginContainer/Description.text =  text
	
	# Агналогично титлу и описанию, но для ссылки		
	if event.has("url"): 
		$VBoxContainer/UrlPanel/URL.disabled = false
		var url = event.url
		$VBoxContainer/UrlPanel/URL.uri= url
		show_smoothly("VBoxContainer/UrlPanel/")
		$VBoxContainer/UrlPanel.visible = true

## Выбираем ранее сохраненный город
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
	
## Получить выбранный город в формате словаря для записи в файл (используется в main.gd)
func get_selected_city_name():
	var option_button = $VBoxContainer/Cities
	var selected = option_button.selected
	var city = {"city": option_button.get_item_text(selected)}
	return city

## Обработчик выбора сигнала после выбора города
func _on_cities_item_selected(index: int):
	init_ui()
