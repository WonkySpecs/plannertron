import options
import sdl2
import ddnimlib / [drawing, utils, linear]
import types, puzzle, assets, tile_objects

proc new_game*(renderer: RendererPtr): Game =
  new result
  result.puzzle = newPuzzle()
  result.quitting = false
  result.planning = true
  result.layer_render_target = renderer.createTexture(
      SDL_PIXELFORMAT_RGBA8888,
      SDL_TEXTUREACCESS_TARGET,
      (144).cint, (144).cint)
  result.layer_render_target.setTextureBlendMode(BLENDMODE_BLEND)
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

var t = 0.0
proc running_tick(game: Game, delta: float) =
  t += delta
  if t > 80:
    game.planning = true
    t = 0
  game.robot.progress += delta / 20
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
    temp_render_ptr = game.layer_render_target

  view.renderer.setRenderTarget(temp_render_ptr)
  view.renderer.setDrawColor(r=0, g=0, b=0)
  view.renderer.clear()
  view.draw(
    layer,
    r(0, 0, size * 32, size * 32),
    robot)
  view.renderer.setRenderTarget(prev_render_ptr)
  temp_render_ptr.setTextureAlphaMod(alpha.uint8)
  var tr = texRegion(temp_render_ptr, none(Rect))
  view.renderAbs(
    tr,
    dest.pos,
    dest.size,
    layer.facing.as_rot() + rot)
  temp_render_ptr.setTextureAlphaMod(255)

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

proc move_up_layer*(game: Game) =
  if not game.planning: return
  if game.transitions.target_layer_idx > 0: game.transitions.target_layer_idx -= 1

proc move_down_layer*(game: Game) =
  if not game.planning: return
  if game.transitions.target_layer_idx < game.num_layers() - 1:
    game.transitions.target_layer_idx += 1
