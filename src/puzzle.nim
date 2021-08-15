import sdl2
import options, sugar
import ddnimlib / [drawing, linear, utils]
import types, assets

func tile_content_asset*(obj: TileObject): Asset =
  case obj.kind:
    of Arrow: ArrowSprite
    of Elevator:
      if obj.goingDown: ElevatorDownSprite else: ElevatorUpSprite
    else: ArrowSprite
const test_size = 5

proc new_puzzle*(): Puzzle =
  new result
  var tiles1 = newSeq[Tile]()
  var tiles2 = newSeq[Tile]()
  for i in 1..test_size*test_size:
    let content = if i != (test_size * test_size / 2).int: none(TileObject) else: some(
      TileObject(kind: Arrow, direction: South))
    tiles1.add Tile(
      bg: textureRegions[TileBg],
      content: content)
    tiles2.add Tile(
      bg: textureRegions[TileBg],
      content: some(TileObject(kind: Elevator, goingDown: true)))

  result.layers = @[
    Layer(
      size: vec(test_size, test_size),
      tiles: tiles1,
      facing: East),
    Layer(
      size: vec(test_size, test_size),
      tiles: tiles2,
      facing: North)]

proc draw*(view: View, layer: Layer, dest: Rect) =
  let
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
