# scripts/Main.gd
# 根场景：初始化游戏，加载存档，切换到主菜单
extends Node

func _ready() -> void:
	SaveSystem.load_save()
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
