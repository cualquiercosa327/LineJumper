import core.volatile;

alias u8 = ubyte;
alias u16 = ushort;
alias u32 = uint;

// memory sections
enum MEM_IO   = cast(u32*) 0x04000000;
enum MEM_VRAM = cast(u16*) 0x06000000;

enum REG_DISPLAY_CONTROL = MEM_IO;

// modes
enum DCNT_MODE3 = 0x003;

// layers
enum DCNT_BG2 = 0x0400;

enum SCREEN_WIDTH  = 240;
enum SCREEN_HEIGHT = 160;

// colors
enum CLR_BLACK  = 0x0000;
enum CLR_RED    = 0x001F;
enum CLR_LIME   = 0x03E0;
enum CLR_YELLOW = 0x03FF;
enum CLR_BLUE   = 0x7C00;
enum CLR_MAG    = 0x7C1F;
enum CLR_CYAN   = 0x7FE0;
enum CLR_WHITE  = 0x7FFF;

u16 rgb15(u32 red, u32 green, u32 blue)
{
    return cast(u16) (red | green << 5 | blue << 10);
}

void drawPixel(u32 x, u32 y, u16 color)
{
    MEM_VRAM[y * SCREEN_WIDTH + x] = color;
}

extern (C) int main()
{
    volatileStore(REG_DISPLAY_CONTROL, DCNT_MODE3 | DCNT_BG2);

    drawPixel(120, 80, rgb15(31,  0,  0));
    drawPixel(136, 80, rgb15( 0, 31,  0));
    drawPixel(120, 96, rgb15( 0,  0, 31));

    while (true) {}

    return 0;
}
