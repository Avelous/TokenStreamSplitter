import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployYourContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  await deploy("StreamSplitter", {
    from: deployer,
    // Contract constructor arguments
    args: [/* sf.settings.config.hostAddress, */ deployer],
    log: true,
    autoMine: true,
  });

  // Get the deployed contract
  // const streamSplitter = await hre.ethers.getContract("StreamSplitter", deployer);
};
export default deployYourContract;

deployYourContract.tags = ["StreamSplitter"];
