// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interface/IObservability.sol";

contract Observability is IObservability, IObservabilityEvents {
    /// > [[[[[[[[[[[ Factory functions ]]]]]]]]]]]

    function emitDeploymentEvent(address owner, address clone)
        external
        override
    {
        emit CloneDeployed(msg.sender, owner, clone);
    }

    function emitFactoryImplementationSet(
        address oldImplementation,
        address newImplementation
    ) external override {
        emit FactoryImplementationSet(
            msg.sender,
            oldImplementation,
            newImplementation
        );
    }

    /// > [[[[[[[[[[[ Clone functions ]]]]]]]]]]]

    function emitContentSet(
        uint256 contentId,
        string calldata content,
        address owner
    ) external override {
        emit ContentSet(msg.sender, contentId, content, owner);
    }

    function emitPlatformMetadataSet(string calldata metadata)
        external
        override
    {
        emit PlatformMetadataSet(msg.sender, metadata);
    }

    function emitRoleSet(
        address account,
        bytes32 role,
        bool granted
    ) external override {
        emit RoleSet(msg.sender, account, role, granted);
    }
}
