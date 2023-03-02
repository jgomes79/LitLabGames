import { deployments } from 'hardhat'

export const deploy = deployments.createFixture(
  async () => await deployments.fixture(undefined, { keepExistingDeployments: true })
)
