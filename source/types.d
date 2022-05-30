module types;

public alias u8 = ubyte;
public alias u16 = ushort;
public alias u32 = uint;

public alias Tile = u32[16];
public alias TileBlock = Tile[256];
public alias ScreenBlock = u16[1024];
