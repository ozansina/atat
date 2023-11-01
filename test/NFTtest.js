const { expect } = require("chai");
const {time,loadFixture} = require("@nomicfoundation/hardhat-network-helpers");

describe("NFTContract", function () {
  let owner;
  let fungibleToken;
  let nftContract;
  let anotherUser;

  before(async () => {
    [owner, anotherUser] = await ethers.getSigners();

        // Deploy FungibleToken contract using the owner account
        const FungibleToken = await ethers.getContractFactory("FungibleToken");
        fungibleToken = await FungibleToken.deploy(10000); // Set the desired maxSupply
        await fungibleToken.deployed();
    
        // Deploy NFTContract to the address of the FungibleToken contract
        const NFTContract = await ethers.getContractFactory("NFTContract");
        nftContract = await NFTContract.deploy(fungibleToken.address);
        await nftContract.deployed();
        // Set NFTContract address in FungibleToken
        await fungibleToken.setNFTContract(nftContract.address);
  });

  it("Should deploy with the correct owner and initial state", async function () {
    // Check if the contract owner is set correctly
    const contractOwner = await nftContract.owner();
    expect(contractOwner).to.equal(owner.address);
  });

  it("Should mint NFTs", async function () {
    // Mint NFTs from the contract by the owner
    await nftContract.connect(owner).mintNFT();
    const NFTId = await nftContract.NFTIdCounter();
    const NFTBal = await nftContract.userNFTBalance(owner.address);
    expect(NFTId).to.equal(2);
    expect(NFTBal).to.equal(1);
  });

  it("Should allow users to claim tokens only when they have tokens to claim", async function () {
    // Wait for some time (e.g., 1 day)
    await time.increase(86400); // Increase the time by 1 day (86400 seconds)

    // Call the claimTokens function from the owner
    await nftContract.connect(owner).claimTokens();
    // Check if the user received the expected amount of tokens
    const userTokenBalance = await fungibleToken.balanceOf(owner.address);
    expect(userTokenBalance).to.equal(100); 
    //Function should revert when there is no tokens to claim
    await expect(nftContract.connect(owner).claimTokens()).to.be.reverted;
  });

  it("Should transfer NFTs and update NFT balances correctly", async function () {
    await nftContract.mintNFT(); //Mint the second NFT to transfer
    await time.increase(86400); //Passing another day. Right now owner should have 100+200=300 tokens. AnotherUser still has none NFTs
    
    //Minting another NFT to update IntermediateTokenBalance
    await nftContract.connect(owner).mintNFT();
    const ownerInitIntermediateBal = await nftContract.IntermediateTokenBalance(owner.address); //=200
    expect(ownerInitIntermediateBal).to.equal(200); //Checking if InterTokBal works correctly

    await nftContract['safeTransferFrom(address,address,uint256,bytes)'](owner.address, anotherUser.address,1,[]);
    //await nftContract.safeTransferFrom(owner.address, anotherUser.address, 1, [],{ from: owner.address });

    //Now the sender should have 2 and receiver should have 1 NFT
    expect(await nftContract.userNFTBalance(owner.address)).to.equal(2);
    expect(await nftContract.userNFTBalance(anotherUser.address)).to.equal(1);

  });
  it("Should check if token balance is calculated correctly for both users after token claim", async function () {
      //Now we will check if tokenBalance is calculated truly for both users
    await time.increase(86400); //1 day later, now owner should have 100+200+200=500tokens and anotherUser should have 100tokens
    await nftContract.connect(owner).claimTokens();
      // Check if the user received the expected amount of tokens
    const ownerTokenBalance = await fungibleToken.balanceOf(owner.address);
    expect(await ownerTokenBalance).to.equal(500); 
    await nftContract.connect(anotherUser).claimTokens();
    const anotherUserTokBal = await fungibleToken.balanceOf(anotherUser.address);
    expect(await anotherUserTokBal).to.equal(100);
  })

  // Add more test cases as needed for other functions in NFTContract
});
