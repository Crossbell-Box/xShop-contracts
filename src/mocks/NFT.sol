// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFT is ERC721Enumerable {
    constructor() ERC721("NFT", "NFT") {}

    function mint(address to) public {
        uint256 tokenId = totalSupply() + 1;
        _safeMint(to, tokenId);
    }
}
