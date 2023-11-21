// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Crowdfunding {
    address public projectCreator;
    uint256 public fundingGoal;
    uint256 public deadline;
    IERC20 public token;
    uint256 public totalFunding;
    mapping(address => uint256) public contributions;
    bool public fundingGoalReached;
    bool public fundingClosed;

    event FundingReceived(address indexed contributor, uint256 amount, uint256 totalFunding);
    event FundingGoalReached(uint256 totalFunding);
    event FundingClosed();

    modifier onlyProjectCreator() {
        require(msg.sender == projectCreator, "Only the project creator can call this function");
        _;
    }

    modifier deadlineReached() {
        require(block.timestamp >= deadline, "Deadline has not been reached");
        _;
    }

    modifier fundingNotClosed() {
        require(!fundingClosed, "Funding is closed");
        _;
    }

    constructor(
        address _projectCreator,
        uint256 _fundingGoal,
        uint256 _durationDays,
        address _token
    ) {
        require(_projectCreator != address(0), "Invalid project creator address");
        require(_fundingGoal > 0, "Funding goal must be greater than 0");

        projectCreator = _projectCreator;
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + (_durationDays * 1 days);
        token = IERC20(_token);
    }
function contribute(uint256 _amount) external fundingNotClosed {
        require(_amount > 0, "Contribution must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        contributions[msg.sender] += _amount;
        totalFunding += _amount;

        emit FundingReceived(msg.sender, _amount, totalFunding);

        checkFundingGoalReached();
    }
function checkFundingGoalReached() internal {
        if (totalFunding >= fundingGoal && !fundingGoalReached) {
            fundingGoalReached = true;
            emit FundingGoalReached(totalFunding);
        }
    }
function closeFunding() external onlyProjectCreator fundingNotClosed deadlineReached {
        fundingClosed = true;

        if (fundingGoalReached) {
            // Transfer funds to the project creator
            require(token.transfer(projectCreator, totalFunding), "Token transfer failed");
        }

        emit FundingClosed();
    }

    function refundContribution() external fundingNotClosed deadlineReached {
        require(!fundingGoalReached, "Funding goal has been reached");
        uint256 amountToRefund = contributions[msg.sender];
        contributions[msg.sender] = 0;
        require(token.transfer(msg.sender, amountToRefund), "Token transfer failed");
    }
}

