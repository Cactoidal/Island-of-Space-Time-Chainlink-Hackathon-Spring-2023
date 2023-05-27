 [main.rs](main.rs) is a Rust implementation of encryptWithPublicKey() from the eth-crypto.js library, currently used by the Chainlink Functions starter kit.  It attempts to replicate the chain of operations shown in the starter kit, eth-crypto.js, eccrypto.js, and node:crypto.js. It will succesfully produce an aes256cbc output JSON and subsequently an encoded base64 string, but its reception by a DON is currently untested and likely will need tweaks for compatibility.
 
[lib.rs](/secrets/biscuits/lib.rs) is a Godot-Rust implementation of the biscuit-auth protocol used by Space & Time, allowing Godot to generate biscuits for creating and accessing SxT tables.  It also includes a simple function for generating an embedded keystore.  Both features have been tested, and they work.

[secret_passer.gd](/secrets/biscuits/secret_passer.gd) is the Godot scene responsible for routing the user's secrets to the Godot-Rust module.  It is also functional.
