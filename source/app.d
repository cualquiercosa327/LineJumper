import core.volatile;

alias u8 = ubyte;
alias u16 = ushort;
alias u32 = uint;

// memory sections
enum MEM_IO   = cast(u32*) 0x04000000;
enum MEM_VRAM = cast(u16*) 0x06000000;

enum REG_DISPLAY_CONTROL = MEM_IO;
enum REG_VCOUNT          = cast(u16*) 0x04000006;

// modes
enum DCNT_MODE3 = 0x003;

// layers
enum DCNT_BG2 = 0x0400;

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
    volatileStore(REG_DISPLAY_CONTROL, DCNT_MODE3 | DCNT_BG2);

    // clear the screen
    for (int y = 0; y < SCREEN_HEIGHT; y++)
    {
        for (int x = 0; x < SCREEN_WIDTH; x++)
        {
            drawPixel(x, y, COL_BLACK);
        }
    }

    int x = 0;
    while (true)
    {
        vsync();

        // if reached end of screen, go back to start
        if (x > SCREEN_WIDTH * (SCREEN_HEIGHT / 10)) x = 0;

        if (x != 0)
        {
            // clear the rect at the previous position
            int previous = x - 10;
            drawRect(previous % SCREEN_WIDTH, (previous / SCREEN_WIDTH) * 10, 10, 10, COL_BLACK);
        }

        drawRect(x % SCREEN_WIDTH, (x / SCREEN_WIDTH) * 10, 10, 10, COL_WHITE);

        x += 10;
    }

    return 0;
}
