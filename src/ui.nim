import strformat, options
import sdl2
import ddnimlib / [fpstimer, ui, linear, utils, drawing]
import types, game

type
  UI* = ref object
    ctx*: Context
    sw*, sh*: int
    #tooltip: Option[string]
    timer: FPSTimer

proc new_ui*(sw, sh: int): UI =
  new result
  result.sw = sw
  result.sh = sh
  result.ctx = newUIContext("assets/framd.ttf")

proc process_inputs*(ui: UI, game: Game) =
  ui.ctx.start_input()
  var ev = defaultEvent
  while pollEvent(ev):
    case ev.kind:
    of QuitEvent: game.quitting = true
    of KeyDown:
      case ev.key.keysym.scancode:
        of SDL_SCANCODE_ESCAPE: game.quitting = true
        of SDL_SCANCODE_Q: game.rotate_left()
        of SDL_SCANCODE_E: game.rotate_right()
        of SDL_SCANCODE_W: game.move_up_layer()
        of SDL_SCANCODE_S: game.move_down_layer()
        else: discard
    of MouseButtonDown:
      case ev.button.button:
        of BUTTON_LEFT: ui.ctx.pressMouse(vec(ev.button.x, ev.button.y))
        else: discard
    of MouseButtonUp:
      if ev.button.button == BUTTON_LEFT:
        ui.ctx.releaseMouse(vec(ev.button.x, ev.button.y))
    else: discard
    ui.ctx.setMousePos(getMousePos())

proc draw*(view: View, ui: UI, game: Game) =
  ui.ctx.start(view.renderer)

  const
    pad = 8
    frac = 1 / 4

  let
    tile_height = ((ui.sh - pad) / game.num_layers()).int
    container_width = (ui.sw.float * frac).int
    container_height = ui.sh - pad * 2
    container_left = ui.sw - container_width
    tile_width = container_width - pad * 2
    tile_size = min(tile_height, tile_width)
    left = container_left + (container_width / 2 - tile_size / 2).int
    total_height = (tile_size + pad) * game.num_layers()
    top = (container_height / 2 - total_height / 2).int

  for i in 0..<game.num_layers():
    let tile_top = top + i * (tile_size + pad) + pad
    if i == game.selected_layer_idx:
      var highlight = r(
        left - 2, tile_top - 2, tile_size + 4, tile_size + 4)
      view.renderer.setDrawColor(Color((150.uint8, 150.uint8, 150.uint8, 255.uint8)))
      view.renderer.fillRect(highlight)
    let dest = r(left,tile_top, tile_size, tile_size)
    view.render_layer(game, i, dest)

  case ui.ctx.doButtonLabel(
    "Go",
    size=42,
    pos=vec(ui.sw - 120, ui.sh - 70),
    fg=c(240, 240, 230),
    bg=some(c(70, 210, 50)),
    hover_bg=some(c(25, 190, 30)),
    active_bg=some(c(10, 150, 0)))
    of Clicked: echo "Clicked"
    else: discard

  ui.timer.tick()
  discard ui.ctx.doLabel(text= fmt"{ui.timer.fps():.2f} fps",
                         fg=color(255, 0, 0, 255),
                         pos=vec(10, ui.sh - 20),
                         size=10)
