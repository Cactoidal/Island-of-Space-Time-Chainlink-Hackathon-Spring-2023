#[method]
#[tokio::main]
async fn do_vrf(key: PoolArray<u8>) -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/")
  .expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214"
  .parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), 
  Arc::new(client.clone()));

let tx = contract.generate_query().send().await.unwrap().await.unwrap();


NewFuture(Ok(()))
}



#[method]
#[tokio::main]
async fn check_query_return(key: PoolArray<u8>, creature_id: i32, ui_node: Ref<Control>) 
  -> NewFuture {

let vec = &key.to_vec();

let keyset = &vec[..]; 
     
let prewallet : LocalWallet = LocalWallet::from_bytes(&keyset).unwrap();
    
let wallet: LocalWallet = prewallet.with_chain_id(Chain::PolygonMumbai);

let provider = Provider::<Http>::try_from("https://rpc-mumbai.maticvigil.com/")
  .expect("could not instantiate HTTP Provider");

//contract
let contract_address: Address = "0x5A5CDB35B69D6af1A3684E9C03e27881Ce559214"
  .parse().unwrap();

let client = SignerMiddleware::new(provider, wallet);

let contract = ChainlinkVRF::new(contract_address.clone(), 
  Arc::new(client.clone()));

let response = contract.check_return(U256::from(creature_id)).call().await.unwrap()
  .to_string().to_variant();

let node: TRef<Control> = unsafe { ui_node.assume_safe() };

unsafe {
    node.call("query_checked", &[contract.check_return(U256::from(creature_id))
  .call().await.unwrap().to_variant()])
};

NewFuture(Ok(()))

}

