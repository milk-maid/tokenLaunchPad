// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Launchpad is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Token {
        bool exists;
        uint256 decimals;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    address public owner;

    uint256 public saleStartTime;
    uint256 public saleEndTime;
    uint256 public saleRate;
    uint256 public totalDeposited;

    mapping(address => Token) public tokens;
    mapping(address => uint256) public deposited;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function launch(  uint256 _saleStartTime, uint256 _saleEndTime, uint256 _saleRate) external {
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;
        saleRate = _saleRate;

    }

    function deposit(address _token, uint256 _amount) external {
        require(block.timestamp >= saleStartTime, "Sale has not started yet");
        require(block.timestamp < saleEndTime, "Sale has ended");
        require(_amount > 0, "Deposit amount must be greater than zero");

        Token storage token = tokens[_token];
        require(token.exists, "Token does not exist");

        IERC20 erc20 = IERC20(_token);
        erc20.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 saleAmount = _amount.mul(saleRate).div(10 ** token.decimals);

        token.balances[msg.sender] = token.balances[msg.sender].add(_amount);
        deposited[msg.sender] = deposited[msg.sender].add(_amount);
        totalDeposited = totalDeposited.add(_amount);

        token.balances[address(this)] = token.balances[address(this)].add(saleAmount);

        emit Deposit(msg.sender, _token, _amount);
    }

    function withdraw(address _token) external {
        require(block.timestamp >= saleEndTime, "Sale is not over yet");

        Token storage token = tokens[_token];
        require(token.exists, "Token does not exist");

        uint256 depositAmount = token.balances[msg.sender];
        require(depositAmount > 0, "No deposit to withdraw");

        token.balances[msg.sender] = 0;
        deposited[msg.sender] = deposited[msg.sender].sub(depositAmount);
        totalDeposited = totalDeposited.sub(depositAmount);

        IERC20 erc20 = IERC20(_token);
        erc20.safeTransfer(msg.sender, depositAmount);

        emit Withdraw(msg.sender, _token, depositAmount);
    }

    function withdrawSaleToken(address _token) external onlyOwner {
        require(block.timestamp >= saleEndTime, "Sale is not over yet");

        Token storage token = tokens[_token;
    }

    /**
     * a smart contract that acts as a launchPad where users deposit token A(native token) to get
     * tokenB(Protocol Ogbeni) such that they equivalent % of what they deposited.
     * - specify a start time and end time for the launch pad 
     * - once the launchpad is over, users can then withdraw token B.
     * - Remember to add a back-door function to get your deposited ether out.
     */
}
