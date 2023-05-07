// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract GasContract {
    // uint256 public immutable totalSupply; // cannot be updated
    uint256 private paymentCounter;
    address private immutable contractOwner;
    mapping(address => uint256) public balances;
    mapping(address => Payment[]) private payments;
    mapping(address => uint256) public whitelist;
    mapping(address => bool) private _administrators; //saves gas for requiring onlyAdminOrOwner
    address[] public administrators;
    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    History[] private paymentHistory; // when a payment was updated

    struct Payment {
        PaymentType paymentType;
        uint256 paymentID;
        bool adminUpdated;
        string recipientName; // max 8 characters
        address recipient;
        address admin; // administrators address
        uint256 amount;
    }

    struct History {
        uint256 lastUpdate;
        address updatedBy;
        uint256 blockNumber;
    }

    mapping(address => uint256) private whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    /*
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        string recipient
    );
    */
    event WhiteListTransfer(address indexed);
    error notAdminOrOwner();
    error transferError();
    error whiteTransferError(uint256 amount, uint256 tier);

    function _onlyAdminOrOwner() internal view {
        // address _owner = contractOwner;
        // assembly {
        //     let admin_ := sload(keccak256(caller(), administrators.slot))
        //     let owner_ := eq(_owner, caller()) //contractOwner
        //     if not(or(owner_, admin_)) {
        //         revert(0, 0) //notAdminOrOwner()
        //     }
        // }

        if (!_administrators[msg.sender] || msg.sender != contractOwner) {
            revert notAdminOrOwner();
        }
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        administrators = _admins;
        for (uint8 i = 0; i < 5; i++) {
            _administrators[_admins[i]] = true;
            if (_admins[i] == msg.sender) {
                balances[msg.sender] = _totalSupply;
                emit supplyChanged(_admins[i], _totalSupply);
            } else {
                // might be a dead-code here
                emit supplyChanged(_admins[i], 0);
            }
        }
    }

    /*
    function getPaymentHistory()
        public
        payable
        returns (History[] memory paymentHistory_)
    {
        return paymentHistory;
    }
    */

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function addHistory(
        address _updateAddress,
        bool _tradeMode
    ) internal returns (bool status_, bool tradeMode_) {
        History memory history;
        history.blockNumber = block.number;
        history.lastUpdate = block.timestamp;
        history.updatedBy = _updateAddress;
        paymentHistory.push(history);
        return (true, _tradeMode);
    }

    /*
    function getPayments(
        address _user
    ) internal view returns (Payment[] memory payments_) {
        assembly {
            if iszero(calldataload(0x04)) {
                revert(0, 0)
            }
            // payments_ := sload(keccak256(payments.slot,calldataload(0x04)))
        }
        return payments[_user];
    }
    */

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public returns (bool status_) {
        uint256 balanceX = balances[msg.sender];
        if (balanceX < _amount || bytes(_name).length > 8) {
            revert transferError();
        }
        uint256 balanceY = balances[_recipient];
        address senderOfTx = msg.sender;
        balanceX -= _amount;
        balanceY += _amount;
        balances[msg.sender] = balanceX;
        balances[_recipient] = balanceY;
        emit Transfer(_recipient, _amount);
        Payment memory payment;
        payment.paymentType = PaymentType.BasicPayment;
        payment.recipient = _recipient;
        payment.amount = _amount;
        payment.recipientName = _name;
        payment.paymentID = ++paymentCounter;
        payments[senderOfTx].push(payment);
        return true;
    }

    /*
    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) internal {
        _onlyAdminOrOwner();
        if (_ID < 0 || _amount < 0 || _user == address(0)) {
            revert();
        }

        Payment[] memory payment = payments[_user];
        for (uint256 ii = 0; ii < payment.length; ii++) {
            if (payment[ii].paymentID == _ID) {
                payments[_user][ii].adminUpdated = true;
                payments[_user][ii].admin = _user;
                payments[_user][ii].paymentType = _type;
                payments[_user][ii].amount = _amount;
                addHistory(_user, true);
                emit PaymentUpdated(
                    msg.sender,
                    _ID,
                    _amount,
                    payment[ii].recipientName
                );
            }
        }
    }
    */

    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        _onlyAdminOrOwner();
        if (_tier > 254) {
            revert();
        }
        if (_tier > 3) {
            _tier = 3;
        }
        whitelist[_userAddrs] = _tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(address _recipient, uint256 _amount) public {
        uint256 usersTier = whitelist[msg.sender];
        uint256 balanceX = balances[msg.sender];
        if (
            balanceX < _amount || _amount <= 3 || usersTier < 1 || usersTier > 3
        ) {
            revert whiteTransferError(_amount, usersTier);
        }
        uint256 balanceY = balances[_recipient];

        whiteListStruct[msg.sender] = _amount;
        balances[msg.sender] = (balanceX - _amount) + usersTier;
        balances[_recipient] = (balanceY + _amount) - usersTier;

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) public view returns (bool status_, uint256 amount_) {
        // assembly {
        //     let amount := sload(keccak256(whiteListStruct.slot, sender))
        //     mstore(0, gt(amount, 0))
        //     mstore(0x20, amount)
        //     return(0, 0x40)
        // }
        amount_ = whiteListStruct[sender];
        status_ = (amount_ > 0);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }

    fallback() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
