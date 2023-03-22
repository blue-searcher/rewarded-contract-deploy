// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

contract RewardedContractDeploy {
    uint256 public nextId;
    
    struct DeployRequest {
        bytes bytecode;
        uint256 reward;
        address owner;
    }

    mapping(uint256 => DeployRequest) public requests;
    mapping(address => uint256) public withdrawable;

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

    function request(bytes memory _bytecode) payable external returns (uint256 id) {
        if (msg.value == 0) revert InvalidReward();
        if (_bytecode.length == 0) revert InvalidBytecode();

        id = nextId;
        requests[id] = DeployRequest({
            bytecode: _bytecode, 
            reward: msg.value, 
            owner: msg.sender
        });

        emit NewRequest(msg.sender, id, msg.value);
        nextId += 1;
    }

    function cancel(uint256 _id) external {
        if (msg.sender != requests[_id].owner) revert NotOwner();

        payable(msg.sender).transfer(requests[_id].reward);
        emit CancelRequest(_id, msg.sender);

        delete requests[_id];
    }

    function deploy(uint256 _id) external returns (address addr) {
        DeployRequest memory req = requests[_id];
        if (req.bytecode.length == 0) revert InvalidRequestId();

        bytes memory creationBytecode = req.bytecode;
        assembly {
            addr := create(0, add(creationBytecode, 0x20), mload(creationBytecode))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(msg.sender, addr, _id);

        withdrawable[msg.sender] += req.reward;

        delete requests[_id];
    }

    function withdraw() external {
        uint256 amount = withdrawable[msg.sender];
        if (amount == 0) revert NotEnoughtBalance();

        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount);
        delete withdrawable[msg.sender];
    }

    receive() external payable {}

    error InvalidReward();
    error InvalidBytecode();
    error NotEnoughtBalance();
    error NotOwner();
    error InvalidRequestId();
}