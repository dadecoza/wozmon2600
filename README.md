## The Woz Monitor ported to the Atari 2600.

[![IMAGE Youtube](https://img.youtube.com/vi/KOp0-bwY_vQ/0.jpg)](https://www.youtube.com/watch?v=KOp0-bwY_vQ "Wozmon2600 Demo")

### Cartridge Memory map

| Address   | Use       |
|-----------|-----------|
| F000-F3FF | RAM Read  |
| F400-F7FF | RAM Write |
| F800-FFFF | ROM       |

Since we do not have the Read/Write line from the CPU exposed through the cartridge slot we had to give up 1K of our 2K addressable RAM by wiring the inverted high address line (A10) to the RAM Write Enable pin. If you want that extra 1K you can use one of the remaining bits on Port A or run a wire from the CPU Read/Write pin ... I didn't find either of these solutions very elegant and 1K should be enough for anyone .. right?


### Example programs
I have included .woz files in the example folder. You can send the file contents to Wozmon using your favorite terminal emulator (I like TeraTerm). You might want to play with the "character" and "line" delays to get the files to load reliably. After the file is loaded into memory you can start it by entering the following run command ...
```
F080 R
```




