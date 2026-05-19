extends Node

signal player_turn_started()
signal player_turn_ended()
signal turret_phase_started()
signal turret_phase_ended()
signal hunter_phase_started()
signal hunter_phase_ended()
signal turn_complete(turn_number: int)

enum Phase { IDLE, PLAYER, TURRET, HUNTER, RESOLUTION }

var current_phase: Phase = Phase.IDLE
var turn_number: int = 0

var _turrets_pending: int = 0
var _hunters_pending: int = 0


func start_turn() -> void:
	if not GameState.is_game_active:
		return
	if current_phase != Phase.IDLE:
		return
	turn_number += 1
	GameState.current_turn = turn_number
	_set_phase(Phase.PLAYER)
	player_turn_started.emit()


func end_player_turn() -> void:
	if current_phase != Phase.PLAYER:
		return
	player_turn_ended.emit()
	_begin_turret_phase()


func report_turret_done() -> void:
	if current_phase != Phase.TURRET:
		return
	_turrets_pending -= 1
	if _turrets_pending <= 0:
		_turrets_pending = 0
		_end_turret_phase()


func report_hunter_done() -> void:
	if current_phase != Phase.HUNTER:
		return
	_hunters_pending -= 1
	if _hunters_pending <= 0:
		_hunters_pending = 0
		_end_hunter_phase()


func _begin_turret_phase() -> void:
	_set_phase(Phase.TURRET)
	_turrets_pending = GameState.turrets.size()
	turret_phase_started.emit()
	if _turrets_pending <= 0:
		_end_turret_phase()


func _end_turret_phase() -> void:
	if current_phase != Phase.TURRET:
		return
	turret_phase_ended.emit()
	_begin_hunter_phase()


func _begin_hunter_phase() -> void:
	_set_phase(Phase.HUNTER)
	_hunters_pending = 1 if GameState.hunter_ref != null else 0
	hunter_phase_started.emit()
	if _hunters_pending <= 0:
		_end_hunter_phase()


func _end_hunter_phase() -> void:
	if current_phase != Phase.HUNTER:
		return
	hunter_phase_ended.emit()
	_begin_resolution_phase()


func _begin_resolution_phase() -> void:
	_set_phase(Phase.RESOLUTION)
	GameState.tick_stuns()
	_check_win_lose()
	_finish_turn()


func _check_win_lose() -> void:
	pass


func _finish_turn() -> void:
	if current_phase != Phase.RESOLUTION:
		return
	_set_phase(Phase.IDLE)
	GameState.try_reward_bullet_on_turn(turn_number)
	turn_complete.emit(turn_number)
	if GameState.is_game_active:
		start_turn()


func reset_turn_system() -> void:
	current_phase = Phase.IDLE
	turn_number = 0
	_turrets_pending = 0
	_hunters_pending = 0


func _set_phase(p: Phase) -> void:
	current_phase = p
