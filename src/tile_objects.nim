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
      new_facing = game.puzzle.layers[new_layer_idx].facing
      dfacing = cur_facing - new_facing
    game.selected_layer_idx = new_layer_idx
    game.robot.pos = game.robot.pos.rotate(dfacing, game.active_layer().size.x.int)

proc nothing(game: Game, obj: TileObject) = discard

const
  on_arrival_procs* = [
    Arrow: change_direction,
    Elevator: change_floor,
    Test: nothing
  ]
