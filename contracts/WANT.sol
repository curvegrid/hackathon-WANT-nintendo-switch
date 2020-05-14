pragma solidity >=0.5.0 <0.6.0;

import "./erc20.sol";


contract WANT is WANTERC20 {
    event Mint(
        address indexed owner,
        uint256 amount,
        address indexed originalTokenAddress,
        uint256 tokenAmount
    );
    event Burn(
        address indexed owner,
        uint256 amount,
        address indexed receivedTokenAddress,
        uint256 tokenAmount
    );

    // For each token, how much do we have
    struct ERC20Token {
        address tokenAddress;
        uint256 amount;
    }
    ERC20Token[] ownedTokenAmounts;
    // Total amount of tokens we have
    uint256 totalOwnedTokens;

    // Mint token -- receives _amount tokens from _tokenAddress,
    // returning the amount of WANT tokens the sender gets.
    function mint(address _tokenAddress, uint256 _amount)
        public
        returns (uint256)
    {
        // Collect the ERC20 token from the sender.
        ERC20 targetToken = ERC20(_tokenAddress);
        targetToken.transferFrom(msg.sender, address(this), _amount);

        uint256 wantAmount = _mintAmount(msg.sender, _tokenAddress, _amount);
        totalSupply += wantAmount;
        balanceOf[msg.sender] += wantAmount;
        totalOwnedTokens += _amount;
        // Find out where the address is
        bool found = false;
        for (uint256 i = 0; i < ownedTokenAmounts.length; i++) {
            ERC20Token storage v = ownedTokenAmounts[i];
            if (_tokenAddress == v.tokenAddress) {
                found = true;
                v.amount += _amount;
                break;
            }
        }
        if (!found) {
            ownedTokenAmounts.push(ERC20Token(_tokenAddress, _amount));
        }
        emit Mint(msg.sender, wantAmount, _tokenAddress, _amount);
        return wantAmount;
    }

    function burn()
        public
        returns (address _tokenAddress, uint256 _receivedAmount)
    {
        uint256 cost = _burnCost(msg.sender);
        require(balanceOf[msg.sender] >= cost);
        balanceOf[msg.sender] -= cost;

        // Which of the tokens to return
        uint256 target = random();
        for (uint256 i = 0; i < ownedTokenAmounts.length; i++) {
            ERC20Token storage v = ownedTokenAmounts[i];
            if (v.amount >= target) {
                ERC20 token = ERC20(v.tokenAddress);
                token.transfer(msg.sender, 1);
                v.amount--;

                emit Burn(msg.sender, cost, v.tokenAddress, 1);

                return (v.tokenAddress, 1);
            }
            target -= v.amount;
        }
    }

    // How much does the minter get from "amount" of "token"
    function _mintAmount(
        address _minter,
        address _tokenAddress,
        uint256 _amount
    ) private view returns (uint256) {
        return _amount;
    }

    // How much does it cost to get a random token back?
    function _burnCost(address _sender) private view returns (uint256) {
        return 1;
    }

    // Get a random number, mod totalOwnedTokens;
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(block.timestamp, block.difficulty))
            ) % totalOwnedTokens;
    }
}
