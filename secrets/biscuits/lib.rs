extern crate biscuit_auth as biscuit;


use gdnative::{prelude::*, object::ownership};
use biscuit_auth::{KeyPair, Biscuit, error::*};
use ethers::{core::{k256::*, abi::{Abi,struct_def::StructFieldType}, types::*}, utils::*, signers::*, providers::*, prelude::SignerMiddleware};
use ethers_contract::{Contract, abigen};
use std::{convert::TryFrom, sync::Arc};

//Creates callable objects in Godot
fn init(handle: InitHandle) {

    handle.add_class::<BiscuitGenerator>();
    handle.add_class::<KeyGen>();
}

pub trait ToVariant {
    fn to_variant(&self) -> Variant;
}

impl ToVariant for Token {
    fn to_variant(&self) -> Variant {todo!()}
}

impl ToVariant for biscuit::Biscuit {
    fn to_variant(&self) -> Variant {todo!()}
}

impl ToVariant for KeyPair {
    fn to_variant(&self) -> Variant {todo!()}
}

#[derive(NativeClass, Debug, ToVariant, FromVariant)]
#[inherit(Node)]
struct BiscuitGenerator;

#[methods]
impl BiscuitGenerator {
    fn new(_owner: &Node) -> Self {
        BiscuitGenerator
    }

    
    #[method]
    fn generate_biscuits(mut blank: PoolArray<GodotString>, sxtfact1: GodotString, sxtfact2: GodotString, sxtfact3: GodotString, sxtfact4: GodotString) -> PoolArray<GodotString> {
        //Create public and private biscuit keypair
        let root = KeyPair::new();
        let public: GodotString = root.public().to_bytes_hex().to_string().into();
        blank.push(public);
        let private: GodotString = hex::encode(root.private().to_bytes()).to_string().into();
        blank.push(private);

        //Use biscuit facts to create a pair of biscuits: 
        //The creator biscuit, used by Godot to upload the encrypted openAI key to SxT
        //The reader biscuit, used by the DON to read and destroy the SxT table
        let fact1: &str = &sxtfact1.to_string();
        let fact2: &str = &sxtfact2.to_string();
        let fact3: &str = &sxtfact3.to_string();
        let fact4: &str = &sxtfact4.to_string();

        let mut creator_biscuit = Biscuit::builder();
        creator_biscuit.add_fact(fact1).unwrap();
        creator_biscuit.add_fact(fact2).unwrap();
        blank.push(String::from_utf8(creator_biscuit.build(&root).unwrap().to_base64().unwrap().into_bytes()).unwrap().into());

        let mut reader_biscuit = Biscuit::builder();
        reader_biscuit.add_fact(fact3).unwrap();
        reader_biscuit.add_fact(fact4).unwrap();
        blank.push(String::from_utf8(reader_biscuit.build(&root).unwrap().to_base64().unwrap().into_bytes()).unwrap().into());

        //Return to Godot
        blank
      
    }
}

#[derive(NativeClass, Debug, ToVariant, FromVariant)]
#[inherit(Node)]
struct KeyGen;

#[methods]
impl KeyGen {
    fn new(_owner: &Node) -> Self {
        KeyGen
    }

    #[method]
    fn generate_keys(password: GodotString) {
        
        let mut rng = rand::thread_rng();
    
        let keys = Wallet::new_keystore("./lolkeys", &mut rng, password.to_string(), Some("path"));

    }

}


godot_init!(init);
