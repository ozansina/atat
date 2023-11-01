// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./fungibleToken.sol";


contract NFTContract is ERC721, Ownable {
    //using SafeMath for uint256;
    using Strings for uint256;
    using Math for uint256;
    FungibleToken public fungibleToken;
    mapping(address => uint256) public userNFTBalance;
    mapping(address => uint256) public lastMintTimestamp;
    mapping(address => uint256) public IntermediateTokenBalance; //yeni NFT mintlendiğinde token mintlemeden token sayısını tutabilmek için
    //iki fonksiyonda da kullanacağimiz variable'ları universal tanımladım
    uint256 public NFTIdCounter =1;
    uint256 currentTimestamp;
    uint256 daysPassed;
    bool success;
    string public baseURI;
    string public baseExtension = ".json";

    constructor(address _fungibleTokenAddress) ERC721("NFTContract", "NFTC") Ownable(msg.sender) {
        fungibleToken = FungibleToken(_fungibleTokenAddress);
        lastMintTimestamp[msg.sender] = block.timestamp; 
        //Deploy anında minttime alıyorum ki variable boş kalmasın, zaten ilk nft mintinde "daysPassed" argümanı işlevsiz 
        //olacak çarpım 0 olacağı için
        
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
    }

    function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require((tokenId<=NFTIdCounter),"ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }
    function mintNFT(address user, uint256 randTokID) public {
        _safeMint(user, randTokID); 
        NFTIdCounter +=1;
        userNFTBalance[user] += 1;
        currentTimestamp =block.timestamp;
        //Yeni NFT ürettiğimizde aradaki sürede eldeki NFT'lerden yield edilen token miktarını storeluyorum ancak işlem yapmıyorum
        (success,daysPassed) = currentTimestamp.trySub(lastMintTimestamp[msg.sender]);
        IntermediateTokenBalance[msg.sender] += (userNFTBalance[msg.sender]-1)*100*daysPassed/86400; 
        //Son eklediğimiz NFT'yi hariç bıraktığımız için hesaplamada -1 kullandım.
        lastMintTimestamp[msg.sender] = block.timestamp; //Last mint'i stampliyoruz
    }

   function claimTokens() external {
    currentTimestamp = block.timestamp; //Claim anındaki time'ı stampliyoruz
    (success,daysPassed) = currentTimestamp.trySub(lastMintTimestamp[msg.sender]);

    uint256 tokensToClaim;
    tokensToClaim += 100*daysPassed*userNFTBalance[msg.sender]/86400+IntermediateTokenBalance[msg.sender];
    //Token balanceımızı, son mintten şimdiye kadarki tüm NFT'lerin yield ettiği token+intermediate step'lerde 
    // yield edilen tokenler toplamına eşitledim
    IntermediateTokenBalance[msg.sender] = 0; //Claim ettiğimiz için 0lıyorum
    
    require(tokensToClaim > 0, "No tokens to claim");
    
    fungibleToken.mint(msg.sender, tokensToClaim);
    //Token balance'ımız kadar mintleyip claimliyoruz ve balance'ı 0lıyoruz
    lastMintTimestamp[msg.sender] = currentTimestamp; //Last mint'i tekrar stampliyoruz
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        currentTimestamp = block.timestamp;
        (success,daysPassed) = currentTimestamp.trySub(lastMintTimestamp[msg.sender]);
        IntermediateTokenBalance[from] += userNFTBalance[from]*100*daysPassed/86400;
        userNFTBalance[from] -= 1;
        userNFTBalance[to] += 1;
        super.safeTransferFrom(from,to, tokenId, data);
        lastMintTimestamp[from] = block.timestamp;
        lastMintTimestamp[to] = block.timestamp;
    }
    function burn(address nftOwner,uint256 tokenId) external {
        require(nftOwner==ownerOf(tokenId), "Token does not belong to msg.sender");
        _burn(tokenId);
    }
}