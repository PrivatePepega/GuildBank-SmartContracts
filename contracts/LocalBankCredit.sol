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



contract LocalBankCredit is ERC20, Ownable, ERC20Permit, ERC20Capped {



    address public DAOTreasuryContract;
    ILocalBoD public LocalBoD;
    address public Operator;


    function setLocalDAOTreasuryContract(address _TreasuryContract) public onlyOwner{
        require(DAOTreasuryContract == address(0));
        DAOTreasuryContract = _TreasuryContract;
    }
    function setLocalBoD(address _contract) public onlyOwner{
        require(address(LocalBoD) == address(0));
        LocalBoD = ILocalBoD(_contract);
    }
    function setOperator(address _Operator) public onlyOwner{
        require(Operator == address(0));
        Operator = _Operator;
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


    modifier onlyOperator {
        require(msg.sender == Operator);
        _;
    }




    uint256 public amountPerMint;
    event halfLife(uint256 value, uint256 _time);
    function halfLifeMint() public onlyOperator{
        amountPerMint = amountPerMint / 2;
        emit halfLife(amountPerMint, block.timestamp);
    }


    uint256 public lastMinted;
    event noMintPunishment(address _user, uint256 _time);
    function NoMintPunishment() public {
        require(!isPaused);
        require(block.timestamp >= lastMinted + 2 days);
        _mint(msg.sender, amountPerMint);
        lastMinted = block.timestamp;
        emit noMintPunishment (msg.sender, block.timestamp);
    }

    function decimals() public pure override returns (uint8) {
        return 8;
    }




    event DAOCoinPaused(bool _pause, uint256 time);
    bool public isPaused; 
    function pauseMinting(bool _pause) public onlyOperator{
        isPaused = _pause;
        emit DAOCoinPaused(_pause, block.timestamp);
    }



    event AddTaxAddress(address _address, uint256 _time);
    event RemoveTaxAddress(address _address, uint256 _time);

    mapping(address => bool) public NoTaxAddress;
    function addNoTax(address _address) public onlyOperator{
        NoTaxAddress[_address] = true;
        emit AddTaxAddress(_address, block.timestamp);
    }
    function removeNoTax(address _address) public onlyOperator{
        NoTaxAddress[_address] = false;
        emit RemoveTaxAddress(_address, block.timestamp);
    }
    function viewNoTaxAddress (address _taxAddress) view public returns(bool){
        return(NoTaxAddress[_taxAddress]);
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









    event MintingBy(address minter, uint256 _times);
    mapping(address => uint256) public MintCounter;
    function Mint(address _user, uint256 _times) public {
        require(_times <= 30);
        require(!isPaused);
        require(ServerWallet == msg.sender, "not server wallet");
        uint256 mintThese = amountPerMint * _times;
        MintCounter[_user] += _times;
        _mint(_user, mintThese);
        lastMinted = block.timestamp;
        emit MintingBy(_user, _times);
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