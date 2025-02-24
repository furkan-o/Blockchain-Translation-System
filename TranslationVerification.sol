// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TranslationVerification {
    struct Translation {
        address translator;
        string hash;
        address peerReviewer;
        bool peerReviewed;
        uint256 approvals;
        uint256 rejections;
        bool verified;
    }

    mapping(string => Translation) public translations;
    mapping(address => uint256) public validatorReputation;
    uint256 public totalValidators;
    
    event TranslationUploaded(address indexed translator, string hash);
    event PeerReviewed(string hash, address indexed reviewer, bool approved);
    event FinalVerified(string hash, bool approved);
    
    function uploadTranslation(string memory hash) public {
        require(bytes(translations[hash].hash).length == 0, "Document already exists.");
        translations[hash] = Translation(msg.sender, hash, address(0), false, 0, 0, false);
        emit TranslationUploaded(msg.sender, hash);
    }

    function peerReviewTranslation(string memory hash, bool approve) public {
        require(bytes(translations[hash].hash).length > 0, "Document not found.");
        require(!translations[hash].peerReviewed, "Already peer reviewed.");
        
        translations[hash].peerReviewer = msg.sender;
        translations[hash].peerReviewed = true;
        
        if (approve) {
            translations[hash].approvals++;
        } else {
            translations[hash].rejections++;
        }
        
        emit PeerReviewed(hash, msg.sender, approve);
    }

    function communityVerifyTranslation(string memory hash, bool approve) public {
        require(translations[hash].peerReviewed, "Must be peer reviewed first.");
        
        if (approve) {
            translations[hash].approvals++;
        } else {
            translations[hash].rejections++;
        }
        
        uint256 requiredApprovals = totalValidators / 2;
        if (translations[hash].approvals >= requiredApprovals) {
            translations[hash].verified = true;
            emit FinalVerified(hash, true);
        } else if (translations[hash].rejections >= requiredApprovals) {
            emit FinalVerified(hash, false);
        }
    }
}
