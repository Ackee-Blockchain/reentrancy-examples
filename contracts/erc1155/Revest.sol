// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165Checker.sol';
import "./interfaces/IRevest.sol";
import "./interfaces/IAddressRegistry.sol";
import "./interfaces/ILockManager.sol";
import "./interfaces/IInterestHandler.sol";
import "./interfaces/ITokenVault.sol";
import "./interfaces/IRewardsHandler.sol";
import "./interfaces/IOracleDispatch.sol";
import "./interfaces/IOutputReceiver.sol";
import "./interfaces/IAddressLock.sol";
import "./utils/RevestAccessControl.sol";
import "./utils/RevestReentrancyGuard.sol";
import "./lib/IUnicryptV2Locker.sol";
import "./lib/IWETH.sol";
import "./FNFTHandler.sol";
import "./LockManager.sol";

/**// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRevest {
    event FNFTTimeLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        uint endTime,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTValueLockMinted(
        address indexed primaryAsset,
        address indexed from,
        uint indexed fnftId,
        address compareTo,
        address oracleDispatch,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTAddressLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address trigger,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTWithdrawn(
        address indexed from,
        uint indexed fnftId,
        uint indexed quantity
    );

    event FNFTSplit(
        address indexed from,
        uint[] indexed newFNFTId,
        uint[] indexed proportions,
        uint quantity
    );

    event FNFTUnlocked(
        address indexed from,
        uint indexed fnftId
    );

    event FNFTMaturityExtended(
        address indexed from,
        uint indexed fnftId,
        uint indexed newExtendedTime
    );

    event FNFTAddionalDeposited(
        address indexed from,
        uint indexed newFNFTId,
        uint indexed quantity,
        uint amount
    );

    struct FNFTConfig {
        address asset; // The token being stored
        address pipeToContract; // Indicates if FNFT will pipe to another contract
        uint depositAmount; // How many tokens
        uint depositMul; // Deposit multiplier
        uint split; // Number of splits remaining
        uint depositStopTime; //
        bool maturityExtension; // Maturity extensions remaining
        bool isMulti; //
        bool nontransferrable; // False by default (transferrable) //
    }

    // Refers to the global balance for an ERC20, encompassing possibly many FNFTs
    struct TokenTracker {
        uint lastBalance;
        uint lastMul;
    }

    enum LockType {
        DoesNotExist,
        TimeLock,
        ValueLock,
        AddressLock
    }

    struct LockParam {
        address addressLock;
        uint timeLockExpiry;
        LockType lockType;
        ValueLock valueLock;
    }

    struct Lock {
        address addressLock;
        LockType lockType;
        ValueLock valueLock;
        uint timeLockExpiry;
        uint creationTime;
        bool unlocked;
    }

    struct ValueLock {
        address asset;
        address compareTo;
        address oracle;
        uint unlockValue;
        bool unlockRisingEdge;
    }

    function mintTimeLock(
        uint endTime,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintValueLock(
        address primaryAsset,
        address compareTo,
        uint unlockValue,
        bool unlockRisingEdge,
        address oracleDispatch,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintAddressLock(
        address trigger,
        bytes memory arguments,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function withdrawFNFT(uint tokenUID, uint quantity) external;

    function unlockFNFT(uint tokenUID) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory proportions,
        uint quantity
    ) external returns (uint[] memory newFNFTIds);

    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount,
        uint quantity
    ) external returns (uint);

    function setFlatWeiFee(uint wethFee) external;

    function setERC20Fee(uint erc20) external;

    function getFlatWeiFee() external returns (uint);

    function getERC20Fee() external returns (uint);


}
 * This is the entrypoint for the frontend, as well as third-party Revest integrations.
 * Solidity style guide ordering: receive, fallback, external, public, internal, private - within a grouping, view and pure go last - https://docs.soliditylang.org/en/latest/style-guide.html
 */
contract Revest is IRevest, AccessControlEnumerable, RevestAccessControl, RevestReentrancyGuard {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes4 public constant ADDRESS_LOCK_INTERFACE_ID = type(IAddressLock).interfaceId;

    address immutable WETH;

    uint public erc20Fee = 0; // out of 1000
    uint private constant erc20multiplierPrecision = 1000;
    uint public flatWeiFee = 0;
    uint private constant MAX_INT = 2**256 - 1;
    mapping(address => bool) private approved;

    /**
     * @dev Primary constructor to create the Revest controller contract
     * Grants ADMIN and MINTER_ROLE to whoever creates the contract
     *
     */

    FNFTHandler handler;
    LockManager lockmanager;
    constructor(address provider, address weth, address fnftHandler, address lcmanager) RevestAccessControl(provider) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        WETH = weth;
        hanlder = FNFTHandler(fnftHandler);
        lockmanager = LockManager(lcmanager);

    }

    function getFNFTHandler() returns(FNFTHandler){
        return handler;
    }

    // PUBLIC FUNCTIONS



    // ---------------------------------------

    function mintAddressLock(
        address trigger,
        bytes memory arguments,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable override returns (uint) {
        uint fnftId = getFNFTHandler().getNextId();

        {
            IRevest.LockParam memory addressLock;
            addressLock.addressLock = trigger;
            addressLock.lockType = IRevest.LockType.AddressLock;
            // Get or create lock based on address which can trigger unlock, assign lock to ID
            uint lockId = getLockManager().createLock(fnftId, addressLock);

            if(trigger.supportsInterface(ADDRESS_LOCK_INTERFACE_ID)) {
                IAddressLock(trigger).createLock(fnftId, lockId, arguments);
            }
        }
        // This is a public call to a third-party contract. Must be done after everything else.
        // Safe for reentry
        doMint(recipients, quantities, fnftId, fnftConfig, msg.value);

        // emit FNFTAddressLockMinted(fnftConfig.asset, _msgSender(), fnftId, trigger, quantities, fnftConfig);

        return fnftId;
    }





    function withdrawFNFT(uint fnftId, uint quantity) external override revestNonReentrant(fnftId) {
        address fnftHandler = addressesProvider.getRevestFNFT();
        // Check if this many FNFTs exist in the first place for the given ID
        require(quantity <= IFNFTHandler(fnftHandler).getSupply(fnftId), "E022");
        // Check if the user making this call has this many FNFTs to cash in
        require(quantity <= IFNFTHandler(fnftHandler).getBalance(_msgSender(), fnftId), "E006");
        // Check if the user making this call has any FNFT's
        require(IFNFTHandler(fnftHandler).getBalance(_msgSender(), fnftId) > 0, "E032");

        IRevest.LockType lockType = getLockManager().lockTypes(fnftId);
        require(lockType != IRevest.LockType.DoesNotExist, "E007");
        require(getLockManager().unlockFNFT(fnftId, _msgSender()),
            lockType == IRevest.LockType.TimeLock ? "E010" :
            lockType == IRevest.LockType.ValueLock ? "E018" : "E019");
        // Burn the FNFTs being exchanged
        burn(_msgSender(), fnftId, quantity);
        getTokenVault().withdrawToken(fnftId, quantity, _msgSender());

        emit FNFTWithdrawn(_msgSender(), fnftId, quantity);
    }



    function unlockFNFT(uint fnftId) external override {
        // Works for value locks or time locks
        // IRevest.LockType lock = getLockManager().lockTypes(fnftId);
        // require(lock == IRevest.LockType.AddressLock || lock == IRevest.LockType.ValueLock, "E008");
        require(getLockManager().unlockFNFT(fnftId, _msgSender()), "E056");

        emit FNFTUnlocked(_msgSender(), fnftId);
    }

    // function splitFNFT(
    //     uint fnftId,
    //     uint[] memory proportions,
    //     uint quantity
    // ) external override returns (uint[] memory) {
    //     // Check if the user making this call has ANY FNFT's
    //     require(getFNFTHandler().getBalance(_msgSender(), fnftId) > 0, "E032");
    //     // Checking if the FNFT is allowing splitting
    //     require(getTokenVault().getSplitsRemaining(fnftId) > 0, "E023");
    //     uint[] memory newFNFTIds = new uint[](proportions.length);
    //     uint start = getFNFTHandler().getNextId();
    //     uint lockId = getLockManager().fnftIdToLockId(fnftId);
    //     getFNFTHandler().burn(_msgSender(), fnftId, quantity);
    //     for(uint i = 0; i < proportions.length; i++) {
    //         newFNFTIds[i] = start + i;
    //         getFNFTHandler().mint(_msgSender(), newFNFTIds[i], quantity, "");
    //         getLockManager().pointFNFTToLock(newFNFTIds[i], lockId);
    //     }
    //     getTokenVault().splitFNFT(fnftId, newFNFTIds, proportions, quantity);

    //     emit FNFTSplit(_msgSender(), newFNFTIds, proportions, quantity);

    //     return newFNFTIds;
    // }

    /// @return the new (or reused) ID
    // function extendFNFTMaturity(
    //     uint fnftId,
    //     uint endTime
    // ) external returns (uint) {
    //     uint supply = getFNFTHandler().getSupply(fnftId);
    //     uint balance = getFNFTHandler().getBalance(_msgSender(), fnftId);

    //     require(fnftId < getFNFTHandler().getNextId(), "E007");
    //     require(balance == supply, "E022");
    //     // If it can't have its maturity extended, revert
    //     // Will also return false on non-time lock locks
    //     require(getTokenVault().getFNFT(fnftId).maturityExtension &&
    //         getLockManager().lockTypes(fnftId) == IRevest.LockType.TimeLock, "E029");
    //     // If desired maturity is below existing date, reject operation
    //     require(getLockManager().fnftIdToLock(fnftId).timeLockExpiry < endTime, "E030");

    //     // Update the lock
    //     IRevest.LockParam memory lock;
    //     lock.lockType = IRevest.LockType.TimeLock;
    //     lock.timeLockExpiry = endTime;

    //     getLockManager().createLock(fnftId, lock);

    //     emit FNFTMaturityExtended(_msgSender(), fnftId, endTime);

    //     // Need to handle fracture into multiple FNFTs with same value as original but different locks
    //     return fnftId;
    // }




    /**
     * Amount will be per FNFT. So total ERC20s needed is amount * quantity.
     * We don't charge an ETH fee on depositAdditional, but do take the erc20 percentage.
     * Users can deposit additional into their own
     * Otherwise, if not an owner, they must distribute to all FNFTs equally
     */
    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount,
        uint quantity
    ) external override returns (uint) {
        IRevest.FNFTConfig memory fnft = getTokenVault().getFNFT(fnftId);
        require(fnftId < getFNFTHandler().getNextId(), "E007");
        require(fnft.isMulti, "E034");
        require(fnft.depositStopTime < block.timestamp || fnft.depositStopTime == 0, "E035");
        require(quantity > 0, "E070");

        address vault = addressesProvider.getTokenVault();
        address handler = addressesProvider.getRevestFNFT();
        address lockHandler = addressesProvider.getLockManager();

        bool createNewSeries = false;
        {
            uint supply = IFNFTHandler(handler).getSupply(fnftId);

            uint balance = IFNFTHandler(handler).getBalance(_msgSender(), fnftId);

            if (quantity > balance) {
                require(quantity == supply, "E069");
            }
            else if (quantity < balance || balance < supply) {
                createNewSeries = true;
            }
        }

        // Transfer the ERC20 fee to the admin address, leave it at that
        uint totalERC20Fee = erc20Fee * quantity * amount / erc20multiplierPrecision;
        if(totalERC20Fee > 0) {
            IERC20(fnft.asset).safeTransferFrom(_msgSender(), addressesProvider.getAdmin(), totalERC20Fee);
        }

        uint lockId = ILockManager(lockHandler).fnftIdToLockId(fnftId);

        // Whether to split the new deposits into their own series, or to simply add to an existing series
        uint newFNFTId;
        if(createNewSeries) {
            // Split into a new series
            newFNFTId = IFNFTHandler(handler).getNextId();
            ILockManager(lockHandler).pointFNFTToLock(newFNFTId, lockId);
            burn(_msgSender(), fnftId, quantity);
            IFNFTHandler(handler).mint(_msgSender(), newFNFTId, quantity, "");
        } else {
            // Stay the same
            newFNFTId = 0; // Signals to handleMultipleDeposits()
        }

        // Will call updateBalance
        ITokenVault(vault).depositToken(fnftId, amount, quantity);
        // Now, we transfer to the token vault
        if(fnft.asset != address(0)){
            IERC20(fnft.asset).safeTransferFrom(_msgSender(), vault, quantity * amount);
        }

        handleMultipleDeposits(fnftId, newFNFTId, fnft.depositAmount + amount);

        emit FNFTAddionalDeposited(_msgSender(), newFNFTId, quantity, amount);

        return newFNFTId;
    }


    function handleMultipleDeposits(
        uint fnftId,
        uint newFNFTId,
        uint amount
    ) external override {
        require(amount >= fnfts[fnftId].depositAmount, 'E003');
        IRevest.FNFTConfig storage config = fnfts[fnftId];
        config.depositAmount = amount;
        mapFNFTToToken(fnftId, config);
        if(newFNFTId != 0) {
            mapFNFTToToken(newFNFTId, config);
        }
    }



    function mapFNFTToToken(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig
    ) public override onlyRevestController {
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

 











    /**
     * @dev Returns the cached IAddressRegistry connected to this contract
     **/
    function getAddressesProvider() external view returns (IAddressRegistry) {
        return addressesProvider;
    }

    //
    // INTERNAL FUNCTIONS
    //

    function doMint(
        address[] memory recipients,
        uint[] memory quantities,
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig,
        uint weiValue
    ) internal {


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

        // Gas optimization
        address vault = addressesProvider.getTokenVault();

        // Take fees
        if(weiValue > 0) {
            // Immediately convert all ETH to WETH
            IWETH(WETH).deposit{value: weiValue}();
        }

        if(flatWeiFee > 0) {
            require(weiValue >= flatWeiFee, "E005");
            address reward = addressesProvider.getRewardsHandler();
            if(!approved[reward]) {
                IERC20(WETH).approve(reward, MAX_INT);
                approved[reward] = true;
            }
            IRewardsHandler(reward).receiveFee(WETH, flatWeiFee);
        }

        {
            uint totalERC20Fee = erc20Fee * totalQuantity * fnftConfig.depositAmount / erc20multiplierPrecision;
            if(totalERC20Fee > 0) {
                IERC20(fnftConfig.asset).safeTransferFrom(_msgSender(), addressesProvider.getAdmin(), totalERC20Fee);
            }
        }
        // If there's any leftover ETH after the flat fee, convert it to WETH
        weiValue -= flatWeiFee;
        // Convert ETH to WETH if necessary
        if(weiValue > 0) {
            // If the asset is WETH, we also enable sending ETH to pay for the tx fee. Not required though
            require(fnftConfig.asset == WETH, "E053");
            require(weiValue >= fnftConfig.depositAmount, "E015");
        }

        // Create the FNFT and update accounting within TokenVault
        ITokenVault(vault).createFNFT(fnftId, fnftConfig, totalQuantity, _msgSender());

        // Now, we move the funds to token vault from the message sender
        if(fnftConfig.asset != address(0)){
            IERC20(fnftConfig.asset).safeTransferFrom(_msgSender(), vault, totalQuantity * fnftConfig.depositAmount);
        }
        // Mint NFT
        // Gas optimization
        if(!isSingular) {
            getFNFTHandler().mintBatchRec(recipients, quantities, fnftId, totalQuantity, '');
        } else {
            getFNFTHandler().mint(recipients[0], fnftId, quantities[0], '');
        }

    }

    function burn(
        address account,
        uint id,
        uint amount
    ) internal {
        address fnftHandler = addressesProvider.getRevestFNFT();
        require(IFNFTHandler(fnftHandler).getSupply(id) - amount >= 0, "E025");
        IFNFTHandler(fnftHandler).burn(account, id, amount);
    }

    function setFlatWeiFee(uint wethFee) external override onlyOwner {
        flatWeiFee = wethFee;
    }

    function setERC20Fee(uint erc20) external override onlyOwner {
        erc20Fee = erc20;
    }

    function getFlatWeiFee() external view override returns (uint) {
        return flatWeiFee;
    }

    function getERC20Fee() external view override returns (uint) {
        return erc20Fee;
    }
}