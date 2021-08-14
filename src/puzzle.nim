import sdl2
import options, sugar
import ddnimlib / [drawing, linear, utils]
import types, assets

func tile_content_asset*(obj: TileObject): Asset =
  case obj.kind:
    of Arrow: ArrowSprite
    of Elevator:
      if obj.goingDown: ElevatorDownSprite else: ElevatorUpSprite

proc new_puzzle*(): Puzzle =
  new result
  var tiles = newSeq[Tile]()
  for i in 1..9:
    let content = if i != 5: none(TileObject) else: some(
      TileObject(kind: Arrow, direction: South))
    tiles.add Tile(
      bg: textureRegions[TileBg],
      content: content)

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
      view.renderAbs(
        tile.bg,
        dest.pos + vec(
          i.float * dest_tile_size.x,
          j.float * dest_tile_size.y),
        dest_tile_size)

  for j in 0..<layer_w:
    for i in 0..<layer_w:
      var tile = layer.tiles[j * layer_w + i]
      if tile.content.isNone: continue
      view.renderAbs(
        textureRegions[tile_content_asset(tile.content.get)],
        dest.pos + vec(
          i.float * dest_tile_size.x,
          j.float * dest_tile_size.y),
        dest_tile_size)
