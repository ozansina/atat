const { expect } = require("chai");
const {time,loadFixture} = require("@nomicfoundation/hardhat-network-helpers");

describe("FungibleToken", function () {
  let owner;
  let nftContract;
  let fungibleToken;

  before(async () => {
    [owner, nftContract, anotherUser] = await ethers.getSigners();

    [owner] = await ethers.getSigners();

    // Deploy both contracts using the same deployer account
    const FungibleToken = await ethers.getContractFactory("FungibleToken");
    fungibleToken = await FungibleToken.deploy(10000); // Set the desired maxSupply
    await fungibleToken.deployed();

    const NFTContract = await ethers.getContractFactory("NFTContract");
    nftContract = await NFTContract.deploy(fungibleToken.address); // Pass the address of FungibleToken
    await nftContract.deployed();

    // Set NFTContract address in FungibleToken
    await fungibleToken.setNFTContract(nftContract.address);
});

  it("Should deploy with the correct owner and maxSupply", async function () {
    expect(await fungibleToken.owner()).to.equal(owner.address);
    expect(await fungibleToken.maxSupply()).to.equal(10000);
  });

  it("Should mint tokens only by the NFTContract", async function () {
    // Mint tokens from the NFTContract
    await nftContract.mintNFT(); // Adjust this based on your NFTContract minting function
    time.increase(86400);
    // Check if the balance of the recipient (owner) has increased
    const ownerBalanceBefore = await fungibleToken.balanceOf(owner.address);
    await nftContract.claimTokens(); // Adjust this based on your NFTContract token claiming function
    const ownerBalanceAfter = await fungibleToken.balanceOf(owner.address);

    // Ensure the balance increased after minting from NFTContract
    expect(ownerBalanceAfter).to.be.gt(ownerBalanceBefore);

    // Ensure it fails when minted from an address other than the NFTContract
      await expect(fungibleToken.connect(anotherUser).mint(owner.address, 100)).to.be.reverted; // Mint from another account
      // If the above line does not throw an error, the test should fail
      // since minting should only be allowed from NFTContract
  });
  it("Should not mint if maxSupply is exceeded", async function () {
    await expect(fungibleToken.connect(owner).mint(owner.address,10001)).to.be.reverted;
  })

  it("Should set the NFTContract address only by the owner", async function () {
    // Attempt to set the NFTContract address from the owner account
    await fungibleToken.setNFTContract(nftContract.address);

    // Verify that the NFTContract address has been set correctly
    const actualNFTContractAddress = await fungibleToken.nftContract();
    expect(actualNFTContractAddress).to.equal(nftContract.address);

    // Attempt to set the NFTContract address from a different account
    
      await expect(fungibleToken.connect(anotherUser).setNFTContract(anotherUser.address)).to.be.reverted;
     
  });

  // Add more test cases as needed for other functions in FungibleToken
});
