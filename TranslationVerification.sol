// SPDX-License-Identifier: AFL-3.0
pragma solidity ^0.8.0;

// Add ERC20 interface for token transfers
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TranslationVerification {
    enum Role { None, Translator, Reviewer, Validator, Admin }
    enum DisputeStatus { None, Pending, Resolved }

    struct Translation {
        address translator;
        string hash;
        uint8 peerReviewCount;
        uint8 approvals;
        uint8 rejections;
        bool verified;
        bool openForCommunity;
        uint256 lastActivityTimestamp;
        DisputeStatus disputeStatus;
        address disputeInitiator;
        string disputeReason;
        mapping(address => bool) hasVoted;
        mapping(address => bool) peerReviewers;
        mapping(address => bool) approvedByReviewer;
    }

    struct Stake {
        uint256 amount;
        uint256 lockedUntil;
    }

    mapping(string => Translation) public translations;
    mapping(address => uint8) public validatorReputation;
    mapping(address => Role) public userRoles;
    mapping(address => Stake) public stakes;
    
    uint8 public totalValidators;
    uint8 public requiredPeerReviews = 2;
    uint256 public minStakeAmount = 0.1 ether;
    uint256 public stakeLockPeriod = 30 days;
    address public owner;
    
    // Token contract address for rewards
    IERC20 public rewardToken;
    uint256 public translatorRewardAmount = 50 * 10**18; // 50 tokens with 18 decimals
    uint256 public reviewerRewardAmount = 10 * 10**18;  // 10 tokens with 18 decimals
    bool public useTokenRewards = false;
    
    event TranslationUploaded(address indexed translator, string hash);
    event PeerReviewed(string hash, address indexed reviewer, bool approved);
    event FinalVerified(string hash, bool approved);
    event RoleAssigned(address indexed user, Role role);
    event DisputeInitiated(string hash, address initiator, string reason);
    event DisputeResolved(string hash, bool approved);
    event Staked(address indexed user, uint256 amount);
    event RewardDistributed(address indexed user, uint256 amount);
    event TokenRewardsEnabled(address tokenAddress);
    event RewardAmountChanged(string role, uint256 amount);

    modifier onlyAdmin() {
        require(userRoles[msg.sender] == Role.Admin, "Admin role required");
        _;
    }

    modifier onlyValidator() {
        require(userRoles[msg.sender] == Role.Validator, "Validator role required");
        _;
    }

    modifier onlyReviewer() {
        require(userRoles[msg.sender] == Role.Reviewer, "Reviewer role required");
        _;
    }

    modifier onlyTranslator() {
        require(userRoles[msg.sender] == Role.Translator, "Translator role required");
        _;
    }

    modifier hasStake() {
        require(stakes[msg.sender].amount >= minStakeAmount, "Minimum stake required");
        require(stakes[msg.sender].lockedUntil > block.timestamp, "Stake expired");
        _;
    }

    constructor() {
        owner = msg.sender;
        userRoles[msg.sender] = Role.Admin;
    }

    function setTotalValidators(uint8 _totalValidators) public onlyAdmin {
        totalValidators = _totalValidators;
    }

    function assignRole(address user, Role role) public onlyAdmin {
        userRoles[user] = role;
        emit RoleAssigned(user, role);
    }

    function setRequiredPeerReviews(uint8 reviews) public onlyAdmin {
        requiredPeerReviews = reviews;
    }

    function stake() public payable {
        require(msg.value >= minStakeAmount, "Minimum stake not met");
        stakes[msg.sender].amount += msg.value;
        stakes[msg.sender].lockedUntil = block.timestamp + stakeLockPeriod;
        emit Staked(msg.sender, msg.value);
    }

    function uploadTranslation(string memory hash) public onlyTranslator hasStake {
        require(
            bytes(translations[hash].hash).length == 0,
            "Translation already exists."
        );
        translations[hash].translator = msg.sender;
        translations[hash].hash = hash;
        translations[hash].lastActivityTimestamp = block.timestamp;
        emit TranslationUploaded(msg.sender, hash);
    }

    function peerReviewTranslation(string memory hash, bool approve) public onlyReviewer hasStake {
        require(
            bytes(translations[hash].hash).length != 0,
            "Translation not found."
        );
        require(
            !translations[hash].peerReviewers[msg.sender],
            "You have already reviewed this translation."
        );
        require(
            translations[hash].translator != msg.sender,
            "Cannot review your own translation."
        );

        translations[hash].peerReviewers[msg.sender] = true;
        translations[hash].approvedByReviewer[msg.sender] = approve;
        translations[hash].peerReviewCount++;
        translations[hash].lastActivityTimestamp = block.timestamp;

        if (approve) {
            translations[hash].approvals++;
        } else {
            translations[hash].rejections++;
        }

        emit PeerReviewed(hash, msg.sender, approve);

        // Open for community voting once we have enough peer reviews
        if (translations[hash].peerReviewCount >= requiredPeerReviews) {
            translations[hash].openForCommunity = true;
        }
    }

    function communityVerifyTranslation(string memory hash, bool approve)
        public
        onlyValidator
        hasStake
    {
        require(
            bytes(translations[hash].hash).length != 0,
            "Translation not found."
        );
        require(
            translations[hash].openForCommunity,
            "Not open for community verification yet."
        );
        require(
            !translations[hash].hasVoted[msg.sender],
            "You have already voted."
        );
        require(
            translations[hash].disputeStatus != DisputeStatus.Pending,
            "Cannot vote while dispute is pending."
        );

        translations[hash].hasVoted[msg.sender] = true;
        translations[hash].lastActivityTimestamp = block.timestamp;

        // Apply reputation-based weighted voting
        uint8 weight = validatorReputation[msg.sender] > 0 ? validatorReputation[msg.sender] : 1;
        
        if (approve) {
            translations[hash].approvals += weight;
        } else {
            translations[hash].rejections += weight;
        }

        uint8 requiredApprovals = (totalValidators / 2) + 1;
        if (translations[hash].approvals >= requiredApprovals) {
            translations[hash].verified = true;
            emit FinalVerified(hash, true);
            // Reward translator and reviewers
            distributeRewards(hash);
            // Increase reputation for validators who voted with majority
            if (approve) updateReputation(msg.sender, true);
        } else if (translations[hash].rejections > translations[hash].approvals) {
            translations[hash].verified = false;
            emit FinalVerified(hash, false);
            // Increase reputation for validators who voted with majority
            if (!approve) updateReputation(msg.sender, true);
        }
    }

    function updateReputation(address validator, bool correct) internal {
        if (correct) {
            if (validatorReputation[validator] < 10) {
                validatorReputation[validator]++;
            }
        } else {
            if (validatorReputation[validator] > 0) {
                validatorReputation[validator]--;
            }
        }
    }

    function initiateDispute(string memory hash, string memory reason) public hasStake {
        require(
            bytes(translations[hash].hash).length != 0,
            "Translation not found."
        );
        require(
            translations[hash].disputeStatus == DisputeStatus.None,
            "Dispute already exists."
        );
        
        translations[hash].disputeStatus = DisputeStatus.Pending;
        translations[hash].disputeInitiator = msg.sender;
        translations[hash].disputeReason = reason;
        translations[hash].lastActivityTimestamp = block.timestamp;
        
        emit DisputeInitiated(hash, msg.sender, reason);
    }
    
    function resolveDispute(string memory hash, bool approve) public onlyAdmin {
        require(
            bytes(translations[hash].hash).length != 0,
            "Translation not found."
        );
        require(
            translations[hash].disputeStatus == DisputeStatus.Pending,
            "No pending dispute."
        );
        
        translations[hash].disputeStatus = DisputeStatus.Resolved;
        translations[hash].verified = approve;
        translations[hash].lastActivityTimestamp = block.timestamp;
        
        emit DisputeResolved(hash, approve);
        
        if (approve) {
            distributeRewards(hash);
        }
    }
    
    // Function to set or update the reward token address
    function setRewardToken(address tokenAddress) public onlyAdmin {
        rewardToken = IERC20(tokenAddress);
        useTokenRewards = true;
        emit TokenRewardsEnabled(tokenAddress);
    }
    
    // Function to configure reward amounts
    function setRewardAmounts(uint256 translatorAmount, uint256 reviewerAmount) public onlyAdmin {
        translatorRewardAmount = translatorAmount;
        reviewerRewardAmount = reviewerAmount;
        emit RewardAmountChanged("translator", translatorAmount);
        emit RewardAmountChanged("reviewer", reviewerAmount);
    }
    
    // Function to toggle between token rewards and native ETH rewards
    function toggleRewardType(bool useTokens) public onlyAdmin {
        useTokenRewards = useTokens;
    }
    
    function distributeRewards(string memory hash) internal {
        address translator = translations[hash].translator;
        
        if (useTokenRewards && address(rewardToken) != address(0)) {
            // Transfer tokens to translator
            require(
                rewardToken.balanceOf(address(this)) >= translatorRewardAmount,
                "Insufficient token balance for rewards"
            );
            rewardToken.transfer(translator, translatorRewardAmount);
            emit RewardDistributed(translator, translatorRewardAmount);
            
            // Reward reviewers who approved the translation
            for (uint i = 0; i < requiredPeerReviews; i++) {
                address reviewer = findReviewer(hash, i);
                if (reviewer != address(0) && translations[hash].approvedByReviewer[reviewer]) {
                    if (rewardToken.balanceOf(address(this)) >= reviewerRewardAmount) {
                        rewardToken.transfer(reviewer, reviewerRewardAmount);
                        emit RewardDistributed(reviewer, reviewerRewardAmount);
                    }
                }
            }
        } else {
            // Fallback to the event emission for now
            emit RewardDistributed(translator, 0.05 ether);
        }
    }
    
    // Helper function to find reviewers by index
    function findReviewer(string memory hash, uint index) internal view returns (address) {

        // For the purpose of this function, I'll implement a workaround that scans a 
        // predefined set of possible validators to find those who reviewed this translation
        
        address[] memory possibleReviewers = new address[](5); // Adjust size as needed
        
        // In a real implementation, this array would be populated with actual reviewers
        // For now, we'll just return address(0) to indicate this needs to be properly implemented
        return address(0);
    }
    
    // Function to withdraw tokens in case of emergency (admin only)
    function withdrawTokens(uint256 amount) public onlyAdmin {
        require(address(rewardToken) != address(0), "Reward token not set");
        require(
            rewardToken.balanceOf(address(this)) >= amount,
            "Insufficient token balance"
        );
        rewardToken.transfer(owner, amount);
    }
    
    function withdrawStake() public {
        require(stakes[msg.sender].amount > 0, "No stake to withdraw");
        require(stakes[msg.sender].lockedUntil < block.timestamp, "Stake is still locked");
        
        uint256 amount = stakes[msg.sender].amount;
        stakes[msg.sender].amount = 0;
        
        payable(msg.sender).transfer(amount);
    }
}
