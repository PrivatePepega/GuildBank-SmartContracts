// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";




    interface ILocalBoD{
        function isBoD(address _user) external view returns(bool);
    }



contract GuildBankCredit is ERC20, Ownable, ERC20Permit, ERC20Capped {



    address public DAOTreasuryContract;
    ILocalBoD public LocalBoD;
    address public LocalBoDTreasury;

    function setLocalDAOTreasury(address _TreasuryContract) public onlyOwner{
        require(DAOTreasuryContract == address(0));
        DAOTreasuryContract = _TreasuryContract;
    }
    function setLocalBoD(address _contract) public onlyOwner{
        require(address(LocalBoD) == address(0));
        LocalBoD = ILocalBoD(_contract);
    }
    function setLocalBoDTreasury(address _localBoD) public onlyOwner{
        require(LocalBoDTreasury == address(0));
        LocalBoDTreasury = _localBoD;
    }











    constructor(address _me, uint256 cap_, uint256 _amountPerMint, string memory _Name, string memory _Symbol)
        ERC20(_Name, _Symbol)
        Ownable(_me)
        ERC20Permit(_Name)
        ERC20Capped(cap_)
    {
        amountPerMint = _amountPerMint;
        isPaused = false;
    }


    function decimals() public pure override returns (uint8) {
        return 8;
    }


    modifier onlyBoD {
        require(msg.sender == LocalBoDTreasury);
        _;
    }


    uint256 public amountPerMint;
    event halfLife(uint256 value, uint256 _time);
    function halfLifeMint() public onlyOwner{
        amountPerMint = amountPerMint/2;
        emit halfLife(amountPerMint, block.timestamp);
    }


    event noMintPunishment(address _user, uint256 _time);
    function NoMintPunishment() public {
        require(!isPaused);
        require(block.timestamp >= nextMintable);
        nextMintable = block.timestamp + 2 days;
        _mint(msg.sender, amountPerMint);
        mintCounter++;
        emit noMintPunishment (msg.sender, block.timestamp);
    }








    event DAOCoinPaused(bool _pause, uint256 time);
    bool public isPaused; 
    function pauseMinting(bool _pause) public onlyBoD{
        isPaused = _pause;
        emit DAOCoinPaused(_pause, block.timestamp);
    }



    event AddNoTaxAddress(address _address, uint256 _time);
    event RemoveNoTaxAddress(address _address, uint256 _time);
    mapping(address => bool) public NoTaxAddress;
    function addNoTax(address _address) public onlyBoD{
        NoTaxAddress[_address] = true;
        emit AddNoTaxAddress(_address, block.timestamp);
    }
    function removeNoTax(address _address) public onlyBoD{
        NoTaxAddress[_address] = false;
        emit RemoveNoTaxAddress(_address, block.timestamp);
    }

    function viewNoTaxAddress (address _taxAddress) view public returns(bool){
        return(NoTaxAddress[_taxAddress]);
    }
















    event MintingBy(address indexed minter, uint256 time);
    uint256 public mintCounter;
    uint256 public nextMintable;
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;


    function Mint() public {
        require(isPaused == false);
        require(LocalBoD.isBoD(msg.sender));
        require(block.timestamp >= nextMintable);
        uint256 currentDay = block.timestamp / 1 days;
        nextMintable = (currentDay + 1) * SECONDS_PER_DAY;
        _mint(LocalBoDTreasury, amountPerMint);
        emit MintingBy(msg.sender, block.timestamp);
        mintCounter++;
    }








    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        require(value > 0);
        if (from == address(0)) {
            uint256 maxSupply = cap();
            uint256 supply = totalSupply();
            if (supply + value > maxSupply) {
                revert ERC20ExceededCap(supply, maxSupply);
            }
            uint256 taxAmount = (value * 20) / 100;
            uint256 amountAfterTax = value - taxAmount;
            super._update(from, to, amountAfterTax);
            super._update(from, DAOTreasuryContract, taxAmount);
        }
        else{
            if(NoTaxAddress[to] || NoTaxAddress[from]){
                    super._update(from, to, value);
            }else{
                uint256 taxAmount = (value * 2) / 1000;
                uint256 amountAfterTax = value - taxAmount;
                super._update(from, to, amountAfterTax);
                super._update(from, DAOTreasuryContract, taxAmount);
            }
        }
    }
    
}
