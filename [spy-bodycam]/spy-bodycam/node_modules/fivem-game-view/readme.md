# fivem-game-view
fivem-game-view is an npm library for gamerender in realtime

## Installation

```
npm  i fivem-game-view
```

## Usage

```js
import { GameView } from 'fivem-game-view'
const gameview = new GameView()
```

### Functions

#### Render GameView to a canvas element

Can be used for a lot of stuff: video calls, video record, live stream ...

- Start canvas render

    ```js
    const canvas = document.getElementById("videocall-canvas");

    gameview.createGameView(canvas);
    ```

- Stop canvas render

    ```js
    gameview.stop();
    ```