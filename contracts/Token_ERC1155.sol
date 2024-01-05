// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";


contract Token_ERC1155 is ERC1155  
{

    uint256 private _tokenIdCounter;
    mapping(uint256 => string) private _hashIPFS;


    constructor() ERC1155("Token_ERC1155")  
    {
    
        _setURI('https://salmon-opposite-porcupine-429.mypinata.cloud/ipfs/');

        _tokenIdCounter = 0;

    }

    
    function safeMint(string[] memory _hashes, uint256 QuantityToken) public  payable {

        for (uint256 i = 0; i < _hashes.length; i++){

            uint256 tokenId = _tokenIdCounter;

            _mint(msg.sender, tokenId, QuantityToken, "");

            // console.log('==========');
            // console.log(tokenId);
            // console.log('==========');


            _hashIPFS[tokenId] = _hashes[i];

            _tokenIdCounter += 1;

        }
        
    }

    function tokenURI(uint256 tokenId)
    public
    view
    returns (string memory)
    {

        string memory currentBaseURI = uri(0);

        return
            (bytes(currentBaseURI).length > 0 &&
                bytes(_hashIPFS[tokenId]).length > 0)
            ? string(abi.encodePacked(currentBaseURI, _hashIPFS[tokenId]))
            : "";

    }


     function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }















  


  

}

