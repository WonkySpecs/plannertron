import macros
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
        ident("TileObject"))],
    body = newStmtList(assert_cmd, body))

obj_proc(change_direction, Arrow):
  game.robot.facing = obj.direction

obj_proc(change_floor, Elevator):
  if obj.going_down:
    game.selected_layer_idx += 1
  else:
    game.selected_layer_idx -= 1

proc nothing(game: Game, obj: TileObject) = discard

const
  on_arrival_procs* = [
    Arrow: change_direction,
    Elevator: change_floor,
    Test: nothing
  ]
