const FrameCBattle = artifacts.require("FrameCBattle")
const Sell = artifacts.require("Sell")
module.exports = function(deployer) {
  deployer.deploy(FrameCBattle)
};
