// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Derived from https://docs.chain.link/getting-started/intermediates-tutorial

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFQuery is VRFConsumerBaseV2 {

    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;

    address vrfCoordinator = 0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed;

    bytes32 s_keyHash =
        0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;

    uint32 callbackGasLimit = 250000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 3;
    address s_owner;
    uint public creatureId = 1;

    mapping(uint256 => uint256) public creatureIdByRequestId;
    mapping(uint256 => address) public creatureBySummoner;
    mapping(address => mapping(uint256 => uint[3])) public CreatureGenQuery;
    mapping(address => uint[]) public summonerCreatures;
    mapping(uint => bool) public creatureReturned;
    mapping(string => uint) public hashById;
    mapping(uint => CreatureObject) public creatureObjects;

    struct CreatureObject {
        bool instantiated;
        uint creatureId;
        uint location;
        uint demeanor;
        uint HP;
        uint Attack;
        string[] Abilities;
        bool questing;
        uint questEnd;
        bool questComplete;
    }

    event SummoningInitiated(uint256 indexed requestId, address indexed summoner);
    event QueryCreated(uint256 indexed requestId, uint indexed creatureId, uint[3] indexed result);


    constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
    }

    function getCreatureId() public view returns (uint) {
        return creatureId;
    }

    function generateQuery(
    ) public returns (uint256 requestId) {
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        creatureIdByRequestId[requestId] = creatureId;
        creatureBySummoner[creatureId] = msg.sender;
        summonerCreatures[msg.sender].push(creatureId);
        creatureId += 1;
        emit SummoningInitiated(creatureId, msg.sender);
    }


    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint creature = creatureIdByRequestId[requestId];
        creatureReturned[creature] = true;
        CreatureGenQuery[creatureBySummoner[creature]][creature] 
        =   [(randomWords[0] % 22) + 1, 
            (randomWords[1] % 13) + 1, 
            (randomWords[2] % 21) + 1];


        emit QueryCreated(requestId, creature, CreatureGenQuery[creatureBySummoner[requestId]][requestId]);
    }

    function checkReturn(uint creature) public view returns (string memory) {
        if (creatureReturned[creature] == false) {
            return "false";
            }
        else {
            return "true";
            }

    }

 
    function getQuery(uint creature) public view returns (string memory) {
        string memory Creature = getCreatureType(CreatureGenQuery[creatureBySummoner[creature]][creature][0]);
        string memory Adjective1 = getAdjective1(CreatureGenQuery[creatureBySummoner[creature]][creature][1]);
        string memory Adjective2 = getAdjective2(CreatureGenQuery[creatureBySummoner[creature]][creature][2]);
        
        string memory Query =  "A magnificent 16-bit pixel art ";
        Query = string.concat(Query, Adjective1);
        Query = string.concat(Query, " ");
        Query = string.concat(Query, Adjective2);
        Query = string.concat(Query, " ");
        Query = string.concat(Query, Creature);
        Query = string.concat(Query, " with a black background, video game asset, many colors");
        
        return Query;
    }

   
    function getCreatureType(uint256 id) private pure returns (string memory) {
        string[22] memory creatureTypes = [
            "gopher",
            "pixie",
            "dragon",
            "cat",
            "serpent",
            "wolf",
            "horse",
            "narwhal",
            "salamander",
            "falcon",
            "gorilla",
            "spider",
            "bat",
            "alligator",
            "dog",
            "lion",
            "kangaroo",
            "capybara",
            "llama",
            "frog",
            "penguin",
            "shark"
        ];
        return creatureTypes[id - 1];
    }

      function getAdjective1(uint256 id) private pure returns (string memory) {
        string[13] memory adjectives = [
            "glittering",
            "feathered",
            "scaly",
            "mercurial",
            "winged",
            "powerful",
            "verdant",
            "sparkling",
            "radiant",
            "vengeful",
            "courageous",
            "sublime",
            "jubilant"
        ];
        return adjectives[id - 1];
    }

    function getAdjective2(uint256 id) private pure returns (string memory) {
        string[21] memory adjectives = [
            "desert",
            "enigmatic",
            "mechanical",
            "cyber",
            "sunset",
            "cowboy",
            "warlike",
            "meditative",
            "glacier",
            "medieval",
            "renaissance",
            "art deco",
            "stained glass",
            "cold",
            "ancient",
            "skeletal",
            "glowing",
            "blazing",
            "calm",
            "irradiated",
            "bejeweled"
        ];
        return adjectives[id - 1];
    }


    function getSummoner(uint creature) public view returns (address) {
        return creatureBySummoner[creature];
    }

    function getCreatures(address summoner) public view returns (uint[] memory) {
        return summonerCreatures[summoner];
    }

    function getCreatureObjects(uint[] memory creatures) public view returns (CreatureObject[] memory objects) {
        objects = new CreatureObject[](creatures.length - 1);
        for (uint i = 1; i < creatures.length; i++) {
            objects[i-1] = getCreatureObject(creatures[i]);
        }
        return objects;
    }

    function initializeCreature(uint creature, string memory hash, uint location, uint demeanor) public {
        require(creatureBySummoner[creature] == msg.sender);
        require(creatureReturned[creature] == true);
        require(creatureObjects[creature].instantiated == false);
        CreatureObject memory newCreature;
        newCreature.instantiated = true;
        newCreature.creatureId = creature;
        newCreature.location = location;
        newCreature.demeanor = demeanor;
        newCreature.HP = 100;
        newCreature.Attack = 10;
        creatureObjects[creature] = newCreature;
        hashById[hash] = creature;
    }

    function checkInitialized(uint creature) public view returns (string memory) {
        if (creatureObjects[creature].instantiated == true) {
            return "true";
        }
        else {
            return "false";
        }

    }

    // 1: beach |  2: mountain  |  3: cave  
    function changeLocation(uint creature, uint location) public {
        require(creatureBySummoner[creature] == msg.sender);
        require(creatureObjects[creature].instantiated == true);
        require(location == 1 || location == 2 || location == 3);
        creatureObjects[creature].location = location;
    }

    // 1: friendly  |  2: aggressive
    function changeDemeanor(uint creature, uint demeanor) public {
        require(creatureBySummoner[creature] == msg.sender);
        require(creatureObjects[creature].instantiated == true);
        require(demeanor == 1 || demeanor == 2);
        creatureObjects[creature].demeanor = demeanor;
    }

    function quest(uint creature) public {
        require(creatureBySummoner[creature] == msg.sender);
        require(creatureObjects[creature].instantiated == true);
        require(creatureObjects[creature].questing == false);
        require(creatureObjects[creature].questComplete == false);
        creatureObjects[creature].questEnd = block.timestamp + 60;
        creatureObjects[creature].questing = true;
    }

    function checkQuest(uint creature) public view returns (string memory, uint time) {
        if (block.timestamp > creatureObjects[creature].questEnd) {
            return ("true", 0);
        }
        else {
            return ("false", block.timestamp - creatureObjects[creature].questEnd);
        }
    }

    function completeQuest(uint creature) public {
        require(creatureBySummoner[creature] == msg.sender);
        require(creatureObjects[creature].questing == true);
        require(block.timestamp > creatureObjects[creature].questEnd);
        creatureObjects[creature].HP = 125;
        creatureObjects[creature].Attack = 15;
        creatureObjects[creature].Abilities.push("Fire Breath");
        creatureObjects[creature].questing == false;
        //Just one quest for now
        creatureObjects[creature].questComplete = true;
    }

    function checkHash(string memory hash, uint creature) public view returns (string memory) {
        if (hashById[hash] == creature) {
            return "true";
        }
        else {
            return "false";
        }
    }

    function getCreatureObject(uint creature) public view returns (CreatureObject memory) {
        return creatureObjects[creature];
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}
