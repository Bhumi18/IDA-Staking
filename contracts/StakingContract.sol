// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ISuperfluid, ISuperToken, SuperAppBase, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import {IDAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/IDAv1Library.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingContract {
    /// @notice Super token to be distributed.
    // ISuperToken public spreaderToken;

    /// @notice IDA Library
    using IDAv1Library for IDAv1Library.InitData;
    IDAv1Library.InitData public idaV1;

    uint32 public INDEX_ID = 0;
    address owner;
    // address acceptedToken = 0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f; // fdaix token
    // uint contractAmount = 1000000;
    // uint endTime;

    // Publisher
    struct Publisher {
        uint id;
        uint32 index_id;
        uint amount;
        uint no_day;
        uint perday_value;
        uint startTime;
        address publisher;
        ISuperToken token;
        bool hasDistrubted;
    }
    uint publisherId;
    // uint[] publishers;
    mapping(uint => Publisher) public idToPublisher;
    mapping(uint => address[]) public idToStakers;
    mapping(address => mapping(uint => bool)) public hasUserStaked;
    mapping(address => uint) public userTotalStakedAmount;
    mapping(address => mapping(uint => uint)) public userCampaignStakedamount;

    constructor() {
        owner = msg.sender;
    }

    function publishTokens(
        ISuperfluid _host,
        ISuperToken _spreaderToken,
        uint _amount,
        uint _days
    ) public payable {
        require(_amount > 0, "Amount must be greater than zero");
        ISuperToken spreaderToken;
        spreaderToken = _spreaderToken;
        spreaderToken.transferFrom(msg.sender, address(this), _amount);
        INDEX_ID = INDEX_ID + 1;
        publisherId = publisherId + 1;
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
        idaV1.createIndex(spreaderToken, INDEX_ID);
        idToPublisher[publisherId] = Publisher(
            publisherId,
            INDEX_ID,
            _amount,
            _days,
            _amount / _days,
            block.timestamp,
            msg.sender,
            _spreaderToken,
            false
        );
    }

    function stakeTokens(uint _amount, uint _publishId) public payable {
        require(_amount > 0, "Amount must be greater than zero");
        require(
            idToPublisher[_publishId].startTime + 82800 > (block.timestamp),
            "Time is out!"
        );
        require(msg.value == _amount, "Not enough value!");
        userCampaignStakedamount[msg.sender][_publishId] += _amount;
        idaV1.updateSubscriptionUnits(
            idToPublisher[_publishId].token,
            idToPublisher[_publishId].index_id,
            msg.sender,
            uint128(userCampaignStakedamount[msg.sender][_publishId])
        );
        userTotalStakedAmount[msg.sender] =
            userTotalStakedAmount[msg.sender] +
            _amount;
        hasUserStaked[msg.sender][_publishId] = true;
        idToStakers[_publishId].push(msg.sender);
    }

    /// @notice Takes the entire balance of the designated spreaderToken in the contract and distributes it out to unit holders w/ IDA
    function distribute(uint _id) public {
        require(msg.sender == owner, "You are not the owner");
        ISuperToken spreaderToken = idToPublisher[_id].token;
        uint256 spreaderTokenBalance = spreaderToken.balanceOf(address(this));

        (uint256 actualDistributionAmount, ) = idaV1.ida.calculateDistribution(
            spreaderToken,
            address(this),
            INDEX_ID,
            spreaderTokenBalance
        );
        idaV1.distribute(spreaderToken, INDEX_ID, actualDistributionAmount);
    }

    function getPublisherId() public view returns (uint) {
        return publisherId;
    }

    function publisherDetails(uint _id) public view returns (Publisher memory) {
        return idToPublisher[_id];
    }

    function afterDistribution(uint _id) public {
        require(msg.sender == owner, "You are not a owner");
        idToPublisher[_id].startTime = block.timestamp;
        idToPublisher[_id].no_day = idToPublisher[_id].no_day - 1;
        if (idToPublisher[_id].no_day == 0) {
            idToPublisher[_id].hasDistrubted = true;
        }
    }

    function unStakeSubscription(uint _id) public {
        require(
            userCampaignStakedamount[msg.sender][_id] > 0,
            "You don't have any staked tokens"
        );
        payable(msg.sender).transfer(userCampaignStakedamount[msg.sender][_id]);
        userTotalStakedAmount[msg.sender] =
            userTotalStakedAmount[msg.sender] -
            userCampaignStakedamount[msg.sender][_id];
        userCampaignStakedamount[msg.sender][_id] = 0;
        idaV1.updateSubscriptionUnits(
            idToPublisher[_id].token,
            idToPublisher[_id].index_id,
            msg.sender,
            uint128(0)
        );
        hasUserStaked[msg.sender][_id] = false;
    }

    function getAllPublisherData() public view returns (Publisher[] memory) {
        Publisher[] memory data = new Publisher[](publisherId);
    }
}
