// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ISuperfluid, ISuperToken, SuperAppBase, SuperAppDefinitions} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperAppBase.sol";
import {IInstantDistributionAgreementV1} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";
import {IDAv1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/IDAv1Library.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakingContract {
    /// @notice Super token to be distributed.
    ISuperToken public spreaderToken;

    /// @notice IDA Library
    using IDAv1Library for IDAv1Library.InitData;
    IDAv1Library.InitData public idaV1;

    uint32 public INDEX_ID = 0;
    address acceptedToken = 0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f; // fdaix token
    uint contractAmount = 1000000;
    address owner;
    uint lastUpdateTime;
    // uint endTime;
    mapping(address => uint) totalStaked;

    // Publisher
    struct Publisher {
        uint id;
        uint32 index_id;
        uint amount;
        uint no_day;
        uint perday_value;
        uint startTime;
        address publisher;
        address token;
        bool hasDistrubted;
    }
    uint publisherId;
    // uint[] publishers;
    mapping(uint => Publisher) public idToPublisher;
    mapping(address => uint[]) public userIndexId;
    mapping(address => mapping(uint => bool)) public hasClaimed;

    constructor(ISuperToken _spreaderToken) {
        // IDA Library Initialize.
        // idaV1 = IDAv1Library.InitData(
        //     _host,
        //     IInstantDistributionAgreementV1(
        //         address(
        //             _host.getAgreementClass(
        //                 keccak256(
        //                     "org.superfluid-finance.agreements.InstantDistributionAgreement.v1"
        //                 )
        //             )
        //         )
        //     )
        // );
        // idaV1.createIndex(spreaderToken, INDEX_ID);
        owner = msg.sender;
        spreaderToken = _spreaderToken;
        lastUpdateTime = block.timestamp;
    }

    function publishTokens(
        ISuperfluid _host,
        address _tokenAddress,
        uint _amount,
        uint _days
    ) public payable {
        require(
            _tokenAddress == acceptedToken,
            "we are not accepting this token"
        );
        require(_amount > 0, "Amount must be greater than zero");
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
            _tokenAddress,
            false
        );
    }

    function stakeTokens(
        uint _amount,
        uint _publishId,
        address _tokenAddress
    ) public payable {
        require(
            _tokenAddress == acceptedToken,
            "we are not accepting this token"
        );
        require(_amount > 0, "Amount must be greater than zero");
        // require(
        //     block.timestamp > idToPool[INDEX_ID].startTime &&
        //         block.timestamp < (idToPool[INDEX_ID].startTime + 7200),
        //     "Wait for the next time period to start"
        // );
        // require(msg.value == (_amount * 10 ** 18), "Not enough value!");
        spreaderToken.transferFrom(msg.sender, address(this), _amount);
        idaV1.updateSubscriptionUnits(
            spreaderToken,
            idToPublisher[_publishId].index_id,
            msg.sender,
            uint128(_amount)
        );
        userIndexId[msg.sender].push(idToPublisher[_publishId].index_id);
    }

    /// @notice Takes the entire balance of the designated spreaderToken in the contract and distributes it out to unit holders w/ IDA
    function distribute() public {
        require(msg.sender == owner, "You are not the owner");
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
        idToPublisher[_id].startTime = block.timestamp;
        idToPublisher[_id].no_day = idToPublisher[_id].no_day - 1;
        idToPublisher[_id].hasDistrubted = true;
    }
}
