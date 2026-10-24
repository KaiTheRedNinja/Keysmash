
# Keysmash

Keysmash is a game where you play as Charybdis, AKA the whirlpool monster. Your task is to create waves that guide travellers' boats towards your mouth, while at the same time trying to avoid the rocks.

## Running the App
1.  Download `Keysmash.app` from the releases page. This game runs on macOS only.
2. Run `Keysmash.app`. You may need to approve it in Privacy & Security in System Settings.

## How to Play
1. When you type a key, Charybdis will raise a wave at that key's position. Keys include letter keys and some punctuation
  a. The more keys you press in the area, the higher the wave. You can press as many keys as your keyboard allows - for this reason, I recommend using an Apple keyboard as most external keyboards cap out at 4 simultaneous key presses
  b. You can spam your keys (or slide your fingers across the keyboard) to move a wave smoothly
2. Guide boats TOWARDS your mouth using the waves. Each boat that you eat gains you +5 points, and each that you miss is -3 points.
3. Guide rocks AWAY FROM your mouth using the waves. Each rock that you avoid gains you +1 points, and each that you eat is -1 life.
4. You have three lives. Charybdis will lose its tentacles and saturation as you lose lives.
5. As you progress in the game, rocks and boats will appear at a higher rate.
6. You can restart the game if you die

## Todo
- [x] Detect key up and key down
- [x] Waves
  - [x] Respond to keystrokes
  - [x] Smooth (bezier?)
  - [x] Extend to fit the screen
  - [x] Letters vertically offset to their position on keyboards
  - [x] Gradient look
- [x] Boats
  - [x] Starting velocity
  - [x] Velocity decay over time
  - [x] Acceleration due to waves
  - [x] Deceleration due to gravity
  - [x] Angle change due to waves
- [x] Rocks
  - [x] Everything that boats have
  - [x] Angle changes proportional to velocity rather than to acceleration
- [x] Charybdis
  - [x] In the middle of the waves
  - [x] Eats boats and rocks
  - [x] Has tentacles going beneath the waves
- [x] Game loop
  - [x] Automatically spawn boats and rocks
    - [x] Spawn more boats and rocks as time goes on
  - [x] Keep track of points and lives
  - [x] Death
