const CryptToken = artifacts.require("CryptToken")

module.exports = function(deployer){
  deployer.deploy(CryptToken, "Crypt Token", "CT", 1000000)
}