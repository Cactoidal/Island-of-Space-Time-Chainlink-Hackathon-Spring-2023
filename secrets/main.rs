use ethers::{core::{types::{Chain, Address}}, utils::*, signers::*, providers::*, prelude::SignerMiddleware};
use ethers_contract::{abigen};
use std::{convert::TryFrom, sync::Arc};
use openssl::{sha::sha512, symm::*};
use hmac_sha256::HMAC;
use secp256k1::{Secp256k1, SecretKey, PublicKey};
use rand::Rng;
use serde_json::json;
use base64::{Engine as _, engine::general_purpose};
use ethers_core::*;

fn main() {
    try_encrypt("test", "test", "test", "test");
}

abigen!(
    FunctionsContract,
    "./src/Functions_ABI.json",
    event_derives(serde::Deserialize, serde::Serialize)
);


// Parameters to be encoded would include the reader biscuit, table name, 
// SxT access token, and the decryption key for the encrypted openAI API key
#[tokio::main]
async fn try_encrypt(_biscuit: &str, _table: &str, _token: &str, _key: &str) -> Result<(), Box<dyn std::error::Error>> {

    // Get the user's private key for signing
    // let signing_key = Wallet::decrypt_keystore("./keys/path", "password").unwrap();

    // For demonstration, we'll just create a temporary key:
    let signing_key = Wallet::new(&mut rand::thread_rng());

    let prewallet: LocalWallet = signing_key;
        
    let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

    
    // Secrets go here and become a stringified JSON
    // Will be converted to bytes below before hashing
    let message_JSON = json!({
        "readerBiscuit": _biscuit,
        "tableName": _table,
        "authToken": _token,
        "decryptionKey": _key

    });

    // Sign the secrets
    let message_hash = keccak256(&message_JSON.to_string().as_bytes());

    let pre_signature = wallet.sign_message(message_hash).await.unwrap();

    // Add 0x 
    let signature = format!("0x{}",pre_signature.to_string());

    // Create payload
    let payload = json!({
        "message": message_JSON,
        "signature": signature
    });


    // Get the DON public key for encrypting, 
    // remove the 0x and add compression flag
    let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/").expect("could not instantiate HTTP Provider");

    let client = SignerMiddleware::new(provider, wallet.clone());

    let contract_address: Address = "0x069613819CB853C939AcC7A2b607A68B4EC41695".parse().unwrap();

    let contract = FunctionsContract::new(contract_address.clone(), Arc::new(client.clone()));

    let pre_DON_public_key1 = contract.get_don_public_key().call().await.unwrap().to_string();

    let pre_DON_public_key2 = match pre_DON_public_key1.char_indices().nth(*&2 as usize) {
        Some((pos, _)) => (&pre_DON_public_key1[pos..]).to_string(),
        None => "".to_string(),
        };

    let DON_public_key = hex::decode(format!("04{}",pre_DON_public_key2)).unwrap();


    // Create the ephemeral public key
    let secp = Secp256k1::new();
    let ephemeral_secret_key = SecretKey::new(&mut rand::thread_rng());
    let ephemeral_public_key = PublicKey::from_secret_key(&secp, &ephemeral_secret_key).serialize();
    

    // Derive the shared secret 
    let converted_DON_key = PublicKey::from_slice(&DON_public_key).unwrap();

    let shared_secret = secp256k1::ecdh::SharedSecret::new(&converted_DON_key, &ephemeral_secret_key);


    // Create the encryption key
    // Hash the shared secret, hex the hash, 
    // Slice the first 32 characters, grab the mac key, then convert key slice to bytes    
    let sha_key = hex::encode(sha512(&shared_secret.secret_bytes()));

    let key_slice = match sha_key.char_indices().nth(*&0 as usize) {
    Some((pos, _)) => (&sha_key[pos..32]).to_string(),
    None => "".to_string(),
    };

    let mac_key = match sha_key.char_indices().nth(*&31 as usize) {
    Some((pos, _)) => (&sha_key[pos..32]).to_string(),
    None => "".to_string(),
    };

    let encrypting_key = &key_slice.into_bytes();


    // Get iv
    // (16 random bytes)
    let iv = rand::thread_rng().gen::<[u8; 16]>();

    // Set Cipher
    let cipher = Cipher::aes_256_cbc();

    // Encrypt the payload with the cipher, encryption key, and iv
    let ciphertext = encrypt(
        cipher,
        &encrypting_key,
    Some(&iv),
        payload.to_string().as_bytes()).unwrap();


    // Create the mac
    let mut mac_data = Vec::with_capacity(iv.len() + ciphertext.len() + ephemeral_public_key.len());
    mac_data.extend(&iv);
    mac_data.extend(&ephemeral_public_key);
    mac_data.extend(&ciphertext);

    let mac = HMAC::mac(&mac_data, mac_key);


    // Concatenate iv, ephemkey, mac, and ciphertext
    let mut packed_data: Vec<u8> = Vec::with_capacity(iv.len() + ciphertext.len() + ephemeral_public_key.len() + mac.len());
    packed_data.extend(&iv);
    packed_data.extend(&ephemeral_public_key);
    packed_data.extend(&mac);
    packed_data.extend(&ciphertext);

   
   // Encode in Standard Base64 (RFC 4648) 
   let converted: String = general_purpose::STANDARD_NO_PAD.encode(packed_data);
    
    
    // Create JSON for DON usage
    let final_JSON = json!({
        "0x0": &converted
    });

    
    // To send the transaction to Functions, 
    // first convert the JSON to ethereum Bytes
    
    // let secrets: ethers::types::Bytes = ethers::types::Bytes::from(final_JSON.to_string().into_bytes());

    // Send transaction 
    
    // let tx = contract.execute_request(secrets, 120, 300000).send().await.unwrap().await.unwrap();

    // println!("Transaction Receipt: {}", serde_json::to_string(&tx)?);

    Ok(())

}
