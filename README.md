# SPY-BODYCAM SYSTEM
Spy bodycam script offers a bodycam overlay on your screen and lets you see other players bodycam and car dashcams, It lets you record a short video and sends it to the discord for you to see with detailed player log.

## Discord Support
For any assistance or questions, feel free to join my Discord server: [https://discord.gg/dg9tFH3F2P](https://discord.gg/dg9tFH3F2P)

## Compatibility
The bodycam script is designed to work seamlessly with the following frameworks:
- QBCore
- Qbox
- ESX [Note:- ESX Support requires ox_target. You can make edits to support other stuff]

## Dependencies
Make sure to have the following dependencies installed:
- `ox_lib`
- `qb/ox/esx-inventory`
- `qb/ox-target`
- `qb-clothing/illenium_appearance [OPTIONAL]`

## Preview - [YouTube](https://youtu.be/bDKH9l0Zhzc)

## How to Install
1. Ensure you have one of the compatible frameworks (QBCore, Qbox, or ESX) installed on your roleplay server.
2. Install the required dependencies.
3. Drag and drop in resources folder and add in server.cfg.
4. Setup the config as per your framework.
5. Add the item images in installfiles folder to your inventory.

![Bodycam Image](https://i.imgur.com/CuSyeZT.png)
![Dashcam Image](https://i.imgur.com/TVx1mcn.png)

6. Add the items

### QBCore
```lua
['bodycam'] = {['name'] = 'bodycam', ['label'] = 'Bodycam', ['weight'] = 500, ['type'] = 'item', ['image'] = 'bodycam.png', ['unique'] = true, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Bodycam for authorized personnel only'},
['dashcam'] = {['name'] = 'dashcam', ['label'] = 'Dashcam', ['weight'] = 500, ['type'] = 'item', ['image'] = 'dashcam.png', ['unique'] = true, ['useable'] = true, ['shouldClose'] = true, ['combinable'] = nil, ['description'] = 'Dashcam for authorized vehicle only'},
```
### OX
```lua
['bodycam'] = { label = 'Bodycam', weight = 500, stack = false, close = true },
['dashcam'] = { label = 'Dashcam', weight = 500, stack = false, close = true },
```
### ESX
```lua
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES ('bodycam', 'Bodycam', 1, 0, 1);
INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES ('dashcam', 'Dashcam', 1, 0, 1);
```
7. Run the sql file in installfiles folder
```sql
CREATE TABLE IF NOT EXISTS `spy_bodycam` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job` varchar(255) NOT NULL,
  `videolink` longtext NOT NULL,
  `street` varchar(255) NOT NULL,
  `date` varchar(255) NOT NULL,
  `playername` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=42 DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;
```
### Setup Fivemerr or Fivemanage

1. Set the `Upload.ServiceUsed` to the desired service in `server/upload_config.lua`:
    ```lua
    Upload.ServiceUsed = 'fivemerr' -- or 'fivemanage'
    ```

2. Create a video-only token and set it in the `Upload.Token` field in `server/upload_config.lua`:
    ```lua
    Upload.Token = 'YOUR_TOKEN'
    ```

Once you have completed these steps, the configuration is finished.


## Features
- **Overlay GTA6-like Bodycam**: Provides an immersive bodycam overlay with sounds.
- **Watch Other Players' Bodycam**: Monitor the bodycam footage of other players in real-time.
- **Decoy Ped Creation**: Automatically creates a decoy pedestrian when watching other players.
- **Multiple Job Support**: Supports various job roles, allowing customization per job.
- **Custom Prop Included**: The script includes a custom bodycam prop for enhanced realism.
- **Dedicated Cam Positions**: Optimized camera positions for walking and car driving.
- **Vehicle Dashcam Support**: You can now use a dashcam item to activate car cameras, which can be viewed anytime, no matter where the vehicle is in real-time.
- **Cam Offset System for Vehicles**: You can now adjust individual vehicle cameras if their positioning is bad with the built-in offset finder.
- **Highly Requested Record Feature**: Added a realistic record cam feature that can be used with /recordcam. This sends the video to a Discord channel with a detailed player log.

## Credits
Special thanks to aarjey0_0 for creating the custom prop included with this script.
Feel free to customize the script further to fit your server's needs and ensure all dependencies are up to date for smooth operation.

Credit to @felipecoder for the fivem game view for recording!

## Feedback and Support
I welcome any feedback or suggestions. If you encounter any issues or need support, please don't hesitate to reach out on the Discord server mentioned above.

Happy roleplaying!


