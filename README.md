# Island of Space & Time


## Summoning

Dynamically create in-game images using artificial intelligence, with parameters bound by a smart contract.  With SxT, images are shared with all players, without needing to connect to a centralized server.  Built using Godot and Godot-Rust.


>WASD/Arrow keys to move

>Mouse to look

>E to interact

>C to capture/uncapture mouse



## Embark

You should need only the game client to enter the Island.  However, if you want to summon creatures, you will need to provide your own OpenAI API key.  Please note that you will incur the usual fees for generating images.  Also, if you don't want to rely on the on-chain SxT relay, you may provide your own REFRESH token.  Otherwise, please leave that field blank.

Be aware that for the purposes of the demo, all players will be sharing the same embedded keystore.  If you run out of gas, please top off at the Mumbai MATIC faucet here:

https://faucet.polygon.technology

The address is 0xa63972A60D577D4c40A84eDABE232B945714Bce3.



## Secrets

Image generation works by taking your OpenAI API key, performing a query, receiving a base64 string, and uploading that string to Space and Time.

**Currently, no Chainlink Functions call takes place, and your OpenAI API key is not passed to a DON.  Godot instead handles the API call and uploads the image by itself.**  Chainlink Functions' HTTP Maximum request length is 2kb, while the base64 strings from OpenAI are approximately 250kb.

I've designed a system mimicking the Github Gist system that would instead use SxT tables as a means of passing secrets to the Chainlink DON, but Functions currently does not accept Inline secrets, therefore I cannot easily test it.  You can find the code for this implementation under the [secrets folder](secrets).  The scheme would work as follows:

* Godot encrypts your OpenAI API key, creates a new SxT biscuit, uses the biscuit to create a permissioned table on SxT, and places the encrypted key there.  

* Godot then uses the DON public key to encrypt the access biscuit, the access token, the table's randomized name, and the encrypted OpenAI key's decryption key.  These values are sent on-chain to the DON, and only the DON can decrypt them.  

* Once the DON receives the encrypted payload, the DON accesses your OpenAI key, decrypts it, performs the OpenAI request, and then deletes the table.  Godot would also perform a follow-up sanity check to ensure the table is deleted.



## How Images Appear in the Godot Client

To make sure that only images generated by the smart contract will show up in the game, each image must prove its provenance by having an on-chain, DON-generated hash that matches its associated hash on the SxT table.  

As part of the image generation process, the DON would produce this hash and map it on-chain to the image's ID, in addition to placing this hash into the SxT table along with the image's base64 string.  This will initialize the "creature object" and allow it to appear in the game.

When pulling strings from the SxT image table, the Godot client will cross-check the hash associated with each image ID with the hashes on-chain.  If the hashes do not match, the Godot client will not load the image into the game.

Because the Island does not currently make use of Chainlink Functions, this cross-checking feature has not yet been implemented.
