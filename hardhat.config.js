require("@nomicfoundation/hardhat-toolbox");

const dotenv = require("dotenv");
dotenv.config({ path: ".env" });

module.exports = {
  solidity: "0.8.13",
  networks: {
    mumbai: {
      chainId: 80001,
      url: [process.env.RPC_URL],
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};
