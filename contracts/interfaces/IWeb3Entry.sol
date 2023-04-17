// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IWeb3Entry {
    function getNote(
        uint256 characterId,
        uint256 noteId
    ) external view returns (DataTypes.Note memory);
}
