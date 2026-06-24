// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";






contract GuildBankPassport is ERC1155, Ownable, ERC1155Pausable, ERC1155Supply, ERC1155Burnable {
    





    modifier onlyServer {
        require(msg.sender == ServerWallet);
        _;
    }
    address public ServerWallet;
    event ServerWalletMod(address Wallet, uint256 Time);
    function addServerWallet(address _Wallet) public onlyOwner{
        ServerWallet = _Wallet;
        emit ServerWalletMod(_Wallet , block.timestamp);
    }



    












    constructor(address initialAuthority)
        ERC1155("GuildBankPassport")
        Ownable(initialAuthority)
    {
        
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        internal
    {
        _mint(account, id, amount, data);
    }


    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        if (from != address(0)) {
            require(to == address(0));
        }        
        super._update(from, to, ids, values);
    }

 
    // Burn tokens (public, but checks ownership or approval)
    function burn(address account, uint256[] memory ids, uint256[] memory values) public {
        require(msg.sender == account);
        super._update(account, address(0), ids, values);
    }

    function setApprovalForAll(address, bool) public pure override {
        revert("Soulbound: approvals not allowed");
    }


    /**


        // Basic Open zepplin functions UP


     */
    /**


        // Custom Code DOWN


     */







    struct structPassport {
        string ipfsProfilePic;
        address ownerAddress;
        string ipfsUserName;
        string handle;
        string statusMsg;
        uint256 accountCreated;
        bool isMinor;
        string userPassword;
        uint256 passportID;
    }


    uint256 public passportCounter;
    mapping(address => structPassport) public Passport;
    mapping(address => bool) public hasPassport;



    mapping(address => mapping(uint256 => bool)) public ToSAccepted;
    uint256 TosId;
    string ToSLink;
    mapping(uint256 => string) public IdtoLinkMapping;




    function returnToS() public view returns(string memory){
        return ToSLink;
    }

    function upDateToS(string memory _ToSLink) public onlyOwner {
        TosId++;
        ToSLink = _ToSLink;
        IdtoLinkMapping[TosId] = _ToSLink;
    }

    function acceptToS() public {
        require(hasPassport[msg.sender]);
        ToSAccepted[msg.sender][TosId] = true;
    }
    function rejectToS() public {
        ToSAccepted[msg.sender][TosId] = false;
        if(hasPassport[msg.sender]){
            deletePassport();
        }

    }



    function serverCreatePassport(address _user, string memory _profilePic, string memory _userName, string memory _handle, string memory _statusMSG, bool _TOS, bool _minor, string memory _password) public onlyServer{
        require(!hasPassport[_user]);
        require(_TOS);
        Passport[_user].ipfsProfilePic = _profilePic;
        Passport[_user].ownerAddress = _user;
        Passport[_user].ipfsUserName = _userName;
        Passport[_user].handle = _handle;
        Passport[_user].statusMsg = _statusMSG;
        Passport[_user].accountCreated = block.timestamp;
        Passport[_user].isMinor = _minor;
        Passport[_user].userPassword = _password;
        hasPassport[_user] = true;
        Passport[_user].passportID = passportCounter;

        passportCounter++;

        ToSAccepted[_user][TosId] = true;

        mint(_user, 0, 1, "0x");
    }
        // make the burn inputs arrays for social too
    function deletePassport() public{
        require(hasPassport[msg.sender]);
        hasPassport[msg.sender] = false;
        burn(msg.sender, 0, 1);
        delete Passport[msg.sender];
        if(hasSocialPassport[msg.sender]){
            deleteSocialPassport();
        }
    }


    function changePFP(string memory _profilePic) public{
        require(hasPassport[msg.sender]);
        Passport[msg.sender].ipfsProfilePic = _profilePic;
    }
    function changeUserName(string memory _userName) public{
        require(hasPassport[msg.sender]);
        Passport[msg.sender].ipfsUserName = _userName;
    }
    function changeHandle(string memory _handle) public{
        require(hasPassport[msg.sender]);
        Passport[msg.sender].handle = _handle;
    }
    function changeMSG(string memory _msg) public {
        require(hasPassport[msg.sender]);
        Passport[msg.sender].statusMsg = _msg;
    }
    function changePassword(string memory _password) public {
        require(hasPassport[msg.sender]);
        Passport[msg.sender].userPassword = _password;
    }
    function viewUserPassword(address _user) public view returns(string memory){
        return Passport[_user].userPassword;
    }







    struct structSocialPassport {
        string ipfsEmail;
        string ipfsChat;
        string ipfsForum;
        string ipfsTwitter;
        string ipfsStream;
        string ipfsLinkTree;
        string socials;
        string verified;
        string doxxed;
    }

    mapping(address => structSocialPassport) public SocialPassport;
    mapping(address => bool) public hasSocialPassport;


    function createSocialPassport() public {
        require(hasPassport[msg.sender]);
        require(!hasSocialPassport[msg.sender]);
        hasSocialPassport[msg.sender] = true;
        mint(msg.sender, 1, 1, "0x");
        emit SocialPassportOnline(block.timestamp, msg.sender);
    }
    event SocialPassportOnline (uint256 timeCreated, address player1);

 
    function deleteSocialPassport() public {
        require(hasSocialPassport[msg.sender]);
        hasSocialPassport[msg.sender] = false;
        burn(msg.sender, 1, 1);
        delete SocialPassport[msg.sender];
    }

    function addEmail(string memory _data) public {
        require(hasSocialPassport[msg.sender]);
        SocialPassport[msg.sender].ipfsEmail = _data;
    }
    function addChat(string memory _data) public {
        require(hasSocialPassport[msg.sender]);
        SocialPassport[msg.sender].ipfsChat = _data;
    }
    function addForum(string memory _data) public {
        require(hasSocialPassport[msg.sender]);
        SocialPassport[msg.sender].ipfsForum = _data;
    }
    function addTwitter(string memory _data) public {
        require(hasSocialPassport[msg.sender]);
        SocialPassport[msg.sender].ipfsTwitter = _data;
    }
    function addLinkTree(string memory _data) public  {
        require(hasSocialPassport[msg.sender]);
        SocialPassport[msg.sender].ipfsLinkTree = _data;
    }
    function addStream(string memory _data) public  {
        require(hasSocialPassport[msg.sender]);
        SocialPassport[msg.sender].ipfsStream = _data;
    }
    function addSocials(string memory _data, address _User) public onlyServer {
        SocialPassport[_User].socials = _data;
    }
    function addVerified(string memory _data , address _User) public onlyServer {
        SocialPassport[_User].verified = _data;
    }function addDoxxed(string memory _data, address _User) public onlyServer {
        SocialPassport[_User].doxxed = _data;
    }



}