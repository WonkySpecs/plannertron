import options
import ddnimlib / [drawing, linear]

type
  Asset* = enum
    ArrowSprite, RobotSprite, TileBg, ElevatorUpSprite, ElevatorDownSprite

  Facing* = enum North, East, South, West

  Robot* = object
    pos: Vec[2]
    # Absolute facing
    facing: Facing
    tex: TextureRegion

  TileObjectKind = enum
    Arrow, Elevator

  TileObject* = object 
    case kind: TileObjectKind
    of Arrow:
      # Facing is relative to the layer
      direction: Facing
    of Elevator:
      goingDown: bool

  Tile* = object
    bg*: TextureRegion
    content*: Option[TileObject]

  Layer* = ref object
    size*: Vec[2]
    tiles*: seq[Tile]
    facing*: Facing

  Puzzle* = ref object
    layers*: seq[Layer]

  Game* = ref object
    selectedLayerIdx*: int
    puzzle*: Puzzle
    planning*: bool
    robot*: Robot
    quitting*: bool
