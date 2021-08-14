import strformat
import sdl2
import ddnimlib / [fpstimer, ui, linear, utils, drawing]
import types, game

type
  UI* = ref object
    ctx*: Context
    sw*, sh*: int
    #tooltip: Option[string]
    timer: FPSTimer

proc newUI*(sw, sh: int): UI =
  new result
  result.sw = sw
  result.sh = sh
  result.ctx = newUIContext("assets/framd.ttf")

proc processInputs*(ui: UI, game: Game) =
  ui.ctx.startInput()
  var ev = defaultEvent
  while pollEvent(ev):
    case ev.kind:
    of QuitEvent: game.quitting = true
    of KeyDown:
      case ev.key.keysym.scancode:
        of SDL_SCANCODE_ESCAPE: game.quitting = true
        of SDL_SCANCODE_Q: game.rotate_left()
        of SDL_SCANCODE_E: game.rotate_right()
        else: discard
    of MouseButtonDown:
      case ev.button.button:
        of BUTTON_LEFT: echo ("Clickety clacked")
        else: discard
    else: discard

proc draw*(view: View, ui: UI, game: Game) =
  ui.ctx.start(view.renderer)

  const
    pad = 5
    frac = 1 / 3

  let
    tile_height = ((ui.sh - pad) / game.num_layers()).int
    container_width = (ui.sw.float * frac).int
    container_left = ui.sw - container_width + pad
    tile_width = container_width - pad * 2
    tile_size = min(tile_height, tile_width)
    left = container_left + (container_width / 2 - tile_size / 2).int

  for i in 0..<game.num_layers():
    let dest = r(left, i * (tile_size + pad) + pad, tile_size, tile_size)
    view.render_layer(game, i, dest)

  ui.timer.tick()
  discard ui.ctx.doLabel(text= fmt"{ui.timer.fps():.2f} fps",
                         fg=color(255, 0, 0, 255),
                         pos=vec(10, ui.sh - 20),
                         size=10)
