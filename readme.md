# Volume

Volume is an Ashita4 addon that adds simple commands for setting the sound and music volumes for FFXI.  It is
heavily derived from the [Config](https://github.com/AshitaXI/Ashita-v4beta/tree/main/addons/config) addon, and, as
such, uses the same license.

## Usage

- `/sound` by itself will show your current sound effects volume.
- `/sound 0-100` will change your sound effects volume.
- `/sound mute` will mute your sound.
- `/sound toggle` will toggle whether your sound is muted or not.
- `/music` works just like `/sound`, but for music.

This is primarily intended for use with keybinds.  I personally do the following:

```
/bind ^+S /sound toggle
/bind ^+M /music toggle
```

This I can quickly toggle sound and music (usually when alt-tabbing between multiple game instances) by doing
`Ctrl+Shift+S` and `Ctrl+Shift+M` respectively.
