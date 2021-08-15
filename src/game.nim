import options
import sdl2
import ddnimlib / [drawing, utils, linear]
import types, puzzle, consts

proc new_game*(renderer: RendererPtr): Game =
  new result
  result.puzzle = newPuzzle()
  result.quitting = false
  result.planning = true
  for n in min_layers..max_layers:
    result.render_targets[n] = renderer.createTexture(
      SDL_PIXELFORMAT_RGBA8888,
      SDL_TEXTUREACCESS_TARGET,
      (n * 32).cint, (n * 32).cint)

proc tick*(game: Game, delta: float) =
  let drot = delta * abs(game.transitions.rot) / 4.5
  if game.transitions.rot > drot:
    game.transitions.rot -= drot
  elif game.transitions.rot < -drot:
    game.transitions.rot += drot
  else:
    game.transitions.rot = 0

proc render_layer*(view: View, game: Game, layerIdx: int, dest: Rect, rot = 0.0) =
  let
    prev_render_ptr = view.renderer.getRenderTarget()
    layer = game.puzzle.layers[layerIdx]
    size = layer.size.x.int
    temp_render_ptr = game.render_targets[size]

  view.renderer.setRenderTarget(temp_render_ptr)
  view.renderer.setDrawColor(r=0, g=0, b=0)
  view.renderer.clear()
  view.draw(
    layer,
    r(0, 0, size * 32, size * 32))
  view.renderer.setRenderTarget(prev_render_ptr)
  var tr = texRegion(temp_render_ptr, none(Rect))
  view.renderAbs(
    tr,
    dest.pos,
    dest.size,
    layer.facing.as_rot() + rot)

proc draw*(view: View, game: Game, dest: Rect) =
  view.start()
  view.render_layer(game, game.selectedLayerIdx, dest, game.transitions.rot)
  view.finish()

proc rotate_left*(game: Game) =
  game.transitions.rot += 90
  while game.transitions.rot > 360:
    game.transitions.rot -= 360
  game.active_layer().rot_left()
proc rotate_right*(game: Game) =
  game.transitions.rot -= 90
  while game.transitions.rot < -360:
    game.transitions.rot += 360
  game.active_layer().rot_right()

proc move_up_layer*(game: Game) =
  if game.selectedLayerIdx > 0: game.selectedLayerIdx -= 1
proc move_down_layer*(game: Game) =
  if game.selectedLayerIdx < game.num_layers() - 1: game.selectedLayerIdx += 1
