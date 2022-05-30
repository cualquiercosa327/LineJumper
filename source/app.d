import core.volatile;

import types;
import sprite;

// memory sections
enum MEM_IO      = cast(u32*)              0x04000000;
enum MEM_VRAM    = cast(u16*)              0x06000000;
enum MEM_PALETTE = cast(u16*)              0x05000200;
enum MEM_TILE    = cast(TileBlock*)        MEM_VRAM;
enum MEM_OAM     = cast(ObjectAttributes*) 0x07000000;

enum REG_DISPLAY_CONTROL = MEM_IO;
enum REG_VCOUNT          = cast(u16*) 0x04000006;

// modes
enum DCNT_MODE0 = 0x000; // MODE 0 - tiled mode, 4 backgrounds, no bg rotation or scaling
enum DCNT_MODE3 = 0x003; // MODE 3 - bitmap mode, 16bpp

// layers
enum DCNT_BG2 = 0x0400;

enum ENABLE_OBJECTS  = 0x1000;
enum MAPPING_MODE_1D = 0x0040;

enum SCREEN_WIDTH  = 240;
enum SCREEN_HEIGHT = 160;

// colors
enum COL_BLACK  = 0x0000;
enum COL_RED    = 0x001F;
enum COL_LIME   = 0x03E0;
enum COL_YELLOW = 0x03FF;
enum COL_BLUE   = 0x7C00;
enum COL_MAG    = 0x7C1F;
enum COL_CYAN   = 0x7FE0;
enum COL_WHITE  = 0x7FFF;

struct ObjectAttributes
{
align(1):
    public u16 attr0;
    public u16 attr1;
    public u16 attr2;
    public u16 pad;
}

u16 rgb15(u32 red, u32 green, u32 blue)
{
    return cast(u16) (red | green << 5 | blue << 10);
}

void drawPixel(u32 x, u32 y, u16 color)
{
    MEM_VRAM[y * SCREEN_WIDTH + x] = color;
}

void drawRect(u32 left, u32 top, u32 width, u32 height, u16 color)
{
    for (int y = 0; y < height; y++)
    {
        for (int x = 0; x < width; x++)
        {
            drawPixel(left + x, top + y, color);
        }
    }
}

void uploadPaletteMemory()
{
    import core.stdc.string : memcpy;

    memcpy(MEM_PALETTE, &spritePalette[0], spritePaletteLength);
}

void uploadTileMemory()
{
    import core.stdc.string : memcpy;

    memcpy(&MEM_TILE[4][1], &spriteTiles[0], spriteTilesLength);
}

/**
 * Waits until all rows are drawn (until VBLANK). Do drawing after calling `vsync`.
 */
void vsync()
{
    while (volatileLoad(REG_VCOUNT) >= 160) {}
    while (volatileLoad(REG_VCOUNT) < 160) {}
}

extern (C) int main()
{
    uploadPaletteMemory();
    uploadTileMemory();

    ObjectAttributes* spriteAttributes = &MEM_OAM[0];
    spriteAttributes.attr0 = 0x2032;
    spriteAttributes.attr1 = 0x4064;
    spriteAttributes.attr2 = 2;

    volatileStore(REG_DISPLAY_CONTROL, DCNT_MODE0 | ENABLE_OBJECTS | MAPPING_MODE_1D);

    u32 x = 0;
    while (true)
    {
        vsync();

        x = (x + 1) % SCREEN_WIDTH;
        spriteAttributes.attr1 = 0x4000 | (0x1FF & x);
    }

    return 0;
}
