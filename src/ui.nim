import strformat, options, strutils
import sdl2
import ddnimlib / [fpstimer, ui, linear, utils, drawing]
import types, game, consts, rendering

type
  UI = ref object of RootObj
    ctx: Context
    timer: FPSTimer

  GameLevelUI* = ref object of UI
    render_targets: array[max_layers,
                      array[min_layer_size..max_layer_size,
                        TexturePtr]]

  MainMenuUI* = ref object of UI
    start_level*, quitting*: bool

proc new_game_level_ui*(renderer: RendererPtr): GameLevelUI =
  new result
  result.ctx = newUIContext("assets/framd.ttf")
  for n in 0..<max_layers:
    let targets = create_layer_render_targets(renderer)
    for i in min_layer_size..max_layer_size:
      result.render_targets[n][i] = targets[i]

proc process_inputs*(ui: GameLevelUI, game: Game) =
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
        of SDL_SCANCODE_W: game.view_layer_above()
        of SDL_SCANCODE_S: game.view_layer_below()
        of SDL_SCANCODE_SPACE: game.go()
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

proc draw*(view: View, ui: GameLevelUI, game: Game, vw, vh: int) =
  ui.ctx.start(view.renderer)

  let orig_render_target = view.renderer.getRenderTarget()
  var textures = newSeq[TextureRegion]()
  for i in 0..<game.num_layers():
    let
      layer_size = game.active_layer().size.x.int
      render_target = ui.render_targets[i][layer_size]
      target_size = render_target.getSize()
      dest = r(0, 0, target_size.x.int, target_size.y.int)
    view.renderer.setRenderTarget(render_target)
    view.render_layer(game, i, dest)
    textures.add(texRegion(render_target, none(Rect)))
  view.renderer.setRenderTarget(orig_render_target)

  const
    h_pad = 10
    v_pad = 80
  let reorder = ui.ctx.doReorderableIcons(
    "layer-previews",
    vec(vw * 3 / 4 + h_pad, v_pad),
    textures,
    fill = c(40, 40, 40),
    size = some(vec(vw / 4 - 2 * h_pad, vh - 2 * v_pad)))
  if reorder.isSome:
    let
      a = reorder.get().old_pos
      b = reorder.get().new_pos
      old = game.puzzle.layers[a]
    game.puzzle.layers.delete(a)
    game.puzzle.layers.insert(old, b)
    game.selected_layer_idx = b
    game.transitions.target_layer_idx = b

  if game.planning and ui.ctx.doButtonLabel(
      "Go",
      size=42,
      pos=vec(vw - 120, vh - 70),
      fg=c(240, 240, 230),
      bg=some(c(70, 210, 50)),
      hover_bg=some(c(25, 190, 30)),
      active_bg=some(c(10, 150, 0))) == Clicked:
    game.go()

  ui.timer.tick()
  discard ui.ctx.doLabel(text= fmt"{ui.timer.fps():.2f} fps",
                         fg=color(255, 0, 0, 255),
                         pos=vec(10, vh - 20),
                         size=10)

proc new_main_menu_ui*(renderer: RendererPtr): MainMenuUI =
  new result
  result.ctx = newUIContext("assets/framd.ttf")

proc process_inputs*(ui: MainMenuUI) =
  ui.ctx.start_input()
  var ev = defaultEvent
  while pollEvent(ev):
    case ev.kind:
    of QuitEvent: ui.quitting = true
    of KeyDown:
      case ev.key.keysym.scancode:
        of SDL_SCANCODE_ESCAPE: ui.quitting = true
        of SDL_SCANCODE_SPACE: ui.start_level = true
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

var c = 0
proc draw*(view: View, ui: MainMenuUI, vw, vh: int) =
  ui.ctx.start(view.renderer)
  if ui.ctx.doButtonLabel(
      "Play",
      size=42,
      pos=vec(0, 0),
      fg=c(240, 240, 230),
      bg=some(c(70, 210, 50)),
      hover_bg=some(c(25, 190, 30)),
      active_bg=some(c(10, 150, 0))) == Clicked:
    ui.start_level = true

  if ui.ctx.doButtonLabel(
      "Useless clicks: " & $c,
      size=42,
      pos=vec(70, 70),
      fg=c(240, 240, 230),
      bg=some(c(70, 210, 50)),
      hover_bg=some(c(25, 190, 30)),
      active_bg=some(c(10, 150, 0))) == Clicked:
    inc c
