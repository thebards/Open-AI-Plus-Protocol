import { zeroPad } from '@ethersproject/bytes';
import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { constants, utils, BytesLike, BigNumber, Signature } from 'ethers'
const { AddressZero, MaxUint256 } = constants
import {
	MAX_UINT256,
	ZERO_ADDRESS,
	FIRST_PROFILE_ID,
	MOCK_PROFILE_HANDLE,
	MOCK_PROFILE_CONTENT_URI,
	DEFAULT_CURATION_BPS,
	DEFAULT_STAKING_BPS
} from '../utils/Constants';
import { ERRORS } from '../utils/Errors';
import {
	cancelWithPermitForAll,
	getSetMarketModuleWithSigParts,
	getSetCurationContentURIWithSigParts,
	getCreateCurationWithSigParts,
	deriveChannelKey,
	toBCT,
	getBCTPermitWithSigParts,
	toBN
} from '../utils/Helpers';
import {
	abiCoder,
	bardsHub,
	ProtocolState,
	CurationType,
	makeSuiteCleanRoom,
	testWallet,
	governance,
	userTwoAddress,
	userTwo,
	userAddress,
	mockCurationMetaData,
	mockMarketModuleInitData,
	mockMinterMarketModuleInitData,
	errorsLib,
	fixPriceMarketModule,
	bardsCurationToken,
	transferMinter,
	user
} from '../__setup.test';

