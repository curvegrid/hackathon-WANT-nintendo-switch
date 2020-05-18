pragma solidity >=0.5.0 <0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./erc20.sol";
import "./pool.sol";


contract WANT is WANTERC20, WANTPool {
    /// @notice Deposits an amount of tokens into the WANT pool.
    /// @param owner  The address of the owner
    /// @param amount The amount of WANT tokens received from the deposit.
    /// @param originalTokenAddress The original ERC20 token address.
    /// @param tokenAmount The token amount deposited.
    event Deposit(
        address indexed owner,
        uint256 amount,
        address indexed originalTokenAddress,
        uint256 tokenAmount
    );
    /// @notice Claims a random token from the Pool.
    /// @param owner  The address of the owner
    /// @param amount The amount of WANT tokens used for claiming.
    /// @param receivedTokenAddress The received ERC20 token address.
    /// @param tokenAmount The token amount claimed.
    event Claim(
        address indexed owner,
        uint256 amount,
        address indexed receivedTokenAddress,
        uint256 tokenAmount
    );

    /// @notice Deposits _amount of _tokenAddress into the Pool. You receive the amount of WANT tokens returned.
    function deposit(address _tokenAddress, uint256 _amount)
        public
        returns (uint256 payout)
    {
        return _depositFrom(msg.sender(), _tokenAddress, _amount);
    }

    /// @notice Returns the claim cost of the next claim.
    function claimCost() public view returns (uint256) {
        return _claimCost(msg.sender());
    }

    /// @notice Burn [claimCost()] WANT tokens in exchange for a single random token in the pool.
    function claim() public returns (address tokenAddress, uint256 amount) {
        return _claimFrom(msg.sender());
    }

    /// @dev Deposits _amount of _tokenAddress from _address, giving _address the payout.
    function _depositFrom(
        address _address,
        address _tokenAddress,
        uint256 _amount
    ) private returns (uint256 payout) {
        // Perform the ERC20 token transfer
        IERC20 _token = IERC20(_tokenAddress);
        _token.transferFrom(_address, address(this), _amount);

        // Save the tokens into our pool
        payout = _addTokenToPool(_tokenAddress, _amount);

        // Mint the target WANT tokens
        _mint(_address, payout);

        // Fire the event
        emit Deposit(_address, payout, _tokenAddress, _amount);

        return payout;
    }

    /// @dev Process a claim from the given address.
    function _claimFrom(address _address)
        private
        returns (address tokenAddress, uint256 amount)
    {
        uint256 _cost = _claimCost(_address);

        // Burn the given amount of tokens
        _burn(_address, _cost);

        // Collect the token from the pool
        (tokenAddress, amount) = _withdrawTokenFromPool();

        // Perform ERC20 transfer from the token
        IERC20 _token = IERC20(tokenAddress);
        _token.transfer(_address, 1);

        // Fire the event
        emit Claim(_address, _cost, tokenAddress, amount);

        // Return the claimed token
        return (tokenAddress, amount);
    }
}
