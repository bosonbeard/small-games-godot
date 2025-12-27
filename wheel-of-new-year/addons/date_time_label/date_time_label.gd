@tool
@icon("./date_time_label.svg")
class_name DateTimeLabel
extends RichTextLabel

## DateTimeLabel
##
## Adds a single configurable label used for displaying the date and time.
## See [member format_str] and [method get_relevant_time_mapping] for more information.

## The format string used to build the label's text.[br]
## The tokens are the names that may be found in the mapping returned by
## [method get_relevant_time_mapping].
## Tokens must be wrapped in curly braces ("{" and "}") and may include
## an optional format string style [code]%[/code] specifiers after the tokens name.[br]
## Ex. [code]"{hour}:{minute%02d}{ampm}"[/code] could appear as [code]1:02am[/code].
## [b]NOTE[b] it is required that all % signs are escaped manually, as this
## string will be used in a %-style format.
@export_multiline
var format_str := "{dayname}, {monthname} {day}{daysuffix}, {year}\n{hour12}:{minute%02d}:{second%02d} {ampm}":
	get:
		return format_str
	set(_value):
		format_str = _value
		update_text()

## When set, the label will update itself roughly every second,
## or every possible processed frame if the label uses [code]subsecond[/code]s;
## but only if it's visible.
## It's suggest to leave this enabled unless you intend to manually call [method update_text]
## to update this labels value yourself.
@export var update_on_frame := true:
	get:
		return update_on_frame
	set(_value):
		update_on_frame = _value
		update_text()

## When set, this label will report the time in utc instead of the user's
## specific timezone.[br]
## If you are unsure of what this means, leave it off,
## even if it reports the right time regardless.[br]
## See the note mentioned in [method get_relevant_time_mapping] regarding inaccuracies
## regarding non-utc timing.
@export var use_utc := false:
	get:
		return use_utc
	set(_value):
		use_utc = _value
		update_text()

var _update_elapsed := NAN

func _ready() -> void:
	if not visibility_changed.is_connected(update_text):
		visibility_changed.connect(update_text)
	update_text()

func _process(delta: float) -> void:
	if update_on_frame and visible:
		if not is_finite(_update_elapsed): #then we should initialise this
			_update_elapsed = Time.get_unix_time_from_system()
		else:
			_update_elapsed += delta

		if _update_elapsed >= 1.0 or "{subsecond" in format_str:
			_update_elapsed -= floorf(_update_elapsed)
			update_text()

func _validate_property(property: Dictionary) -> void:
	if property.name == "text":
		property.usage &= ~(PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE)

## Retrieves a dictionary containing a superset of
## [method Time.get_datetime_dict_from_system]
## (or [method Time.get_datetime_dict_from_unix_time] if [param using_utc] is true);[br]
## also including additional entries collating to other time information:[br][br]
## - [b]subsecond[/b]: the seconds as a float value (see note below)[br]
## - [b]daysuffix[/b]: the ordinal suffix for [b]day[/b] (from [method get_ordinal_suffix])[br]
## - [b]monthname[/b]: the appropriate month's English name (taken from [member get_month_name])[br]
## - [b]dayname[/b]: the appropriate weekday's English name
## (taken from [member get_weekday_name])[br]
## - [b]hour12[/b]: the hour adjusted appropriately for the 12-hour time format[br]
## - [b]ampm[/b]: the appropriate "AM" or "PM" suffix for [b]hour12[/b][br]
## - [b]yearadbc[/b]: the year adjusted appropriately to corelate to a "AD" or "BD" suffix[br]
## - [b]adbc[/b]: the appropriate "AD" or "BD" suffix for [b]yearadbc[/b][br]
## - [b]timezonebiasminute[/b]: the time zone bias as a int offset of minuets from utc[br]
## - [b]timezonebiashour[/b]: the time zone bias as a float offset of hours from utc[br]
## - [b]timezonebias[/b]: the time zone via [method Time.get_offset_string_from_offset_minutes][br]
## - [b]timezonename[/b]: the time zone name[br][br]
## [param using_utc] determined weather or not the time will use the current utc time
## or the system's returned values for local date and time instead. Regardless of this value,
## timezone related values will always return the local timezone's information.
## [param translation_context] applies to items that are formal names or suffixes, where
## the names translation is looked up in the methods used to determine them.[br][br]
## [b]NOTE[/b] there is a limit to the accuracy of this clock,
## especially when it comes to subseconds.
## Disabling utc may result in the subseconds and seconds being slightly desynced,
## as godot does not report anything beyond seconds from the system,
## meaning that subseconds are being calculated from a poll of the clock that can be slightly
## different from the one used to report the other parts of the date and time;
## and there is no performant and reliable way to get the utc or the subseconds as reported
## by the system in order to fix this inaccuracy.
func get_relevant_time_mapping(using_utc := false, translation_context := "Time") -> Dictionary:
	var utc := Time.get_unix_time_from_system()
	var ret := {}
	if using_utc:
		ret = Time.get_datetime_dict_from_unix_time(utc)
	else:
		ret = Time.get_datetime_dict_from_system()
	var tz := Time.get_time_zone_from_system()
	ret["subsecond"] = ret["second"] + (utc - floorf(utc))
	ret["ampm"] = get_am_pm(ret["hour"], translation_context)
	ret["hour12"] = ((ret["hour"] - 1) % 12) + 1
	ret["adbc"] = get_ad_bc(ret["year"], translation_context)
	ret["yearadbc"] = ret["year"] if ret["year"] >= 1 else 1-ret["year"]
	ret["daysuffix"] = get_ordinal_suffix(ret["day"])
	ret["monthname"] = get_month_name(ret["month"], translation_context)
	ret["dayname"] = get_weekday_name(ret["weekday"], translation_context)
	ret["timezonename"] = tz["name"]
	ret["timezonebiasminute"] = tz["bias"]
	ret["timezonebiashour"] = tz["bias"]/60
	ret["timezonebias"] = Time.get_offset_string_from_offset_minutes(tz["bias"])
	return ret

