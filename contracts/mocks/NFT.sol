// SPDX-License-Identifier: MIT
/* solhint-disable */
// slither-disable-start naming-convention
pragma solidity 0.8.18;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {
    IERC721Enumerable
} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {
    ERC721Enumerable
} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFT is ERC721Enumerable, ERC2981 {
    uint256 internal _tokenCounter;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

    function mint(address to) external returns (uint256 tokenId) {
        unchecked {
            tokenId = ++_tokenCounter;
        }
        _mint(to, tokenId);
    }

    function setTokenRoyalty(uint256 tokenId, address recipient, uint96 fraction) external {
        _setTokenRoyalty(tokenId, recipient, fraction);
    }

    function setDefaultRoyalty(address recipient, uint96 fraction) external {
        _setDefaultRoyalty(recipient, fraction);
    }

    function deleteDefaultRoyalty() external {
        _deleteDefaultRoyalty();
    }

    /// @inheritdoc IERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ERC721Enumerable) returns (bool) {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenCounter;
    }
}

contract NFT1155 is ERC1155 {
    constructor() ERC1155("https://ipfsxxxx") {}

    function mint(address to) public {
        bytes memory data = new bytes(0);
        _mint(to, 1, 1, data);
    }
}
// slither-disable-end naming-convention
