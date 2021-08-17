import sdl2, sdl2 / [image, ttf]
import ddnimlib / [init, drawing, utils]
import assets, ui, game

type
  SDLException = object of Defect

proc main =
  const
    fps_cap = -1
    frame_time_min_ms = (1000 / fps_cap).int
    fs = false
    expected_frame_ms = 1000 / 60

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
    game = new_game(renderer)
    ui = new_ui(vw, vh, renderer)

  while not game.quitting:
    let
      time = getTicks().int
      delta = (time - last_frame)
    last_frame = time

    ui.process_inputs(game)
    game.tick(delta.float / expected_frame_ms)
    let
      h_pad = 30
      frac = 3 / 4
      w = (vw.float  * frac).int - h_pad * 2
      main_dest = r(h_pad, ((vh / 2) - (w / 2)).int, w, w)
    view.draw(game, main_dest)
    view.draw(ui, game)
    view.renderer.present()

    if fps_cap > 0 and delta < frame_time_min_ms:
       delay((frame_time_min_ms - delta).uint32)

when isMainModule:
  main()
