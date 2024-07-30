// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/mocks/InitializableMock.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title NFTStaking
 * @dev This contract allows users to stake NFTs and earn ERC20 reward tokens.
 *      It supports pausing, unpausing, and upgradeability using the UUPS pattern.
 */
contract NFTStaking is Initializable, UUPSUpgradeable, ERC1155PausableUpgradeable, OwnableUpgradeable{
    using SafeERC20 for IERC20;

    struct StakedNFT {
        address owner;
        uint256 tokenId;
        uint256 stakedFromBlock;
        uint256 rewardDebt;
    }

    // ERC20 reward token
    IERC20 public rewardToken;
    // ERC721 NFT token
    IERC721 public nftToken;
    // Reward rate per block
    uint256 public rewardRate;
    // Unbonding period in blocks
    uint256 public unbondingPeriod;
    // Reward claim delay period in blocks
    uint256 public rewardClaimDelay;

    // Mapping from token ID to staked NFT details
    mapping(uint256 => StakedNFT) public stakedNFTs;
    // Mapping from user address to array of staked token IDs
    mapping(address => uint256[]) public stakedTokens;
    // Mapping from user address to last reward claim block number
    mapping(address => uint256) public lastClaimBlock;
    // Mapping from token ID to unbonding start block number
    mapping(uint256 => uint256) public unbondingStartBlock;

    // Events
    event NFTStaked(address indexed user, uint256 indexed tokenId);
    event NFTUnstaked(address indexed user, uint256 indexed tokenId);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRewardRate);
    event UnbondingPeriodUpdated(uint256 newUnbondingPeriod);
    event RewardClaimDelayUpdated(uint256 newRewardClaimDelay);

    /**
     * @dev Initializes the contract with the given parameters.
     * @param _rewardToken Address of the ERC20 reward token.
     * @param _nftToken Address of the ERC721 NFT token.
     * @param _rewardRate Reward rate per block.
     * @param _unbondingPeriod Unbonding period in blocks.
     * @param _rewardClaimDelay Reward claim delay period in blocks.
     */
    function initialize(
        IERC20 _rewardToken,
        IERC721 _nftToken,
        uint256 _rewardRate,
        uint256 _unbondingPeriod,
        uint256 _rewardClaimDelay
    ) public initializer {
        __Ownable_init(msg.sender);
        __Pausable_init();
        __UUPSUpgradeable_init();

        rewardToken = _rewardToken;
        nftToken = _nftToken;
        rewardRate = _rewardRate;
        unbondingPeriod = _unbondingPeriod;
        rewardClaimDelay = _rewardClaimDelay;
    }

    /**
     * @dev Stakes the given NFTs and starts earning rewards.
     * @param tokenIds Array of token IDs to stake.
     */
    function stake(uint256[] calldata tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(nftToken.ownerOf(tokenId) == msg.sender, "You do not own this NFT");
            nftToken.transferFrom(msg.sender, address(this), tokenId);

            stakedNFTs[tokenId] = StakedNFT({
                owner: msg.sender,
                tokenId: tokenId,
                stakedFromBlock: block.number,
                rewardDebt: 0
            });
            stakedTokens[msg.sender].push(tokenId);

            emit NFTStaked(msg.sender, tokenId);
        }
    }

    /**
     * @dev Unstakes the given NFTs and starts the unbonding period.
     * @param tokenIds Array of token IDs to unstake.
     */
    function unstake(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            StakedNFT storage stakedNFT = stakedNFTs[tokenId];
            require(stakedNFT.owner == msg.sender, "You do not own this staked NFT");
            require(unbondingStartBlock[tokenId] == 0, "NFT is already in unbonding");

            _updateReward(tokenId);

            unbondingStartBlock[tokenId] = block.number;

            emit NFTUnstaked(msg.sender, tokenId);
        }
    }

    /**
     * @dev Withdraws the unstaked NFTs after the unbonding period.
     * @param tokenIds Array of token IDs to withdraw.
     */
    function withdraw(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(unbondingStartBlock[tokenId] > 0, "NFT is not in unbonding");
            require(block.number >= unbondingStartBlock[tokenId] + unbondingPeriod, "Unbonding period not over");

            StakedNFT storage stakedNFT = stakedNFTs[tokenId];
            require(stakedNFT.owner == msg.sender, "You do not own this staked NFT");

            nftToken.transferFrom(address(this), msg.sender, tokenId);
            _removeStakedToken(msg.sender, tokenId);
            delete stakedNFTs[tokenId];
            delete unbondingStartBlock[tokenId];
        }
    }

    /**
     * @dev Claims the accumulated rewards.
     */
    function claimRewards() external {
        uint256 rewardAmount = _calculateRewards(msg.sender);
        require(rewardAmount > 0, "No rewards to claim");
        require(block.number >= lastClaimBlock[msg.sender] + rewardClaimDelay, "Reward claim delay not over");

        rewardToken.safeTransfer(msg.sender, rewardAmount);
        lastClaimBlock[msg.sender] = block.number;

        emit RewardClaimed(msg.sender, rewardAmount);
    }

    /**
     * @dev Updates the reward rate.
     * @param newRewardRate New reward rate per block.
     */
    function updateRewardRate(uint256 newRewardRate) external onlyOwner {
        rewardRate = newRewardRate;
        emit RewardRateUpdated(newRewardRate);
    }

    /**
     * @dev Updates the unbonding period.
     * @param newUnbondingPeriod New unbonding period in blocks.
     */
    function updateUnbondingPeriod(uint256 newUnbondingPeriod) external onlyOwner {
        unbondingPeriod = newUnbondingPeriod;
        emit UnbondingPeriodUpdated(newUnbondingPeriod);
    }

    /**
     * @dev Updates the reward claim delay period.
     * @param newRewardClaimDelay New reward claim delay period in blocks.
     */
    function updateRewardClaimDelay(uint256 newRewardClaimDelay) external onlyOwner {
        rewardClaimDelay = newRewardClaimDelay;
        emit RewardClaimDelayUpdated(newRewardClaimDelay);
    }

    /**
     * @dev Pauses the staking process.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the staking process.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Authorizes the contract upgrade.
     * @param newImplementation Address of the new implementation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Removes a token from the staked tokens list.
     * @param user Address of the user.
     * @param tokenId Token ID to remove.
     */
    function _removeStakedToken(address user, uint256 tokenId) internal {
        uint256[] storage tokens = stakedTokens[user];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
    }

    /**
     * @dev Calculates the accumulated rewards for a user.
     * @param user Address of the user.
     * @return Reward amount.
     */
    function _calculateRewards(address user) internal view returns (uint256) {
        uint256[] storage tokens = stakedTokens[user];
        uint256 rewardAmount = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            StakedNFT storage stakedNFT = stakedNFTs[tokens[i]];
            uint256 stakedBlocks = block.number - stakedNFT.stakedFromBlock;
            rewardAmount += stakedBlocks * rewardRate;
        }
        return rewardAmount;
    }

    /**
     * @dev Updates the reward debt for a specific NFT.
     * @param tokenId Token ID of the NFT.
     */
    function _updateReward(uint256 tokenId) internal {
        StakedNFT storage stakedNFT = stakedNFTs[tokenId];
        uint256 stakedBlocks = block.number - stakedNFT.stakedFromBlock;
        stakedNFT.rewardDebt += stakedBlocks * rewardRate;
        stakedNFT.stakedFromBlock = block.number;
    }
}
