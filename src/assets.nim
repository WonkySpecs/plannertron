import tables, options
import sdl2
import sdl2 / image
import ddnimlib / [drawing, utils]
import types

const
  fileExt = ".png"
  rootFolder = "assets/"

var
  textureStore: array[Asset, TexturePtr]
  textureRegions*: array[Asset, TextureRegion]

func cell(x, y, size = 32): Rect {.inline.} =
  r(x * size, y * size, size, size)

const spriteSheets = {
  ArrowSprite: (cell(0, 0), "placeholders"),
  RobotSprite: (cell(1, 0), "placeholders"),
  TileBg: (cell(2, 0), "placeholders"),
  ElevatorUpSprite: (cell(3, 0), "placeholders"),
  ElevatorDownSprite: (cell(4, 0), "placeholders"),
}.toTable

proc loadTextures*(renderer: RendererPtr) =
  let loaded = newTable[string, TexturePtr]()
  for (k, v) in spriteSheets.pairs:
    if not loaded.hasKey(v[1]):
      let
        f = rootFolder & v[1] & fileExt
        tex = renderer.loadTexture(f)
      assert tex != nil, "Failed to load texture: " & f
      loaded[v[1]] = tex

    let tex = loaded[v[1]]
    textureStore[k] = tex
    textureRegions[k] = texRegion(tex, some(v[0]))
