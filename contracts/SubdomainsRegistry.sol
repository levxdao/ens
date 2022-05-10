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

    mapping(address => mapping(bytes32 => Deposit)) public deposits;

    struct Deposit {
        uint64 deadline;
        bool withdrawn;
    }

    event Register(bytes32 indexed label, address indexed to, bool indexed paid);
    event Withdraw(bytes32 indexed label, address indexed to);

    constructor(
        address _token,
        address _ens,
        bytes32 _node,
        address _resolver
    ) {
        owner = msg.sender;
        token = _token;
        ens = _ens;
        node = _node;
        resolver = _resolver;
    }

    function register(string memory domain, address to) external {
        uint256 length = bytes(domain).length;
        require(length >= 3, "LEVX: DOMAIN_TOO_SHORT");

        bytes32 label = keccak256(abi.encodePacked(domain));
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        require(ENS(ens).owner(subnode) == address(0), "LEVX: DUPLICATE");

        ENS(ens).setSubnodeRecord(node, label, address(this), resolver, 0);

        PublicResolver(resolver).setAddr(subnode, to);
        ENS(ens).setSubnodeOwner(node, label, to);

        bool paid = length <= 7;
        emit Register(label, to, paid);
        if (paid) {
            deposits[msg.sender][label].deadline = uint64(block.timestamp + 2 weeks);
            IERC20(token).safeTransferFrom(msg.sender, address(this), 1e18);
        }
    }

    function withdraw(bytes32 label, address to) external {
        Deposit storage deposit = deposits[msg.sender][label];
        (uint64 deadline, bool withdrawn) = (deposit.deadline, deposit.withdrawn);
        require(deadline > 0, "LEVX: NON_EXISTENT");
        require(deadline <= block.timestamp, "LEVX: TOO_EARLY");
        require(!withdrawn, "LEVX: WITHDRAWN");

        deposit.withdrawn = true;
        emit Withdraw(label, to);
        IERC20(token).safeTransfer(to, 1e18);
    }
}
