import options
import sdl2
import ddnimlib / [drawing, utils, linear]
import types, puzzle, assets, tile_objects, consts, rendering

proc new_game*(renderer: RendererPtr, level_size: int): Game =
  new result
  result.puzzle = new_puzzle(level_size)
  result.planning = true
  result.layer_render_targets = create_layer_render_targets(renderer)
  result.robot = Robot(
    tr: texture_regions[RobotSprite])

proc go*(game: Game) =
  game.planning = false
  game.running_puzzle = deepCopy(game.puzzle)
  game.selected_layer_idx = 0
  game.robot.pos = vec(0, 0).rotate(
    North - game.active_layer().facing,
    game.active_layer().size.x.int)
  game.robot.facing = South
  game.robot.movement = (game.robot.facing - game.active_layer().facing).as_dir()

proc planning_tick(game: Game, delta: float) =
  let drot = delta * abs(game.transitions.rot) / 4.5
  if game.transitions.rot > drot:
    game.transitions.rot -= drot
  elif game.transitions.rot < -drot:
    game.transitions.rot += drot
  else:
    game.transitions.rot = 0

  if game.layer_change_dir() != 0:
    game.transitions.progress += delta / 10
    if game.transitions.progress >= 1:
      game.selected_layer_idx = game.transitions.target_layer_idx
      game.transitions.progress = 0

proc running_tick(game: Game, delta: float) =
  let old_prog = game.robot.progress
  game.robot.progress += delta / 40
  if old_prog < 0.5 and game.robot.progress > 0.5:
    let
      next_tile = game.robot.pos + game.robot.movement
      layer_size = game.active_layer().size

    if next_tile.x < 0 or next_tile.y < 0 or
      next_tile.x >= layer_size.x or next_tile.y >= layer_size.y:
      game.failure("hit a wall")

  if game.robot.progress > 1:
    game.robot.progress -= 1
    game.robot.pos += game.robot.movement
    let tile = game.active_layer().tile_at(game.robot.pos)
    if tile.content.isSome:
      let obj = tile.content.get()
      on_arrival_procs[obj.kind](game, obj)
    game.robot.movement = (game.robot.facing - game.active_layer().facing).as_dir()

proc tick*(game: Game, delta: float) =
  if game.planning:
    game.planning_tick(delta)
  else:
    game.running_tick(delta)

proc render_layer*(
  view: View,
  game: Game,
  layerIdx: int,
  dest: Rect,
  rot = 0.0,
  alpha = 255,
  robot = none(Robot)) =
  let
    prev_render_ptr = view.renderer.getRenderTarget()
    layer = game.puzzle.layers[layerIdx]
    size = layer.size.x.int
    render_target = game.layer_render_targets[size]

  view.renderer.setRenderTarget(render_target)
  view.renderer.setDrawColor(r=0, g=0, b=0)
  view.renderer.clear()
  view.draw(
    layer,
    r(0, 0, size * 32, size * 32),
    robot)
  view.renderer.setRenderTarget(prev_render_ptr)
  render_target.setTextureAlphaMod(alpha.uint8)
  var tr = texRegion(render_target, none(Rect))
  view.renderAbs(
    tr,
    dest.pos,
    dest.size,
    layer.facing.as_rot() + rot)

proc planning_draw(view: View, game: Game, dest: Rect) =
  view.start()
  if game.layer_change_dir() != 0:
    let
      cur_prog = 1 - game.transitions.progress
      cur_layer_a = (255 * cur_prog).int
      next_layer_a = (255 * game.transitions.progress).int

      cur_shift = vec(0, -1 * game.layer_change_dir().float * game.transitions.progress) * 30
      next_shift = vec(0, game.layer_change_dir().float * cur_prog) * 30

    view.render_layer(game, game.transitions.target_layer_idx, dest + next_shift, alpha=next_layer_a)
    view.render_layer(game, game.selected_layer_idx, dest + cur_shift, alpha=cur_layer_a)

  else:
    view.render_layer(game, game.selected_layer_idx, dest, game.transitions.rot)
  view.finish()

proc running_draw(view: View, game: Game, dest: Rect) =
  view.start()
  view.render_layer(game, game.selected_layer_idx, dest, robot = some(game.robot))
  view.finish()

proc draw*(view: View, game: Game, dest: Rect) =
  if game.planning:
    view.planning_draw(game, dest)
  else:
    view.running_draw(game, dest)

proc rotate_left*(game: Game) =
  if not game.planning: return
  game.transitions.rot += 90
  while game.transitions.rot > 360:
    game.transitions.rot -= 360
  game.active_layer().rot_left()

proc rotate_right*(game: Game) =
  if not game.planning: return
  game.transitions.rot -= 90
  while game.transitions.rot < -360:
    game.transitions.rot += 360
  game.active_layer().rot_right()

proc view_layer_above*(game: Game) =
  if not game.planning: return
  if game.transitions.target_layer_idx > 0: game.transitions.target_layer_idx -= 1

proc view_layer_below*(game: Game) =
  if not game.planning: return
  if game.transitions.target_layer_idx < game.num_layers() - 1:
    game.transitions.target_layer_idx += 1
