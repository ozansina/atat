// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./nftcontract.sol";

contract HipodromMarketplace is ERC721, Ownable {
    
    NFTContract public nftContract;

    modifier onlyNFTOwner() {
        require(balanceOf(msg.sender)>0, "Not an NFT Owner");
        _;
    }
    struct Listing {
        address seller;
        uint256 price;
        uint256 buyNowPrice;
        string tokenURI;
        uint256 listingTime;
    }
    struct Bidding {
        address bidder;
        address seller;
        uint256 bidAmount;
        string tokenURI;
    }
    struct Buying {
        address buyer;
        address seller;
        uint256 price;
        string tokenURI;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => Bidding) public bids;
    mapping(uint256 => Buying) public transfers;
    mapping(uint256 => uint256) public listingPrice;

    event NFTListed(address indexed seller, uint256 indexed tokenID, uint256 listingPrice, uint256 buyNowPrice, uint256 listingTime);
    event BidMade(address indexed seller, address indexed bidder, uint256 indexed tokenID, uint256 bidAmount);
    event NFTSold(address indexed seller, address indexed buyer, uint256 indexed tokenID, uint256 sellPrice);

    constructor(address _nftcontractAddress) ERC721("HipodromMarketplace", "HPMP") Ownable(msg.sender) {
        nftContract = NFTContract(_nftcontractAddress);
    }

    function sendToMarket(uint256 tokenID, uint256 askPrice, uint256 askBuyNowPrice, string memory tokenURI, uint256 time) external onlyNFTOwner {
        require(msg.sender==ownerOf(tokenID), "Token does not belong to msg.sender");
        Listing memory newListing = Listing({
            seller: msg.sender,
            price: askPrice,
            buyNowPrice: askBuyNowPrice,
            tokenURI: tokenURI,
            listingTime: time
        });

        listings[tokenID] = newListing;

        setPrice(tokenID,askPrice);
        uint256 price = getPrice(tokenID);
        emit NFTListed(msg.sender,tokenID,price,askBuyNowPrice,time);
    }
    function setPrice(uint256 tokenID, uint256 price) internal onlyNFTOwner {
        listingPrice[tokenID] = price;
    }
    function getPrice(uint256 tokenID) internal onlyNFTOwner view returns (uint256) {
        return listingPrice[tokenID];
    }
    //function quickSell(address user, uint256 tokenID) external onlyNFTOwner{
    //    nftContract.burn(user,tokenID);
    //    userNFTBalance -=1;
    //}
    function bid(uint256 tokenID, address sellerAddress, uint256 bidAmount, string memory tokenURI) external {
        uint256 bidderBalance = 100; //This is a placeholder which substitutes function from frontend that gives us the user balance
        require(bidderBalance>(listings[tokenID].price), "Not enough coins to bid");
        //At this point we also need to check if the bid amount is bigger than the previous bid but I couldnt figure out how to
        Bidding memory newBid = Bidding ({
            bidder: msg.sender,
            seller: sellerAddress,
            bidAmount: bidAmount,
            tokenURI: tokenURI
        });
        bids[tokenID]=newBid;
        emit BidMade(sellerAddress,msg.sender,tokenID, bidAmount);
    }
    function decideBuyer(uint256 tokenID,address sellerAddress, address lastBidder, uint256 lastBidAmount, string memory tokenURI ) external payable {
        uint256 timePassed = 100; //This is a placeholder for a function that calculates the time passed since the the listing made
        require(timePassed>(listings[tokenID].listingTime),"Bidding period is still active");
        Buying memory newSell = Buying ({
            buyer: lastBidder,
            seller: sellerAddress,
            price: lastBidAmount,
            tokenURI: tokenURI
        });
        transfers[tokenID] = newSell;
        // I couldnt figure out how to implement safetransfer (once again xd)
        //nftContract['safeTransferFrom(address,address,uint256,bytes)'](sellerAddress, msg.sender,tokenID, tokenURI);
        emit NFTSold(sellerAddress,lastBidder, tokenID, lastBidAmount);        
    }
    function buyNow(uint256 tokenID, address sellerAddress, uint256 buyNowPrice,string memory tokenURI ) external payable {
        uint256 buyerBalance = 100; //This is a placeholder which substitutes function from frontend that gives us the user balance
        require(buyerBalance>(listings[tokenID].buyNowPrice), "Not enough coins to direct purchase");
        Buying memory newSell = Buying ({
            buyer: msg.sender,
            seller: sellerAddress,
            price: buyNowPrice,
            tokenURI: tokenURI
        });
        transfers[tokenID] = newSell;
        // I couldnt figure out how to implement safetransfer (once again xd)
        //nftContract['safeTransferFrom(address,address,uint256,bytes)'](sellerAddress, msg.sender,tokenID, tokenURI);
        emit NFTSold(sellerAddress,msg.sender, tokenID, buyNowPrice);        
    }


}