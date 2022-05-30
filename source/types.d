module types;

public alias u8 = ubyte;
public alias u16 = ushort;
public alias u32 = uint;

public alias s8 = byte;
public alias s16 = short;
public alias s32 = int;

public alias Tile = u32[16];
public alias TileBlock = Tile[256];
public alias ScreenBlock = u16[1024];
