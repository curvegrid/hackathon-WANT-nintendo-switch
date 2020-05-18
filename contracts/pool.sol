pragma solidity >=0.5.0 <0.6.0;

import "./erc20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


/// @dev Handles the Pool part of the system. It does not interact with the WANT ERC20 token, nor
/// @dev the other ERC20 tokens in anyway.
contract WANTPool is WANTDecimals {
    using SafeMath for uint256;

    struct ERC20Token {
        address tokenAddress;
        uint256 amount;
    }
    /// @dev For each token, how much do we have
    ERC20Token[] private _ownedTokenAmounts;
    /// @dev Total amount of tokens we have
    uint256 private _totalOwnedTokens;

    /// @notice Returns the amount of tokens we have as an array.
    function ownedTokenAmount(uint256 index)
        public
        view
        returns (address tokenAddress, uint256 amount)
    {
        ERC20Token storage v = _ownedTokenAmounts[index];
        return (v.tokenAddress, v.amount);
    }

    /// @notice Returns the total amount of tokens we own.
    function totalOwnedTokens() public view returns (uint256) {
        return _totalOwnedTokens;
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
                v.amount.add(_amount);
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
        require(
            _totalOwnedTokens >= 0,
            "There must be at least one token in the pool to claim"
        );
        _totalOwnedTokens--;

        uint256 current = _random();
        for (uint256 i = 0; i < _ownedTokenAmounts.length; i++) {
            ERC20Token storage v = _ownedTokenAmounts[i];
            if (v.amount > current) {
                v.amount.sub(1);
                return (v.tokenAddress, 1);
            } else {
                current -= v.amount;
            }
        }
        assert(false); // We should never reach here
    }

    /// @dev How much does it cost to get a random token back?
    function _claimCost(address _sender) internal view returns (uint256) {
        return _oneWANTUnit;
    }

    /// @dev How much does the minter get from "amount" of "token"
    function _depositPayout(ERC20Token storage _erc20Token, uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount;
    }

    // Get a random number, mod totalOwnedTokens;
    function _random() private view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % _totalOwnedTokens;
    }
}
