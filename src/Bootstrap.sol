// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Bootstrap is Ownable {
    IERC20 public immutable token;

    uint256 public immutable rewardRate;

    mapping(uint8 => mapping(uint256 => bytes)) enrIndex;

    mapping(uint8 => uint256) shardEnrIndex;

    mapping(uint8 => mapping(uint256 => mapping(bytes => bool))) public shardEnrs;

    uint8 public immutable shardCount;

    mapping(address => bool) public arbiters;

    struct Challenge {
        uint256 uptime;
        address arbiter;
    }

    modifier onlyArbiter() {
        require(arbiters[msg.sender] == true, "Arbiter: you aren't");
        _;
    }

    // map epoch => shard => enr => uptime struct
    mapping(uint256 => mapping(uint8 => mapping(uint256 => mapping(bytes => Challenge)))) public challenges;

    event NewEnr(uint8 shardId, bytes enr);
    event RemovedEnr(uint8 shardId, bytes enr, Challenge challenge);

    constructor(address _token, uint8 _shardCount, address[] memory _arbiters, uint256 _rewardRate) {
        token = IERC20(_token);
        shardCount = _shardCount;
        for (uint8 i = 0; i < _arbiters.length; ++i) {
            arbiters[_arbiters[i]] = true;
        }
        rewardRate = _rewardRate;
    }

    function registerEnr(uint8 shard, bytes memory enr) external {
        require(shard <= shardCount, "shard invalid");

        shardEnrs[shard][shardEnrIndex[shard]][enr] = true;
        ++shardEnrIndex[shard];

        emit NewEnr(shard, enr);
    }

    function getEnrForShard(uint8 shard) public view returns (bytes[] memory) {
        uint256 shardSize = shardEnrIndex[shard];
        bytes[] memory t = new bytes[](shardSize);
        for (uint256 i = 0; i < shardSize; i++) {
            bytes memory enr = enrIndex[shard][i];
            t[i] = enr;
        }
        return t;
    }

    function challengeEnrUptime(uint8 shard, bytes memory enr, uint256 uptime) public onlyArbiter {
        uint256 epoch = block.number % 10; // todo define epochs
        challenges[epoch][shard][shardEnrIndex[shard]][enr] = Challenge({uptime: uptime, arbiter: msg.sender});
    }

    function removeEnr(uint256 epoch, uint8 shard, bytes memory enr) public onlyOwner {
        Challenge storage c = challenges[epoch][shard][shardEnrIndex[shard]][enr];
        require(c.uptime >= 0, "RemoveEnr: 0 uptime");
        require(c.arbiter != address(0), "RemoveEnr: 0 address");

        require(token.balanceOf(address(this)) >= rewardRate, "RemoveEnr: no balance");

        shardEnrs[shard][shardEnrIndex[shard]][enr] = false;
        emit RemovedEnr(shard, enr, c);

        // add balance to arbiter's
        token.transfer(c.arbiter, rewardRate);
    }
}
