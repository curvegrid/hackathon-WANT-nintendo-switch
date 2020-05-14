pragma solidity >=0.5.0 <0.6.0;


contract ERC20 {
    uint256 public totalSupply;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
}


contract WANTERC20 {
    uint256 public totalSupply = 0;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    // How many WANT tokens each owner has
    mapping(address => uint256) public balanceOf;

    // ERC20 allowance
    mapping(address => mapping(address => uint256)) public allowance;

    function name() public pure returns (string memory) {
        return "WANT";
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount)
        public
        returns (bool)
    {
        if (msg.sender == _from) return transfer(_to, _amount);
        // this is a withdraw
        require(_to == msg.sender);
        require(allowance[_from][_to] >= _amount);
        _transfer(_from, _to, _amount);
        allowance[_from][_to] -= _amount;
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }

    function _transfer(address _from, address _to, uint256 _amount) private {
        require(balanceOf[_from] >= _amount);
        balanceOf[_from] -= _amount;
        balanceOf[_to] += _amount;

        emit Transfer(_from, _to, _amount);
    }
}
