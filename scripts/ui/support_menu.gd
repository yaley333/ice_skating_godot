extends Control

const MAIN_MENU_SCENE: = "res://ui/main_menu3d.tscn"
const SBP_URL: = "https://messenger.online.sberbank.ru/sl/aKf1Zimhy2OxxpmsH"

const ERC20_ADDRESS: = "0x7c7B91B431bd46A1C41F39fE67FDa5682b38C3C5"
const SOL_USDT_ADDRESS: = "25R3t8RxUwf4FNBkZuhVzptV9rvfJmtZYKuzDTb169if"
const ETH_ADDRESS: = "0x7c7B91B431bd46A1C41F39fE67FDa5682b38C3C5"
const SOL_ADDRESS: = "25R3t8RxUwf4FNBkZuhVzptV9rvfJmtZYKuzDTb169if"
const BTC_ADDRESS: = "bc1qhzk827pzagrcje84ehmcf0e08lwjgvqq2v57cp"
const TON_ADDRESS: = "UQD_GB3SMkFBqq29SVKjHvTAIqFLydJ7Ut8hY_fZFDKaT17F"

@onready var qr_texture: TextureRect = $AddressOverlay / Center / Panel / VBox / QR
@onready var address_edit: LineEdit = $AddressOverlay / Center / Panel / VBox / AddressValue
@onready var copied_label: Label = $AddressOverlay / Center / Panel / VBox / CopiedLabel
@onready var overlay: Control = $AddressOverlay
@onready var snowflakes_root: Node = $Snowflakes

var _qr_map: Dictionary = {
	"erc20": preload("res://images/erc20.jpg"), 
	"usdt_sol": preload("res://images/sol.jpg"), 
	"eth": preload("res://images/eth.jpg"), 
	"sol": preload("res://images/sol_qr.jpg"), 
	"btc": preload("res://images/btc.jpg"), 
	"ton": preload("res://images/ton.jpg"), 
}

func _ready() -> void :
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	overlay.visible = false
	_start_menu_fx()

func _start_menu_fx() -> void :
	if not snowflakes_root:
		return
	var i: = 0
	for n in snowflakes_root.get_children():
		if not (n is CanvasItem):
			continue
		var item: = n as CanvasItem
		var base_pos: Vector2 = item.position
		var t: = create_tween()
		t.set_loops()
		var phase: = float(i) * 0.3
		t.tween_property(item, "position", base_pos + Vector2(0, -18), 2.2 + phase).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(item, "position", base_pos + Vector2(0, 18), 2.2 + phase).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var r: = create_tween()
		r.set_loops()
		r.tween_property(item, "rotation", 0.3, 4.0 + phase).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		r.tween_property(item, "rotation", -0.3, 4.0 + phase).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		i += 1

func _on_back_pressed() -> void :
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_sbp_pressed() -> void :
	OS.shell_open(SBP_URL)

func _on_erc20_pressed() -> void :
	_show_crypto("erc20", ERC20_ADDRESS)

func _on_usdt_sol_pressed() -> void :
	_show_crypto("usdt_sol", SOL_USDT_ADDRESS)

func _on_eth_pressed() -> void :
	_show_crypto("eth", ETH_ADDRESS)

func _on_sol_pressed() -> void :
	_show_crypto("sol", SOL_ADDRESS)

func _on_btc_pressed() -> void :
	_show_crypto("btc", BTC_ADDRESS)

func _on_ton_pressed() -> void :
	_show_crypto("ton", TON_ADDRESS)

func _show_crypto(key: String, address: String) -> void :
	var tex: Texture2D = _qr_map.get(key)
	if tex == null:
		push_warning("QR texture is missing for key: %s" % key)
	qr_texture.texture = tex
	address_edit.text = address
	copied_label.visible = false
	overlay.visible = true

func _on_copy_pressed() -> void :
	DisplayServer.clipboard_set(address_edit.text)
	copied_label.visible = true

func _on_close_overlay_pressed() -> void :
	overlay.visible = false

func _unhandled_input(event: InputEvent) -> void :
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if overlay.visible:
			overlay.visible = false
		else:
			_on_back_pressed()
