// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";




    interface ILocalDAOElection{
        function getElectionSeason() external view returns(bool);
    }

    interface ILocalBoD{
        function isBoD(address _user) external view returns(bool);
    }

contract LocalBankDAOcoin is ERC20, Ownable, ERC20Permit, ERC20Votes, ERC20Capped {

    

    function setDaoTreasuryContract(address _daoTreasuryAddress) public onlyOwner{
        require(DAOTreasuryADDRESS == address(0));
        DAOTreasuryADDRESS = _daoTreasuryAddress;
    }
    function setLocalElectionContract(address _LocalDAOElection) public onlyOwner{
        require(address(LocalDAOElection) == address(0));
        LocalDAOElection = ILocalDAOElection(_LocalDAOElection);
    }

    function setLocalBoD(address _contract) public onlyOwner{
        require(address(LocalBoD) == address(0));
        LocalBoD = ILocalBoD(_contract);
    }
    function setDAOVault(address _contract) public {
        require(DAOVault == address(0));
        require(msg.sender == GlobalBoD);
        DAOVault = _contract;
    }
    function setOperator(address _Operator) public onlyOwner{
        require(Operator == address(0), "operator nos zero address");
        Operator = _Operator;
    }







    address public DAOTreasuryADDRESS; 
    ILocalDAOElection public LocalDAOElection;
    address public Operator;
    ILocalBoD public LocalBoD;
    address public DAOVault;
    address public GlobalBoD;




    constructor(address _me, uint256 cap_, uint256 _amountPerMint, string memory _Name, string memory _Symbol, address _globalBoD)
        ERC20(_Name, _Symbol)
        Ownable(_me)
        ERC20Permit(_Name)
        ERC20Capped(cap_)
    {
        amountPerMint = _amountPerMint;
        isPaused = false;
        GlobalBoD = _globalBoD;
    }



    function clock() public view override returns (uint48) {
        return uint48(block.timestamp);
    }

    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public pure override returns (string memory) {
        return "mode=timestamp";
    }



    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }



    modifier onlyOperator {
        require(msg.sender == Operator);
        _;
    }

   function decimals() public pure override returns (uint8) {
        return 8;
    }



    address public ServerWallet;
    event ServerWalletMod(address Wallet, uint256 Time);
    function addServerWallet(address _Wallet) public onlyOperator{
        ServerWallet = _Wallet;
        emit ServerWalletMod(_Wallet , block.timestamp);
    }
    function removeServerWallet() public onlyOperator{
        ServerWallet = address(0);
        emit ServerWalletMod(address(0) , block.timestamp);
    }










    uint256 public amountPerMint;
    event halfLife(uint256 value, uint256 _time);
    function halfLifeMint () public onlyOperator{
        amountPerMint = amountPerMint/2;
        emit halfLife(amountPerMint, block.timestamp);
    }







 




    function showVotingUnits(address account) public view returns (uint256) {
        return getVotes(account);
    }


    uint256 public burnCounter;

    function burn(uint256 value) public {
        require(msg.sender == DAOVault);
        uint256 taxAmount = (value * 2) / 1000;
        uint256 amountAfterTax = value - taxAmount;
        burnCounter += amountAfterTax;
        _burn(msg.sender, value);
    }

    function returnCap() public view returns(uint256){
        return cap();
    }




    function delegate(address _account) public override{
        if(LocalBoD.isBoD(msg.sender)){
            require(!LocalBoD.isBoD(msg.sender));
        }
        if(LocalDAOElection.getElectionSeason()){
            require(!LocalDAOElection.getElectionSeason());
        }else{
            super.delegate(_account);
        }
    }


    bool public isPaused; 
    event DAOCoinPaused(bool _pause, uint256 time);
    function pauseMinting(bool _pause) public onlyOperator{
        isPaused = _pause;
        emit DAOCoinPaused(isPaused, block.timestamp);
    }
    uint256 public lastMinted;
    event noMintPunishment(address _user, uint256 _time);
    function NoMintPunishment() public {
        require(!isPaused);
        require(block.timestamp >= lastMinted + 8 days);
        _mint(msg.sender, amountPerMint);
        lastMinted = block.timestamp;
        emit noMintPunishment (msg.sender, block.timestamp);
    }











    event MintingBy(address minter, uint256 _times);
    mapping(address => uint256) public MintCounter;
    function Mint(address _user, uint256 _times) public {
        require(_times <= 10);
        require(!isPaused);
        require(ServerWallet == msg.sender);
        uint256 mintThese = amountPerMint * _times;
        MintCounter[_user] +=  _times;
        _mint(_user, mintThese);
        lastMinted = block.timestamp;
        emit MintingBy(_user, _times);
    }





    // Override the _update function from ERC20CappedUpgradeable and ERC20Upgradeable
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes, ERC20Capped) {
        require(value > 0);
        if (from == address(0)) {
            uint256 maxSupply = cap();
            uint256 supply = totalSupply();
            if (supply + value  > maxSupply) {
                revert ERC20ExceededCap(supply, maxSupply);
            }
            uint256 taxAmount = (value * 20) / 100; 
            uint256 amountAfterTax = value - taxAmount;
            super._update(from, to, amountAfterTax);
            super._update(from, DAOTreasuryADDRESS, taxAmount);
        }else{
            bool electionSeason = LocalDAOElection.getElectionSeason();
                if(electionSeason){
                    require(!electionSeason);
                }else{
                    uint256 taxAmount = (value * 2) / 1000;
                    uint256 amountAfterTax = value - taxAmount;
                    super._update(from, to, amountAfterTax);
                    super._update(from, DAOTreasuryADDRESS, taxAmount);
                }
            }

        }
    
}
