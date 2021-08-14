import sdl2
import options, sugar
import ddnimlib / [drawing, linear, utils]
import types, assets

proc newPuzzle*(): Puzzle =
  new result
  var tiles = newSeq[Tile]()
  for i in 1..9:
    tiles.add Tile(
      bg: textureRegions[TileBg],
      content: none(TileObject))
  result.layers = @[
    Layer(
      size: vec(3, 3),
      tiles: tiles,
      facing: East),
    Layer(
      size: vec(3, 3),
      tiles: tiles,
      facing: North)]

proc draw*(view: View, puzzle: Puzzle, layerIdx: int, dest: Rect) =
  let
    layer = puzzle.layers[layerIdx]
    layer_w = layer.size.x.int
    layer_h = layer.size.y.int
    dest_w = dest.w.int
    dest_h = dest.h.int
    dest_tile_size = vec(dest_w / layer_w, dest_h / layer_h)

  for j in 0..<layer_w:
    for i in 0..<layer_w:
      var tile = layer.tiles[j * layer_w + i]
      view.renderAbs(tile.bg,
                  dest.pos + vec(
                    i.float * dest_tile_size.x,
                    j.float * dest_tile_size.y),
                  dest_tile_size)
