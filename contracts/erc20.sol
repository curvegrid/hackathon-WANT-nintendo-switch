pragma solidity >=0.5.0 <0.6.0;



// the first five lines will be ignore by scripts/create_upload.sh

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";


contract WANTDecimals {
    uint8 internal constant _decimals = 3;
    uint256 internal constant _oneWANTUnit = 10**uint256(_decimals);
}


contract WANTERC20 is ERC20Burnable, ERC20Detailed, WANTDecimals {
    constructor() public ERC20Detailed("WANT Token", "WANT", _decimals) {}
}
