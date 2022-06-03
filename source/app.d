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
enum MEM_OAM          = cast(u16*)              0x07000000;

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

enum NUM_SPRITES = 128;

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

struct Sprite
{
align(1):
    public u16 attr0;
    public u16 attr1;
    public u16 attr2;
    public u16 attr3;
}

enum SpriteSize
{
    s8x8,
    s16x16,
    s32x32,
    s64x64,
    s16x8,
    s32x8,
    s32x16,
    s64x32,
    s8x16,
    s8x32,
    s16x32,
    s32x64
}

__gshared Sprite[NUM_SPRITES] sprites;
__gshared u32 nextSpriteIndex = 0;

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

Sprite* initSprite(u32 x, u32 y, SpriteSize size, bool hFlip, bool vFlip, u32 tileIndex, u32 priority)
{
    u32 index = nextSpriteIndex++;

    u32 sizeBits;
    u32 shapeBits;
    final switch (size)
    {
        case SpriteSize.s8x8:   sizeBits = 0; shapeBits = 0; break;
        case SpriteSize.s16x16: sizeBits = 1; shapeBits = 0; break;
        case SpriteSize.s32x32: sizeBits = 2; shapeBits = 0; break;
        case SpriteSize.s64x64: sizeBits = 3; shapeBits = 0; break;
        case SpriteSize.s16x8:  sizeBits = 0; shapeBits = 1; break;
        case SpriteSize.s32x8:  sizeBits = 1; shapeBits = 1; break;
        case SpriteSize.s32x16: sizeBits = 2; shapeBits = 1; break;
        case SpriteSize.s64x32: sizeBits = 3; shapeBits = 1; break;
        case SpriteSize.s8x16:  sizeBits = 0; shapeBits = 2; break;
        case SpriteSize.s8x32:  sizeBits = 1; shapeBits = 2; break;
        case SpriteSize.s16x32: sizeBits = 2; shapeBits = 2; break;
        case SpriteSize.s32x64: sizeBits = 3; shapeBits = 2; break;
    }

    u32 h = hFlip ? 1 : 0;
    u32 v = vFlip ? 1 : 0;


    sprites[index].attr0 = cast(u16) (y         | // y pos
                                     (0 << 8)   | // rendering mode
                                     (0 << 10)  | // gfx mode
                                     (0 << 12)  | // mosaic
                                     (1 << 13)  | // color mode, 0:16, 1:256
                                     (shapeBits << 14)); // shape

    sprites[index].attr1 = cast(u16) (x         | // x pos
                                     (0 << 9)   | // affine flag
                                     (h << 12)  | // hflip
                                     (v << 13)  | // vflip
                                     (sizeBits << 14)); // size

    sprites[index].attr2 = cast(u16) (tileIndex        |
                                     (priority << 10)  |
                                     (0 << 12)); // palette bank (only 16 color)

    return &sprites[index];
}

void updateSpritePosition(Sprite* sprite, u32 x, u32 y)
{
    sprite.attr0 &= 0xff00; // clear y
    sprite.attr0 |= (y & 0xff); // set new y

    sprite.attr1 &= 0xfe00; // clear x
    sprite.attr1 |= (x & 0x1ff); // set new x
}

void memcpySprites()
{
    import core.stdc.string : memcpy;

    memcpy(MEM_OAM, sprites.ptr, NUM_SPRITES * Sprite.sizeof);
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

    memcpy(MEM_BG_PALETTE, bgPalette.ptr, bgPalette.length * u16.sizeof);
    memcpy(&MEM_TILE[0][0], bgTileset.ptr, bgTileset.length * u8.sizeof);

    memcpy(&MEM_SCREENBLOCKS[1], &bgTilemap[0], bgTilemap.length * u16.sizeof);

    volatileStore(REG_BG0_CONTROL, 0x180);

    memcpy(MEM_OBJ_PALETTE, &spritePalette[0], spritePalette.length * u16.sizeof);
    memcpy(&MEM_TILE[4][1], &spriteTiles[0], spriteTiles.length * u8.sizeof);

    u32 playerX = 100;
    u32 playerY = 100;

    u32 playerMaxJumpHeight = 15;
    u32 playerJumpHeight = 0;
    s32 playerJumpDir = 1;
    bool playerJumping = false;

    Sprite* player = initSprite(playerX, playerY, SpriteSize.s8x8, false, false, 2, 0);
    Sprite* playerShadow = initSprite(playerX, playerY, SpriteSize.s8x8, false, false, 4, 0);

    volatileStore(REG_DISPLAY_CONTROL, DCNT_MODE0 | DCNT_BG0 | ENABLE_OBJECTS | MAPPING_MODE_1D);

    while (true)
    {
        vsync();
        keyPoll();

        if (getKeyState(KEY_LEFT))
        {
            if (playerX > 52) playerX--;
        }
        else if (getKeyState(KEY_RIGHT))
        {
            if (playerX < 180) playerX++;
        }

        if (getKeyState(KEY_UP))
        {
            if (playerY > 9) playerY--;
        }
        else if (getKeyState(KEY_DOWN))
        {
            if (playerY < 137) playerY++;
        }

        if (getKeyState(KEY_B) && !playerJumping)
        {
            playerJumping = true;
            playerJumpDir = 1;
        }

        if (playerJumping)
        {
            if (playerJumpHeight == playerMaxJumpHeight) playerJumpDir = -1;

            playerJumpHeight += playerJumpDir;

            if (playerJumpHeight == 0) playerJumping = false;
        }

        updateSpritePosition(player, playerX, playerY - playerJumpHeight);
        updateSpritePosition(playerShadow, playerX, playerY);

        memcpySprites();
    }

    return 0;
}
