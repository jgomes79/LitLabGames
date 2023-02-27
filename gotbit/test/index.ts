import { deployments, ethers } from 'hardhat'

import type { AntisnipeMock, LitlabGamesToken } from '@/typechain'

export const useContracts = async () => {
  return {
    token: await ethers.getContract<LitlabGamesToken>('AntisnipeToken'),
    antisnipeMock: await ethers.getContract<AntisnipeMock>('AntisnipeMock'),
  }
}

export const deploy = deployments.createFixture(() =>
  deployments.fixture(undefined, { keepExistingDeployments: true })
)
