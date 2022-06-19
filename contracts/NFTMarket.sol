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

  struct Order {
    uint itemId;
    address nftContract;
    uint256 tokenId;
    address payable seller;
    address payable buyer; // The buyer
    uint256 price;
    bool sold;
  }
  
  mapping(uint256 => Order) private orders;

  event OrderCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address payable seller,
    address payable buyer,
    uint256 price,
    bool sold
  );

  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  function createOrder(
    address nftContract,
    uint256 tokenId,
    uint256 price
  ) public payable nonReentrant {
    require(price > 0, "Price must be at least 1 wei");
    require(msg.value == listingPrice, "Listing price must be sent over.");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();

    orders[itemId] = Order(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)), // The buyer is unknown atm
      price,
      false
    );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

    emit OrderCreated(
      itemId,
      nftContract,
      tokenId,
      payable(msg.sender),
      payable(address(0)),
      price,
      false
    );
  }

  function processNftSale(
    address nftContract,
    uint256 itemId
  ) public payable nonReentrant {
    uint price = orders[itemId].price;
    uint tokenId = orders[itemId].tokenId;

    require(msg.sender != orders[itemId].seller, "You cannot buy your own NFT.");
    require(msg.value == price, "Please submit the asking price for this purchase");
    
    orders[itemId].seller.transfer(msg.value);
    IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    orders[itemId].buyer = payable(msg.sender);
    orders[itemId].sold = true;
    _itemsSold.increment();
    payable(owner).transfer(listingPrice); // Pay the owner of this contract the listing fee
  }

  function fetchOrders() public view returns (Order[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = itemCount - _itemsSold.current();
    uint currentIndex = 0;

    Order[] memory items = new Order[](unsoldItemCount);
    for (uint i = 1; i < itemCount; i++) {
      if (orders[i].buyer == address(0)) {
        uint currentId = orders[i].itemId;
        Order storage currentItem = orders[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function fetchMyNFTs() public view returns (Order[] memory) {
    uint totalItemsCount = _itemIds.current();
    uint currentIndex = 0;
    uint itemCount = 0;

    for (uint i = 1; i < totalItemsCount; i++) { // We want an array with the exact size fitting the nfts owner by sender
      if (orders[i].buyer == msg.sender
      || (orders[i].seller == msg.sender && orders[i].buyer == address(0))
      ) {
         itemCount += 1;
      }
    }

    Order[] memory items = new Order[](itemCount);
    for (uint i = 1; i < totalItemsCount; i++) {
      if (orders[i].buyer == msg.sender
      || (orders[i].seller == msg.sender && orders[i].buyer == address(0))
      ) {
        uint currentId = orders[i].itemId;
        Order storage currentItem = orders[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  function fetchSoldUserNFTs() public view returns (Order[] memory) {
    uint totalItemsCount = _itemIds.current();
    uint currentIndex = 0;
    uint itemCount = 0;

    for (uint i = 1; i < totalItemsCount; i++) { // We want an array with the exact size fitting the nfts owner by sender
      if (orders[i].seller == msg.sender) {
         itemCount += 1;
      }
    }

    Order[] memory items = new Order[](itemCount);
    for (uint i = 1; i < totalItemsCount; i++) {
      if (orders[i].seller == msg.sender) {
        uint currentId = orders[i].itemId;
        Order storage currentItem = orders[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

}