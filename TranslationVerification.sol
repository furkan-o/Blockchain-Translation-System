// SPDX-License-Identifier: AFL-3.0
pragma solidity ^0.8.0;

contract TranslationVerification {
    struct Translation {
        address translator;
        string hash;
        address peerReviewer;
        bool peerReviewed;
        uint8 approvals;
        uint8 rejections;
        bool verified;
        mapping(address => bool) hasVoted;
    }

    mapping(string => Translation) public translations;
    mapping(address => uint8) public validatorReputation;
    uint8 public totalValidators;

    event TranslationUploaded(address indexed translator, string hash);
    event PeerReviewed(string hash, address indexed reviewer, bool approved);
    event FinalVerified(string hash, bool approved);

    function uploadTranslation(string memory hash) public {
        require(
            bytes(translations[hash].hash).length == 0,
            "Translation already exists."
        );
        translations[hash].translator = msg.sender;
        translations[hash].hash = hash;
        emit TranslationUploaded(msg.sender, hash);
    }

    function peerReviewTranslation(string memory hash, bool approve) public {
        require(
            bytes(translations[hash].hash).length != 0,
            "Translation not found."
        );
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

    function communityVerifyTranslation(string memory hash, bool approve)
        public
    {
        require(
            bytes(translations[hash].hash).length != 0,
            "Translation not found."
        );
        require(
            translations[hash].peerReviewed,
            "Must be peer reviewed first."
        );
        require(
            translations[hash].approvals > 0,
            "Peer review must have at least one approval."
        );
        require(
            !translations[hash].hasVoted[msg.sender],
            "You have already voted."
        );

        translations[hash].hasVoted[msg.sender] = true;

        if (approve) {
            translations[hash].approvals++;
        } else {
            translations[hash].rejections++;
        }

        uint8 requiredApprovals = (totalValidators / 2) + 1;
        if (translations[hash].approvals >= requiredApprovals) {
            translations[hash].verified = true;
            emit FinalVerified(hash, true);
        } else if (
            translations[hash].rejections > translations[hash].approvals
        ) {
            translations[hash].verified = false;
            emit FinalVerified(hash, false);
        }
    }
}
