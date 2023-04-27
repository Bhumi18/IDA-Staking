require("@nomicfoundation/hardhat-toolbox");

const dotenv = require("dotenv");
dotenv.config({ path: ".env" });

module.exports = {
  solidity: "0.8.13",
  networks: {
    mumbai: {
      chainId: 80001,
      url: "https://polygon-mumbai.g.alchemy.com/v2/3ohLMSxKL3LyiT3ppE7-raO4PAOgbX-b",
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};
