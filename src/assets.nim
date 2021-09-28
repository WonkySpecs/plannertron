import tables, options
import sdl2
import sdl2 / image
import ddnimlib / [drawing, utils]
import types

const
  file_ext = ".png"
  root_folder = "assets/"

var
  texture_store: array[Asset, TexturePtr]
  texture_regions*: array[Asset, TextureRegion]

func cell(x, y, size = 32): Rect {.inline.} =
  r(x * size, y * size, size, size)

const sprite_sheets = {
  ArrowSprite: (cell(0, 0), "placeholder"),
  RobotSprite: (cell(1, 0), "placeholder"),
  TileBg: (cell(2, 0), "placeholder"),
  ElevatorUpSprite: (cell(3, 0), "placeholder"),
  ElevatorDownSprite: (cell(4, 0), "placeholder"),
  PressurePlateSprite: (cell(5, 0), "placeholder"),
  ActivePressurePlateSprite: (cell(6, 0), "placeholder"),
}.toTable

proc load_textures*(renderer: RendererPtr) =
  let loaded = newTable[string, TexturePtr]()
  for (k, v) in sprite_sheets.pairs:
    if not loaded.hasKey(v[1]):
      let
        f = root_folder & v[1] & file_ext
        tex = renderer.loadTexture(f)
      assert tex != nil, "Failed to load texture: " & f
      loaded[v[1]] = tex

    let tex = loaded[v[1]]
    texture_store[k] = tex
    texture_regions[k] = texRegion(tex, some(v[0]))
