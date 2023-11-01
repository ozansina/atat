import { Network, Alchemy } from 'alchemy-sdk';

const settings = {
    apiKey: "0b5DfiTOZUzz43jHF33pXafVaAoaz6rf",
    network: Network.ETH_MAINNET,
};

const alchemy = new Alchemy(settings);

// get the latest block
const latestBlock = alchemy.core.getBlock("latest").then(console.log);