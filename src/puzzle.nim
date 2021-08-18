import options, sugar
import sdl2
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
    tiles1.add Tile(
      bg: textureRegions[TileBg],
      content: none(TileObject))
    tiles2.add Tile(
      bg: textureRegions[TileBg],
      content: some(TileObject(kind: Elevator, goingDown: false)))
  tiles1[test_size].content = some(TileObject(kind: Arrow, direction: East))
  tiles1[test_size+1].content = some(TileObject(kind: Arrow, direction: South))
  tiles1[test_size*2+1].content = some(TileObject(kind: Elevator, going_down: true))

  result.layers = @[
    Layer(
      size: vec(test_size, test_size),
      tiles: tiles1,
      facing: North),
    Layer(
      size: vec(test_size, test_size),
      tiles: tiles2,
      facing: North)]

proc draw*(view: View, layer: Layer, dest: Rect, robot = none(Robot)) =
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
      let
        obj = tile.content.get
        rot = case obj.kind:
          of Arrow: obj.direction.as_rot()
          else: 0
      view.renderAbs(
        textureRegions[tile_content_asset(obj)],
        dest.pos + vec(
          i.float * dest_tile_size.x,
          j.float * dest_tile_size.y),
        dest_tile_size,
        rot)

  if robot.isSome:
    var r = robot.get()
    view.renderAbs(
      r.tr,
      dest.pos + (r.pos + r.progress * r.movement) * dest_tile_size.x,
      dest_tile_size,
      (r.facing - layer.facing).as_rot)
