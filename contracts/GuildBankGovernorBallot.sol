// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;



import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "https://github.com/RollaProject/solidity-datetime/blob/master/contracts/DateTime.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DateTime.sol";



    interface IDAOcoinAddress is IERC20{
        function showVotingUnits(address account) external view returns (uint256);
    }






contract GuildBankGovernorBallot is Ownable, ReentrancyGuard {




    function setElection(address _Address) public onlyOwner {
        require(ElectionAddress == address(0));
        ElectionAddress = _Address;
    }


    address public ElectionAddress;
    IDAOcoinAddress public DAOcoinAddress;
    address public GuildBankPassportAddress;



    constructor(
    address _me, address _DAOcoinAddress, address _GuildBankPassportAddress
    )
    Ownable(_me)
    {
        DAOcoinAddress = IDAOcoinAddress(_DAOcoinAddress);
        GuildBankPassportAddress = _GuildBankPassportAddress;
        ElectionCounter = 0;
    }


    modifier onlyPassport() {
        require(IERC1155(GuildBankPassportAddress).balanceOf(msg.sender, 0) == 1, "no passport");
        _;
    }

    function readAccountDAOcoinVotingPower(address account) internal view returns (uint256) {
        return DAOcoinAddress.showVotingUnits(account);
    }

    modifier onlyDuringElectionSeason() {
        require(ElectionSeason);
        _;
    }

// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason
// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason
// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason
// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason// System ElectionSeason




        function startElection(uint256 _Counter) public {
            require(msg.sender == ElectionAddress);
            ElectionCounter = _Counter;
            ElectionSeason = true;
        }

        function endElection() public {
            require(msg.sender == ElectionAddress);
            ElectionSeason = false;
            delete topCandidatesCEO;
            delete topCandidatesCTO;
            delete topCandidatesCFO;
            delete topCandidatesCCO;
            delete topCandidatesCOO;
        }









    uint256 public ElectionCounter;
    bool public ElectionSeason;






 

    enum roleStatus {
        CEO, CTO, CFO, CCO, COO
    }
// System Self-Election
    event NewCanditateInTheBallot( uint256 ElectionCount, structCandidate Struct, address CanditateWallet);
    struct structCandidate {
        address candidateAddress;
        string ipfsLink; 
        uint256 votingScore;
        roleStatus role;
        uint256 ElectionSeasonCount;
    }

    mapping(address => structCandidate) public Candidates;







    function joinAsCandidate(string memory _ipfsLink, roleStatus _role) public onlyDuringElectionSeason nonReentrant onlyPassport{
        require(Candidates[msg.sender].ElectionSeasonCount != ElectionCounter);
        Candidates[msg.sender].candidateAddress =  msg.sender;
        Candidates[msg.sender].ipfsLink = _ipfsLink;
        Candidates[msg.sender].votingScore = 0;
        Candidates[msg.sender].role = _role;
        Candidates[msg.sender].ElectionSeasonCount = ElectionCounter;      
        emit NewCanditateInTheBallot(ElectionCounter, Candidates[msg.sender], msg.sender);
    }

// System Voting 
        // userVoted-------electionCounter--bool
    mapping(address => mapping(uint256 => bool)) public votedCEO;
    mapping(address => mapping(uint256 => bool)) public votedCTO;
    mapping(address => mapping(uint256 => bool)) public votedCFO;
    mapping(address => mapping(uint256 => bool)) public votedCCO;
    mapping(address => mapping(uint256 => bool)) public votedCOO;



    address[5] public topCandidatesCEO;
    address[5] public topCandidatesCTO;
    address[5] public topCandidatesCFO;
    address[5] public topCandidatesCCO;
    address[5] public topCandidatesCOO;



    function viewTopCandidatesCEOArray() view public returns(address[5] memory){
        return topCandidatesCEO;
    }
    function viewTopCandidatesCTOArray() view public returns(address[5] memory){
        return topCandidatesCTO;
    }
    function viewTopCandidatesCFOArray() view public returns(address[5] memory){
        return topCandidatesCFO;
    }
    function viewTopCandidatesCCOArray() view public returns(address[5] memory){
        return topCandidatesCCO;
    }
    function viewTopCandidatesCOOArray() view public returns(address[5] memory){
        return topCandidatesCOO;
    }


        // userVoted-------electionSeason--bool


    function voteCEO (address _candidate) public onlyDuringElectionSeason onlyPassport nonReentrant{
        require(Candidates[_candidate].role == roleStatus.CEO, "Not a CEO candidate");
        require(Candidates[_candidate].ElectionSeasonCount == ElectionCounter, "Wrong election season");
        require(!votedCEO[msg.sender][ElectionCounter], "Already voted for this role");
        votedCEO[msg.sender][ElectionCounter] = true;
        uint256 votingPower = readAccountDAOcoinVotingPower(msg.sender);
        Candidates[_candidate].votingScore += votingPower;
        updateTopCEO(_candidate);       
    }
    function updateTopCEO(address _candidate) internal {
        // Validate candidate score
        uint256 thisScore = Candidates[_candidate].votingScore;
        // Remove existing candidate to prevent duplicates
        for (uint8 i = 0; i < 5; i++) {
            if (topCandidatesCEO[i] == _candidate) {
                for (uint8 j = i; j < 4; j++) {
                    topCandidatesCEO[j] = topCandidatesCEO[j + 1]; // Shift left
                }
                topCandidatesCEO[4] = address(0); // Clear last slot
                break;
            }
        }
        // Find insertion index and shift array
        for (uint8 i = 0; i < 5; i++) {
            uint256 currentScore = topCandidatesCEO[i] == address(0) ? 0 : Candidates[topCandidatesCEO[i]].votingScore;
            if (thisScore > currentScore) {
                for (uint8 j = 4; j > i; j--) {
                    topCandidatesCEO[j] = topCandidatesCEO[j - 1]; // Shift right
                }
                topCandidatesCEO[i] = _candidate;
                break;
            }
        }
    }


    function voteCTO (address _candidate) public onlyDuringElectionSeason onlyPassport nonReentrant{
        require(Candidates[_candidate].role == roleStatus.CTO, "Not a CTO candidate");
        require(Candidates[_candidate].ElectionSeasonCount == ElectionCounter, "Wrong election season");
        require(!votedCTO[msg.sender][ElectionCounter], "Already voted for this role");
        votedCTO[msg.sender][ElectionCounter] = true;
        uint256 votingPower = readAccountDAOcoinVotingPower(msg.sender);
        Candidates[_candidate].votingScore += votingPower;
        updateTopCTO(_candidate);       
    }
    function updateTopCTO(address _candidate) internal {
        // Validate candidate score
        uint256 thisScore = Candidates[_candidate].votingScore;
        // Remove existing candidate to prevent duplicates
        for (uint8 i = 0; i < 5; i++) {
            if (topCandidatesCTO[i] == _candidate) {
                for (uint8 j = i; j < 4; j++) {
                    topCandidatesCTO[j] = topCandidatesCTO[j + 1]; // Shift left
                }
                topCandidatesCTO[4] = address(0); // Clear last slot
                break;
            }
        }
        // Find insertion index and shift array
        for (uint8 i = 0; i < 5; i++) {
            uint256 currentScore = topCandidatesCTO[i] == address(0) ? 0 : Candidates[topCandidatesCTO[i]].votingScore;
            if (thisScore > currentScore) {
                for (uint8 j = 4; j > i; j--) {
                    topCandidatesCTO[j] = topCandidatesCTO[j - 1]; // Shift right
                }
                topCandidatesCTO[i] = _candidate;
                break;
            }
        }
    }


    function voteCFO (address _candidate) public onlyDuringElectionSeason onlyPassport nonReentrant{
        require(Candidates[_candidate].role == roleStatus.CFO, "Not a CFO candidate");
        require(Candidates[_candidate].ElectionSeasonCount == ElectionCounter, "Wrong election season");
        require(!votedCFO[msg.sender][ElectionCounter], "Already voted for this role");
        votedCFO[msg.sender][ElectionCounter] = true;
        uint256 votingPower = readAccountDAOcoinVotingPower(msg.sender);
        Candidates[_candidate].votingScore += votingPower;
        updateTopCFO(_candidate);       
    }
    function updateTopCFO(address _candidate) internal {
        // Validate candidate score
        uint256 thisScore = Candidates[_candidate].votingScore;
        // Remove existing candidate to prevent duplicates
        for (uint8 i = 0; i < 5; i++) {
            if (topCandidatesCFO[i] == _candidate) {
                for (uint8 j = i; j < 4; j++) {
                    topCandidatesCFO[j] = topCandidatesCFO[j + 1]; // Shift left
                }
                topCandidatesCFO[4] = address(0); // Clear last slot
                break;
            }
        }
        // Find insertion index and shift array
        for (uint8 i = 0; i < 5; i++) {
            uint256 currentScore = topCandidatesCFO[i] == address(0) ? 0 : Candidates[topCandidatesCFO[i]].votingScore;
            if (thisScore > currentScore) {
                for (uint8 j = 4; j > i; j--) {
                    topCandidatesCFO[j] = topCandidatesCFO[j - 1]; // Shift right
                }
                topCandidatesCFO[i] = _candidate;
                break;
            }
        }
    }


    function voteCCO (address _candidate) public onlyDuringElectionSeason onlyPassport nonReentrant{
        require(Candidates[_candidate].role == roleStatus.CCO, "Not a CCO candidate");
        require(Candidates[_candidate].ElectionSeasonCount == ElectionCounter, "Wrong election season");
        require(!votedCCO[msg.sender][ElectionCounter], "Already voted for this role");
        votedCCO[msg.sender][ElectionCounter] = true;
        uint256 votingPower = readAccountDAOcoinVotingPower(msg.sender);
        Candidates[_candidate].votingScore += votingPower;
        updateTopCCO(_candidate);       
    }
    function updateTopCCO(address _candidate) internal {
        // Validate candidate score
        uint256 thisScore = Candidates[_candidate].votingScore;
        // Remove existing candidate to prevent duplicates
        for (uint8 i = 0; i < 5; i++) {
            if (topCandidatesCCO[i] == _candidate) {
                for (uint8 j = i; j < 4; j++) {
                    topCandidatesCCO[j] = topCandidatesCCO[j + 1]; // Shift left
                }
                topCandidatesCCO[4] = address(0); // Clear last slot
                break;
            }
        }
        // Find insertion index and shift array
        for (uint8 i = 0; i < 5; i++) {
            uint256 currentScore = topCandidatesCCO[i] == address(0) ? 0 : Candidates[topCandidatesCCO[i]].votingScore;
            if (thisScore > currentScore) {
                for (uint8 j = 4; j > i; j--) {
                    topCandidatesCCO[j] = topCandidatesCCO[j - 1]; // Shift right
                }
                topCandidatesCCO[i] = _candidate;
                break;
            }
        }
    }


    function voteCOO (address _candidate) public onlyDuringElectionSeason onlyPassport nonReentrant{
        require(Candidates[_candidate].role == roleStatus.COO, "Not a COO candidate");
        require(Candidates[_candidate].ElectionSeasonCount == ElectionCounter, "Wrong election season");
        require(!votedCOO[msg.sender][ElectionCounter], "Already voted for this role");
        votedCOO[msg.sender][ElectionCounter] = true;
        uint256 votingPower = readAccountDAOcoinVotingPower(msg.sender);
        Candidates[_candidate].votingScore += votingPower;
        updateTopCOO(_candidate);       
    }
    function updateTopCOO(address _candidate) internal {
        // Validate candidate score
        uint256 thisScore = Candidates[_candidate].votingScore;
        // Remove existing candidate to prevent duplicates
        for (uint8 i = 0; i < 5; i++) {
            if (topCandidatesCOO[i] == _candidate) {
                for (uint8 j = i; j < 4; j++) {
                    topCandidatesCOO[j] = topCandidatesCOO[j + 1]; // Shift left
                }
                topCandidatesCOO[4] = address(0); // Clear last slot
                break;
            }
        }
        // Find insertion index and shift array
        for (uint8 i = 0; i < 5; i++) {
            uint256 currentScore = topCandidatesCOO[i] == address(0) ? 0 : Candidates[topCandidatesCOO[i]].votingScore;
            if (thisScore > currentScore) {
                for (uint8 j = 4; j > i; j--) {
                    topCandidatesCOO[j] = topCandidatesCOO[j - 1]; // Shift right
                }
                topCandidatesCOO[i] = _candidate;
                break;
            }
        }
    }


   


}