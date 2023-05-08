// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract GasContract {
    address private immutable contractOwner;
    //uint256 private paymentCounter;  Variable not used
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    address[] public administrators;
    mapping(address => bool) private _administrators; //saves gas for requiring onlyAdminOrOwner
    mapping(address => uint256) private whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event WhiteListTransfer(address indexed);

    // error E0(address adminOwner); //NOT ADMIN OR OWNER
    // error E1(uint256 amount, string name); //TRANSFER ERROR
    // error E2(uint256 amount, uint256 tier); //WHITE TRANSFER ERROR
    // error E3(uint256 tier); //TIER ERROR

    constructor(address[] memory _admins, uint256 _totalSupply) {
        unchecked {
            contractOwner = msg.sender;
            administrators = _admins;
            for (uint8 i = 0; i < 5; i++) {
                _administrators[_admins[i]] = true;
                if (_admins[i] == msg.sender) {
                    balances[msg.sender] = _totalSupply;
                    emit supplyChanged(_admins[i], _totalSupply);
                } else {
                    emit supplyChanged(_admins[i], 0);
                }
            }
        }
    }
    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        unchecked {
            if (_tier > 254) {
                revert(); // E3(_tier);
            }
            if (!_administrators[msg.sender] || msg.sender != contractOwner) {
                revert(); // E0(msg.sender);
            }
            uint256 temp = _tier; 
            if (_tier > 3) {
                temp = 3;
                
            }
            whitelist[_userAddrs] = temp;

            emit AddedToWhitelist(_userAddrs, _tier);
        }
    }
    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
        ) public returns (bool) {
        unchecked {
            uint256 balanceX = balances[msg.sender];
            if (balanceX < _amount || bytes(_name).length > 8) {
                revert(); // E1(_amount, _name);
            }
            uint256 balanceY = balances[_recipient];
            balances[msg.sender] = balanceX - _amount;
            balances[_recipient] = balanceY + _amount;
            emit Transfer(_recipient, _amount);
        }
        return true;
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function getPaymentStatus(
        address sender
        ) external view returns (bool status_, uint256 amount_) { //changed visibility to external
        unchecked {
            amount_ = whiteListStruct[sender];
            status_ = (amount_ > 0);
        }
    }

    function whiteTransfer(address _recipient, uint256 _amount) external { //changed visibility to external
        unchecked {
            uint256 usersTier = whitelist[msg.sender];
            uint256 balanceX = balances[msg.sender];
            if (
                balanceX < _amount ||
                _amount <= 3 ||
                usersTier < 1 ||
                usersTier > 3
            ) {
                revert(); // E2(_amount, usersTier);
            }
            uint256 balanceY = balances[_recipient];

            whiteListStruct[msg.sender] = _amount;
            balances[msg.sender] = (balanceX - _amount) + usersTier;
            balances[_recipient] = (balanceY + _amount) - usersTier;

            emit WhiteListTransfer(_recipient);
        }
    }

}
