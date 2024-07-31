### Requirements
1. **Staking Functionality**:
- Users can stake one or more multiple NFTs.
- For each staked NFT, the user receives X reward tokens per block.
2. **Unstaking Functionality**:
- Users can unstake NFTs.
- Users can choose which specific NFTs to unstake.
- After unstaking, there is an unbonding period after which the user can withdraw the
NFT.
- No additional rewards are given after unbonding period for the unstaked NFTs.
3. **Reward Claiming**:
- Users can claim their accumulated rewards after a delay period Z.
- Once rewards are claimed, the delay period resets.
4. **Upgradeable Contract**:
- Implement the UUPS (Universal Upgradeable Proxy Standard) proxy pattern for
upgradeability.
5. **Control Mechanisms**:
- Methods to pause and unpause the staking process.
- Ability to update the number of reward tokens

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
