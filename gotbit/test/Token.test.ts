import { expect } from 'chai'
import { ethers, time } from 'hardhat'

import { deploy, useContracts } from '@/test'

const getNow = async () => {
  const { token } = await useContracts()
  const nowBlockNumber = await token.provider.getBlockNumber()
  const nowBlock = await token.provider.getBlock(nowBlockNumber)
  return nowBlock.timestamp
}

describe('Token', () => {
  const initAmount = '1_000_000'.toBigNumber(18)

  beforeEach(async () => await deploy())

  describe('Antisnipe', () => {
    it('should set antisnipe address only by owner', async () => {
      const [owner, user, antisnipe] = await ethers.getSigners()
      const { token } = await useContracts()

      const antisnipeAddress = antisnipe.address
      await expect(
        token.connect(user).setAntisnipeAddress(antisnipeAddress),
        'User cant set antisnipe address'
      ).reverted

      await token.connect(owner).setAntisnipeAddress(antisnipeAddress)

      expect(await token.antisnipe()).eq(antisnipeAddress)
    })
    it('should disable antisnipe in one-way only by owner', async () => {
      const [owner, user] = await ethers.getSigners()
      const { token } = await useContracts()

      expect(await token.antisnipeDisable()).false
      await expect(
        token.connect(user).setAntisnipeDisable(),
        'User cant disable antisnipe'
      ).reverted

      await token.connect(owner).setAntisnipeDisable()

      expect(await token.antisnipeDisable(), 'Antisnipe is disable').true

      await expect(
        token.connect(owner).setAntisnipeDisable(),
        'Cant change state of antisnipe disability'
      ).reverted
    })
    it('should call antisnipe contract when enable', async () => {
      const [deployer, user, anotherUser] = await ethers.getSigners()
      const { token, antisnipeMock } = await useContracts()

      // transfer some tokens to user
      await token.connect(deployer).transfer(user.address, initAmount)
      expect(await token.balanceOf(user.address), 'Correct transfered amount').eq(
        initAmount
      )

      await expect(
        token.connect(user).setAntisnipeAddress(antisnipeMock.address),
        'User cant setup antisnipe address'
      ).reverted

      await token.connect(deployer).setAntisnipeAddress(antisnipeMock.address)
      expect(await token.antisnipe()).eq(antisnipeMock.address)

      const amount = '1'.toBigNumber(18)
      await token.connect(user).transfer(anotherUser.address, amount)

      expect(await antisnipeMock.lastAmount(), 'Correct amount').eq(amount)
      expect(await antisnipeMock.lastSender(), 'Correct sender').eq(user.address)
      expect(await antisnipeMock.lastFrom(), 'Correct from').eq(user.address)
      expect(await antisnipeMock.lastTo(), 'Correct to').eq(anotherUser.address)

      /// disable antisnipe
      await token.connect(deployer).setAntisnipeDisable()

      const newAmount = amount.sub(1)
      await token.connect(anotherUser).transfer(user.address, newAmount)

      /// nothing changed because antisnipe is disable
      expect(await antisnipeMock.lastAmount()).not.eq(newAmount)
      expect(await antisnipeMock.lastSender()).not.eq(anotherUser.address)
      expect(await antisnipeMock.lastFrom()).not.eq(anotherUser.address)
      expect(await antisnipeMock.lastTo()).not.eq(user.address)
    })
    it('should burn tokens', async () => {
      const [deployer, user] = await ethers.getSigners()
      const { token } = await useContracts()

      // transfer some tokens to user
      await token.connect(deployer).transfer(user.address, initAmount)
      expect(await token.balanceOf(user.address), 'Correct transfered amount').eq(
        initAmount
      )

      await token.connect(user).burn(initAmount)
      expect(await token.balanceOf(user.address), 'Correct burned amount').eq(0)
    })
  })
})
