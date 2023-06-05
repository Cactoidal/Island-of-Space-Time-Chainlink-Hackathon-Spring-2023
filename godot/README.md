I have uploaded the script files I personally wrote for this project.  

User.gd is a singleton holding universally important data such as the SxT refresh token and loaded creature set.  It periodically refreshes the SxT token and queries SxT for creature images.

DataEntry.gd is the script handling the game's login and pause menu, and like User and Player also serves as a reference point for multiple other scripts.

CreatureMenu.gd governs the Summoned Creature screen.  It queries SxT for the user's summoned creatures and is responsible for rendering them in the game.  It provides the Location and Demeanor buttons and their connections into Godot Rust.

Chainlink.gd is the reference point for the Summoning chamber, used to spawn and delete the Island's terrain when exiting the doors or teleporting back inside.

Player.gd is responsible for triggering interactions with the Chainlink VRF summoner and the Creature screen.  It also handles spawning of creatures into the world, and is what triggers teleportation when it collides with certain areas.  The FPS controller responsible for movement was copied from the youtube link below.

Godot uses a node-based architecture reliant on "scene" and "resource" files.  I have not uploaded these as they primarily consist of configuration data, nor have I provided the plugin or asset files (the latter amounting to hundreds of MBs).  However, I will provide links below to the invaluable resources I have used to make this project:

Godot https://github.com/godotengine/godot

Godot Rust https://github.com/godot-rust/gdnative

Rust Ethers https://github.com/gakonst/ethers-rs

Forest tutorial https://www.youtube.com/watch?v=0bgw7crtOcQ

UniversalSky plugin https://github.com/dwlcj/UniversalSky/

Waterways Plugin https://github.com/Arnklit/Waterways

Heightmap Terrain Plugin https://github.com/Zylann/godot_heightmap_plugin

Scatter Tool Plugin https://github.com/Zylann/godot_scatter_plugin

FPS Controller https://www.youtube.com/watch?v=Nn2mi5sI8bM

Water Shader https://github.com/godot-extended-libraries/godot-realistic-water

Metal Shader https://godotshaders.com/shader/simple-3d-metal/

Pink Skybox https://github.com/rpgwhitelock/AllSkyFree_Godot

Ground Textures https://ambientcg.com

Palm Tree https://opengameart.org/content/palm-tree-v2

Wind Sound https://freesound.org/people/Proxima4/sounds/104320/

Ocean Sound https://freesound.org/people/tawix/sounds/547222/

Stream Sound https://freesound.org/people/Auxide_Audio/sounds/585497/

Heightmap https://heightmap.skydark.pl/beta/ (Somewhere east of Yosemite)

Godot Metamask https://github.com/nate-trojian/MetamaskAddon
