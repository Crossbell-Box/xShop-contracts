// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.8.16;

import "../../contracts/interfaces/IWeb3Entry.sol";
import "../../contracts/libraries/DataTypes.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract MockWeb3Entry is IWeb3Entry, ERC721Enumerable {
    address public mintNoteNFT;

    constructor(address _nftAddress) ERC721("Web3 Entry Character", "WEC") {
        mintNoteNFT = _nftAddress;
    }

    function mintCharacter(address to) public {
        uint256 tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);
    }

    // if noteId is 1, returns mintNFT
    function getNote(
        uint256 characterId,
        uint256 noteId
    ) external view returns (DataTypes.Note memory) {
        (characterId);

        address nftAddress;
        if (noteId == 1) {
            nftAddress = mintNoteNFT;
        } else {
            nftAddress = address(0);
        }

        DataTypes.Note memory note = DataTypes.Note(
            0,
            0,
            "note content",
            address(0),
            address(0),
            nftAddress,
            false,
            false
        );
        return note;
    }
}
