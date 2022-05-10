// SPDX-License-Identifier: WTFPL

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ENS {
    function owner(bytes32 node) external view returns (address);

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);
}

interface PublicResolver {
    function setAddr(bytes32 node, address a) external;
}

contract SubdomainsRegistry {
    using SafeERC20 for IERC20;

    address public immutable owner;
    address public immutable token;
    address public immutable ens;
    bytes32 public immutable node;
    address public immutable resolver;
    uint256 public immutable deadline;

    mapping(address => uint256) public amountLocked;

    event Register(string indexed domain, address indexed to);
    event Withdraw(uint256 amount, address indexed to);

    constructor(
        address _token,
        address _ens,
        bytes32 _node,
        address _resolver,
        uint256 _deadline
    ) {
        owner = msg.sender;
        token = _token;
        ens = _ens;
        node = _node;
        resolver = _resolver;
        deadline = _deadline;
    }

    function register(string memory domain, address to) external {
        require(block.timestamp < deadline, "LEVX: EXPIRED");

        uint256 length = bytes(domain).length;
        require(length >= 3, "LEVX: DOMAIN_TOO_SHORT");

        bytes32 label = keccak256(abi.encodePacked(domain));
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        require(ENS(ens).owner(subnode) == address(0), "LEVX: DUPLICATE");

        ENS(ens).setSubnodeRecord(node, label, address(this), resolver, 0);

        PublicResolver(resolver).setAddr(subnode, to);
        ENS(ens).setSubnodeOwner(node, label, to);

        uint256 amount;
        if (length == 3) {
            amount = 10e18;
        } else if (length == 4) {
            amount = 333e16;
        } else if (length <= 7) {
            amount = 1e18;
        }
        emit Register(domain, to);
        if (amount > 0) {
            amountLocked[msg.sender] += amount;
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function withdraw() external {
        require(block.timestamp >= deadline, "LEVX: TOO_EARLY");

        uint256 amount = amountLocked[msg.sender];
        require(amount > 0, "LEVX: NOTHING_TO_WITHDRAW");
        emit Withdraw(amount, msg.sender);
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}
