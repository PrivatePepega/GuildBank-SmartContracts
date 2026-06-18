// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";








contract GuildBankGovernorTreasury is Ownable, ERC1155Holder {


    address public LocalBoDTreasury;
    address public GuildBankElection;
    address public GlobalBoDTreasury;

    constructor(
        address initialOwner,
        address _LocalBoDTreasury,
        address _GuildBankElection,
        address _GlobalBoD
        )
        Ownable(initialOwner)
    {
        LocalBoDTreasury = _LocalBoDTreasury;
        GuildBankElection = _GuildBankElection;
        GlobalBoDTreasury = _GlobalBoD;
    }



    modifier onlyBoD() {
        require(msg.sender == LocalBoDTreasury);
        _;
    }





    event tokenAddedToTreasury(tokenInVault _Token);
    event tokenRemovedFromTreasury(tokenInVault _Token);
    event withdrawToBoDEvent(uint256 _time);


     function showTreasuryArray() view public returns(string[] memory) {
        return TokensInVault;
    }
    function showTokenAmount(string memory _name) view public returns (uint256){
        return VaultMap[_name].amount;
    }
    function showTokenAddress(string memory _name) view public returns (address){
        return VaultMap[_name].tokenAddress;
    }
    function showTokenId(string memory _name) view public returns (uint256){
        return VaultMap[_name].tokenId;
    }
    function showTokenIsERC20(string memory _name) view public returns (bool){
        return VaultMap[_name].isErc20;
    }

    struct tokenInVault {
        bool tokenAccepted;
        string tokenName;
        address tokenAddress;
        uint256 arrayId;
        uint256 amount;
        bool isErc20;
        uint256 tokenId;
    }

    string[] public TokensInVault;
    mapping(string => tokenInVault) public VaultMap;

    function addTokenTreasury (string memory _tokenName, address _TokenAddress, bool _isErc20, uint256 _id) public onlyBoD {
        require(!VaultMap[_tokenName].tokenAccepted);
        VaultMap[_tokenName].tokenAccepted = true;
        VaultMap[_tokenName].tokenName = _tokenName;
        VaultMap[_tokenName].tokenAddress = _TokenAddress;
        VaultMap[_tokenName].isErc20 = _isErc20;
        VaultMap[_tokenName].amount = 0;
        VaultMap[_tokenName].arrayId = TokensInVault.length;
        VaultMap[_tokenName].tokenId = _id;
        TokensInVault.push(_tokenName);
        emit tokenAddedToTreasury(VaultMap[_tokenName]);
    }


    function removeTokenTreasury (string memory _tokenName) public onlyBoD {
        require(VaultMap[_tokenName].tokenAccepted);
        // the last token in the vaultArray gets re-assigned theyre mapArrayID to the removed token arrayID
        VaultMap[TokensInVault[TokensInVault.length - 1]].arrayId = VaultMap[_tokenName].arrayId;
        // we replace the removed token in the vault array with the last vault array token name 
        TokensInVault[VaultMap[_tokenName].arrayId] = VaultMap[TokensInVault[TokensInVault.length - 1]].tokenName;
        // we remove the last token in the vaultArray since we moved the last token to the removed token vaultArray and its ID in the map
        TokensInVault.pop();
        VaultMap[_tokenName].tokenAccepted = false;
        VaultMap[_tokenName].arrayId = 0;
        emit tokenRemovedFromTreasury(VaultMap[_tokenName]);
    }

    function updateBalance(string memory _tokenName) public {
        require(VaultMap[_tokenName].tokenAccepted);
        bool isERC20 = VaultMap[_tokenName].isErc20;
        if(isERC20){
            IERC20 coin = IERC20(VaultMap[_tokenName].tokenAddress);
            VaultMap[_tokenName].amount = coin.balanceOf(address(this));
        }
        if(!isERC20){
            IERC1155 coin = IERC1155(VaultMap[_tokenName].tokenAddress);
            VaultMap[_tokenName].amount = coin.balanceOf(address(this), VaultMap[_tokenName].tokenId);
        }
    }


    event SeasonTransfer(string Token, uint256 balanceSent);



    function NewSeasonTransfer(bytes calldata _data) public{
        require(msg.sender == GuildBankElection);
        for (uint256 i = 0; i < TokensInVault.length; i++) {
            uint256 balance = VaultMap[TokensInVault[i]].amount;
            uint256 fourPercent = (balance * 4) / 100;
            uint256 twoPercent = fourPercent / 2;
            bool isERC20 = VaultMap[TokensInVault[i]].isErc20;
            if(isERC20){
                IERC20 coin = IERC20(VaultMap[TokensInVault[i]].tokenAddress);
                require(coin.transfer(GlobalBoDTreasury, twoPercent));
                require(coin.transfer(address(LocalBoDTreasury), twoPercent));
            }
            if(!isERC20){
                IERC1155 coin = IERC1155(VaultMap[TokensInVault[i]].tokenAddress);
                coin.safeTransferFrom(address(this), GlobalBoDTreasury, VaultMap[TokensInVault[i]].tokenId, twoPercent, _data);
                coin.safeTransferFrom(address(this), address(LocalBoDTreasury), VaultMap[TokensInVault[i]].tokenId, twoPercent, _data);
            }
            emit SeasonTransfer(VaultMap[TokensInVault[i]].tokenName, fourPercent);
            VaultMap[TokensInVault[i]].amount -= fourPercent;
        }
    }


    function dumpResourcesToBoD(bytes calldata _data) public onlyOwner{
        for (uint256 i = 0; i < TokensInVault.length; i++) {
            uint256 totalBalance = VaultMap[TokensInVault[i]].amount;
            uint256 halfBalance = totalBalance / 2;
            bool isERC20 = VaultMap[TokensInVault[i]].isErc20;
            if(isERC20){
                IERC20 coin = IERC20(VaultMap[TokensInVault[i]].tokenAddress);
                require(coin.transfer(GlobalBoDTreasury, halfBalance));
                require(coin.transfer(LocalBoDTreasury, halfBalance));
            }
            if(!isERC20){
                IERC1155 coin = IERC1155(VaultMap[TokensInVault[i]].tokenAddress);
                coin.safeTransferFrom(address(this), GlobalBoDTreasury, VaultMap[TokensInVault[i]].tokenId, halfBalance, _data);
                coin.safeTransferFrom(address(this), LocalBoDTreasury, VaultMap[TokensInVault[i]].tokenId, halfBalance, _data);
            }
            VaultMap[TokensInVault[i]].amount -= totalBalance;
        }
    }


}