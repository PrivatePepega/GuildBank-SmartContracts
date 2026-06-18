// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



    interface IDAOcoinAddress is IERC20 { 
        function showVotingUnits(address account) external view returns (uint256);
        function getPastVotes(address account, uint256 timepoint) external view returns (uint256);
    }


contract GuildBankBoD is Ownable {





    address public ceoChair;
    address public ctoChair;
    address public cfoChair;
    address public ccoChair;
    address public cooChair;
    address public GuildBankChair;
    mapping(address => bool) public isBoD;
    address[16] public BoDChairs;





    address public GlobalGuildBankBoDTreasury;
    function setGlobalGuildBankBoDTreasury(address _contract) public onlyOwner{
        require(GlobalGuildBankBoDTreasury == address(0));
        GlobalGuildBankBoDTreasury = _contract;
    }




    function showBoDPower(address _user) view public returns(uint256) {
        uint256 power = 0;
        for(uint256 i = 0; i < BoDChairs.length; i++){
            if(BoDChairs[i] == _user){
                power++;
            }
        }
        return power;
    }






    function returnBoD() view public returns(address[16] memory){
        return BoDChairs;
    }





    address public LocalGovernorElection;
    IDAOcoinAddress public DAOcoinContract;
    address public GuildBankPassport;

    constructor(
        address initialOwner,
        address _GuildBankChair,
        address _LocalGovernorElection,
        address _DAOcoinContract,
        address _GuildBankPassportContractAddress
        )
        Ownable(initialOwner)
        {
        GuildBankChair = _GuildBankChair;
        initBOD();
        LocalGovernorElection = _LocalGovernorElection;
        DAOcoinContract = IDAOcoinAddress (_DAOcoinContract);
        GuildBankPassport = _GuildBankPassportContractAddress;
    }


    bool public innited;
    function initBOD() internal {
        require(innited == false);
        ceoChair = msg.sender;
        ctoChair = msg.sender;
        cfoChair = msg.sender;
        ccoChair = msg.sender;
        cooChair = msg.sender;
        BoDChairs[0] = GuildBankChair;
        BoDChairs[1] = msg.sender;
        BoDChairs[2] = msg.sender;
        BoDChairs[3] = msg.sender;
        BoDChairs[4] = msg.sender;
        BoDChairs[5] = msg.sender;
        BoDChairs[6] = msg.sender;
        BoDChairs[7] = msg.sender;
        BoDChairs[8] = msg.sender;
        BoDChairs[9] = msg.sender;
        BoDChairs[10] = msg.sender;
        BoDChairs[11] = ceoChair;
        BoDChairs[12] = ctoChair;
        BoDChairs[13] = cfoChair;
        BoDChairs[14] = ccoChair;
        BoDChairs[15] = cooChair;
        isBoD[msg.sender] = true;
        innited = true;
    }

    




    event WelcomeNewSenator(
        address indexed challenger,
        address indexed holder,
        uint256 challengerVotingPower,
        uint256 holderVotingPower
    );



    function challengeSenatorChair(uint8 index) public {
        require(IERC1155(GuildBankPassport).balanceOf(msg.sender, 0) == 1,"You dont own a GuildBankPassport");
        require(!isBoD[msg.sender]);
        require(index > 0 && index <= 10, "Invalid index");
        uint256 challengerPower = DAOcoinContract.getPastVotes(msg.sender, block.timestamp - 1 days);
        uint256 currentPower = BoDChairs[index] == address(0) ? 0 : DAOcoinContract.showVotingUnits(BoDChairs[index]);
        require(challengerPower > currentPower, "You lost the Duel fren. gg.");
        emit WelcomeNewSenator(msg.sender, BoDChairs[index], challengerPower, currentPower);
            isBoD[BoDChairs[index]] = false;
            BoDChairs[index] = msg.sender;
            isBoD[msg.sender] = true;
    }

    event NewCSuitChair (address _NewElected, string role, uint256 season);

    function newlyElectCSuit(address _NewElected, uint256 _role, uint256 _season)  public {
        require(msg.sender == LocalGovernorElection, "Only Governor Elections can call this function");
        if(_role == 1){
            isBoD[ceoChair] = false;
            isBoD[_NewElected] = true;
            ceoChair = _NewElected;   
            BoDChairs[11] = _NewElected;
            emit NewCSuitChair(_NewElected, "CEO", _season);
        }
        if(_role == 2){
            isBoD[ctoChair] = false;
            isBoD[_NewElected] = true;
            ctoChair = _NewElected;
            BoDChairs[12] = _NewElected;
            emit NewCSuitChair(_NewElected, "CTO", _season);
        }
        if(_role == 3){
            isBoD[cfoChair] = false;
            isBoD[_NewElected] = true;
            cfoChair = _NewElected;
            BoDChairs[13] = _NewElected;
            emit NewCSuitChair(_NewElected, "CFO", _season);
        }
        if(_role == 4){
            isBoD[ccoChair] = false;
            isBoD[_NewElected] = true;
            ccoChair = _NewElected;
            BoDChairs[14] = _NewElected;
            emit NewCSuitChair(_NewElected, "CCO", _season);
        }
        if(_role == 5){
            isBoD[cooChair] = false;
            isBoD[_NewElected] = true;
            cooChair = _NewElected;
            BoDChairs[15] = _NewElected;
            emit NewCSuitChair(_NewElected, "COO", _season);
        }
    }




// add function to replace GuildBankChair Address, Restricted by GuildBank
    event WelcomeGuildBankChairDirector(
        address indexed newPlayer,
        address indexed oldPlayer
    );
    function replaceGuildBankChair (address _newPlayer) public {
        require(msg.sender == GlobalGuildBankBoDTreasury, "Only GuildBankBoD can call this function");
        address oldPlayer = GuildBankChair;
        isBoD[GuildBankChair] = false;
        isBoD[_newPlayer] = true;
        GuildBankChair = _newPlayer;
        BoDChairs[0] = _newPlayer;
        emit WelcomeGuildBankChairDirector(_newPlayer, oldPlayer);
    }





    event LocalBoDChairForfeited (address indexed sender);

    function ForfeitChair(bool _Forfeit) public {
        require(isBoD[msg.sender], "You are not a BoD");
        require(_Forfeit == true, "You havnt forfeited");
        isBoD[msg.sender] = false;
        if(msg.sender == GuildBankChair){
            GuildBankChair = address(0);
            BoDChairs[0] = address(0);
        }
        if(msg.sender == ceoChair){ ceoChair = address(0); BoDChairs[11] = address(0); }
        if(msg.sender == ctoChair){ ctoChair = address(0); BoDChairs[12] = address(0); }
        if(msg.sender == cfoChair){ cfoChair = address(0); BoDChairs[13] = address(0); }
        if(msg.sender == ccoChair){ ccoChair = address(0); BoDChairs[14] = address(0); }
        if(msg.sender == cooChair){ cooChair = address(0); BoDChairs[15] = address(0); }
        for(uint8 i = 1; i <= 10; i++){
            if(BoDChairs[i] == msg.sender){
                BoDChairs[i] = address(0);
            }
        }
        emit LocalBoDChairForfeited(msg.sender);

    }
}






