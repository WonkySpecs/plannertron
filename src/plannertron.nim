import options
import sdl2, sdl2 / [image, ttf]
import ddnimlib / [init, drawing, utils]
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
    screen = GameLevel(
      ui: new_ui(vw, vh, renderer),
      game: new_game(renderer))
    next = some(Level)

  while not next.isNone:
    let
      time = getTicks().int
      delta = (time - last_frame)
    last_frame = time

    next = screen.update(delta)
    view.draw(screen, vw.int, vh.int)

    if fps_cap > 0 and delta < frame_time_min_ms:
       delay((frame_time_min_ms - delta).uint32)

when isMainModule:
  main()
