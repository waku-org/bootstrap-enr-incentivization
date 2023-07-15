// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "forge-std/Test.sol";
import "../src/Bootstrap.sol";

contract BootstrapTest is Test {
    ERC20 public token;
    Bootstrap public bootstrap;

    function setUp() public {
        token = new ERC20("bootstrap_test", "BOOT");
        bootstrap = new Bootstrap(address(token));
    }

    function testSanity() public {
        assertEq(address(this), bootstrap.owner());
        assertEq(address(token), address(bootstrap.token()));
    }
}
