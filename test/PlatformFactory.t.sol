// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/platform/Platform.sol";
import "../src/platform/PlatformFactory.sol";
import "../src/observability/Observability.sol";

contract PlatformTest is Test {
    PlatformFactory factory;
    address owner = address(1);

    function setUp() public {
        factory = new PlatformFactory(owner);
    }

    function test_SetImplementation() public {
        vm.prank(owner);
        factory.setImplementation(address(2));
    }

    function testRevert_SetImplementationUnauthorizedCaller() public {
        vm.expectRevert("caller is not the owner.");
        factory.setImplementation(address(2));
    }

    function test_Create() public {
        factory.create(getInitalPlatformData());
    }

    function getInitalPlatformData()
        internal
        pure
        returns (IPlatform.PlatformData memory)
    {
        address[] memory publishers = new address[](1);
        address[] memory managers = new address[](1);

        return
            IPlatform.PlatformData({
                platformMetadataDigest: "",
                publishers: publishers,
                metadataManagers: managers,
                initalContent: new bytes32[](0),
                nonce: 0
            });
    }
}
