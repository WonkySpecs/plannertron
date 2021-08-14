import strformat
import sdl2
import ddnimlib / [fpstimer, ui, linear]
import types

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
        of SDL_SCANCODE_Q: game.quitting = true
        else: discard
    of MouseButtonDown:
      case ev.button.button:
        of BUTTON_LEFT: echo ("Clickety clacked")
        else: discard
    else: discard

proc draw*(renderer: RendererPtr, ui: UI) =
  ui.ctx.start(renderer)
  ui.timer.tick()
  discard ui.ctx.doLabel(text= fmt"{ui.timer.fps():.2f} fps",
                         fg=color(255, 0, 0, 255),
                         pos=vec(10, ui.sh - 20),
                         size=10)
