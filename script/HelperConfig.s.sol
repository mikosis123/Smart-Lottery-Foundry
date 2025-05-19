// SPDX-License-Identifier : MIT
pragma solidity ^0.8.19;
import {Raffle} from "../src/Raffle.sol";
import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

abstract contract CodeConstrant {
    uint256 public constant SEPOLIA_ETH_CHAINID = 11155111;
    uint256 public constant LocalChainID = 31337;
    uint96 public constant MOCK_BASE_FEE = 0.25 ether;
    uint96 public constant MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public constant MOCK_WEI_PER_UINT_LINK = 4e15;
}

contract HelperConfig is CodeConstrant, Script {
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfCoordinator;
        bytes32 keyHash;
        uint256 subscriptionId;
        uint32 callbackGasLimit;
    }

    NetworkConfig public localNetworkConfig;

    mapping(uint256 chainId => NetworkConfig) public networkConfig;

    constructor() {
        networkConfig[SEPOLIA_ETH_CHAINID] = getSepoliaEthConfig();
    }
    function getConfigByChainID(
        uint256 chainId
    ) public view returns (NetworkConfig memory) {
        NetworkConfig memory config = networkConfig[chainId];
        if (config.vrfCoordinator != address(0)) {
            return config;
        } else if (chainId == LocalChainID) {
            revert("Local chain configuration must be created explicitly");
        } else {
            revert("Chain not supported");
        }
    }
    function getConfig() public view returns (NetworkConfig memory) {
        return getConfigByChainID(block.chainid);
    }

    function getSepoliaEthConfig() public returns (NetworkConfig memory) {
        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30 seconds,
            vrfCoordinator: 0x5CE8D5A2BC84beb22a398CCA51996F7930313D61,
            keyHash: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be,
            subscriptionId: 1234,
            callbackGasLimit: 100000
        });
    }

    function createLocalChainConfig() public returns (NetworkConfig memory) {
        return getOrCreateAnvilEthConfig();
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            MOCK_WEI_PER_UINT_LINK
        );
        vm.stopBroadcast();
        localNetworkConfig = NetworkConfig({
            entranceFee: 0.01 ether,
            interval: 30 seconds,
            vrfCoordinator: address(vrfCoordinatorMock),
            keyHash: 0x1770bdc7eec7771f7ba4ffd640f34260d7f095b79c92d34a5b2551d6f6cfd2be,
            subscriptionId: 1234,
            callbackGasLimit: 100000
        });
        return localNetworkConfig;
    }
}
