// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title GreenWipeToken
 * @dev ERC-1155 NFT contract for tokenizing environmental impact of device recycling
 * Each token represents CO₂ saved by securely wiping and recycling devices
 */
contract GreenWipeToken is ERC1155, Ownable {
    using Strings for uint256;

    // Contract info
    string public name = "Green Wipe Credits";
    string public symbol = "GWC";
    
    // Token counter
    uint256 private _tokenIdCounter = 1;
    
    // Device type to CO₂ savings mapping (in kg)
    mapping(string => uint256) public deviceCO2Savings;
    
    // Token metadata
    struct TokenMetadata {
        string deviceType;
        string certHash;
        uint256 co2SavedKg;
        string issuedTo;
        uint256 timestamp;
        bool exists;
    }
    
    // Token ID to metadata mapping
    mapping(uint256 => TokenMetadata) public tokenMetadata;
    
    // Organization stats
    mapping(address => uint256) public orgTotalCO2Saved;
    mapping(address => uint256) public orgDevicesWiped;
    mapping(address => string) public orgNames;
    
    // Global stats
    uint256 public totalCO2Saved;
    uint256 public totalDevicesWiped;
    
    // Events
    event GreenTokenMinted(
        uint256 indexed tokenId, 
        address indexed recipient, 
        string deviceType, 
        uint256 co2SavedKg,
        string certHash
    );
    
    event OrganizationRegistered(address indexed org, string orgName);
    
    constructor() ERC1155("https://api.onewipe.app/green-token/{id}.json") {
        // Initialize default CO₂ savings for common device types
        deviceCO2Savings["laptop"] = 200;      // kg CO₂
        deviceCO2Savings["desktop"] = 300;     // kg CO₂
        deviceCO2Savings["smartphone"] = 70;   // kg CO₂
        deviceCO2Savings["tablet"] = 100;      // kg CO₂
        deviceCO2Savings["hdd"] = 50;          // kg CO₂
        deviceCO2Savings["ssd"] = 40;          // kg CO₂
        deviceCO2Savings["server"] = 500;      // kg CO₂
        deviceCO2Savings["monitor"] = 150;     // kg CO₂
        deviceCO2Savings["printer"] = 80;      // kg CO₂
        deviceCO2Savings["router"] = 30;       // kg CO₂
    }
    
    /**
     * @dev Register an organization with a friendly name
     */
    function registerOrganization(string memory orgName) external {
        orgNames[msg.sender] = orgName;
        emit OrganizationRegistered(msg.sender, orgName);
    }
    
    /**
     * @dev Mint a Green Token representing environmental impact of device wipe
     */
    function mintGreenToken(
        address recipient,
        string memory deviceType,
        string memory certHash,
        string memory issuedTo
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;
        
        // Get CO₂ savings for device type (default to 50 kg if unknown)
        uint256 co2Saved = deviceCO2Savings[deviceType];
        if (co2Saved == 0) {
            co2Saved = 50; // Default fallback
        }
        
        // Store token metadata
        tokenMetadata[tokenId] = TokenMetadata({
            deviceType: deviceType,
            certHash: certHash,
            co2SavedKg: co2Saved,
            issuedTo: issuedTo,
            timestamp: block.timestamp,
            exists: true
        });
        
        // Update organization stats
        orgTotalCO2Saved[recipient] += co2Saved;
        orgDevicesWiped[recipient] += 1;
        
        // Update global stats
        totalCO2Saved += co2Saved;
        totalDevicesWiped += 1;
        
        // Mint the NFT (1 copy)
        _mint(recipient, tokenId, 1, "");
        
        emit GreenTokenMinted(tokenId, recipient, deviceType, co2Saved, certHash);
        
        return tokenId;
    }
    
    /**
     * @dev Update CO₂ savings for a device type (only owner)
     */
    function updateDeviceCO2Savings(string memory deviceType, uint256 co2Savings) external onlyOwner {
        deviceCO2Savings[deviceType] = co2Savings;
    }
    
    /**
     * @dev Get token metadata
     */
    function getTokenMetadata(uint256 tokenId) external view returns (TokenMetadata memory) {
        require(tokenMetadata[tokenId].exists, "Token does not exist");
        return tokenMetadata[tokenId];
    }
    
    /**
     * @dev Get organization stats
     */
    function getOrganizationStats(address org) external view returns (
        string memory orgName,
        uint256 totalCO2,
        uint256 devicesWiped
    ) {
        return (
            orgNames[org],
            orgTotalCO2Saved[org],
            orgDevicesWiped[org]
        );
    }
    
    /**
     * @dev Get global sustainability stats
     */
    function getGlobalStats() external view returns (
        uint256 totalCO2,
        uint256 totalDevices
    ) {
        return (totalCO2Saved, totalDevicesWiped);
    }
    
    /**
     * @dev Generate token URI for metadata
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenMetadata[tokenId].exists, "Token does not exist");
        
        // Return API endpoint that will serve JSON metadata
        return string(abi.encodePacked(
            "https://api.onewipe.app/green-token/",
            tokenId.toString(),
            ".json"
        ));
    }
    
    /**
     * @dev Check if token exists
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return tokenMetadata[tokenId].exists;
    }
    
    /**
     * @dev Get next token ID (for frontend)
     */
    function getNextTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }
    
    /**
     * @dev Batch mint tokens (for efficiency)
     */
    function batchMintGreenTokens(
        address[] memory recipients,
        string[] memory deviceTypes,
        string[] memory certHashes,
        string[] memory issuedToNames
    ) external onlyOwner returns (uint256[] memory) {
        require(recipients.length == deviceTypes.length, "Arrays length mismatch");
        require(recipients.length == certHashes.length, "Arrays length mismatch");
        require(recipients.length == issuedToNames.length, "Arrays length mismatch");
        
        uint256[] memory tokenIds = new uint256[](recipients.length);
        
        for (uint256 i = 0; i < recipients.length; i++) {
            tokenIds[i] = mintGreenToken(
                recipients[i],
                deviceTypes[i],
                certHashes[i],
                issuedToNames[i]
            );
        }
        
        return tokenIds;
    }
}