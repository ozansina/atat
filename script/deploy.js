async function main() {
const [deployer] = await ethers.getSigners();
console.log(`deploying contracts with account: ${deployer.address}`);

const balance = await deployer.getBalance();
console.log(`account balance: ${balance.toString()}`);

const Fung =await ethers.getContractFactory('FungibleToken');
const NFT = await ethers.getContractFactory('NFTContract');
const fung =await Fung.deploy(10000);
const nft = await NFT.deploy(fung.address);
console.log(`token address: ${fung.address}`);
console.log(`nft address: ${nft.address}`)

}

main()
.then(() => process.exit(0))
.catch(error => {
process.exit(1);
});
