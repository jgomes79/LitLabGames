# LitlabToken

## Getting Started

Recommended Node version is 16.0.0.

```bash
$ yarn
$ yarn compile
$ yarn testf
```

## Project Structure

This a hardhat typescript project with hardhat-deploy extension.
Solidity version 0.8.17

### Tests

Tests are found in the ./test/ folder.

To run tests

```bash
$ yarn testf
```

To run coverage

```bash
$ yarn coverage
```

### Coverage result

```text
  Token
    Antisnipe
      ✔ should set antisnipe address only by owner (86ms)
      ✔ should disable antisnipe in one-way only by owner (67ms)
      ✔ should call antisnipe contract when enable (162ms)
      ✔ should burn tokens (57ms)


  4 passing (642ms)

--------------------|----------|----------|----------|----------|----------------|
File                |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
--------------------|----------|----------|----------|----------|----------------|
 contracts/         |      100 |      100 |      100 |      100 |                |
  LitlabToken.sol   |      100 |      100 |      100 |      100 |                |
 contracts/mock/    |      100 |      100 |      100 |      100 |                |
  AntisnipeMock.sol |      100 |      100 |      100 |      100 |                |
--------------------|----------|----------|----------|----------|----------------|
All files           |      100 |      100 |      100 |      100 |                |
--------------------|----------|----------|----------|----------|----------------|
```

### Contracts

Solidity smart contracts are found in ./contracts/.
./contracts/mock folder contains contracts mocks that are used for testing purposes.

### Deploy

Deploy script can be found in the ./deploy/localhost for local testing and ./deploy/mainnet for mainnet deploy

Generate .env file

```bash
$ cp .env.example .env
```

Add .env file to the project root.

To add the private key of a deployer account, assign the following variable

```
PRIVATE_TEST=
PRIVATE_MAIN=
```

To add API Keys for verifying

```
API_ETH=
API_BSC=
API_POLYGON=
API_AVAX=
API_FTM=
API_ARBITRUM=
```

To deploy contracts on Polygon chain

```bash
$ yarn deploy --network polygon_mainnet
```

### Deployments

Deployments on mainnets and testnets store in ./deployments

### Verify

To verify contracts on Polygon chain

```bash
$ yarn verify --network polygon_mainnet
```

## Tokenomics

- Token name: LitlabToken
- Token symbol: LITT
- Supported Chain: BNB Smart Chain
- Total supply: 3,000,000,000 LITT
- Decimals: 18
- Mintable: no
- Burnable: yes

## Custom functionality

### Antisnipe

3rd party dependecy to protect tokens from bot snipers

#### Function setAntisnipeAddress

```solidity
function setAntisnipeAddress(address addr) external onlyOwner
```

Only owner can set antisnipe address

#### Function setAntisnipeDisable

```solidity
function setAntisnipeDisable() external onlyOwner
```

Only owner can one-way disable antisnipe

### Overriding _beforeTokenTransfer

ERC20 function _beforeTokenTransfer overriding in LitlabGamesToken to implement [Antisnipe](#antisnipe) functionality
