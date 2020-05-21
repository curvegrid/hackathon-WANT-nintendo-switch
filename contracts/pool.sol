pragma solidity >=0.5.0 <0.6.0;

import "contracts/erc20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "contracts/UniswapV2Library.sol";

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
        uint256 amount;
    }
    /// @dev For each token, what is the amount of tokens in the pool
    /// @dev this amount is the number of tokens before considering decimals
    ERC20Token[] private _ownedTokenAmounts;

    /// @dev uniswap router with a hard-coded address
    IUniswapV2Router01 _router = IUniswapV2Router01(0xf164fC0Ec4E93095b804a4795bBe1e041497b92a);

    /// @notice Return the amount of a token in the pool
    function ownedTokenAmount(address tokenAddress)
        public
        view
        returns (uint256 amount)
    {
        // if we cannot find the token in pool, the amount is zero
        amount = 0;
        for (uint256 i = 0; i < _ownedTokenAmounts.length; i++) {
            if (_ownedTokenAmounts[i].tokenAddress == tokenAddress) {
                amount = _ownedTokenAmounts[i].amount;
            }
        }
    }

    /// @notice Return the total amount of tokens we own.
    function totalOwnedTokens() public view returns (uint256 amount) {
        amount = 0;
        for (uint256 i = 0; i < _ownedTokenAmounts.length; i++) {
            amount.add(_ownedTokenAmounts[i].amount.div(_getOneTokenAmount(_ownedTokenAmounts[i].tokenAddress)));
        }
    }

    /// @dev Return the total amount of tokens we own before considering decimals
    function _totalOwnedTokensWithoutDecimals() internal view returns (uint256 amount) {
        amount = 0;
        for (uint256 i = 0; i < _ownedTokenAmounts.length; i++) {
            amount.add(_ownedTokenAmounts[i].amount);
        }

    }

    /// @notice Get the number of distinct tokens in the pool
    function NumberOfTokens() public view returns (uint256) {
        return _ownedTokenAmounts.length;
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
                payout = getPayout(_tokenAddress, _amount);
                v.amount = v.amount.add(_amount);
                return payout;
            }
        }
        // Token not found: add it
        payout = getPayout(_tokenAddress, _amount);
        _ownedTokenAmounts.push(ERC20Token(_tokenAddress, _amount));
        return payout;
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
    function _claimCost(address _sender) internal pure returns (uint256) {
        return _oneWANTUnit;
    }

    /// @dev Return reserves of a uniswap pair of tokenAddress and WETH
    function _getUniswapReserves(address _tokenAddress) internal view returns (uint256 reserveWETH, uint256 reserveToken) {
        address wethAddress = _router.WETH();
        address factory = _router.factory();
        (reserveWETH, reserveToken) = UniswapV2Library.getReserves(factory, wethAddress, _tokenAddress);
        // we reject all tokens which cannot convert to WETH by Uniswap-v2
        require(reserveWETH > 0 && reserveToken > 0, "The deposited token is not supported");
    }

    /// @dev Return the amount of one token before considering decimals
    function _getOneTokenAmount(address _tokenAddress) internal pure returns (uint256 amount) {
        IERC20WithDecimals _token = IERC20WithDecimals(_tokenAddress);
        uint8 tokenDecimals = _token.decimals();
        // calculate 10^{tokenDecimals}
        amount = 1;
        for (uint256 i = 0; i < tokenDecimals; i++) {
            amount = amount.mul(10);
        }
    }

    /// @notice Return the expected number of WANT tokens received from a deposit
    function getPayout(address tokenAddress, uint256 amount) public view returns (uint256 payout) {
        // try to find the token from the pool list
        for (uint256 i = 0; i < _ownedTokenAmounts.length; i++) {
            if (_ownedTokenAmounts[i].tokenAddress == tokenAddress) {
                return _depositPayout(tokenAddress, _ownedTokenAmounts[i].amount, amount);
            }
        }
        // not found, querying the payout with 0 as the current token amount in the pool
        return _depositPayout(tokenAddress, 0, amount);
    }

    /// @dev How much does the minter get from "amount" of "token"
    function _depositPayout(address _tokenAddress, uint256 _tokenAmount, uint256 _amount)
        private
        view
        returns (uint256 payout)
    {
        (uint256 reserveWETH, uint256 reserveToken) = _getUniswapReserves(_tokenAddress);

        payout = 1;
        // payout = eth_relative_price * (1 - rarity) * amount_of_tokens * 200
        // in which, 200 is a constant to make one WANT token has an expected price of 1/200 ether,
        // eth_relative_price = reserveToken / reserveWETH is the token's relative price compared to WrappedETH
        // rarity = _erc20Token.amount / (totalOwnedTokens + _amount) is the rarity of the token in the pool
        // amount_of_tokens = _amount / oneTokenAmount is the amount of tokens if we consider decimals

        // nextTotal is the next amount of tokens in the pool before considering decimals
        uint256 nextTotal = _totalOwnedTokensWithoutDecimals().add(_amount);

        payout = payout.mul(reserveToken);
        payout = payout.mul(nextTotal.sub(_tokenAmount));
        payout = payout.mul(_amount);
        payout = payout.mul(200);

        payout = payout.mul(_oneWANTUnit); // the current amount is without WANT decimals

        payout = payout.div(reserveWETH);
        payout = payout.div(nextTotal);
        payout = payout.div(_getOneTokenAmount(_tokenAddress));

        return payout;
    }

    /// @dev Get a pseudorandom number, mod totalOwnedTokens
    function _random() private view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % totalOwnedTokens();
    }
}