## Returns the localized English name of the given [param month] (from 1 to 12,
## as represented in [enum Time.Month]).
## The returned value is first attempted to be translated (using [method Object.tr])
## with the given [param translation_context].
func get_month_name(month:Time.Month, translation_context := "Time") -> String:
	assert(month > 0 and month <= 12)
	const NAMES := [
						"January",
						"February",
						"March",
						"April",
						"May",
						"June",
						"July",
						"August",
						"September",
						"October",
						"November",
						"December",
						]
	return tr(NAMES[month-1], translation_context)

## Returns the localized English name of the given [param weekday] (from 0 to 6,
## as represented in [enum Time.Weekday]).
## The returned value is first attempted to be translated (using [method Object.tr])
## with the given [param translation_context].
func get_weekday_name(weekday:Time.Weekday, translation_context := "Time") -> String:
	assert(weekday >= 0 and weekday < 7)
	const NAMES := [
						"Sunday",
						"Monday",
						"Tuesday",
						"Wednesday",
						"Thursday",
						"Friday",
						"Saturday",
						]
	return tr(NAMES[weekday], translation_context)

## Returns the [code]am[/code] or [code]pm[/code] suffix relevant to the given [param hour_24].
## It's expected that the given [param hour_24] is in the 24 hour clock format.
## The returned value is first attempted to be translated (using [method Object.tr])
## with the given [param translation_context].
func get_am_pm(hour_24:int, translation_context := "Time") -> String:
	assert(hour_24 >= 0 and hour_24 < 24)
	return tr("am" if hour_24 < 12 else "pm", translation_context)

## Returns the [code]bc[/code] or [code]ad[/code] suffix relevant to the given [param year_signed].
## It's expected that the given [param year_signed] is a signed value,
## with 1 corelating to the 1st year AD, 0 corelating to the year [/i]before[/i] that,
## and so on into the negatives.
## The returned value is first attempted to be translated (using [method Object.tr])
## with the given [param translation_context].
func get_ad_bc(year_signed:int, translation_context := "Time") -> String:
	return tr("ad" if year_signed <= 0 else "bc", translation_context)

## Returns the appropriate suffix commonly used for numeric ordinals in English
## for the value of [param ordinal].
## Ex. 1, 11, 21, and 101 returns "st"; 2, 12, and 22 return "nd" and so on.
## 0 will return "th", and negative values return the same as their positive counterparts.
## The returned value is [b]not[/b] translated in any way.
func get_ordinal_suffix(ordinal:int) -> String:
	const SUFFIX := {1:"st", 2:"nd", 3:"rd"}
	const DEFAULT := "th"
	return SUFFIX.get(abs(ordinal) % 10, DEFAULT)

## Manually updates the label. Called when a an appropriate property is changed,
## or every frame when [member update_on_frame] is set.[br]
## If [member update_on_frame] is not set, this must be called manually to have this
## label's text updated.
func update_text() -> void:
	var time_info = get_relevant_time_mapping(use_utc)

	var format_string_seq := []
	var format_map := {}
	for sec in format_str.split("{"):
		sec = sec.get_slice("}", 0)
		var k := sec.get_slice("%", 0)
		var f := sec.get_slice("%", 1)
		if f == sec:
			f = ""
		if k in time_info.keys():
			if f.is_empty():
				format_map[sec] = "%s"
			else:
				format_map[sec] = "%" + f.lstrip("%")
			format_string_seq.append(time_info[k])
	text = format_str.format(format_map) % format_string_seq
