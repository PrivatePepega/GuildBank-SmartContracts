// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";



    interface ILocalBoD{
        function isBoD(address _addr) external view returns (bool);
        function showBoDPower(address _user) external view returns(uint256);
        function returnBoD() view external returns(address[16] memory);
    }



contract GuildBankBoDTreasury is Ownable, ERC1155Holder , ReentrancyGuard {

    ILocalBoD public LocalBoD;

    constructor(
        address initialOwner,
        address _LocalBoD
        )
        Ownable(initialOwner)
    {
        LocalBoD = ILocalBoD(_LocalBoD);
  
    }



    modifier onlyBoD() {
        require(LocalBoD.isBoD(msg.sender));
        _;
    }





    event tokenAddedToTreasury(tokenInVault _Token);
    event tokenRemovedFromTreasury(tokenInVault _Token);


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

    function addTokenTreasury (string memory _tokenName, address _TokenAddress, bool _isErc20, uint256 _id) external {
        require(msg.sender == address(this));
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

    function removeTokenTreasury (string memory _tokenName) external  {
        require(msg.sender == address(this));
        require(VaultMap[_tokenName].tokenAccepted);
        VaultMap[TokensInVault[TokensInVault.length - 1]].arrayId = VaultMap[_tokenName].arrayId;
        TokensInVault[VaultMap[_tokenName].arrayId] = VaultMap[TokensInVault[TokensInVault.length - 1]].tokenName;
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
            VaultMap[_tokenName].amount = coin.balanceOf(address(this)) - QueueMap[_tokenName];
        }
        if(!isERC20){
            IERC1155 coin = IERC1155(VaultMap[_tokenName].tokenAddress);
            VaultMap[_tokenName].amount = coin.balanceOf(address(this), VaultMap[_tokenName].tokenId) - QueueMap[_tokenName];
        }
    }







    function checkFunds(string[] memory _tokenNames, uint256[] memory _amounts) view internal returns(bool){
        require(_tokenNames.length == _amounts.length);
        for(uint256 i = 0; i < _tokenNames.length; i++){
            require(VaultMap[_tokenNames[i]].tokenAccepted, "token not accepted");
            if(VaultMap[_tokenNames[i]].amount < _amounts[i]){
                return false;
            }
        }
        return true;
    }


    mapping(string => uint256) public QueueMap;
    mapping(string => uint256) public PayedMap;

    function moveVaultToQueue(string[] memory _tokenNames, uint256[] memory _amounts) internal {
        for(uint256 i = 0; i < _tokenNames.length; i++){
            VaultMap[_tokenNames[i]].amount -=  _amounts[i];
            QueueMap[_tokenNames[i]] +=  _amounts[i];
        }
    }

    function moveQueueToVault(string[] memory _tokenNames, uint256[] memory _amounts) internal {
        for(uint256 i = 0; i < _tokenNames.length; i++){
            VaultMap[_tokenNames[i]].amount +=  _amounts[i];
            QueueMap[_tokenNames[i]] -=  _amounts[i];
        }
    }

    function moveQueueToPay(string[] memory _tokenNames, uint256[] memory _amounts) internal {
        for(uint256 i = 0; i < _tokenNames.length; i++){
            PayedMap[_tokenNames[i]] +=  _amounts[i];
            QueueMap[_tokenNames[i]] -=  _amounts[i];
        }
    }



    function forLoopTransferFunction(uint _Id, bytes calldata _data) internal  {
        for(uint256 i = 0; i < actionsMapping[_Id].tokenName.length; i++){
            bool isERC20 = VaultMap[actionsMapping[_Id].tokenName[i]].isErc20;
            if(isERC20){
                IERC20 coin = IERC20(VaultMap[actionsMapping[_Id].tokenName[i]].tokenAddress);
                require(coin.transfer(actionsMapping[_Id].target, actionsMapping[_Id].tokenAmount[i]));
            }
            if(!isERC20){
                IERC1155 coin = IERC1155(VaultMap[actionsMapping[_Id].tokenName[i]].tokenAddress);
                coin.safeTransferFrom(address(this), actionsMapping[_Id].target, VaultMap[actionsMapping[_Id].tokenName[i]].tokenId, actionsMapping[_Id].tokenAmount[i], _data);
            }
        }
    }
    

    mapping(uint256=>mapping(address=>uint256)) public BoDPower;

    function snapshotBoD(uint _ticketId) internal {
        address[16] memory BoD = LocalBoD.returnBoD();
        for (uint i = 0; i < 16; i++) {                 
                BoDPower[_ticketId][BoD[i]] += 1;      
            }
    }


    function showActionOnQueueArray() view public returns(uint[] memory) {
        return activeActionsQueue;
    }
    function getActionTokenNames(uint _id) public view returns (string[] memory) {
        return actionsMapping[_id].tokenName;
    }
    function getActionAmount(uint _id) public view returns (uint256[] memory) {
        return actionsMapping[_id].tokenAmount;
    }



    event eventActionSubmit(address indexed submitter, string ipfsLink, uint256 publishTimer, uint counterId);
    event eventActionApprovedBy(address person, uint256 indexed ActionId);
    event eventActionDeniedBy(address person, uint256 indexed ActionId);
    event eventActionApproved(uint256 indexed ActionId);
    event eventActionDeleted(uint256 indexed ActionId);
    event eventActionExecuted(uint256 indexed ActionId, uint256 publishTimer);
    
    modifier actionActive(uint256 AxId) {
        require(actionsMapping[AxId].active);
       _;
    }
    enum actionStatus {
        queue, accepted, denied, executed
    }
    struct PendingAction {
        string ipfsLink;
        address submitter;
        address target;
        bytes data;
        bool active;
        uint256 approvalCount;
        uint256 deniedCount;
        uint256 autoDelete;
        uint actionId;
        uint arrayId;
        actionStatus Status;
        bool isTx;
        string[] tokenName;
        uint256[] tokenAmount;
    }


    uint[] public activeActionsQueue;
    mapping(uint => PendingAction) public actionsMapping;
    mapping(uint => bool) public approvedActions;
    uint public actionsCounter;
    // TXid------------voter address---voted
    mapping(uint => mapping(address => bool)) public ActionsVoteLedger;


    function submitAction(address _target, bytes memory _data, string memory _ipfsLink, bool _Tx, string[] memory _tokenName, uint256[] memory _tokenAmount) public onlyBoD {
        if(_Tx == true){
            require(checkFunds(_tokenName, _tokenAmount));
        }
        actionsMapping[actionsCounter].ipfsLink = _ipfsLink;
        actionsMapping[actionsCounter].submitter = msg.sender;
        actionsMapping[actionsCounter].target = _target;
        actionsMapping[actionsCounter].data = _data;
        actionsMapping[actionsCounter].active = true;
        actionsMapping[actionsCounter].approvalCount = 0;
        actionsMapping[actionsCounter].deniedCount = 0; 
        actionsMapping[actionsCounter].autoDelete = block.timestamp + 1 weeks;
        actionsMapping[actionsCounter].actionId = actionsCounter;
        actionsMapping[actionsCounter].arrayId = activeActionsQueue.length;
        actionsMapping[actionsCounter].Status = actionStatus.queue;
        actionsMapping[actionsCounter].isTx = _Tx;
        if(_Tx == true){
            actionsMapping[actionsCounter].tokenName = _tokenName;
            actionsMapping[actionsCounter].tokenAmount = _tokenAmount;
            moveVaultToQueue(_tokenName, _tokenAmount);
        }
        activeActionsQueue.push(actionsCounter);
        snapshotBoD(actionsCounter);
        emit eventActionSubmit(msg.sender, _ipfsLink, block.timestamp, actionsCounter);
        actionsCounter++;
    }

    function denyAction(uint _ActionId) public onlyBoD actionActive(_ActionId){
        if(block.timestamp > actionsMapping[_ActionId].autoDelete){
            if(actionsMapping[_ActionId].isTx){
                moveQueueToVault(actionsMapping[_ActionId].tokenName, actionsMapping[_ActionId].tokenAmount);
            }
            closeAction(_ActionId);
            return;
        }
        require(!ActionsVoteLedger[_ActionId][msg.sender]);
        uint256 power = BoDPower[_ActionId][msg.sender];
        ActionsVoteLedger[_ActionId][msg.sender] = true;
        actionsMapping[_ActionId].deniedCount += power;
        emit eventActionDeniedBy(msg.sender, _ActionId);
        if(actionsMapping[_ActionId].deniedCount >= 7){
            if(actionsMapping[_ActionId].isTx){
                moveQueueToVault(actionsMapping[_ActionId].tokenName, actionsMapping[_ActionId].tokenAmount);
            }
            closeAction(_ActionId);
        }
    }

    function approveAction(uint _ActionId) public onlyBoD actionActive(_ActionId){
        if(block.timestamp > actionsMapping[_ActionId].autoDelete){
            if(actionsMapping[_ActionId].isTx){
                moveQueueToVault(actionsMapping[_ActionId].tokenName, actionsMapping[_ActionId].tokenAmount);
            }
            closeAction(_ActionId);
            return;
        }
        require(!ActionsVoteLedger[_ActionId][msg.sender]);
        uint256 power = BoDPower[_ActionId][msg.sender];
        ActionsVoteLedger[_ActionId][msg.sender] = true;
        actionsMapping[_ActionId].approvalCount += power;
        emit eventActionApprovedBy(msg.sender, _ActionId);
        if(actionsMapping[_ActionId].approvalCount == 5 ){
            actionsMapping[_ActionId].autoDelete += 1 weeks;
        }
        if(actionsMapping[_ActionId].approvalCount >= 12){
            actionsMapping[_ActionId].Status = actionStatus.accepted;
            emit eventActionApproved(_ActionId);
        }
    }
    function executeAction(uint _ActionId, bytes calldata _data) public onlyBoD nonReentrant actionActive (_ActionId){ 
        require(actionsMapping[_ActionId].Status == actionStatus.accepted);
        if(block.timestamp > actionsMapping[_ActionId].autoDelete){
            closeAction(_ActionId);
            return;
        }
        if(actionsMapping[_ActionId].isTx){
                forLoopTransferFunction(_ActionId , _data);
                moveQueueToPay(actionsMapping[_ActionId].tokenName, actionsMapping[_ActionId].tokenAmount);
        }else{
            (bool success, ) = actionsMapping[_ActionId].target.call(actionsMapping[_ActionId].data);
            require(success, "Execution of action failed");
        }
        execAction(_ActionId);
        emit eventActionExecuted(_ActionId, block.timestamp);
    }
    function closeAction(uint _Id) internal {
        actionsMapping[_Id].Status = actionStatus.denied;
        actionsMapping[_Id].active = false;
        approvedActions[_Id] = false;

        if(activeActionsQueue.length == 1){
            activeActionsQueue.pop();
        }else{
            actionsMapping[activeActionsQueue[activeActionsQueue.length - 1]].arrayId = actionsMapping[_Id].arrayId;
            activeActionsQueue[actionsMapping[_Id].arrayId] = activeActionsQueue[activeActionsQueue.length - 1];
            activeActionsQueue.pop();
        }
        emit eventActionDeleted(_Id);
    }
    function execAction(uint _Id) internal {
        actionsMapping[_Id].Status = actionStatus.executed;
        actionsMapping[_Id].active = false;
        approvedActions[_Id] = true;

        if(activeActionsQueue.length == 1){
            activeActionsQueue.pop();
        }else{
            actionsMapping[activeActionsQueue[activeActionsQueue.length - 1]].arrayId = actionsMapping[_Id].arrayId;
            activeActionsQueue[actionsMapping[_Id].arrayId] = activeActionsQueue[activeActionsQueue.length - 1];
            activeActionsQueue.pop();
        }
        emit eventActionDeleted(_Id);
    }



}
