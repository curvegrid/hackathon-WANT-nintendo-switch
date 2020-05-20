pragma solidity >=0.5.0 <0.6.0;

import "contracts/erc20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";

/// @dev A uniswap router interface to find the addresses of WETH coin and uniswap's factory
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IERC20WithDecimals {
    function decimals() external pure returns (uint8);
}

/// @dev Handles the Pool part of the system. It does not interact with the WANT ERC20 token, nor
/// @dev the other ERC20 tokens in anyway.
contract WANTPool is WANTDecimals {
    using SafeMath for uint256;

    struct ERC20Token {
        address tokenAddress;
        uint256 amount; // the token amount before taking decimals into account
    }
    /// @dev For each token, what is the amount of tokens in the pool
    ERC20Token[] private _ownedTokenAmounts;

    /// @dev uniswap router
    IUniswapV2Router01 _router = IUniswapV2Router01(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);

    /// @notice Returns the amount of tokens we have as an array.
    function ownedTokenAmount(uint256 index)
        public
        view
        returns (address tokenAddress, uint256 amount)
    {
        ERC20Token storage v = _ownedTokenAmounts[index];
        return (v.tokenAddress, v.amount.div(_getOneTokenAmount(v.tokenAddress)));
    }

    /// @notice Returns the total amount of tokens we own.
    function totalOwnedTokens() public view returns (uint256 amount) {
        uint256 amount = 0;
        for (uint256 i = 0; i < _ownedTokenAmounts.length; i++) {
            amount.add(_ownedTokenAmounts[i].amount.div(_getOneTokenAmount(_ownedTokenAmounts[i].tokenAddress)));
        }
        return amount;
    }

    /// @dev Returns the total amount of tokens we own before taking decimals into account
    function _totalOwnedTokensWithoutDecimals() internal view returns (uint256) {
        uint256 amount = 0;
        for (uint256 i = 0; i < _ownedTokenAmounts.length; i++) {
            amount.add(_ownedTokenAmounts[i].amount);
        }
        return amount;

    }

    /// @dev Add a token (with amount) to the pool, returning the amount of supposed payout.
    function _addTokenToPool(address _tokenAddress, uint256 _amount)
        internal
        returns (uint256 payout)
    {
        // Find and add the token
        for (uint256 i = 0; i < _ownedTokenAmounts.length; i++) {
            ERC20Token storage v = _ownedTokenAmounts[i];
            if (v.tokenAddress == _tokenAddress) {
                v.amount = v.amount.add(_amount);
                return _depositPayout(v, _amount);
            }
        }
        // Token not found: add it
        _ownedTokenAmounts.push(ERC20Token(_tokenAddress, _amount));
        return
            _depositPayout(
                _ownedTokenAmounts[_ownedTokenAmounts.length - 1],
                _amount
            );
    }

    /// @dev Withdraw a single (random) token from the pool.
    function _withdrawTokenFromPool()
        internal
        returns (address tokenAddress, uint256 amount)
    {
        uint256 current = _random();
        for (uint256 i = 0; i < _ownedTokenAmounts.length; i++) {
            ERC20Token storage v = _ownedTokenAmounts[i];
            uint256 oneTokenAmount = _getOneTokenAmount(v.tokenAddress);
            if (v.amount > current) {
                v.amount = v.amount.sub(oneTokenAmount);
                return (v.tokenAddress, oneTokenAmount);
            } else {
                current = current.sub(v.amount.div(oneTokenAmount));
            }
        }
        assert(false); // We should never reach here
    }

    /// @dev How much does it cost to get a random token back?
    function _claimCost(address _sender) internal view returns (uint256) {
        return _oneWANTUnit;
    }

    /// @dev Return reserves of a uniswap pair of tokenAddress and WETH
    function _getUniswapReserves(address tokenAddress) internal view returns (uint256 reserveWETH, uint256 reserveToken) {
        address wethAddress = _router.WETH();
        address factory = _router.factory();
        (reserveWETH, reserveToken) = tokenUniswapV2Library.getReserves(factory, wethAddress, tokenAddress);
        // we reject all tokens which cannot convert to WETH by Uniswap-v2
        require(reserveWETH > 0 && reserveToken > 0, "The deposited token is not supported");
    }

    /// @dev Return the amount of one token before taking decimals into account
    function _getOneTokenAmount(address tokenAdress) internal view returns (uint256 amount) {
        IERC20 _token = IERC20WithDecimals(TokenAddress);
        uint8 tokenDecimals = _token.decimals();
        // calculate 10^{tokenDecimals}
        uint256 pow10 = 1;
        for (uint256 i = 0; i < tokenDecimals; i++) {
            pow10 = pow10.mul(pow10, 10);
        }
        return pow10;
    }

    /// @dev How much does the minter get from "amount" of "token"
    function _depositPayout(ERC20Token storage _erc20Token, uint256 _amount)
        private
        view
        returns (uint256)
    {
        (reserveWETH, reserveToken) = _getUniswapReserves(_erc20Token.tokenAddress);

        uint256 returnAmount = 1;
        // returnAmount = eth_relative_price * (1 - rarity) * amount_of_tokens * 200
        // in which, 200 is a constant to make one WANT token has an expected price of 1/200 ether,
        // eth_relative_price = reserveToken / reserveWETH is the token's relative price compared to WrappedETH
        // rarity = _erc20Token.amount / (totalOwnedTokens + _amount) is the rarity of the token in the pool
        // amount_of_tokens = _amount / oneTokenAmount is the amount of tokens if we take decimals into account

        // nextTotal is the next amount of tokens in the pool before taking decimals into account
        uint256 nextTotal = _totalOwnedTokensWithoutDecimals().add(_amount);

        returnAmount = returnAmount.mul(reserveToken);
        returnAmount = returnAmount.mul(_sub(nextTotal, _erc20Token.amount));
        returnAmount = returnAmount.mul(_amount);
        returnAmount = returnAmount.mul(200);

        returnAmount = returnAmount.div(reserveWETH);
        returnAmount = returnAmount.div(nextTotal);
        returnAmount = returnAmount.div(_getOneTokenAmount(tokenAddress));

        return returnAmount;
    }

    // Get a pseudorandom number, mod totalOwnedTokens;
    function _random() private view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % totalOwnedTokens();
    }
}
