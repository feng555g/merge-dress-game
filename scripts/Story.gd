# scripts/Story.gd
extends Node2D

signal story_complete

var _lines: Array = []
var _current_index: int = 0
var _is_typing: bool = false
var _full_text: String = ""
var _chapter: int = 1

@onready var bg: ColorRect = $Background
@onready var character_panel: Panel = $UILayer/CharacterPanel
@onready var character_display: ColorRect = $UILayer/CharacterPanel/CharacterDisplay
@onready var name_label: Label = $UILayer/DialogPanel/NameLabel
@onready var text_label: RichTextLabel = $UILayer/DialogPanel/TextLabel
@onready var continue_hint: Label = $UILayer/DialogPanel/ContinueHint
@onready var dialog_panel: Panel = $UILayer/DialogPanel
@onready var typing_timer: Timer = $TypingTimer

const TYPING_SPEED = 0.04  # 秒/字

func _ready() -> void:
	typing_timer.wait_time = TYPING_SPEED
	typing_timer.timeout.connect(_on_typing_tick)
	continue_hint.visible = false

func load_chapter_story(chapter: int) -> void:
	_chapter = chapter
	_lines = DataLoader.get_story(chapter)
	_current_index = 0
	if _lines.is_empty():
		_finish_story()
		return
	_show_line(_lines[0])

func _show_line(line: Dictionary) -> void:
	var speaker = line.get("speaker", "")
	var text = line.get("text", "")
	var emotion = line.get("emotion", "neutral")
	name_label.text = speaker
	text_label.text = ""
	_full_text = text
	_is_typing = true
	continue_hint.visible = false
	# 根据说话者更新角色显示
	_update_character(speaker, emotion)
	typing_timer.start()

func _update_character(speaker: String, emotion: String) -> void:
	var colors = {
		"neutral": Color(0.7, 0.7, 0.8),
		"happy": Color(1.0, 0.85, 0.5),
		"sad": Color(0.5, 0.6, 0.8),
		"surprised": Color(1.0, 0.7, 0.4),
		"serious": Color(0.6, 0.5, 0.7)
	}
	character_display.color = colors.get(emotion, Color(0.7, 0.7, 0.8))
	character_panel.visible = not speaker.is_empty()

func _on_typing_tick() -> void:
	var current_len = text_label.text.length()
	if current_len < _full_text.length():
		text_label.text = _full_text.substr(0, current_len + 1)
	else:
		typing_timer.stop()
		_is_typing = false
		continue_hint.visible = true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if not event.pressed:
			return
		if _is_typing:
			# 跳过打字效果，直接显示全文
			typing_timer.stop()
			_is_typing = false
			text_label.text = _full_text
			continue_hint.visible = true
		else:
			_advance()

func _advance() -> void:
	_current_index += 1
	if _current_index >= _lines.size():
		_finish_story()
	else:
		_show_line(_lines[_current_index])

func _finish_story() -> void:
	# 标记章节完成
	GameState.complete_chapter(_chapter)
	# 解锁下一章
	if _chapter < 3:
		GameState.current_chapter = _chapter + 1
	SaveSystem.save()
	emit_signal("story_complete")
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
