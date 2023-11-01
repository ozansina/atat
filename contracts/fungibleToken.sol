// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FungibleToken is ERC20, Ownable {
    uint256 public maxSupply;
    address public nftContract;

    modifier onlyNFTContract() {
        require(msg.sender == nftContract, "Not the NFTContract");
        _;
    }
    constructor(uint256 _maxSupply) ERC20("FungibleToken", "FTOK") Ownable(msg.sender){
        maxSupply = _maxSupply;
        
    }

    function mint(address to, uint256 amount) external onlyNFTContract {
        require(totalSupply() + amount <= maxSupply, "Exceeds max supply");
        _mint(to, amount);
    }
       function setNFTContract(address _nftContract) external onlyOwner {
        nftContract = _nftContract;
    }
}