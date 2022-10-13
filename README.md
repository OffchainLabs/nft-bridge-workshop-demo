## Ethereum / Arbitrum NFT Bridge Workshop!

> DISCLAIMER: For workshop / demo / testnet purposes only; has not been audited, don't use this on mainnet, etc. 

Today we'll be building an ERC-721 bridge!


#### Arbitrum
Arbitrum is a layer 2 Optimistic Rollup chain that runs on top of Ethereum. It suppots arbitrary asynchronous contract calls:

L1 to L2:

``` sol
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable returns (uint256);
```


L2 To L1:
``` solidity


interface ArbSys {

    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

}

```

We will use these arbitrary cross-chain message affordances to build our bridge; we'll be using Goerli / Arbitrum Goerli Rollup Testnet.


### Minimum Viable NFT Bridge

The NFT bridge will have similar architecture to Arbitrum ["Custom ERC20 Bridge."](
https://developer.arbitrum.io/asset-bridging#the-arbitrum-generic-custom-gateway)

2 "Gateway" contracts – one at L1 and one at L2 — are responsible for mapping L1 ERC721s to their L2 ERC721s counterparts, and for enabling deposits and withdrawals.


#### Flow
1. ERC721 is deployted on L1 with affordance to register its L2 token address to L1 gateway.
1. ERC721 is deployed on L2 with affordance for L2 gateway to mint/burn.
1. **X chain message**: L1 ERC721 registers its L2 address on L1 and L2 via retryable ticket.
1. **X chain message** Deposit to L2 via retryable ticket (escrow token in L1 gateway and mint L2 token at L2).
1. **X chain message** Withdraw via ArbSys/Outbox (burn token at L2 and transfer from escrow at L1.)


### Setup / Commands
1. `git clone` this repo
1. `yarn install`
1. Add env variables (i.e., to a .env file):

    ```
    TESTNET_PRIVKEY=xyzxyz
    GOERLI_RPC=https://goerli.infura.io/v3/infura_key
    ```
1. Complete function bodies in contracts (i.e., do all the `"// DO!"` things)
1. Deploy contracts:
    ```bash
    yarn hardhat deploy-all
    ```bash
1. Test out a register / deposit:
    ```
    yarn hardhat register-and-deposit
    ```

