import core.volatile;

import types;
import tiles;

// memory sections
enum MEM_IO           = cast(u32*)              0x04000000;
enum MEM_VRAM         = cast(u16*)              0x06000000;
enum MEM_BG_PALETTE   = cast(u16*)              0x05000000;
enum MEM_OBJ_PALETTE  = cast(u16*)              0x05000200;
enum MEM_TILE         = cast(TileBlock*)        MEM_VRAM;
enum MEM_SCREENBLOCKS = cast(ScreenBlock*)      MEM_VRAM;
enum MEM_OAM          = cast(ObjectAttributes*) 0x07000000;

enum REG_DISPLAY_CONTROL = MEM_IO;
enum REG_VCOUNT          = cast(u16*) 0x04000006;

// modes
enum DCNT_MODE0 = 0x000; // MODE 0 - tiled mode, 4 backgrounds, no bg rotation or scaling
enum DCNT_MODE3 = 0x003; // MODE 3 - bitmap mode, 16bpp

// backgrounds
enum DCNT_BG0 = 0x0100;
enum DCNT_BG1 = 0x0200;
enum DCNT_BG2 = 0x0400;
enum DCNT_BG3 = 0x0800;

enum REG_BG0_CONTROL = cast(u16*) 0x04000008;
enum REG_BG1_CONTROL = cast(u16*) 0x0400000A;
enum REG_BG2_CONTROL = cast(u16*) 0x0400000C;
enum REG_BG3_CONTROL = cast(u16*) 0x0400000E;

enum REG_BG0_SCROLL_H = cast(u16*) 0x04000010;
enum REG_BG0_SCROLL_V = cast(u16*) 0x04000012;
enum REG_BG1_SCROLL_H = cast(u16*) 0x04000014;
enum REG_BG1_SCROLL_V = cast(u16*) 0x04000016;
enum REG_BG2_SCROLL_H = cast(u16*) 0x04000018;
enum REG_BG2_SCROLL_V = cast(u16*) 0x0400001A;
enum REG_BG3_SCROLL_H = cast(u16*) 0x0400001C;
enum REG_BG3_SCROLL_V = cast(u16*) 0x0400001E;

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

// input
enum REG_KEYINPUT = cast(u16*) 0x4000130;

enum KEY_A      = 0x0001;
enum KEY_B      = 0x0002;
enum KEY_SELECT = 0x0004;
enum KEY_START  = 0x0008;
enum KEY_RIGHT  = 0x0010;
enum KEY_LEFT   = 0x0020;
enum KEY_UP     = 0x0040;
enum KEY_DOWN   = 0x0080;
enum KEY_R      = 0x0100;
enum KEY_L      = 0x0200;

enum KEY_MASK   = 0xFC00;

__gshared u32 currentInput;

void keyPoll()
{
    currentInput = volatileLoad(REG_KEYINPUT) | KEY_MASK;
}

u32 getKeyState(u32 key)
{
    return !(key & currentInput);
}

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
    import core.stdc.string : memcpy;

    memcpy(MEM_BG_PALETTE, &bgPalette[0], bgPalette.length * u16.sizeof);
    memcpy(&MEM_TILE[0][0], &bgTileset[0], bgTileset.length * u8.sizeof);

    memcpy(&MEM_SCREENBLOCKS[1], &bgTilemap[0], bgTilemap.length * u16.sizeof);

    volatileStore(REG_BG0_CONTROL, 0x180);

    volatileStore(REG_DISPLAY_CONTROL, DCNT_MODE0 | DCNT_BG0 | MAPPING_MODE_1D);

    while (true)
    {
        vsync();
        keyPoll();
    }

    return 0;
}
