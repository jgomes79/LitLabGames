import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'

import { ethers } from 'hardhat'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre
  const { deploy } = deployments
  const [deployer] = await ethers.getSigners()

  await deploy('AntisnipeToken', {
    contract: 'LitlabGamesToken',
    from: deployer.address,
    args: [],
    log: true,
  })
}
export default func

func.tags = ['AntisnipeToken.deploy']
