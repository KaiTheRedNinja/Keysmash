
# Keysmash

Keysmash is a game where you play as Charybdis, AKA the whirlpool monster. Your task is to create waves that guide travellers' boats towards your mouth, while at the same time trying to avoid the rocks.

## Todo
- [x] Detect key up and key down
- [x] Waves
  - [x] Respond to keystrokes
  - [x] Smooth (bezier?)
  - [x] Extend to fit the screen
  - [x] Letters vertically offset to their position on keyboards
  - [ ] Gradient look
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
- [ ] Game loop
  - [x] Automatically spawn boats and rocks
    - [x] Spawn more boats and rocks as time goes on
  - [x] Keep track of points and lives
  - [ ] Death
