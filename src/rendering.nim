import sdl2
import consts

proc create_layer_render_targets*(
  renderer: RendererPtr): array[min_layer_size..max_layer_size, TexturePtr] =
  for n in min_layer_size..max_layer_size:
    let tex = renderer.createTexture(
      SDL_PIXELFORMAT_RGBA8888,
      SDL_TEXTUREACCESS_TARGET,
      (n * 32).cint, (n * 32).cint)
    tex.setTextureBlendMode(BLENDMODE_BLEND)
    result[n] = tex
