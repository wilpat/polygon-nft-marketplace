const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarket", function () {
  it("Should create and execute orders", async function () {
    const Market = await ethers.getContractFactory("NFTMarket");
    const market = await Market.deploy()
    await market.deployed()
    const marketAddress = market.address;
    console.log({marketAddress})

    const NFT = await ethers.getContractFactory("NFT");
    const nft = await NFT.deploy(marketAddress)
    await nft.deployed()
    const nftContractAddress = nft.address;

    let listingPrice = await market.getListingPrice()
    listingPrice = listingPrice.toString()
    console.log({listingPrice})

    const auctionPrice = ethers.utils.parseUnits("100", "ether");

    await nft.createToken("https://www.mytokenlocation-1.com")
    await nft.createToken("https://www.mytokenlocation-2.com")

    await market.createOrder(
      nftContractAddress,
      1,
      auctionPrice,
      "sell",
      { value: listingPrice }
    )

    await market.createOrder(
      nftContractAddress,
      2,
      auctionPrice,
      "sell",
      { value: listingPrice }
    )

    const [_, buyAddress] = await ethers.getSigners()

    await market.connect(buyAddress).processNftSale(
      nftContractAddress,
      1,
      { value: auctionPrice }
    )
    
    let items = await market.fetchOrders()
    items = await Promise.all(items.map(async item => {
      const tokenUri = await nft.tokenURI(Number(item.tokenId))
      return {
        ...item,
        price: item.price.toString(),
        tokenId: item.tokenId.toString(),
        tokenUri
      }
    }))
    console.log({items})

  });
});
