// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ISuperfluid, ISuperToken, SuperAppBase, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import {IDAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/IDAv1Library.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IDAStaking {
    /// @notice Super token to be distributed.
    ISuperToken public spreaderToken;

    /// @notice IDA Library
    using IDAv1Library for IDAv1Library.InitData;
    IDAv1Library.InitData public idaV1;

    /// @notice Index ID. Never changes.

    // uint lastUpdateTime;
    uint timePeriod = 43200;
    address acceptedToken = 0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f; // fdaix token
    // mapping(address => uint) userStakedAmount;
    // mapping(address => uint) rewardsEarned;

    struct StakingDetails {
        uint stakingTime;
        uint amount;
        uint rewards;
        uint totalReturn;
        uint withdrawTime;
        bool isStaked;
        bool hasWithdraw;
    }
    mapping(address => mapping(uint => StakingDetails))
        public userToPoolToStakingDetails;
    mapping(address => uint[]) public userPools;

    struct Pool {
        uint32 id;
        uint totalStaked;
        uint startTime;
        uint endTime;
    }
    uint32 public INDEX_ID = 0;
    mapping(uint32 => Pool) public idToPool;

    constructor(ISuperToken _spreaderToken) {
        spreaderToken = _spreaderToken;
        // lastUpdateTime = block.timestamp;
    }

    function createIndex(ISuperfluid _host) public {
        // IDA Library Initialize.
        idaV1 = IDAv1Library.InitData(
            _host,
            IInstantDistributionAgreementV1(
                address(
                    _host.getAgreementClass(
                        keccak256(
                            "org.superfluid-finance.agreements.InstantDistributionAgreement.v1"
                        )
                    )
                )
            )
        );

        // Creates the IDA Index through which tokens will be distributed
        INDEX_ID = INDEX_ID + 1;
        idaV1.createIndex(spreaderToken, INDEX_ID);
        idToPool[INDEX_ID] = Pool(
            INDEX_ID,
            0,
            block.timestamp,
            block.timestamp + timePeriod
        );
    }

    function stakeTokens(address _tokenAddress, uint _amount) public payable {
        require(_amount > 0, "Amount must be greater than zero");
        require(_tokenAddress == acceptedToken, "You can not stake this token");
        require(
            block.timestamp > idToPool[INDEX_ID].startTime &&
                block.timestamp < (idToPool[INDEX_ID].startTime + 7200),
            "Wait for the next time period to start"
        );
        require(
            !userToPoolToStakingDetails[msg.sender][INDEX_ID].isStaked,
            "You have already staked in this pool!"
        );
        require(msg.value == (_amount * 10 ** 18), "Not enough value!");
        // IERC20 token = IERC20(_tokenAddress);
        // token.transfer(msg.sender, _amount * 10 ** 18);
        // userStakedAmount[msg.sender] = _amount;
        // totalStaked += _amount;
        idToPool[INDEX_ID].totalStaked += _amount;
        userPools[msg.sender].push(INDEX_ID);
        userToPoolToStakingDetails[msg.sender][INDEX_ID] = StakingDetails(
            block.timestamp,
            _amount,
            0,
            0,
            0,
            true,
            false
        );
        idaV1.updateSubscriptionUnits(
            spreaderToken,
            INDEX_ID,
            msg.sender,
            uint128(_amount)
        );
    }

    /// @notice Takes the entire balance of the designated spreaderToken in the contract and distributes it out to unit holders w/ IDA
    function distribute() public {
        uint256 spreaderTokenBalance = spreaderToken.balanceOf(address(this));

        (uint256 actualDistributionAmount, ) = idaV1.ida.calculateDistribution(
            spreaderToken,
            address(this),
            INDEX_ID,
            spreaderTokenBalance
        );

        idaV1.distribute(spreaderToken, INDEX_ID, actualDistributionAmount);
    }

    function calculateTotalReturn(address _user) internal returns (uint) {}

    function withdrawTokens(uint32 _id) public {
        require(
            block.timestamp > (idToPool[_id].endTime),
            "You can not claim it right now. The time is left to claim"
        );
        require(
            userToPoolToStakingDetails[msg.sender][_id].isStaked,
            "You have not staked in this pool"
        );
        require(
            !userToPoolToStakingDetails[msg.sender][_id].hasWithdraw,
            "You have already withdraw your rewards from this pool"
        );
        uint totalAmount = calculateTotalReturn(msg.sender);
        userToPoolToStakingDetails[msg.sender][_id].rewards =
            totalAmount -
            userToPoolToStakingDetails[msg.sender][_id].amount;
        userToPoolToStakingDetails[msg.sender][_id].totalReturn = totalAmount;
        userToPoolToStakingDetails[msg.sender][_id].withdrawTime = block
            .timestamp;
        userToPoolToStakingDetails[msg.sender][_id].hasWithdraw = true;
    }

    function getStakingDetails(
        address _user
    ) public view returns (StakingDetails[] memory) {
        StakingDetails[] memory details;
        for (uint i = 0; i < userPools[_user].length; i++) {
            details[i] = userToPoolToStakingDetails[msg.sender][
                userPools[_user][i]
            ];
        }
        return details;
    }
}
