// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../libraries/DataTypes.sol";

interface IWeb3Entry {
    function getNote(uint256 characterId, uint256 noteId)
        external
        view
        returns (DataTypes.Note memory);
}
