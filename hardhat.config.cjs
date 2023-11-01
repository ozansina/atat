/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config(); //all the key value pairs are being made available due to this lib
//require("@nomicfoundation/hardhat-toolbox");
require('@nomiclabs/hardhat-waffle');
require("@nomiclabs/hardhat-etherscan");
require('solidity-coverage');   
module.exports = {
  solidity: "0.8.20",
  defaultNetwork: "goerli",
  networks: {
    goerli: {
      url: `${process.env.ALCHEMY_GOERLI_URL}`,
      accounts: [`0x${process.env.GOERLI_PRIVATE_KEY}`],
    }
  }
};