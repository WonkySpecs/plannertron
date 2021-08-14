import options
import ddnimlib / [drawing, linear]
import types, assets

const
  tileSideLen = 32
  tileSize = vec(tileSideLen, tileSideLen)

proc newPuzzle*(sw, sh: int): Puzzle =
  new result
  result.layers = @[
    Layer(
      size: vec(1, 1),
      tiles: @[
        Tile(
          bg: textureRegions[TileBg],
          content: none(TileObject))],
      facing: North
  )]

proc draw*(view: View, puzzle: Puzzle, layerIdx: int) =
  view.start()
  let
    layer = puzzle.layers[layerIdx]
    w = layer.size.x.int
    h = layer.size.y.int
  for j in 0..<h:
    for i in 0..<w:
      var tile = layer.tiles[j * w + i]
      view.render(tile.bg,
                  vec(i * tileSideLen, j * tileSideLen),
                  tileSize)
  view.finish()
