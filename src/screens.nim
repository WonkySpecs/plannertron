import options
import sdl2
import ddnimlib / [drawing, utils]
import types, ui, game

const
  expected_frame_ms = 1000 / 60

type
  Screen* = ref object of RootObj

  GameLevelScreen* = ref object of Screen
    ui*: GameLevelUI
    game*: Game

  MainMenuScreen* = ref object of Screen
    ui*: MainMenuUI

  EditorMenuScreen* = ref object of Screen
    ui*: EditorMenuUI

method update*(screen: Screen, frameMS: int): Option[ScreenKind] {.base} = discard
method draw*(screen: Screen, view: View, vw, vh: int) {.base} = discard

method update*(level: GameLevelScreen, frameMS: int): Option[ScreenKind] =
  level.ui.process_inputs(level.game)
  level.game.tick(frameMS.float / expected_frame_ms.float)
  if level.ui.quitting:
    none(ScreenKind)
  else:
    some(GameLevel)

method draw*(level: GameLevelScreen, view: View, vw, vh: int) =
  let
    h_pad = 30
    frac = 3 / 4
    w = (vw.float  * frac).int - h_pad * 2
    h = w
    main_dest = r(h_pad, ((vh / 2) - (h / 2)).int, w, h)
  view.draw(level.game, main_dest)
  view.draw(level.ui, level.game, vw, vh)
  view.renderer.present()

method update*(menu: MainMenuScreen, frameMS: int): Option[ScreenKind] =
  menu.ui.process_inputs()
  if menu.ui.start_level:
    some(GameLevel)
  elif menu.ui.quitting:
    none(ScreenKind)
  elif menu.ui.next_screen.isSome:
    menu.ui.next_screen
  else:
    some(MainMenu)

method draw*(menu: MainMenuScreen, view: View, vw, vh: int) =
  view.renderer.setDrawColor(r=40, g=0, b=100)
  view.renderer.clear()
  view.draw(menu.ui, vw, vh)
  view.renderer.present()

method update*(menu: EditorMenuScreen, frameMS: int): Option[ScreenKind] =
  menu.ui.process_inputs()

  if menu.ui.quitting:
    none(ScreenKind)
  elif menu.ui.next_screen.isSome:
    menu.ui.next_screen
  else:
    some(EditorMenu)

method draw*(menu: EditorMenuScreen, view: View, vw, vh: int) =
  view.renderer.setDrawColor(r=40, g=0, b=100)
  view.renderer.clear()
  view.draw(menu.ui, vw, vh)
  view.renderer.present()
