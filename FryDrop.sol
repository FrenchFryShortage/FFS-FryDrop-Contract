pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FryDrop is Ownable, ReentrancyGuard {
    
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public hasWithdrawn;
    uint256 public startTime;

    event Whitelisted(address indexed recipient);
    event TokensDistributed(address indexed token, address indexed recipient, uint256 amount);
    event TokensClaimed(address indexed token, uint256 amount);

    constructor() {
        startTime = block.timestamp;
    }

    function distributeTokens(
        IERC20 token,
        address[] memory recipients,
        uint256[] memory amounts
    ) 
        external 
        nonReentrant
        onlyOwner
    {
        require(recipients.length == amounts.length, "Mismatched input arrays");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(isWhitelisted[recipients[i]], "Recipient is not whitelisted");
            require(!hasWithdrawn[recipients[i]], "Recipient has already withdrawn");
            require(recipients[i] != address(0), "Cannot distribute to zero address");

            require(block.timestamp >= startTime, "Distribution has not started yet");

            require(token.transferFrom(msg.sender, recipients[i], amounts[i]), "Transfer failed");
            hasWithdrawn[recipients[i]] = true;

            emit TokensDistributed(address(token), recipients[i], amounts[i]);
        }
    }

    function whitelistRecipients(address[] memory recipients) external onlyOwner {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Cannot whitelist zero address");
            isWhitelisted[recipients[i]] = true;
            emit Whitelisted(recipients[i]);
        }
    }
    
    function claimTokens(IERC20 token, uint256 amount) external nonReentrant {
        require(isWhitelisted[msg.sender], "Sender is not whitelisted");
        require(!hasWithdrawn[msg.sender], "Sender has already withdrawn");

        require(token.transfer(msg.sender, amount), "Transfer failed");
        hasWithdrawn[msg.sender] = true;

        emit TokensClaimed(address(token), amount);
    }
}
