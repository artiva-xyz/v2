// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "../observability/interface/IObservability.sol";
import "./interface/IPlatform.sol";

import "openzeppelin/contracts/access/AccessControl.sol";

contract Platform is AccessControl, IPlatform {
    /// > [[[[[[[[[[[ Version ]]]]]]]]]]]

    /// @notice Version.
    uint8 public immutable override VERSION = 1;

    /// > [[[[[[[[[[[ Authorization ]]]]]]]]]]]

    /// @notice Address that deploys and initializes clones.
    address public immutable override factory;

    /// > [[[[[[[[[[[ Configuration ]]]]]]]]]]]

    /// @notice Address for Mirror's observability contract.
    address public immutable override o11y;

    /// @notice Digest of the platform metadata content
    bytes32 public platformMetadataDigest;

    /// @notice Mapping of content digests to their publishers
    mapping(bytes32 => address) contentDigestToOwner;

    bytes32 public constant override CONTENT_PUBLISHER_ROLE =
        keccak256("CONTENT_PUBLISHER_ROLE");

    bytes32 public constant override METADATA_MANAGER_ROLE =
        keccak256("METADATA_MANAGER_ROLE");

    modifier onlyDigestPublisher(bytes32 _digest) {
        require(
            contentDigestToOwner[_digest] == msg.sender,
            "NOT_DIGEST_OWNER"
        );
        _;
    }

    modifier onlyRoleMember(bytes32 role) {
        require(hasRole(role, msg.sender), "UNAUTHORIZED_CALLER");
        _;
    }

    /// > [[[[[[[[[[[ Constructor ]]]]]]]]]]]

    constructor(address _factory, address _o11y) {
        // Assert not the zero-address.
        require(_factory != address(0), "MUST_SET_FACTORY");

        // Store factory.
        factory = _factory;

        // Assert not the zero-address.
        require(_o11y != address(0), "MUST_SET_OBSERVABILITY");

        // Store observability.
        o11y = _o11y;
    }

    /// > [[[[[[[[[[[ View Methods ]]]]]]]]]]]

    function getDefaultAdminRole() external view returns (bytes32) {
        return DEFAULT_ADMIN_ROLE;
    }

    /// > [[[[[[[[[[[ Initializing ]]]]]]]]]]]

    function initialize(address owner, PlatformData memory platform) external {
        require(msg.sender == factory, "NOT_FACTORY");

        if (platform.platformMetadataDigest.length > 0)
            platformMetadataDigest = platform.platformMetadataDigest;

        for (uint256 i; i < platform.initalContent.length; i++) {
            _addContentDigest(platform.initalContent[i], owner);
            IObservability(o11y).emitContentDigestAdded(
                platform.initalContent[i],
                owner
            );
        }

        for (uint256 i; i < platform.publishers.length; i++) {
            _setupRole(CONTENT_PUBLISHER_ROLE, platform.publishers[i]);
            IObservability(o11y).emitRoleSet(
                platform.publishers[i],
                CONTENT_PUBLISHER_ROLE,
                true
            );
        }

        for (uint256 i; i < platform.metadataManagers.length; i++) {
            _setupRole(METADATA_MANAGER_ROLE, platform.metadataManagers[i]);
            IObservability(o11y).emitRoleSet(
                platform.metadataManagers[i],
                METADATA_MANAGER_ROLE,
                true
            );
        }

        _setupRole(DEFAULT_ADMIN_ROLE, owner);
    }

    /// > [[[[[[[[[[[ Digest Methods ]]]]]]]]]]]

    function addContentDigest(bytes32 digest, address owner)
        public
        onlyRoleMember(CONTENT_PUBLISHER_ROLE)
    {
        require(
            contentDigestToOwner[digest] == address(0),
            "DIGEST_ALREADY_PUBLISHED"
        );
        _addContentDigest(digest, owner);
        IObservability(o11y).emitContentDigestAdded(digest, owner);
    }

    function addManyContentDigests(bytes32[] memory digests, address owner)
        public
    {
        for (uint256 i; i < digests.length; i++) {
            addContentDigest(digests[i], owner);
        }
    }

    function removeContentDigest(bytes32 digest)
        public
        onlyDigestPublisher(digest)
    {
        _removeContentDigest(digest);
        IObservability(o11y).emitContentDigestRemoved(digest);
    }

    function removeManyContentDigests(bytes32[] memory digests) public {
        for (uint256 i; i < digests.length; i++) {
            removeContentDigest(digests[i]);
        }
    }

    /// > [[[[[[[[[[[ Platform Metadata Methods ]]]]]]]]]]]

    function setPlatformMetadataDigest(bytes32 _platformMetadataDigest)
        external
        onlyRoleMember(METADATA_MANAGER_ROLE)
    {
        platformMetadataDigest = _platformMetadataDigest;
        IObservability(o11y).emitPlatformMetadataDigestSet(
            _platformMetadataDigest
        );
    }

    /// > [[[[[[[[[[[ Role Methods ]]]]]]]]]]]

    function setManyRoles(
        address[] memory accounts,
        bytes32 role,
        bool grant
    ) public {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (grant) grantRole(role, accounts[i]);
            else revokeRole(role, accounts[i]);

            IObservability(o11y).emitRoleSet(accounts[i], role, grant);
        }
    }

    /// > [[[[[[[[[[[ Internal Functions ]]]]]]]]]]]

    function _addContentDigest(bytes32 digest, address publisher) internal {
        contentDigestToOwner[digest] = publisher;
    }

    function _removeContentDigest(bytes32 digest) internal {
        delete contentDigestToOwner[digest];
    }
}
