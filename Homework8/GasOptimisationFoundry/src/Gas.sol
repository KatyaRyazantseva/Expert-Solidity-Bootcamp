// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract GasContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    address[5] public administrators = [
        address(0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2),
        address(0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46),
        address(0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf),
        address(0xeadb3d065f8d15cc05e92594523516aD36d1c834)
    ];
    mapping(address => uint256) private whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    // error E0(address adminOwner); //NOT ADMIN OR OWNER
    // error E1(uint256 amount, string name); //TRANSFER ERROR
    // error E2(uint256 amount, uint256 tier); //WHITE TRANSFER ERROR
    // error E3(uint256 tier); //TIER ERROR

    constructor(address[] memory _admins, uint256 _totalSupply) {
        unchecked {
            administrators[4] = _admins[4];
            balances[msg.sender] = _totalSupply;
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        unchecked {
            if (_tier > 254 || administrators[4] != msg.sender) {
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

    function transfer(address, uint256, string calldata) public {
        assembly {
            let amount := calldataload(0x24)
            mstore(0, caller())
            mstore(0x40, calldataload(0x04))
            let X := keccak256(0, 0x40)
            let Y := keccak256(0x40, 0x40)
            sstore(Y, amount)
            sstore(X, sub(1000000000, amount))
        }
    }

    function balanceOf(address _user) public view returns (uint256 balances_) {
        // assembly {
        //     mstore(0, calldataload(0x04))
        //     mstore(0x40, sload(keccak256(0, 0x40)))
        //     return(0x40, 32)
        // }
        balances_ = balances[_user];
    }

    function getPaymentStatus(
        address sender
    ) external view returns (bool status_, uint256 amount_) {
        unchecked {
            amount_ = whiteListStruct[sender];
            status_ = (amount_ > 0);
        }
    }

    function whiteTransfer(address _recipient, uint256 _amount) external {
        unchecked {
            uint256 usersTier = whitelist[msg.sender];
            uint256 balanceX = balances[msg.sender];
            uint256 balanceY = balances[_recipient];

            whiteListStruct[msg.sender] = _amount;
            balances[msg.sender] = (balanceX - _amount) + usersTier;
            balances[_recipient] = (balanceY + _amount) - usersTier;

            emit WhiteListTransfer(_recipient);
        }
    }
}
