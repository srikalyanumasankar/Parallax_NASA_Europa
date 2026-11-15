class_name NotificationToast
extends PanelFrame

## PARALLAX — a transient notification (mission unlocked / completed / alert).
## Auto-dismisses; never blocks input.

func _init() -> void:
	super("", ParallaxPalette.CYAN)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.x = 300.0


func _ready() -> void:
	super._ready()
	var tw: Tween = create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(self, "modulate:a", 0.0, 0.7)
	tw.tween_callback(queue_free)


func setup(kind: String, message: String, color: Color) -> void:
	set_title(kind)
	accent = color
	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	var msg: Label = ParallaxPalette.label(message, ParallaxPalette.F_LABEL + 1, ParallaxPalette.TEXT)
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.custom_minimum_size.x = 264.0
	body.add_child(msg)
	get_content().add_child(body)