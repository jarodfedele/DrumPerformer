extends Control

signal saved(to_save: int)

@onready var save_button = %Save
@onready var continue_without_saving_button = %ContinueWithoutSavingButton
@onready var cancel_button = %Cancel

var is_open = false

func _ready():
	set_process_unhandled_key_input(false)
	if save_button:
		save_button.pressed.connect(_on_save_button_pressed)
	if continue_without_saving_button:
		continue_without_saving_button.pressed.connect(_on_continue_without_saving_button_pressed)
	if cancel_button:
		cancel_button.pressed.connect(_on_cancel_button_pressed)
	hide()

func cancel():
	_close_modal("cancel")

func _close_modal(button_name):
	set_process_unhandled_key_input(false)
	if button_name == "save":
		saved.emit(true)
	if button_name == "continue_without_saving":
		saved.emit(false)
	hide()
	
func _unhandled_key_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		cancel()
			
func _on_save_button_pressed() -> void:
	_close_modal("save")
	
func _on_continue_without_saving_button_pressed() -> void:
	_close_modal("continue_without_saving")

func _on_cancel_button_pressed() -> void:
	cancel
