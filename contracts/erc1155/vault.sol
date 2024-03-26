//
import "./FNFTHandler.sol";

contract Interaction {

    FNFTHandler handler;

    mapping(uint => IRevest.FNFTConfig) private fnfts;

    constructor (address handler_ad){
        handler = FNFTHandler(handler_ad);
    }

    function mint (
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) public {
        uint fnftId = handler.getNextId();

        doMint(recipients, quantities, fnftId, fnftConfig, msg.value);
    }

    function doMint(
        address[] memory recipients,
        uint[] memory quantities,
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig,
        uint weiValue

    ) public{

        bool isSingular;
        uint totalQuantity = quantities[0];
        {
            uint rec = recipients.length;
            uint quant = quantities.length;
            require(rec == quant, "recipients and quantities arrays must match");
            // Calculate total quantity
            isSingular = rec == 1;
            if(!isSingular) {
                for(uint i = 1; i < quant; i++) {
                    totalQuantity += quantities[i];
                }
            }
            require(totalQuantity > 0, "E003");
        }

        weiValue -= totalQuantity * fnftConfig.depositAmount;


        require(weiValue > 0);


        deposit
        createFNFT(fnftId, fnftConfig, totalQuantity, msg.sender);

        if(!isSingular) {
            handler.mintBatchRec(recipients, quantities, fnftId, totalQuantity, '');
        } else {
            handler.mint(recipients[0], fnftId, quantities[0], '');
        }

    }


    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount, // fnft
        uint quantity 
    ) external {


        bool createNewSeries = false;
        {
            uint supply = handler.getSupply(fnftId);

            uint balance = handler.getBalance((msg.sender), fnftId);

            if (quantity > balance) {
                require(quantity == supply, "E069");
            }
            else if (quantity < balance || balance < supply) {
                createNewSeries = true;
            }
        }

         uint newFNFTId;
        if(createNewSeries) {
            // Split into a new series
            newFNFTId = handler.getNextId();
            // ILockManager(lockHandler).pointFNFTToLock(newFNFTId, lockId);
            burn(msg.sender, fnftId, quantity);

            handler.mint(msg.sender, newFNFTId, quantity, "");
        } else {
            // Stay the same
            newFNFTId = 0; // Signals to handleMultipleDeposits()
        }

        // Will call updateBalance
        depositToken(fnftId, amount, quantity);

        // Now, we transfer to the token vault
        if(fnft.asset != address(0)){
            IERC20(fnft.asset).safeTransferFrom(msg.sender, vault, quantity * amount);
        }

        // should be in token vault
        handleMultipleDeposits(fnftId, newFNFTId, fnft.depositAmount + amount);


    }   

    function burn(
        address account,
        uint id,
        uint amount
    ) internal {
        handler.burn(account, id, amount);
    }


    

    function createFNFT(uint fnftId, IRevest.FNFTConfig memory fnftConfig, uint quantity, address from) external {
        mapFNFTToToken(fnftId, fnftConfig);
        depositToken(fnftId, fnftConfig.depositAmount, quantity);
    }

    function depositToken(
        uint fnftId,
        uint transferAmount,
        uint quantity
    //  ) public override onlyRevestController {
    ) public {
        // Updates in advance, to handle rebasing tokens
        updateBalance(fnftId, quantity * transferAmount);
        IRevest.FNFTConfig storage fnft = fnfts[fnftId];
        fnft.depositMul = tokenTrackers[fnft.asset].lastMul;
    }

    function withdrawToken(
        uint fnftId,
        uint quantity,
        address user
        // ) external override onlyRevestController {
    ) external {
        IRevest.FNFTConfig storage fnft = fnfts[fnftId];
        IRevest.TokenTracker storage tracker = tokenTrackers[fnft.asset];
        address asset = fnft.asset;

        // Update multiplier first
        updateBalance(fnftId, 0);

        uint withdrawAmount = fnft.depositAmount * quantity * tracker.lastMul / fnft.depositMul;
        tracker.lastBalance -= withdrawAmount;

        if(asset != address(0)) {
            IERC20(asset).safeTransfer(user, withdrawAmount);
        }

    }

    function mapFNFTToToken(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig
        // ) public override onlyRevestController {
    ) public  {
        // Gas optimizations
        fnfts[fnftId].asset =  fnftConfig.asset;
        fnfts[fnftId].depositAmount =  fnftConfig.depositAmount;
        if(fnftConfig.depositMul > 0) {
            fnfts[fnftId].depositMul = fnftConfig.depositMul;
        }
        if(fnftConfig.split > 0) {
            fnfts[fnftId].split = fnftConfig.split;
        }
        if(fnftConfig.maturityExtension) {
            fnfts[fnftId].maturityExtension = fnftConfig.maturityExtension;
        }
        if(fnftConfig.pipeToContract != address(0)) {
            fnfts[fnftId].pipeToContract = fnftConfig.pipeToContract;
        }
        if(fnftConfig.isMulti) {
            fnfts[fnftId].isMulti = fnftConfig.isMulti;
            fnfts[fnftId].depositStopTime = fnftConfig.depositStopTime;
        }
        if(fnftConfig.nontransferrable){
            fnfts[fnftId].nontransferrable = fnftConfig.nontransferrable;
        }
    }
}