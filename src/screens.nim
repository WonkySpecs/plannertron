import options
import sdl2
import ddnimlib / [drawing, utils]
import types, ui, game

const
  expected_frame_ms = 1000 / 60

type
  NextScreen* = enum
    MainMenu, Level

  GameLevel* = ref object
    ui*: LevelUI
    game*: Game

proc update(level: GameLevel, frameMS: int): Option[NextScreen] =
  level.ui.process_inputs(level.game)
  level.game.tick(frameMS.float / expected_frame_ms.float)
  if level.game.quitting:
    none(NextScreen)
  else:
    some(Level)

proc draw(view: View, level: GameLevel, vw, vh: int) =
  let
    h_pad = 30
    frac = 3 / 4
    w = (vw.float  * frac).int - h_pad * 2
    h = w
    main_dest = r(h_pad, ((vh / 2) - (h / 2)).int, w, h)
  view.draw(level.game, main_dest)
  view.draw(level.ui, level.game)
  view.renderer.present()

proc update*[Screen](screen: Screen, frameMS: int): Option[NextScreen] =
  screen.update(frameMS)

proc draw*[Screen](view: View, screen: Screen, vw, vh: int) =
  view.draw(screen, vw, vh)