# SPY-BODYCAM SYSTEM
Spy bodycam script offers a bodycam overlay on your screen and lets you see other players bodycam.

## Discord Support
For any assistance or questions, feel free to join my Discord server: [https://discord.gg/dg9tFH3F2P](https://discord.gg/dg9tFH3F2P)

## Compatibility
The bodycam script is designed to work seamlessly with the following frameworks:
- QBCore
- Qbox
- ESX [Note:- ESX Support is only for OX Inv and Target. You can make make edits to support other stuff]

## Dependencies
Make sure to have the following dependencies installed:
- `ox_lib`
- `qb/ox-inventory`
- `qb/ox-target`
- `qb-clothing/illenium_appearance [OPTIONAL]`

## Preview - [`youtube`](https://youtu.be/n4S_a9JKzFw)

## How to Install
1. Ensure you have one of the compatible frameworks (QBCore, Qbox, or ESX) installed on your roleplay server.
2. Install the required dependencies.
3. Drap and drop in resources folder and add in server.cfg.
4. Setup the config as per your framework.
5. Add the item image in image folder to your inventory.
6. Add the item
 
### qbcore
```lua
['bodycam'] 		= {['name'] = 'bodycam', 			    ['label'] = 'Bodycam', 		['weight'] = 500, 		['type'] = 'item', 		['image'] = 'bodycam.png', 	    ['unique'] = true, 	    ['useable'] = true, 	['shouldClose'] = true,	   ['combinable'] = nil,   ['description'] = 'Bodycam for authorized personnel only'},
```
### ox_inv
```lua
['bodycam'] = { label = 'Bodycam', weight = 500, stack = false, close = true },
```
