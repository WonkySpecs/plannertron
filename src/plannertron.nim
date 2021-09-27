import options
import sdl2, sdl2 / [image, ttf]
import ddnimlib / [init, drawing]
import assets, ui, game, screens

type
  SDLException = object of Defect

proc main =
  const
    fps_cap = -1
    frame_time_min_ms = (1000 / fps_cap).int
    fs = false

  initSdl()

  let window = if fs: createWindow(0, 0,
                                   flags=SDL_WINDOW_FULLSCREEN_DESKTOP or
                                         SDL_WINDOW_INPUT_GRABBED)
               else: createWindow(800, 600)
  sdlFailIf window.isNil: "Window could not be created"
  defer: window.destroy()
  let (vw, vh) = window.getSize()

  let renderer = window.createRenderer()
  sdlFailIf renderer.isNil: "Renderer could not be created"
  defer: renderer.destroy()

  load_textures(renderer)
  var
    last_frame = getTicks().int
    view = init_view(renderer, vw, vh)
    screen: Screen = MainMenuScreen(
      ui: new_main_menu_ui(renderer))
    cur_screen = MainMenuSK
    next_screen = some(MainMenuSK)

  while next_screen.isSome:
    let
      time = getTicks().int
      delta = (time - last_frame)
    last_frame = time

    next_screen = screen.update(delta)
    screen.draw(view, vw.int, vh.int)

    if next_screen.isSome and next_screen.get() != cur_screen:
      case next_screen.get():
      of GameLevelSK:
        screen = GameLevelScreen(
          ui: new_game_level_ui(renderer),
          game: new_game(renderer))
      of MainMenuSK: screen = MainMenuScreen(
        ui: new_main_menu_ui(renderer))
      of EditorMenuSK: screen = EditorMenuScreen(
        ui: new_editor_menu_ui(renderer))
      of LevelEditorSK:
        screen = new_editor_screen(
          renderer,
          # This is an ugly hack
          screen.EditorMenuScreen.ui.level_size)

      cur_screen = next_screen.get()

    if fps_cap > 0 and delta < frame_time_min_ms:
       delay((frame_time_min_ms - delta).uint32)

when isMainModule:
  main()
