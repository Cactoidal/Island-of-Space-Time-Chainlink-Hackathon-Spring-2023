 [main.rs](main.rs) is a Rust implementation of encryptWithPublicKey() from the eth-crypto.js library, currently used by the Chainlink Functions starter kit.  It attempts to replicate the chain of operations shown in the starter kit, eth-crypto.js, eccrypto.js, and node:crypto.js. It will successfully produce an aes256cbc output JSON and subsequently an encoded base64 string, but its reception by a DON is currently untested and likely will need tweaks for compatibility.
 
Example output:

{"0x0":"BzuUe84jy7sWgBzDGCv00AIPjC3npM0WAJVfhvFNwMawU1DUy9Gs+2Yn1IHGvoVcxBVsXFfIi+YnVw3DIEdfzoFgsmJE/DWb8j4o1/Pm+REQFUA7thNelHpBaAHR5KXQSD29rDa8YYn8o9LsrTfUBpUCUP6NvTy0yyWoPoD+8vYdwDvNOenS9O23wreRiEWT1nCD4T/prPSNxpHZA43eQugKDekChBVrXUT9oo/Sa2dhSpWywOMSBgpPfJX7/VjzPKMsrTEcu/bwL0FgdfeBERC6NOFlQuKDYh0azaplrKbKo4KjZ8FM/faQCH2zSEQtW2SZgpVHDH0ZmsWp6jLppH/uscgcziQYnY6escvtdOxB1/GdT6dM0Kxwug4Ck0cD2QcPsC9L0gKFIp9LxCHcKP3CHX/glTZmNAI7khEazwWykDBkg9KXYh+FJBqQVDybzw=="}
 
[lib.rs](/secrets/biscuits/lib.rs) is a Godot-Rust implementation of the biscuit-auth protocol used by Space & Time, allowing Godot to generate biscuits for creating and accessing SxT tables.

[secret_passer.gd](/secrets/biscuits/secret_passer.gd) is the Godot scene responsible for routing the user's secrets to the Godot-Rust module.
