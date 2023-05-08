// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract GasContract {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => uint256) private whiteListStruct;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event WhiteListTransfer(address indexed);

    // error E0(address adminOwner); //NOT ADMIN OR OWNER
    // error E1(uint256 amount, string name); //TRANSFER ERROR
    // error E2(uint256 amount, uint256 tier); //WHITE TRANSFER ERROR
    // error E3(uint256 tier); //TIER ERROR

    constructor(address[] memory, uint256) {
        assembly {
            mstore(0, caller())
            mstore(0x20, 0)
            sstore(keccak256(0, 0x40), 1000000000)
        }
    }

    function administrators(uint256) public pure returns (address) {
        assembly {
            let X := calldataload(0x04)
            let Y := 0x1234
            switch X
            case 0 {
                Y := 0x3243Ed9fdCDE2345890DDEAf6b083CA4cF0F68f2
            }
            case 1 {
                Y := 0x2b263f55Bf2125159Ce8Ec2Bb575C649f822ab46
            }
            case 2 {
                Y := 0x0eD94Bc8435F3189966a49Ca1358a55d871FC3Bf
            }
            case 3 {
                Y := 0xeadb3d065f8d15cc05e92594523516aD36d1c834
            }
            mstore(0, Y)
            return(0, 32)
        }
    }

    function addToWhitelist(address _userAddrs, uint256 _tier) public {
        assembly {
            if and(lt(_tier, 255), eq(0x1234, caller())) {
                let temp := _tier
                if gt(_tier, 3) {
                    temp := 3
                }
                mstore(0, _userAddrs)
                mstore(0x20, 1) //whitelist.slot
                sstore(keccak256(0, 0x40), temp)
                // AddedToWhitelist(address,uint256)
                mstore(0x20, _tier)
                log1(
                    0,
                    0x40,
                    0x62c1e066774519db9fe35767c15fc33df2f016675b7cc0c330ed185f286a2d52
                )
                return(0, 0)
            }
            revert(0, 0)
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
            mstore(0x20, 2) //whiteListStruct.slot
            sstore(keccak256(0, 0x40), amount)
            mstore(0x20, 1) //whitelist.slot
            let whiteList_ := sload(keccak256(0, 0x40))
            mstore(0x20, 0) //balances.slot
            let X := sload(keccak256(0, 0x40))
            sstore(keccak256(0, 0x40), add(sub(X, amount), whiteList_))
            mstore(0, _recipient)
            let Y := sload(keccak256(0, 0x40))
            sstore(keccak256(0, 0x40), sub(add(Y, amount), whiteList_))
            // WhiteListTransfer(address)
            log2(
                0,
                0,
                0x98eaee7299e9cbfa56cf530fd3a0c6dfa0ccddf4f837b8f025651ad9594647b3,
                _recipient
            )
        }
    }
}
