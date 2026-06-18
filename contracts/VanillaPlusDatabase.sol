// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/access/Ownable.sol";

contract VanillaPlusDatabase is Ownable {

    // mapping(string => bool) hashWeekly;
    // mapping(string => bool) hashDaily;
    // mapping(address =>mapping(string => bool)) addressToHashMap;
    // event hashMinted(address, uint256);


    // function addressToHash (address _accountname, string memory _hash, bool _daily, bool _weekly) public{
    //     addressToHashMap[_accountname][_hash] = false;
    //     hashDaily[_hash] = _daily;
    //     hashWeekly[_hash] = _weekly;
    //     emit hashMinted(_accountname, block.timestamp);

    // }
    // function cashDailyHash (address _accountname, string memory _hash) public{
    //     require(hashDaily[_hash] = true);
    //     addressToHashMap[_accountname][_hash] = true;
    //     hashDaily[_hash] = true;
    // }
    // function cashWeeklyHash (address _accountname, string memory _hash) public{
    //     require(hashDaily[_hash] = false);
    //     addressToHashMap[_accountname][_hash] = true;
    //     hashWeekly[_hash] = true;
    // }
    constructor(
        address initialOwner,
        address _globalBoDTreasury
        )
        Ownable(initialOwner)
    {
        GlobalBoDTreasury = _globalBoDTreasury;
    }
        address GlobalBoDTreasury;
        address ServerWallet;


        function setServerWallet (address _serverWallet) public {
            require(msg.sender == GlobalBoDTreasury);
            ServerWallet = _serverWallet;
        }


    //      userName           Hash     minted?
    mapping(string => mapping(string => bool)) UserToHash;
    mapping(string => bool) IsDaily;
    mapping(string => bool) IsWeekly;

    function insertHash(string memory _userName, string memory _hash, bool _isDaily) public{
        require(msg.sender == ServerWallet);
        UserToHash[_userName][_hash] = false;
        if(_isDaily == true) {
            IsDaily[_hash] = true;
        }else{
            IsWeekly[_hash] = true;
        }
    }

    function viewIsDaily(string memory _hash) view public returns(bool){
        return(IsDaily[_hash]);
    }
    function viewIsWeekly(string memory _hash) view public returns(bool){
        return(IsWeekly[_hash]);
    }


    function cashInHash(string memory _userName, string memory _hash, bool _isDaily) public{
        require(msg.sender == ServerWallet);
        UserToHash[_userName][_hash] = true;
    }

}

