import macros
import ddnimlib / linear
import types

macro obj_proc(p_name, obj_type, body: untyped): untyped =
  let assert_cmd = quote do:
    assert obj.kind == `obj_type`
  result = new_proc(
    name = p_name,
    params = @[
      newEmptyNode(),
      newIdentDefs(
        ident("game"),
        ident("Game")),
      newIdentDefs(
        ident("obj"),
        newNimNode(nnkVarTy).add(ident("TileObject")))],
    body = newStmtList(assert_cmd, body),
    # Have to mark as sideEffect so all procs are the same type
    pragmas = nnkPragma.newTree(ident("sideEffect")))

obj_proc(change_direction, Arrow):
  game.robot.facing = obj.direction + game.active_layer().facing

obj_proc(change_floor, Elevator):
  let new_layer_idx = game.selected_layer_idx + (if obj.going_down: 1 else: -1)
  if new_layer_idx < 0:
    game.failure("Squashed against the ceiling")
  elif new_layer_idx >= game.num_layers():
    game.failure("Descended into the abyss")
  else:
    let
      cur_facing = game.active_layer().facing
      new_facing = game.running_puzzle.layers[new_layer_idx].facing
      dfacing = cur_facing - new_facing
    game.selected_layer_idx = new_layer_idx
    game.robot.pos = game.robot.pos.rotate_point(
      dfacing, game.active_layer().size.x.int)
    game.robot.movement = game.robot.movement.rotate_movement(dfacing)

obj_proc(press_plate, PressurePlate):
  echo "press"
  obj.active = true

obj_proc(release_plate, PressurePlate):
  echo "release"
  obj.active = false

proc nothing(game: Game, obj: var TileObject) {.sideEffect.} = discard

const
  on_enter_procs* = [
    Arrow: change_direction,
    Elevator: nothing,
    Test: nothing,
    PressurePlate: press_plate
  ]

  on_arrival_procs* = [
    Arrow: nothing,
    Elevator: change_floor,
    Test: nothing,
    PressurePlate: nothing
  ]

  on_exit_procs* = [
    Arrow: nothing,
    Elevator: nothing,
    Test: nothing,
    PressurePlate: release_plate
  ]
