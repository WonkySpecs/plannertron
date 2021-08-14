import ddnimlib / [drawing, linear]
import types, assets, puzzle

proc newGame*(sw, sh: int): Game =
  new result
  result.puzzle = newPuzzle(sw, sh)
  result.quitting = false
  result.planning = true

proc draw*(view: View, game: Game) =
  view.start()
  view.draw(game.puzzle, game.selectedLayerIdx)
  view.finish()
