// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";



    interface IDAOcoinAddress is IERC20 { 
        function burn(uint256 amount) external;
        function returnCap() external view returns(uint256);
        function totalSupply() external view returns(uint256);
    }


contract GuildBankGovernorVault is Ownable, ERC1155Holder, ReentrancyGuard  {
   


    IDAOcoinAddress public DAOcoinAddress;
    address public GuildBankPassportAddress;
    address public GuildBODTreasury;






    constructor(
    address initialOwner, address _DAOcoinAddress,
    address _GuildBankBODTreasury, address _GuildBankPassportAddress
    )
    Ownable(initialOwner)
    {
        GuildBankPassportAddress = _GuildBankPassportAddress;
        DAOcoinAddress = IDAOcoinAddress (_DAOcoinAddress);
        GuildBODTreasury = _GuildBankBODTreasury;
        DcoinBurningCounter = 0;
    }



    /**

        // Custom Code DOWN


     */



    modifier onlyLocalBoD() {
        require(msg.sender == GuildBODTreasury);
        _;
    }

    event VaultReEvaluatoion(uint256 time);



    function showBurnArray() view public returns(string[] memory) {
        return BurnVaultRewardsArray;
    }
    function showTokenAmount(string memory _name) view public returns (uint256){
        return BurnTokenMapping[_name].amount;
    }
    function showTokenAddress(string memory _name) view public returns (address){
        return BurnTokenMapping[_name].tokenAddress;
    }
    function showTokenId(string memory _name) view public returns (uint256){
        return BurnTokenMapping[_name].tokenId;
    }
    function showTokenIsERC20(string memory _name) view public returns (bool){
        return BurnTokenMapping[_name].isErc20;
    }



    function updateFundCheck() public {
        for(uint256 i = 0; i < BurnVaultRewardsArray.length; i++){
            bool isERC20 = BurnTokenMapping[BurnVaultRewardsArray[i]].isErc20;
            if(isERC20){
                IERC20 coin = IERC20(BurnTokenMapping[BurnVaultRewardsArray[i]].tokenAddress);
                uint256 total = coin.balanceOf(address(this));
                BurnTokenMapping[BurnVaultRewardsArray[i]].amount = total;
            }
            if(!isERC20){
                IERC1155 coin = IERC1155(BurnTokenMapping[BurnVaultRewardsArray[i]].tokenAddress);
                uint256 total = coin.balanceOf(address(this), BurnTokenMapping[BurnVaultRewardsArray[i]].tokenId);
                BurnTokenMapping[BurnVaultRewardsArray[i]].amount = total;
            }
        }
        emit VaultReEvaluatoion(block.timestamp);
    }









    struct burnInVault {
        bool tokenAccepted;
        string tokenName;
        address tokenAddress;
        uint256 arrayId;
        uint256 amount;
        bool isErc20;
        uint256 tokenId;
    }

    string[] public BurnVaultRewardsArray;
    mapping(string => burnInVault) public BurnTokenMapping;

    uint256 public DcoinBurningCounter;
    
    event tokenAddedToVault(burnInVault _Token);
    event tokenRemovedFromVault(burnInVault _Token);

    function addToken (string memory _tokenName, address _TokenAddress, bool _isErc20, uint256 _id) onlyLocalBoD public {
        require(!BurnTokenMapping[_tokenName].tokenAccepted);
        BurnVaultRewardsArray.push(_tokenName);
        BurnTokenMapping[_tokenName].tokenAccepted = true;
        BurnTokenMapping[_tokenName].tokenName = _tokenName;
        BurnTokenMapping[_tokenName].tokenAddress = _TokenAddress;
        BurnTokenMapping[_tokenName].isErc20 = _isErc20;
        BurnTokenMapping[_tokenName].amount = 0;
        BurnTokenMapping[_tokenName].tokenId = _id;
        BurnTokenMapping[_tokenName].arrayId = BurnVaultRewardsArray.length - 1;
        emit tokenAddedToVault(BurnTokenMapping[_tokenName]);
    }


    function removeTokenTreasury (string memory _tokenName) public onlyLocalBoD  {
        require(BurnTokenMapping[_tokenName].tokenAccepted);
        BurnTokenMapping[BurnVaultRewardsArray[BurnVaultRewardsArray.length - 1]].arrayId = BurnTokenMapping[_tokenName].arrayId;
        BurnVaultRewardsArray[BurnTokenMapping[_tokenName].arrayId] = BurnTokenMapping[BurnVaultRewardsArray[BurnVaultRewardsArray.length - 1]].tokenName;
        BurnVaultRewardsArray.pop();
        BurnTokenMapping[_tokenName].tokenAccepted = false;
        BurnTokenMapping[_tokenName].arrayId = 0;
        emit tokenRemovedFromVault(BurnTokenMapping[_tokenName]);
    }







    uint256 constant PRECISION = 10**18;
    function BurnDAOTokenToLocal (uint256 _amount, bytes calldata _data) public {
        require(_amount > 0);
        require(DcoinBurningCounter < DAOcoinAddress.totalSupply());
        IDAOcoinAddress localDcoin = IDAOcoinAddress(DAOcoinAddress);
        require(localDcoin.balanceOf(msg.sender) >= _amount);
        localDcoin.transfer(address(this), _amount);
        uint256 taxAmount = (_amount * 2 * PRECISION) / (1000 * PRECISION) / PRECISION;
        uint256 amountAfterTax = _amount - taxAmount;
        localDcoin.burn(amountAfterTax);
        DcoinBurningCounter += _amount;
        BurntDAOReward(_amount, msg.sender, _data);
    }



    function BurntDAOReward(uint256 _amount, address _to, bytes calldata _data) internal {
        uint256 totalSupply = DAOcoinAddress.totalSupply();
        uint256 percentage = (_amount * PRECISION) / totalSupply;
        for (uint256 i = 0; i < BurnVaultRewardsArray.length; i++) {
            uint256 rewardAmount = (BurnTokenMapping[BurnVaultRewardsArray[i]].amount * percentage) / PRECISION;
            if(BurnTokenMapping[BurnVaultRewardsArray[i]].isErc20){
                IERC20 tokenContract = IERC20(BurnTokenMapping[BurnVaultRewardsArray[i]].tokenAddress);
                tokenContract.transfer(_to, rewardAmount);
                BurnTokenMapping[BurnVaultRewardsArray[i]].amount -= rewardAmount;
            }
            if(!BurnTokenMapping[BurnVaultRewardsArray[i]].isErc20){
                IERC1155 tokenContract = IERC1155(BurnTokenMapping[BurnVaultRewardsArray[i]].tokenAddress);
                tokenContract.safeTransferFrom(address(this), _to, BurnTokenMapping[BurnVaultRewardsArray[i]].tokenId, rewardAmount, _data);
                BurnTokenMapping[BurnVaultRewardsArray[i]].amount -= rewardAmount;
            }
        }
    }





}