import strformat, options, strutils
import sdl2
import ddnimlib / [fpstimer, linear, utils, drawing, ui]
import types, game, consts, rendering

type
  ScreenKind* = enum
    MainMenu, GameLevel, EditorMenu, LevelEditor

  UI = ref object of RootObj
    ctx: Context
    timer: FPSTimer
    quitting*: bool
    next_screen*: Option[ScreenKind]
    frame_events: seq[Event]

  GameLevelUI* = ref object of UI
    render_targets: array[max_layers,
                      array[min_layer_size..max_layer_size,
                        TexturePtr]]

  MainMenuUI* = ref object of UI
    start_level*: bool

  EditorMenuUI* = ref object of UI
    level_size*: int

  LevelEditorUI* = ref object of UI

proc shared_process_inputs(ui:  UI) =
  ui.ctx.start_input()
  ui.frame_events.setLen(0)
  var ev = defaultEvent
  while pollEvent(ev):
    ui.frame_events.add(ev)
    case ev.kind:
    of QuitEvent: ui.quitting = true
    of KeyDown:
      case ev.key.keysym.scancode:
        of SDL_SCANCODE_ESCAPE: ui.quitting = true
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

proc new_game_level_ui*(renderer: RendererPtr): GameLevelUI =
  new result
  result.ctx = newUIContext("assets/framd.ttf")
  for n in 0..<max_layers:
    let targets = create_layer_render_targets(renderer)
    for i in min_layer_size..max_layer_size:
      result.render_targets[n][i] = targets[i]

proc process_inputs*(ui: GameLevelUI, game: Game) =
  ui.shared_process_inputs()
  for ev in ui.frame_events:
    case ev.kind:
    of KeyDown:
      case ev.key.keysym.scancode:
        of SDL_SCANCODE_Q: game.rotate_left()
        of SDL_SCANCODE_E: game.rotate_right()
        of SDL_SCANCODE_W: game.view_layer_above()
        of SDL_SCANCODE_S: game.view_layer_below()
        of SDL_SCANCODE_SPACE: game.go()
        else: discard
    else: discard

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
  ui.shared_process_inputs()
  for ev in ui.frame_events:
    case ev.kind:
    of KeyDown:
      case ev.key.keysym.scancode:
        of SDL_SCANCODE_SPACE: ui.start_level = true
        else: discard
    else: discard

var useless_clicks = 0
proc draw*(view: View, ui: MainMenuUI, vw, vh: int) =
  ui.ctx.start(view.renderer)
  if ui.ctx.doButtonLabel(
      "Play",
      size=42,
      pos=vec(10, 0),
      fg=c(240, 240, 230),
      bg=some(c(70, 210, 50)),
      hover_bg=some(c(25, 190, 30)),
      active_bg=some(c(10, 150, 0))) == Clicked:
    ui.start_level = true
  elif ui.ctx.doButtonLabel(
      "Level Editor",
      size=42,
      pos=vec(10, 50),
      fg=c(240, 240, 230),
      bg=some(c(70, 210, 50)),
      hover_bg=some(c(25, 190, 30)),
      active_bg=some(c(10, 150, 0))) == Clicked:
    ui.next_screen = some(EditorMenu)

  if ui.ctx.doButtonLabel(
      "Useless clicks: " & $useless_clicks,
      size=42,
      pos=vec(70, 350),
      fg=c(240, 240, 230),
      bg=some(c(70, 210, 50)),
      hover_bg=some(c(25, 190, 30)),
      active_bg=some(c(10, 150, 0))) == Clicked:
    inc useless_clicks

proc new_editor_menu_ui*(renderer: RendererPtr): EditorMenuUI =
  new result
  result.ctx = newUIContext("assets/framd.ttf")

proc process_inputs*(ui: EditorMenuUI) =
  ui.shared_process_inputs()

proc draw*(view: View, ui: EditorMenuUI, vw, vh: int) =
  ui.ctx.start(view.renderer)
  if ui.ctx.doButtonLabel(
      "Back",
      size=42,
      pos=vec(0, 0),
      fg=c(240, 240, 230),
      bg=some(c(70, 210, 50)),
      hover_bg=some(c(25, 190, 30)),
      active_bg=some(c(10, 150, 0))) == Clicked:
    ui.next_screen = some(MainMenu)

  const
    num_rows = 2
    num_btns = max_layer_size - min_layer_size + 1
    row_size = int((num_btns + 1) / num_rows)

  for ls in min_layer_size..max_layer_size:
    let
      i = ls - min_layer_size
      second_line = i >= row_size
      y = if second_line: 150 else: 100
      x = 30 * (if second_line: i - row_size else: i)

    if ui.ctx.doButtonLabel(
        $ls,
        size=42,
        pos=vec(x, y),
        fg=c(240, 240, 230),
        bg=some(c(70, 210, 50)),
        hover_bg=some(c(25, 190, 30)),
        active_bg=some(c(10, 150, 0))) == Clicked:
      ui.level_size = ls
      ui.next_screen = some(LevelEditor)

proc new_level_editor_ui*(renderer: RendererPtr): LevelEditorUI =
  new result
  result.ctx = newUIContext("assets/framd.ttf")

proc process_inputs*(ui: LevelEditorUI) =
  ui.shared_process_inputs()

proc draw*(view: View, ui: LevelEditorUI, vw, vh: int) =
  ui.ctx.start(view.renderer)
