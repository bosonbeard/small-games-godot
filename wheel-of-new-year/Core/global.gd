extends Node

const SECTOR_ROTATION_SIGNS = - 1 #сли сектора заданы по часовой стрелке

var sectors = [	
	"cinema",
	"theater",
	"сoncert",
	"day_event",
	"exhibition",
	"social",
	"education",
	"other"
	]


signal spin_started()

signal spin_finished(sectors:String)
