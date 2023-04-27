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

    uint32 public constant INDEX_ID = 0;
    address acceptedToken = 0x5D8B4C2554aeB7e86F387B4d6c00Ac33499Ed01f; // fdaix token
    uint contractAmount = 1000000;
    address owner;
    uint lastUpdateTime;
    // uint endTime;
    mapping(address => uint) totalStaked;

    constructor(ISuperToken _spreaderToken, ISuperfluid _host) {
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
        owner = msg.sender;
        spreaderToken = _spreaderToken;
        lastUpdateTime = block.timestamp;
    }

    function stakeTokens(uint _amount) public payable {
        require(_amount > 0, "Amount must be greater than zero");
        // require(
        //     block.timestamp > idToPool[INDEX_ID].startTime &&
        //         block.timestamp < (idToPool[INDEX_ID].startTime + 7200),
        //     "Wait for the next time period to start"
        // );
        require(msg.value == (_amount * 10 ** 18), "Not enough value!");
        idaV1.updateSubscriptionUnits(
            spreaderToken,
            INDEX_ID,
            msg.sender,
            uint128(_amount)
        );
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
}
