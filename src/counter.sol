// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

library Counters {

    error IntegerUnderflow();

    struct Counter {
        uint256 value;
    }

    function current(Counter storage counter) internal view returns (uint256 count) {
        assembly {
            count := sload(counter.slot)
        }
    }
    
    function increment(Counter storage counter) internal {
        assembly {
            sstore(counter.slot, add(sload(counter.slot), 1))
        }
    }

    function decrement(Counter storage counter) internal {
        assembly {
            let value := sload(counter.slot)

            if iszero(value) {
                mstore(0x00, 0x6dbd55ba)
                revert(0x1c, 0x04)
            }

            sstore(counter.slot, sub(value, 1))
        }
    }

    function reset(Counter storage counter) internal {
        assembly {
            sstore(counter.slot, 0)
        }
    }

}