makeSuiteCleanRoom('BardsCurationToken', function () {
	beforeEach(async function () {
		// Mint some tokens
		const tokens = toBCT('10000')
		await expect(
			bardsCurationToken.connect(governance).mint(testWallet.address, tokens)
		).to.not.be.reverted;
	});

	context('permit', function () {
		it('should permit some token allowance', async function () {
			// Allow to transfer tokens
			const tokensToApprove = toBCT('1000')
			const nonce = (await bardsCurationToken.sigNonces(testWallet.address)).toNumber();

			const { v, r, s } = await getBCTPermitWithSigParts(
				testWallet.address,
				userAddress,
				tokensToApprove,
				nonce,
				MAX_UINT256
			);

			await expect(
				bardsCurationToken.connect(testWallet).permit({
					owner: testWallet.address,
					spender: userAddress,
					value: tokensToApprove,
					sig: {
						v,
						r,
						s,
						deadline: MAX_UINT256
					},
				})
			).to.not.be.reverted;

			// Allowance updated
			expect(
				await bardsCurationToken.allowance(testWallet.address, userAddress)
			).eq(tokensToApprove)

			// Transfer tokens should work
			await expect(
				bardsCurationToken.connect(user).transferFrom(
					testWallet.address, 
					userAddress,
					toBCT('100')
				)
			).to.not.be.reverted;
		});

		it('should permit max token allowance', async function () {
			// Allow to transfer tokens
			const tokensToApprove = MaxUint256;
			const nonce = (await bardsCurationToken.sigNonces(testWallet.address)).toNumber();

			const { v, r, s } = await getBCTPermitWithSigParts(
				testWallet.address,
				userAddress,
				tokensToApprove,
				nonce,
				MAX_UINT256
			);

			await expect(
				bardsCurationToken.connect(testWallet).permit({
					owner: testWallet.address,
					spender: userAddress,
					value: tokensToApprove,
					sig: {
						v,
						r,
						s,
						deadline: MAX_UINT256
					},
				})
			).to.not.be.reverted;

			// Allowance updated
			expect(
				await bardsCurationToken.allowance(testWallet.address, userAddress)
			).eq(tokensToApprove)

			// Transfer tokens should work
			await expect(
				bardsCurationToken.connect(user).transferFrom(
					testWallet.address,
					userAddress,
					toBCT('100')
				)
			).to.not.be.reverted;
		})

		it('reject to transfer more tokens than approved by permit', async function () {
			// Allow to transfer tokens
			// Allow to transfer tokens
			const tokensToApprove = toBCT('1000')
			const nonce = (await bardsCurationToken.sigNonces(testWallet.address)).toNumber();

			const { v, r, s } = await getBCTPermitWithSigParts(
				testWallet.address,
				userAddress,
				tokensToApprove,
				nonce,
				MAX_UINT256
			);

			await expect(
				bardsCurationToken.connect(testWallet).permit({
					owner: testWallet.address,
					spender: userAddress,
					value: tokensToApprove,
					sig: {
						v,
						r,
						s,
						deadline: MAX_UINT256
					},
				})
			).to.not.be.reverted;

			// Should not transfer more than approved
			const tooManyTokens = toBCT('1001')
			await expect(
				bardsCurationToken.connect(user).transferFrom(
					testWallet.address,
					userAddress,
					tooManyTokens
				)
			).revertedWith('ERC20: insufficient allowance')

			// Should transfer up to the approved amount
			await expect(
				bardsCurationToken.connect(user).transferFrom(
					testWallet.address,
					userAddress,
					tokensToApprove
				)
			).to.not.be.reverted;
		})

		it('reject use expired permit', async function () {
			// Allow to transfer tokens
			const tokensToApprove = MaxUint256;
			const nonce = (await bardsCurationToken.sigNonces(testWallet.address)).toNumber();

			const { v, r, s } = await getBCTPermitWithSigParts(
				testWallet.address,
				userAddress,
				tokensToApprove,
				nonce,
				'0'
			);

			await expect(
				bardsCurationToken.connect(testWallet).permit({
					owner: testWallet.address,
					spender: userAddress,
					value: tokensToApprove,
					sig: {
						v,
						r,
						s,
						deadline: '0'
					},
				})
			).to.be.rejectedWith('SignatureExpired');
		})

		it('reject permit if holder address does not match', async function () {
			// Allow to transfer tokens
			const tokensToApprove = MaxUint256;
			const nonce = (await bardsCurationToken.sigNonces(testWallet.address)).toNumber();

			const { v, r, s } = await getBCTPermitWithSigParts(
				testWallet.address,
				userAddress,
				tokensToApprove,
				nonce,
				MAX_UINT256
			);

			await expect(
				bardsCurationToken.connect(testWallet).permit({
					owner: testWallet.address,
					spender: userTwoAddress,
					value: tokensToApprove,
					sig: {
						v,
						r,
						s,
						deadline: MAX_UINT256
					},
				})
			).to.be.rejectedWith(ERRORS.SIGNATURE_INVALID);
			// .revertedWithCustomError(
			// 	errorsLib,
			// 	ERRORS.SIGNATURE_INVALID
			// );
		})

		it('should deny transfer from if permit was denied', async function () {
			// Allow to transfer tokens
			const tokensToApprove = toBN('0');
			const nonce = (await bardsCurationToken.sigNonces(testWallet.address)).toNumber();

			const { v, r, s } = await getBCTPermitWithSigParts(
				testWallet.address,
				userAddress,
				tokensToApprove,
				nonce,
				MAX_UINT256
			);

			await expect(
				bardsCurationToken.connect(testWallet).permit({
					owner: testWallet.address,
					spender: userAddress,
					value: tokensToApprove,
					sig: {
						v,
						r,
						s,
						deadline: MAX_UINT256
					},
				})
			).to.not.be.reverted;

			// Allowance updated
			const allowance = await bardsCurationToken.allowance(testWallet.address, userAddress)
			expect(allowance).eq(toBN('0'))

			// Try to transfer without permit should fail
			await expect(
				bardsCurationToken.connect(user).transferFrom(
					testWallet.address, userAddress, toBCT('100')
				)
			).revertedWith('ERC20: insufficient allowance')
		})
	});

	describe('mint', function () {
		describe('addMinter', function () {
			it('reject add a new minter if not allowed', async function () {
				await expect(
					bardsCurationToken.addMinter(testWallet.address)
				).revertedWith('Only governance can call');

			})

			it('should add a new minter', async function () {
				expect(await bardsCurationToken.isMinter(testWallet.address)).eq(false);

				await expect(
					bardsCurationToken.connect(governance).addMinter(testWallet.address)
				).to.not.be.reverted;

				expect(await bardsCurationToken.isMinter(testWallet.address)).eq(true);
			})
		});
	})

	context('> when is minter', function () {
		beforeEach(async function () {
			await bardsCurationToken.connect(governance).addMinter(testWallet.address)
			expect(await bardsCurationToken.isMinter(testWallet.address)).eq(true)
		})

		describe('mint', async function () {
			it('should mint', async function () {
				const beforeTokens = await bardsCurationToken.balanceOf(testWallet.address)

				const tokensToMint = toBCT('100')
				await expect(
					bardsCurationToken.connect(testWallet).mint(testWallet.address, tokensToMint)
				).to.not.be.reverted;

				expect(
					await bardsCurationToken.balanceOf(testWallet.address)
				).eq(beforeTokens.add(tokensToMint))
			})

			it('should mint if governor', async function () {
				const tokensToMint = toBCT('100')
				await expect(
					bardsCurationToken.connect(governance).mint(testWallet.address, tokensToMint)
				).to.not.be.reverted;
			})
		})

		describe('removeMinter', function () {
			it('reject remove a minter if not allowed', async function () {
				await expect(
					bardsCurationToken.removeMinter(testWallet.address)
				).to.be.revertedWith('Only governance can call');
			})

			it('should remove a minter', async function () {
				await expect(
					bardsCurationToken.connect(governance).removeMinter(testWallet.address)
				).to.not.be.reverted;

				expect(await bardsCurationToken.isMinter(testWallet.address)).eq(false);
			})
		})

		describe('renounceMinter', function () {
			it('should renounce to be a minter', async function () {
				await expect(
					bardsCurationToken.connect(testWallet).renounceMinter()
				).to.not.be.reverted;

				expect(await bardsCurationToken.isMinter(testWallet.address)).eq(false);
			})
		})
	})
})