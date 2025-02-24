// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TranslationVerification {
    struct Translation {
        address translator;
        bytes32 hash;
        address peerReviewer;
        bool peerReviewed;
        uint8 approvals;
        uint8 rejections;
        bool verified;
    }

    mapping(bytes32 => Translation) public translations;
    mapping(address => uint8) public validatorReputation;
    uint8 public totalValidators;
    
    event TranslationUploaded(address indexed translator, bytes32 hash);
    event PeerReviewed(bytes32 hash, address indexed reviewer, bool approved);
    event FinalVerified(bytes32 hash, bool approved);
    
    function uploadTranslation(bytes32 hash) public {
        require(translations[hash].translator == address(0), "TranslAlrdyExist");
        translations[hash] = Translation(msg.sender, hash, address(0), false, 0, 0, false);
        emit TranslationUploaded(msg.sender, hash);
    }

    function peerReviewTranslation(bytes32 hash, bool approve) public {
        require(translations[hash].translator != address(0), "TranslNotFound");
        require(!translations[hash].peerReviewed, "AlrdyPeerRev");
        
        translations[hash].peerReviewer = msg.sender;
        translations[hash].peerReviewed = true;
        
        if (approve) {
            translations[hash].approvals++;
        } else {
            translations[hash].rejections++;
        }
        
        emit PeerReviewed(hash, msg.sender, approve);
    }

    function communityVerifyTranslation(bytes32 hash, bool approve) public {
        require(translations[hash].peerReviewed, "MustPeerRevFirst");
        
        if (approve) {
            translations[hash].approvals++;
        } else {
            translations[hash].rejections++;
        }
        
        uint8 requiredApprovals = totalValidators / 2;
        if (translations[hash].approvals >= requiredApprovals) {
            translations[hash].verified = true;
            emit FinalVerified(hash, true);
        } else if (translations[hash].rejections >= requiredApprovals) {
            emit FinalVerified(hash, false);
        }
    }
}
