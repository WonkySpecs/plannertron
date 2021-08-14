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

proc render_layer*(view: View, game: Game, layerIdx: int, dest: Rect) =
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
    layer.facing.as_rot())

proc draw*(view: View, game: Game, dest: Rect) =
  view.start()
  view.render_layer(game, game.selectedLayerIdx, dest)
  view.finish()

proc rotate_left*(game: Game) = game.active_layer().rot_left()
proc rotate_right*(game: Game) = game.active_layer().rot_right()
