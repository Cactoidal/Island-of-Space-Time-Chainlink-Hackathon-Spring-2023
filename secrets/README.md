 [main.rs](main.rs) is a Rust implementation of encryptWithSignature() currently used by the Chainlink Functions starter kit.  It attempts to replicate the chain of operations shown in the starter kit, eth-crypto.js, eccrypto.js, and node:crypto.js. It will produce an encoded base64 string composed of what is ostensibly the concatenated iv/ephemkey/ciphertext/mac, containing the JSON payload of the signed secrets JSON, but it still needs tweaks to be accepted by a DON.
 
Having conducted some testing, possible sticking points could be differences between rust's keccak256 and ethers.js' solidityKeccak256; differences between eth-crypto's sign() and rust's sign_message() (sign_typed_data() may be more appropriate); formatting differences between JSONs produced by the rust json! macro and JavaScript's JSON.stringify; or some yet-unknown difference or mistake resulting in a faulty output.
 
Example output:

`{"0x0":"lDaeE9aWQpiN9PTzc/nskgIMgUmKCyK/FZxTfMICCLUktT6JTQU4PruRNwfh8gauSDw2i819a6SxBq7k0VcXOWgQSQ6umfzZuHlHznQfH3Fyk5aSL4fBUCit5CUmU7dkYN0hNaS74FBDS3FfF2R99FJd8q7cvIrrVWhxYHB1jtJJXgqk/ardzjmUf9AkM3Z8sPBi91N3GaPTrHhg2H81iXQvHxWu8NMz7C8V7ohfDotBWHAOwEnOwHmMLgW/3c9bhyyDyi8DdqyYdv69w+uYXnbJ5jdh3vtipQz33/tSNBt3HYaGlzbDWrSUtBLPGgt/u2qccOoksteKWYafuwHLlbcfe66y4wgVvDhkLIOVFmSb5Sm3xnu/Zdn2W3lueXhG/K6tWY+SJAi3vAYeOb+4MF9+qjtG5NgLZ+8xSFsvlBU4"}`
 
[lib.rs](/secrets/biscuits/lib.rs) is a Godot-Rust implementation of the biscuit-auth protocol used by Space & Time, allowing Godot to generate biscuits for creating and accessing SxT tables.

[secret_passer.gd](/secrets/biscuits/secret_passer.gd) is the Godot script responsible for routing the user's secrets to the Godot-Rust module.
