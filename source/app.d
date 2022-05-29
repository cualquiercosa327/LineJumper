import tonc;

extern (C) int main()
{
    *REG_DISPCNT = DCNT_MODE4 | DCNT_BG2;
    pal_bg_mem[0] = 0x6B9D;

    while (true)
    {
        key_poll();
    }

    return 0;
}
