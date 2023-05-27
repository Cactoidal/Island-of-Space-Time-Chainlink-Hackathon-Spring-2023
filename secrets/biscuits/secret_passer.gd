extends Node

var table_name
var auth_token = User.auth_token
var http_request_delete
var secret
var secret_decryption_key
var creator_biscuit
var reader_biscuit

	
func pass_secret():
	
	table_name = "x" + generate_hash()
	
	var sxt_fact1 = 'sxt:capability("ddl_create", "imaginary.' + table_name + '")' 
	var sxt_fact2 = 'sxt:capability("dml_insert", "imaginary.' + table_name + '")' 
	
	var sxt_fact3 = 'sxt:capability("dql_select", "imaginary.' + table_name + '")'
	var sxt_fact4 = 'sxt:capability("ddl_drop", "imaginary.' + table_name + '")' 
	
	var blank: PoolStringArray = []
  
  	# Create the biscuit keypair and generate the creator and reader biscuits
	var new_biscuit = Biscuit.generate_biscuits(blank, sxt_fact1, sxt_fact2, sxt_fact3, sxt_fact4)
	
	creator_biscuit = new_biscuit[2]
	reader_biscuit = new_biscuit[3]
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_table_created")
	http_request_delete = http_request

	var body = JSON.print({"sqlText": "CREATE TABLE IMAGINARY." + table_name +  " (ID VARCHAR, NAME VARCHAR, PRIMARY KEY (ID)) WITH \"public_key=" + new_biscuit[0] + ",access_type=permissioned\""})
	var error = http_request.request("https://hackathon.spaceandtime.dev/v1/sql/ddl", ["accept: application/json", "authorization: Bearer " + auth_token, "biscuit: " + creator_biscuit, "content-type: application/json"], true, HTTPClient.METHOD_POST, body)
	

func _table_created(result, response_code, headers, body):
	http_request_delete.queue_free()
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.connect("request_completed", self, "_secret_placed")
	http_request_delete = http_request
  
  	# This as-yet unimplemented function would use Godot-Rust to encrypt the user's openAI key
  	# in preparation for decryption by the DON using vanilla Node Crypto functions
  	var key_encrypt = User.encrypt(User.open_ai_key)
  
  	secret_decryption_key = key_encrypt[0]
  	secret = key_encrypt[1]
  
	var request_body = JSON.print({"resourceId": "IMAGINARY." + table_name, "sqlText": "INSERT INTO IMAGINARY." + table_name + "(ID, NAME) VALUES ('" + generate_hash() + "', '" + secret + "')"})
	var error = http_request.request("https://hackathon.spaceandtime.dev/v1/sql/dml", ["accept: application/json", "authorization: Bearer " + auth_token, "biscuit: " + creator_biscuit, "content-type: application/json"], true, HTTPClient.METHOD_POST, request_body)


func _secret_placed(result, response_code, headers, body):
	http_request_delete.queue_free()
  
  	#   SUMMONING WOULD TAKE PLACE HERE  *
	# Summoning will first encrypt secrets with the DON public key, then perform executeRequest()
  
	# Summon.try_encrypt(reader_biscuit, table_name, auth_token, secret_decryption_key)
	# query string and image table biscuit are on-chain


#For creating random table names and IDs	
func generate_hash():
	var hash_string = ""
	for number in range(24):
		randomize()
		var chunk = randi()%7777
		var chunk_string = str(chunk)
		if chunk < 1000:
			chunk_string = "0" + chunk_string
		if chunk < 100:
			chunk_string = "0" + chunk_string
		if chunk < 10:
			chunk_string = "0" + chunk_string
		hash_string += chunk_string
	return hash_string.sha256_text()
	

#Used for creating embedded keystore using Godot-Rust
func generate_secret_key(var password):
	#will overwrite existing keystore - check if one exists!
	KeyGen.generate_keys(password)
	

	
