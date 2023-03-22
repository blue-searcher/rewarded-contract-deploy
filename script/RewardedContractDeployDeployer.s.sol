pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/RewardedContractDeploy.sol";

contract RewardedContractDeployDeployer is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        new RewardedContractDeploy();

        vm.stopBroadcast();
    }
}
