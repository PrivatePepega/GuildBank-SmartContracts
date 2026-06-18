// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;



import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "https://github.com/RollaProject/solidity-datetime/blob/master/contracts/DateTime.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DateTime.sol";



    interface IGovernorTreasury {
        function NewSeasonTransfer(bytes calldata _data) external;
    }
    interface ILocalBoDAddress{
        function newlyElectCSuit(address _NewElected, uint256 _role, uint256 _season) external; 
    }

    interface IBallot{
        function viewTopCandidatesCEOArray() view external returns(address[5] memory);
        function viewTopCandidatesCTOArray() view external returns(address[5] memory);
        function viewTopCandidatesCFOArray() view external returns(address[5] memory);
        function viewTopCandidatesCCOArray() view external returns(address[5] memory);
        function viewTopCandidatesCOOArray() view external returns(address[5] memory);
        function startElection(uint256 _Counter) external;
        function endElection() external;
    }




contract GuildBankGovernorElection is Ownable, ReentrancyGuard {




    function setBallot(address _localBallot) public onlyOwner{
        require(address(Ballot) == address(0));
        Ballot = IBallot(_localBallot);
    }


    function setBoD(address _BoD) public onlyOwner{
        require(address(LocalBoDAddress) == address(0));
        LocalBoDAddress = ILocalBoDAddress(_BoD);
    }


    function setGovernorTreasury(address _GovernorTreasury) public onlyOwner{
        require(address(GovernorTreasury) == address(0));
        GovernorTreasury = IGovernorTreasury(_GovernorTreasury);
    }

    IBallot public Ballot;
    ILocalBoDAddress public LocalBoDAddress;
    IGovernorTreasury public GovernorTreasury;




    constructor(address _me)
    Ownable(_me)
    {
        ElectionCounter = 0;
    }



    function todayDate() public view returns(uint256 _year, uint256 _month, uint256 _day) {
        (uint256 year, uint256 month, uint256 day) = DateTime.timestampToDate(block.timestamp);
        return (year, month, day);
    }



    modifier onlyDuringElectionSeason() {
        require(ElectionSeason);
        _;
    }


    uint256 public ElectionCounter;
    bool public ElectionSeason;
    function getElectionSeason() public view returns(bool){
        return ElectionSeason;
    }

    
    uint256[2] public WinterElectionStart = [12, 1];
    uint256[2] public WinterElectionEnd = [12, 20];
    uint256[2] public SummerElectionStart = [6, 1];
    uint256[2] public SummerElectionEnd = [6, 20];



    event ElectionSeasonStarted (address person, uint256 month, uint256 day, uint256 year, uint256 ElectionCounter);
    event ElectionSeasonEnded (address person, uint256 month, uint256 day, uint256 year, uint256 ElectionCounter);
    uint256 public electionEndedTimer;

// Function to start the election
    function startElection() public {
        require(!ElectionSeason);
        (uint256 year, uint256 month, uint256 day) = todayDate();
        require(
            (month == WinterElectionStart[0] && day == WinterElectionStart[1]) ||
            (month == SummerElectionStart[0] && day == SummerElectionStart[1])
        );
        ElectionSeason = true;
        // we use this for CSuit to be able activate and endTimer is needed for this to work
        electionEndedTimer = 0;
        ElectionCounter ++;
        Ballot.startElection(ElectionCounter);
        emit ElectionSeasonStarted(msg.sender, month, day, year, ElectionCounter);
    }
    function endElection() public nonReentrant {
        require(ElectionSeason);
        (uint256 year, uint256 month, uint256 day) = todayDate();
        require(
            (month == WinterElectionEnd[0] && day == WinterElectionEnd[1]) ||
            (month == SummerElectionEnd[0] && day == SummerElectionEnd[1])
        );
        ElectionSeason = false;
        GovernorTreasury.NewSeasonTransfer("");
        electionEndedTimer = block.timestamp;
        getTopBallots();
        Ballot.endElection();
        emit ElectionSeasonEnded(msg.sender, month, day, year, ElectionCounter);
    }
    
 
    function getTopBallots () internal {
        topCandidatesCEO = Ballot.viewTopCandidatesCEOArray();
        topCandidatesCTO = Ballot.viewTopCandidatesCTOArray();
        topCandidatesCFO = Ballot.viewTopCandidatesCFOArray();
        topCandidatesCCO = Ballot.viewTopCandidatesCCOArray();
        topCandidatesCOO = Ballot.viewTopCandidatesCOOArray();
    }









    address[5] public topCandidatesCEO;
    address[5] public topCandidatesCTO;
    address[5] public topCandidatesCFO;
    address[5] public topCandidatesCCO;
    address[5] public topCandidatesCOO;


// System Activation Winning Candidate
    address public CEO;
    address public CTO;
    address public CFO;
    address public CCO;
    address public COO;



    function activationCEO() public {
        require(electionEndedTimer != 0);
        uint256 eligibleIndex = (block.timestamp - electionEndedTimer) / (3 days);
        for (uint8 i = 0; i < topCandidatesCEO.length; i++){
            if(topCandidatesCEO[i] == msg.sender){
                require(i <= eligibleIndex);
                CEO = msg.sender;
                LocalBoDAddress.newlyElectCSuit(msg.sender, 1, ElectionCounter);
                delete topCandidatesCEO;
                return;
            }
        }
    }
    function activationCTO() public {
        require(electionEndedTimer != 0);
        uint256 eligibleIndex = (block.timestamp - electionEndedTimer) / (3 days);
        for (uint8 i = 0; i < topCandidatesCTO.length; i++){
            if(topCandidatesCTO[i] == msg.sender){
                require(i <= eligibleIndex);
                CTO = msg.sender;
                LocalBoDAddress.newlyElectCSuit(msg.sender, 2, ElectionCounter);
                delete topCandidatesCTO;
                return;
            }
        }
    }
    function activationCFO() public {
        require(electionEndedTimer != 0);
        uint256 eligibleIndex = (block.timestamp - electionEndedTimer) / (3 days);
        for (uint8 i = 0; i < topCandidatesCFO.length; i++){
            if(topCandidatesCFO[i] == msg.sender){
                require(i <= eligibleIndex);
                CFO = msg.sender;
                LocalBoDAddress.newlyElectCSuit(msg.sender, 3, ElectionCounter);
                delete topCandidatesCFO;
                return;
            }
        }
    }
    function activationCCO() public{
        require(electionEndedTimer != 0);
        uint256 eligibleIndex = (block.timestamp - electionEndedTimer) / (3 days);
        for (uint8 i = 0; i < topCandidatesCCO.length; i++){
            if(topCandidatesCCO[i] == msg.sender){
                require(i <= eligibleIndex);
                CCO = msg.sender;
                LocalBoDAddress.newlyElectCSuit(msg.sender, 4, ElectionCounter);
                delete topCandidatesCCO;
                return;
            }
        }
    }
    function activationCOO() public {
        require(electionEndedTimer != 0);
        uint256 eligibleIndex = (block.timestamp - electionEndedTimer) / (3 days);
        for (uint8 i = 0; i < topCandidatesCOO.length; i++){
            if(topCandidatesCOO[i] == msg.sender){
                require(i <= eligibleIndex);
                COO = msg.sender;
                LocalBoDAddress.newlyElectCSuit(msg.sender, 5, ElectionCounter);
                delete topCandidatesCOO;
                return;
            }
        }
    }
// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason
// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason
// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason
// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason


}