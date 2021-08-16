from sdl2 import TexturePtr
import options
import ddnimlib / [drawing, linear]
import consts

type
  Asset* = enum
    ArrowSprite, RobotSprite, TileBg, ElevatorUpSprite, ElevatorDownSprite

  Facing* = enum North, East, South, West

  Robot* = object
    pos*: Vec[2]
    movement*: Vec[2] # Cache next movement
    facing*: Facing # Absolute facing
    tr*: TextureRegion
    progress*: float

  TileObjectKind* = enum
    Arrow, Elevator, Test

  TileObject* = object 
    case kind*: TileObjectKind
    of Arrow:
      # Facing is relative to the layer
      direction*: Facing
    of Elevator:
      going_down*: bool
    else: discard

  Tile* = object
    bg*: TextureRegion
    content*: Option[TileObject]

  LayerTransitions = object
    rot*: float
    target_layer_idx*: int
    progress*: float

  Layer* = ref object
    size*: Vec[2]
    tiles*: seq[Tile]
    facing*: Facing

  Puzzle* = ref object
    layers*: seq[Layer]

  Game* = ref object
    selected_layer_idx*: int
    puzzle*: Puzzle
    running_puzzle*: Puzzle
    robot*: Robot
    planning*: bool
    quitting*: bool
    render_targets*: array[min_layers..max_layers, TexturePtr]
    transitions*: LayerTransitions

func rot_right*(facing: Facing): Facing =
  case facing:
    of North: East
    of East: South
    of South: West
    of West: North

func rot_left*(facing: Facing): Facing =
  case facing:
    of North: West
    of West: South
    of South: East
    of East: North

func as_rot*(facing: Facing): float =
  case facing:
    of North: 0
    of East: 90
    of South: 180
    of West: 270

func num_layers*(game: Game): int = game.puzzle.layers.len
func active_layer*(game: Game): Layer = game.puzzle.layers[game.selected_layer_idx]

proc rot_left*(layer: Layer) = layer.facing = layer.facing.rot_left()
proc rot_right*(layer: Layer) = layer.facing = layer.facing.rot_right()

func layer_change_dir*(game: Game): int =
  game.transitions.target_layer_idx - game.selected_layer_idx

func `+`*(f1, f2: Facing): Facing = ((ord(f1) + ord(f2)) mod 4).Facing
func `-`*(f1, f2: Facing): Facing = ((ord(f1) - ord(f2) + 4) mod 4).Facing

func rotate*(v: Vec[2], facing: Facing, side_len: int): Vec[2] =
  let n = side_len - 1
  case facing:
    of North: v
    of East: vec(n - v.y.int, v.x.int)
    of South: vec(n - v.x.int, n - v.y.int)
    of West: vec(v.y.int, n - v.x.int)

func as_dir*(facing: Facing): Vec[2] =
  case facing:
    of North: vec(0, -1)
    of East: vec(1, 0)
    of South: vec(0, 1)
    of West: vec(-1, 0)
