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
	getBCTPermitWithSigParts
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
				bardsCurationToken.connect(testWallet).permit(
					testWallet.address,
					userAddress,
					tokensToApprove,
					{
						v,
						r,
						s,
						deadline: MAX_UINT256,
					},
				)
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
				bardsCurationToken.connect(testWallet).permit(
					testWallet.address,
					userAddress,
					tokensToApprove,
					{
						v,
						r,
						s,
						deadline: MAX_UINT256,
					},
				)
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
				bardsCurationToken.connect(testWallet).permit(
					testWallet.address,
					userAddress,
					tokensToApprove,
					{
						v,
						r,
						s,
						deadline: MAX_UINT256,
					},
				)
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
				bardsCurationToken.connect(testWallet).permit(
					testWallet.address,
					userAddress,
					tokensToApprove,
					{
						v,
						r,
						s,
						deadline: '0'
					},
				)
			).to.be.revertedWithCustomError(
				errorsLib,
				ERRORS.SIGNATURE_EXPIRED
			);
		})


	});
})