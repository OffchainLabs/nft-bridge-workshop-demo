import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { task } from "hardhat/config";
import { JsonRpcProvider } from "@ethersproject/providers";
import { Wallet } from "@ethersproject/wallet";
import { AddressZero } from "@ethersproject/constants";
import { writeFileSync, readFileSync } from 'fs'
require("dotenv").config();

const config = {
  solidity: "0.8.9",
  networks: {
    goerli: {
      url: "https://goerli.infura.io/v3/" + String(process.env.INFURA_KEY),
      accounts: [String(process.env.TESTNET_PRIVKEY)]
    },
    arbgoerli: {
      url: "https://goerli-rollup.arbitrum.io/rpc",
      accounts: [String(process.env.TESTNET_PRIVKEY)]
    }
  }
};

const deploymentsPath = "./deployments.json"
task(
  "deploy-all",
  "deploy bridge and token contracts",
  async (taskArgs, hre) => {
    const inbox =
      "0x6BEbC4925716945D46F0Ec336D5C2564F419682C"; /** Goerli rollup testnet (42113) */

    const l1Provider = new JsonRpcProvider(config.networks.goerli.url);
    const l1Signer = new Wallet(config.networks.goerli.accounts[0]).connect(
      l1Provider
    );
    const l2Provider = new JsonRpcProvider(config.networks.arbgoerli.url);
    const l2Signer = new Wallet(config.networks.arbgoerli.accounts[0]).connect(
      l2Provider
    );
    console.log('Deploying from signer',l2Signer.address );
    

    const L1NFTGateway__factory = (
      await hre.ethers.getContractFactory("L1NftGateway")
    ).connect(l1Signer);
    const l1NFTGateway = await L1NFTGateway__factory.deploy();
    await l1NFTGateway.deployed();

    console.log(`l1NFTGateway deployed at ${l1NFTGateway.address}`);
    

    const L2NFTGateway__factory = (
      await hre.ethers.getContractFactory("L2NftGateway")
    ).connect(l2Signer);
    const l2NFTGateway = await L2NFTGateway__factory.deploy();
    await l2NFTGateway.deployed();

    console.log(`l2NFTGateway deployed at ${l2NFTGateway.address}`);

    let res = await l1NFTGateway.initialize(l2NFTGateway.address, inbox);
    let rec = await res.wait();

    res = await l2NFTGateway.initialize(l1NFTGateway.address);
    rec = await res.wait();

    const L1NFT__factory = (
      await hre.ethers.getContractFactory("L1ArbERC721")
    ).connect(l1Signer);
    
    
    
    const l1NFT = await L1NFT__factory.deploy("GoldmanCoins", "GMC");
    await l1NFT.deployed();
    console.log(`L1ArbERC721 deployed at ${l1NFT.address}`);

    const L2NFT__factory = (
      await hre.ethers.getContractFactory("L2ArbERC721")
    ).connect(l2Signer);

    const l2NFT = await L2NFT__factory.deploy(
      "GoldmanCoins",
      "GMC",
      l1NFT.address,
      l2NFTGateway.address
    );

    console.log(`L2ArbERC721 deployed at ${l2NFT.address}`);


    writeFileSync(deploymentsPath, JSON.stringify({
      l1TokenAddress: l1NFT.address,
      l2TokenAddress: l2NFT.address,
      l1GatewayAddress: l1NFTGateway.address,
      l2GatewayAddress: l2NFTGateway.address
    }))
    console.log('done ✌️');
  }
);

task(
  "register-and-deposit",
  "register and deposit token",
  async (taskArgs, hre) => {
    const deploymentAddresses = JSON.parse(readFileSync(deploymentsPath, 'utf8'))
    console.log(deploymentAddresses);
    
    const l1Provider = new JsonRpcProvider(config.networks.goerli.url);
    const l1Signer = new Wallet(config.networks.goerli.accounts[0]).connect(
      l1Provider
    );
    const l2Provider = new JsonRpcProvider(config.networks.arbgoerli.url);
    const l2Signer = new Wallet(config.networks.arbgoerli.accounts[0]).connect(
      l2Provider
    );

    const l1NFTGateway = (
      await hre.ethers.getContractFactory("L1NftGateway")
    ).attach(deploymentAddresses.l1GatewayAddress).connect(l1Signer);

    const l1NFT = (
      await hre.ethers.getContractFactory("L1ArbERC721")
    ).attach(deploymentAddresses.l1TokenAddress).connect(l1Signer);

    const registeredL2Adddress  = await l1NFTGateway.l1ToL2Token(deploymentAddresses.l1TokenAddress) 
    if(registeredL2Adddress === AddressZero){
      console.log('Not registered; registering now');
 
      // l1NFT.registerTokenToL2
      
    }
    
  })

export default config;
