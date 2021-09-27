from sdl2 import RendererPtr
import game, types, rendering

proc new_level_editor*(renderer: RendererPtr, level_size: int): LevelEditor =
  new result
  result.game = new_game(renderer, level_size)
