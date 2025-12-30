extends Node

const SECTOR_ROTATION_SIGNS = - 1 #сли сектора заданы по часовой стрелке



#var sectors = {
	#"cinema": ["cinema"],
	#"theater": ["theater"],
	#"сoncert": ["сoncert"],
	#"quest": ["quest"],
	#"exhibition": ["exhibition"],
	#"social": ["party","social-activity",],
	#"education": ["education"],
	#"other": ["entertainment","festival","other"]
#}

var sectors = [
	"cinema",
	"theater",
	"concert",
	"quest",
	"exhibition",
	"party,social-activity",
	"education",
	"entertainment,festival,other"
]

var locations = []

var can_spin = true

signal init_ui()

signal spin_started()

signal spin_finished(sector:int)
