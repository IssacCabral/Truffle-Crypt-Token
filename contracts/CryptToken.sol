// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CryptToken {
    // VARIABLES, MAPPS AND DATA STRUCTURES
    address private owner;

    uint private _maxMintLimit;
    uint private _accruedFee;
    uint private _percentageOfFeeCharged;
    uint private deadLine;

    string private _name;
    string private _symbol;

    mapping(address => uint) private _balanceOf;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _vipClients;
    mapping(address => uint) private _transationsTime;

    bool public pausedTransfers = false;
    
    struct Transaction {
        address from;
        address to;
        uint value;
    }

    Transaction[] public transactions;

    // CONSTRUCTOR
    constructor(string memory _tokenName, string memory _tokenSymbol, uint maxMintLimit){
        owner = msg.sender;
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _maxMintLimit = maxMintLimit;
        _percentageOfFeeCharged = 10;
    }

    // EVENTS
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    // MODIFIERS
    modifier onlyOwner(){
        require(msg.sender == owner, "You are not allowed");
        _;
    }

    modifier onlyNoPause{
        require(!pausedTransfers, "Transfers currently paused");
        _;
    }

    //-------------------ERC20 TOKEN - begin ---------------------//
    function name() public view returns (string memory){return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return 18;}

    function transfer(address _to, uint256 _value) public onlyNoPause returns (bool success) {
        require(_balanceOf[msg.sender] >= _value, "Value not enough to sent");
        require(_to != address(0));

        if(!_vipClients[msg.sender]) {
            uint transactionRate = (_value * getPercentageOfFeeCharged()) / 100;

            _accruedFee += transactionRate;
            _balanceOf[msg.sender] -= _value;
            _balanceOf[_to] += _value - transactionRate;

            transactions.push(Transaction(msg.sender, _to, _value));
            emit Transfer(msg.sender, _to, _value);
            return true;
        }else{
            _balanceOf[msg.sender] -= _value;
            _balanceOf[_to] += _value;

            transactions.push(Transaction(msg.sender, _to, _value));
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) public onlyNoPause returns (bool success) {
        require(_from != address(0) && _to != address(0));
        require(_allowances[_from][msg.sender] >= _value, "You are not allowed to send this value");
        require(_balanceOf[_from] >= _value, "The balance of who you are trying to send is insufficient");

        if(!_vipClients[_from]) {
            uint transactionRate = (_value * getPercentageOfFeeCharged()) / 100;

            _accruedFee += transactionRate;
            _balanceOf[_from] -= _value;
            _balanceOf[_to] += _value - transactionRate;
            _allowances[_from][msg.sender] -= _value;

            transactions.push(Transaction(_from, _to, _value));
            emit Transfer(msg.sender, _to, _value);
            return true;
        }else{
            _balanceOf[_from] -= _value;
            _balanceOf[_to] += _value;
            _allowances[_from][msg.sender] -= _value;

            transactions.push(Transaction(_from, _to, _value));
            emit Transfer(msg.sender, _to, _value);
            return true;
        }

    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0));
        _allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowances[_owner][_spender];
    } 

    //------------------SETTERS AND GETTERS--------------------------//
    function setPausedTransfers(bool _value) public onlyOwner{pausedTransfers = _value;}
    function setMaxMintLimit(uint _value) public onlyOwner{_maxMintLimit = _value;}
    function setVipClient(address client) public onlyOwner{_vipClients[client] = true;}
    function setPercentageOfFeeCharged(uint _value) public onlyOwner{require(_value != 0); _percentageOfFeeCharged = _value;}

    function getMaxMintLimit() public view onlyOwner returns(uint){return _maxMintLimit;}
    function getVipClient(address client) public view returns(bool){return _vipClients[client];}
    function getAccruedFee() public view onlyOwner returns(uint){return _accruedFee;}
    function getPercentageOfFeeCharged() public view returns(uint){return _percentageOfFeeCharged;}
    function getContractBalance() external view returns(uint) {return address(this).balance;}
    function balanceOf(address account) public view returns (uint256 balance) {return _balanceOf[account];}

    function donate(address payable _to) public payable{
        require(msg.value <= 1 ether, "Your transfer limit is 1 ether");
        require(block.timestamp >= _transationsTime[msg.sender], "You need to wait longer to be able to donate");

        _to.transfer(msg.value);
        _transationsTime[msg.sender] = block.timestamp + 30 days;
    }

    function mint(address account, uint amount) public onlyOwner onlyNoPause{
        require(_maxMintLimit >= amount, "You cannot mint more than the maximum amount");
        require(account != address(0));

        _maxMintLimit -= amount;
        _balanceOf[account] += amount;
        
        transactions.push(Transaction(address(0), account, amount));
        emit Transfer(address(0), account, amount);
    }

    function withdrawAccruedFees() public onlyOwner{
        _balanceOf[owner] += _accruedFee;
        _accruedFee = 0;
    }
}