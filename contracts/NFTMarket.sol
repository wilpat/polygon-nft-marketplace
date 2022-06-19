// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTMarket is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsSold;

  address payable owner;
  uint256 listingPrice = 0.025 ether;

  constructor() {
    owner = payable(msg.sender);
  }

  struct MarketItem {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable owner; // The buyer
    uint256 price;
    bool sold;
  }
  
  mapping(uint256 => MarketItem) private idToMarketItem;

  event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address payable seller,
    address payable owner,
    uint256 price,
    bool sold
  );

  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  function createMarketItem(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable nonReentrant {
    require(price > 0, "Price must be at least 1 wei");
    require(msg.value == listingPrice, "Listing price must be sent over.");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();

    idToMarketItem[itemId] = MarketItem(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)), // The buyer is unknown atm
      price,
      false
    );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit MarketItemCreated(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      false
    );
  }

  function createMarketSale(
    address nftContract,
    uint256 itemId
  ) public payable nonReentrant {
    uint price = idToMarketItem[itemId].price;
    uint tokenId = idToMarketItem[itemId].tokenId;

    require(msg.sender != idToMarketItem[itemId].seller, "You cannot buy your own NFT.");
    require(msg.value == price, "Please submit the asking price for this purchase");
    
    idToMarketItem[itemId].seller.transfer(msg.value);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    idToMarketItem[itemId].owner = payable(msg.sender);
    idToMarketItem[itemId].sold = true;
    _itemsSold.increment();
    payable(owner).transfer(listingPrice); // Pay the owner of this contract the listing fee
  }

  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = itemCount - _itemsSold.current();
    uint currentIndex = 0;

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 1; i < itemCount; i++) {
      if (idToMarketItem[i].owner == address(0)) {
        uint currentId = idToMarketItem[i].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemsCount = _itemIds.current();
    uint currentIndex = 0;
    uint itemCount = 0;

    for (uint i = 1; i < totalItemsCount; i++) { // We want an array with the exact size fitting the nfts owner by sender
      if (idToMarketItem[i].owner == msg.sender
      || (idToMarketItem[i].seller == msg.sender && idToMarketItem[i].owner == address(0))
      ) {
         itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 1; i < totalItemsCount; i++) {
      if (idToMarketItem[i].owner == msg.sender
      || (idToMarketItem[i].seller == msg.sender && idToMarketItem[i].owner == address(0))
      ) {
        uint currentId = idToMarketItem[i].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function fetchUserSoldMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemsCount = _itemIds.current();
    uint currentIndex = 0;
    uint itemCount = 0;

    for (uint i = 1; i < totalItemsCount; i++) { // We want an array with the exact size fitting the nfts owner by sender
      if (idToMarketItem[i].seller == msg.sender) {
         itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 1; i < totalItemsCount; i++) {
      if (idToMarketItem[i].seller == msg.sender) {
        uint currentId = idToMarketItem[i].itemId;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

}