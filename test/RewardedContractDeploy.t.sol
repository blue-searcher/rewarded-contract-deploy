// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "src/RewardedContractDeploy.sol";

contract RewardedContractDeployTest is Test {
    RewardedContractDeploy public deployer;

    event NewRequest(
        address indexed submitter,
        uint256 id,
        uint256 reward
    );
    event CancelRequest(
        uint256 indexed id,
        address indexed submitter
    );
    event Deployed(
        address indexed deployer,
        address indexed contractAddress,
        uint256 id
    );
    event Withdrawn(
        address indexed deployer,
        uint256 amount
    );

    function setUp() public {
        deployer = new RewardedContractDeploy();
    }

    receive() external payable {
    }

    function getTokenBytecode() internal view returns (bytes memory bytecode) {
        string memory name = "Test token";
        string memory symbol = "TEST";
        uint8 decimals = 18;

        bytes memory args = abi.encode(name, symbol, decimals);
        bytecode = abi.encodePacked(vm.getCode("MockERC20.sol:MockERC20"), args);
    }

    function testRequest() public {
        bytes memory bytecode = getTokenBytecode();

        assertEq(deployer.nextId(), 0);

        uint256 reward = 0.2 ether;

        vm.expectEmit(true, true, true, true);
        emit NewRequest(address(this), deployer.nextId(), reward);
        uint256 id = deployer.request{value: reward}(bytecode);

        (bytes memory bc, uint256 savedReward, address owner) = deployer.requests(id);
        assertEq(address(deployer).balance, reward);
        assertEq(bc, bytecode);
        assertEq(savedReward, reward);
        assertEq(owner, address(this));
        assertEq(id, 0);
        assertEq(deployer.nextId(), 1);
    }

    function testRequestNextIdIncrement() public {
        bytes memory bytecode = getTokenBytecode();
        uint256 reward = 0.2 ether;

        assertEq(deployer.nextId(), 0);
        deployer.request{value: reward}(bytecode);
        assertEq(deployer.nextId(), 1);
        deployer.request{value: reward}(bytecode);
        assertEq(deployer.nextId(), 2);
        deployer.request{value: reward}(bytecode);
        assertEq(deployer.nextId(), 3);
    }

    function testInvalidReward() public {
        bytes memory bytecode = getTokenBytecode();

        vm.expectRevert();
        deployer.request{value: 0}(bytecode);
    }

    function testInvalidBytecode() public {
        bytes memory bytecode = hex"";
        uint256 reward = 0.2 ether;

        vm.expectRevert();
        deployer.request{value: reward}(bytecode);
    }

    function testCancelRequest() public {
        bytes memory bytecode = getTokenBytecode();
        uint256 reward = 0.2 ether;

        uint256 id = deployer.request{value: reward}(bytecode);

        uint256 preBalance = address(this).balance;
        vm.expectEmit(true, true, true, true);
        emit CancelRequest(id, address(this));
        deployer.cancel(id);
        uint256 postBalance = address(this).balance;

        (bytes memory bc, uint256 savedReward, address owner) = deployer.requests(id);
        assertEq(bc, hex"");
        assertEq(savedReward, 0);
        assertEq(owner, address(0));
        assertEq(preBalance + reward, postBalance);
    }

    function testCancelRequestNotOwner() public {
        bytes memory bytecode = getTokenBytecode();
        uint256 reward = 0.2 ether;

        uint256 id = deployer.request{value: reward}(bytecode);
        
        vm.prank(address(0));
        vm.expectRevert();
        deployer.cancel(id);
    }

    function testDeploy() public {
        bytes memory bytecode = getTokenBytecode();
        uint256 reward = 0.2 ether;

        uint256 id = deployer.request{value: reward}(bytecode);

        vm.expectEmit(true, false, true, true);
        emit Deployed(address(this), address(0), id);
        deployer.deploy(id);

        assertEq(deployer.withdrawable(address(this)), reward);

        (bytes memory bc, uint256 savedReward, address owner) = deployer.requests(id);
        assertEq(bc, hex"");
        assertEq(savedReward, 0);
        assertEq(owner, address(0));
    }

    function testDeployedContract() public {
        bytes memory bytecode = getTokenBytecode();
        uint256 reward = 0.2 ether;

        uint256 id = deployer.request{value: reward}(bytecode);
        address deployedAddress = deployer.deploy(id);

        MockERC20 token = MockERC20(deployedAddress);
        assertEq(token.symbol(), "TEST");
        assertEq(token.name(), "Test token");
        assertEq(token.decimals(), 18);
    }

    function testDeployInvalidRequestId() public {
        vm.expectRevert();
        deployer.deploy(0);
    }

    function testWithdraw() public {
        bytes memory bytecode = getTokenBytecode();
        uint256 reward = 0.2 ether;

        uint256 id = deployer.request{value: reward}(bytecode);
        deployer.deploy(id);

        uint256 preBalance = address(this).balance;
        vm.expectEmit(true, true, true, true);
        emit Withdrawn(address(this), reward);
        deployer.withdraw();
        uint256 postBalance = address(this).balance;

        assertEq(preBalance + reward, postBalance);
        assertEq(deployer.withdrawable(address(this)), 0);
    }

    function testWithdrawNotEnoughtBalance() public {
        vm.expectRevert();
        deployer.withdraw();
    }
}
