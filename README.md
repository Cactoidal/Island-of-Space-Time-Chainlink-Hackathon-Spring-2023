# Island of Space & Time


## Summoning

Create images using Dall-E and Chainlink VRF, with parameters bound by a smart contract. With SxT, images are shared with all players, without needing to connect to a centralized server. Player-created creatures live on-chain. Gameplay is off-chain. 

Built using [Godot](https://github.com/godotengine) and [Godot-Rust](https://github.com/godot-rust).


>WASD/Arrow keys to move

>Mouse to look

>E to interact

>Spacebar to jump

>Shift to run

>C / ESC to capture/uncapture mouse



## Embark

[Download the game client for your system on the release page.](https://github.com/Cactoidal/Island-of-Space-Time-Chainlink-Hackathon-Spring-2023/releases/tag/SxT_Island) **Currently, only Mac ARM is supported.**  Intel Mac may also work, but has not been tested.

If the SxT relay is operational, you should need only the game client to enter the Island. However, if you want to summon creatures, you will need to provide your own OpenAI API key on the login screen. Please note that you will incur the usual fees for generating images. If the relay is available, you may use it by leaving the SxT field blank. Otherwise, you will need to provide your own REFRESH token to summon and see creatures.

The game will generate a keystore file for you when you first start playing. Click the "Copy Address" and "Get MATIC" buttons to get gas from the faucet.


## How it Works

The game uses an SxT table to store images shared between all players. Creatures are created by first calling Chainlink VRF, which randomly inserts words into an on-chain AI prompt form. Dall-E takes the prompt and returns a base64 string, which is uploaded to SxT along with a unique hash value and the creature's ID.

On-chain, the hash is mapped to the creature ID, and the creature's base statistics are also set.

When Godot loads creatures into the game, it first checks whether the creature has been properly initialized on-chain before loading its image from the SxT table. Godot also pulls each creature's base stats from the smart contract. A creature's "location" can be set with an on-chain transaction, and Godot will use this setting to determine where creatures are loaded into the game world.

This is made possible using Godot Rust in conjunction with Ethers.rs, which allows the game to create a local keystore and perform transactions.


## Secrets

Image generation works by taking your OpenAI API key, performing a query, receiving a base64 string, and uploading that string to Space and Time.

I spent a great deal of time working to integrate Chainlink Functions into the game. Namely, I ported the secrets encryption functionality of the starter kit into Rust, and built a tool that allows Godot Rust to create SxT biscuits that would be used for secret-passing. **Currently, no Chainlink Functions call takes place, and your OpenAI API key is not passed to a DON. Godot instead handles the API call and uploads the image by itself.** Chainlink Functions' HTTP Maximum request length is 2kb, while the base64 strings from OpenAI are approximately 250kb.

I've designed a system mimicking the Github Gist system that would instead use SxT tables as a means of passing secrets to the Chainlink DON.   [You can find the code for this implementation under the secrets folder](secrets).  The scheme would work as follows:

* Godot encrypts your OpenAI API key, creates a new SxT biscuit, uses the biscuit to create a permissioned table on SxT, and places the encrypted key there.  

* Godot then uses the DON public key to encrypt the access biscuit, the access token, the table's randomized name, and the encrypted OpenAI key's decryption key.  These values are sent on-chain to the DON, and only the DON can decrypt them.  

* Once the DON receives the encrypted payload, the DON accesses your OpenAI key, decrypts it, performs the OpenAI request, and then deletes the table.  Godot would also perform a follow-up sanity check to ensure the table is deleted.

