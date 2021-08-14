import sdl2
import ddnimlib / [drawing, utils]
import types, puzzle

proc newGame*(): Game =
  new result
  result.puzzle = newPuzzle()
  result.quitting = false
  result.planning = true

proc render_layer*(view: View, game: Game, layerIdx: int, dest: Rect) =
  view.draw(
    game.puzzle,
    game.selectedLayerIdx,
    dest)

proc draw*(view: View, game: Game, dest: Rect) =
  view.start()
  view.render_layer(game, game.selectedLayerIdx, dest)
  view.finish()
