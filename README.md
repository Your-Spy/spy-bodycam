# SPY-BODYCAM SYSTEM
Spy bodycam script offers a bodycam overlay on your screen and lets you see other players bodycam.

## Discord Support
For any assistance or questions, feel free to join my Discord server: [https://discord.gg/dg9tFH3F2P](https://discord.gg/dg9tFH3F2P)

## Compatibility
The bodycam script is designed to work seamlessly with the following frameworks:
- QBCore
- Qbox
- ESX [Note:- ESX Support is only for OX Inv and Target. You can make edits to support other stuff]

## Dependencies
Make sure to have the following dependencies installed:
- `ox_lib`
- `qb/ox-inventory`
- `qb/ox-target`
- `qb-clothing/illenium_appearance [OPTIONAL]`

## Preview - [YouTube](https://youtu.be/bDKH9l0Zhzc)

## How to Install
1. Ensure you have one of the compatible frameworks (QBCore, Qbox, or ESX) installed on your roleplay server.
2. Install the required dependencies.
3. Drag and drop in resources folder and add in server.cfg.
4. Setup the config as per your framework.
5. Add the item image to your inventory.

![Bodycam Image](https://i.imgur.com/CuSyeZT.png)

6. Add the item

### QBCore
```lua
['bodycam'] = {['name'] = 'bodycam', ['label'] = 'Bodycam', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bodycam.png', ['unique'] = true, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Bodycam for authorized personnel only'},
```
### OX
```lua
['bodycam'] = { label = 'Bodycam', weight = 500, stack = false, close = true },
```
## Features
- **Overlay GTA6-like Bodycam**: Provides an immersive bodycam overlay with sounds.
- **Watch Other Players' Bodycam**: Monitor the bodycam footage of other players in real-time.
- **Decoy Ped Creation**: Automatically creates a decoy pedestrian when watching other players.
- **Multiple Job Support**: Supports various job roles, allowing customization per job.
- **Custom Prop Included**: The script includes a custom bodycam prop for enhanced realism.
- **Dedicated Cam Positions**: Optimized camera positions for walking and car driving.

## Credits
Special thanks to aarjey0_0 for creating the custom prop included with this script.
Feel free to customize the script further to fit your server's needs and ensure all dependencies are up to date for smooth operation.

Credit to @felipecoder for the fivem game view for recording!

## Feedback and Support
I welcome any feedback or suggestions. If you encounter any issues or need support, please don't hesitate to reach out on the Discord server mentioned above.

Happy roleplaying!


