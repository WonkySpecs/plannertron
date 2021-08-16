import macros
import types

type ObjProc = proc(game: Game, obj: TileObject)

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
  game.robot.facing = obj.direction + game.active_layer().facing

obj_proc(change_floor, Elevator):
  let change = if obj.going_down: 1 else: -1
  game.selected_layer_idx += change

proc nothing(game: Game, obj: TileObject) = discard

const
  on_arrival_procs* = [
    Arrow: change_direction,
    Elevator: change_floor,
    Test: nothing
  ]
