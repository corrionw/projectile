# Projectile
A library for physics based projectiles in Roblox using both Raycasts and Shapecasts.
If you have used [FastCast](https://devforum.roblox.com/t/making-a-combat-game-with-ranged-weapons-fastcast-may-be-the-module-for-you/133474), you'll notice that the design and API are similar to each-other and would be easy to adjust to using this module should you ever transition.

# Features
 - Resolution
  Allows you to change how many segments each cast is broken up into, for example, with a resolution set to 4, it would break the raycast into 4 segments, and raycast along those. Good for when you need a higher fidelity, i.e for fast moving projectiles, or when FPS is low. (greater time between the frames)
  - Volumetric Projectiles
   Give your projectiles volume with Roblox's new Shapecast features, no longer will you have to rely on complex solutions for projectiles that would need to have a large size so a level of realism can be had.
