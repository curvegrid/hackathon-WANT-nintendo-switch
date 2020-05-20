pragma solidity >=0.5.0 <0.6.0;

import "contracts/erc20.sol";
import "contracts/pool.sol";


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

    /// @dev claimedToken shows the total claimed amount and cost of an ERC20 token
    struct ClaimedToken {
        address tokenAddress;
        uint256 amount;
        uint256 cost;
    }

    /// @notice Deposits amount of tokenAddress into the Pool. You receive the amount of WANT tokens returned.
    function deposit(address tokenAddress, uint256 amount)
        public
        returns (uint256 payout)
    {
        return _depositFrom(msg.sender, tokenAddress, amount);
    }

    /// @notice Returns the claim cost of the next claim.
    function claimCost() public view returns (uint256 cost) {
        return _claimCost(msg.sender);
    }

    /// @notice Burn [claimCost()] WANT tokens in exchange for a single random token in the pool.
    /// @notice Try to perform the withdraw [amount] times
    function claim(uint256 amount) public returns (uint256 claimedAmount) {
        return _claimFrom(msg.sender, amount);
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
    }

    /// @dev Process a claim from the given address.
    /// @dev Return the amount of successfully claimed tokens from the pool
    function _claimFrom(address _address, uint256 _amount)
        private
        returns (uint256 amount)
    {
        // claimedTokens represents the amount of claimed tokens for each ERC20 token
        ClaimedToken[] memory claimedTokens = new ClaimedToken[](NumberOfTokens());

        for (uint256 i = 0; i < _amount; i++) {
            uint256 _cost = _claimCost(_address);

            // Burn the given amount of tokens
            _burn(_address, _cost);

            // If there is no token in the pool, we stop with the withdraw
            if (totalOwnedTokens() == 0) break;
            // Collect the token from the pool
            amount = amount.add(1);
            (address tokenAddress, uint256 claimedAmount) = _withdrawTokenFromPool();

            // check if the claimed token is already in claimedTokens list
            bool found = false;
            for (uint256 j = 0; j < claimedTokens.length; j++) {
                if (claimedTokens[j].tokenAddress == tokenAddress) {
                    claimedTokens[j].amount = claimedTokens[j].amount.add(claimedAmount);
                    claimedTokens[j].cost = claimedTokens[j].cost.add(_cost);
                    found = true;
                    break;
                }
            }

            // cannot find the token, this should not happen
            assert(false);
        }

        // Perform ERC20 transfer for each ERC20 token claimed
        for (uint256 i = 0; i < claimedTokens.length; i++) {
            IERC20 _token = IERC20(claimedTokens[i].tokenAddress);
            _token.transfer(_address, claimedTokens[i].amount);
            // Fire the event
            emit Claim(_address, claimedTokens[i].cost, claimedTokens[i].tokenAddress, claimedTokens[i].amount);
        }
    }
}