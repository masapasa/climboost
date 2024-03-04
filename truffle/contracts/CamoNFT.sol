// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CamoNFT is ERC721, Ownable {
    enum RarityLevel {Common, Uncommon, Rare, Epic, Legendary}

    struct NFT {
        uint256 tokenId;
        RarityLevel rarity;
        uint256 mintTimestamp;
    }

    uint256 private _tokenIdCounter = 0;
    mapping(uint256 => NFT) public nfts;
    mapping(RarityLevel => uint256) public rarityCounts;
    mapping(RarityLevel => uint256) public rarityCaps;
    mapping(RarityLevel => uint256) public rarityPrices;

    event NFTMinted(address to, uint256 tokenId, RarityLevel rarity);

    constructor() ERC721("CamoNFT", "CNFT") {
        rarityCaps[RarityLevel.Common] = 22500;
        rarityCaps[RarityLevel.Uncommon] = 2500;
        rarityCaps[RarityLevel.Rare] = 900;
        rarityCaps[RarityLevel.Epic] = 100;
        rarityCaps[RarityLevel.Legendary] = 25;

        rarityPrices[RarityLevel.Common] = 0.1 ether;
        rarityPrices[RarityLevel.Uncommon] = 0.2 ether;
        rarityPrices[RarityLevel.Rare] = 0.3 ether;
        rarityPrices[RarityLevel.Epic] = 0.5 ether;
        rarityPrices[RarityLevel.Legendary] = 0.8 ether;
    }

    function mintNFT(RarityLevel rarity) public payable {
        require(rarityCounts[rarity] < rarityCaps[rarity], "Rarity cap reached");
        require(msg.value >= rarityPrices[rarity], "Insufficient payment");

        uint256 tokenId = _tokenIdCounter++;
        _safeMint(msg.sender, tokenId);

        nfts[tokenId] = NFT(tokenId, rarity, block.timestamp);
        rarityCounts[rarity]++;

        if (msg.value > rarityPrices[rarity]) {
            payable(msg.sender).transfer(msg.value - rarityPrices[rarity]);
        }

        emit NFTMinted(msg.sender, tokenId, rarity);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer not authorized");
        require(from != to, "What are you doing?");

        // Remove token ID from sender's list
        uint256[] storage fromTokenList = _ownedTokens[from];
        for (uint256 i = 0; i < fromTokenList.length; i++) {
            if (fromTokenList[i] == tokenId) {
                fromTokenList[i] = fromTokenList[fromTokenList.length - 1];
                fromTokenList.pop();
                break;
            }
        }

        // Add token ID to receiver's list
        _ownedTokens[to].push(tokenId);

        // Perform the transfer
        _transfer(from, to, tokenId);

        nfts[tokenId].entryTimestamp = block.timestamp;
        nfts[tokenId].owner = to;
    }

    function getPrice(RarityLevel rarity) public pure returns (uint256) {
        if (rarity == RarityLevel.Common) {
            return COMMON_PRICE;
        } else if (rarity == RarityLevel.Uncommon) {
            return UNCOMMON_PRICE;
        } else if (rarity == RarityLevel.Rare) {
            return RARE_PRICE;
        } else if (rarity == RarityLevel.Epic) {
            return EPIC_PRICE;
        } else if (rarity == RarityLevel.Legendary) {
            return LEGENDARY_PRICE;
        }
        revert("Invalid rarity level");
    }


    function getCap(RarityLevel rarity) public pure returns (uint256) {
        if (rarity == RarityLevel.Common) {
            return COMMON_CAP;
        } else if (rarity == RarityLevel.Uncommon) {
            return UNCOMMON_CAP;
        } else if (rarity == RarityLevel.Rare) {
            return RARE_CAP;
        } else if (rarity == RarityLevel.Epic) {
            return EPIC_CAP;
        } else if (rarity == RarityLevel.Legendary) {
            return LEGENDARY_CAP;
        }
        revert("Invalid rarity level");
    }

    function getCount(RarityLevel rarity) public view returns (uint256) {
        if (rarity == RarityLevel.Common) {
            return commonCount;
        } else if (rarity == RarityLevel.Uncommon) {
            return uncommonCount;
        } else if (rarity == RarityLevel.Rare) {
            return rareCount;
        } else if (rarity == RarityLevel.Epic) {
            return epicCount;
        } else if (rarity == RarityLevel.Legendary) {
            return legendaryCount;
        }
        revert("Invalid rarity level");
    }

    function updateCount(RarityLevel rarity) internal {
        if (rarity == RarityLevel.Common) {
            commonCount++;
        } else if (rarity == RarityLevel.Uncommon) {
            uncommonCount++;
        } else if (rarity == RarityLevel.Rare) {
            rareCount++;
        } else if (rarity == RarityLevel.Epic) {
            epicCount++;
        } else if (rarity == RarityLevel.Legendary) {
            legendaryCount++;
        }
    }

    function getOwnedTokens(address owner) external view onlyAuthorizedContract returns (uint256[] memory) {
        return _ownedTokens[owner];
    }

    function updateTimestamp(address user) external onlyAuthorizedContract {
        uint256[] storage tokenList = _ownedTokens[user];
        for(uint i=0;i< tokenList.length; i++){
            uint256 tokenId = tokenList[i];
            nfts[tokenId].entryTimestamp = block.timestamp;
        }
    }

    function withdrawFunds() public payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }

    function checkBalance() public view onlyOwner returns(uint256){
        return address(this).balance;
    }
}

