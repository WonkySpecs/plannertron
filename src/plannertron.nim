import sdl2, sdl2 / [image, ttf]
import ddnimlib / [init, drawing]
import assets, ui, game

type
  SDLException = object of Defect

proc main =
  const
    fpsCap = -1
    frameTimeMinMS = (1000 / fpsCap).int
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

  loadTextures(renderer)
  var
    lastFrame = getTicks().int
    view = initView(renderer, vw, vh)
    game = newGame(vw, vh)
    ui = newUI(vw, vh)

  while not game.quitting:
    let
      time = getTicks().int
      delta = (time - lastFrame)
    lastFrame = time

    ui.processInputs(game)
    #game.process(view.cam, delta.float)
    #if game.quitting: break
    view.draw(game)
    view.renderer.draw(ui)
    view.renderer.present()

    if fpsCap > 0:
      if delta < frameTimeMinMS:
       delay((frameTimeMinMS - delta).uint32)

when isMainModule:
  main()
