// blockchain-certs/api/greenToken.js

const { ethers } = require('ethers');

class GreenTokenService {
    constructor(provider, contractAddress, abi, privateKey) {
        this.provider = provider;
        this.contractAddress = contractAddress;
        this.wallet = new ethers.Wallet(privateKey, provider);
        this.contract = new ethers.Contract(contractAddress, abi, this.wallet);
        
        // Device type to CO₂ mapping (matches smart contract)
        this.co2Mappings = {
            'laptop': 200,
            'desktop': 300,
            'smartphone': 70,
            'tablet': 100,
            'hdd': 50,
            'ssd': 40,
            'server': 500,
            'monitor': 150,
            'printer': 80,
            'router': 30
        };
    }

    /**
     * Detect device type from wipe data
     */
    detectDeviceType(wipeData) {
        const targetPath = wipeData.targetPath?.toLowerCase() || '';
        const deviceName = wipeData.deviceName?.toLowerCase() || '';
        
        // Simple device detection logic - can be enhanced
        if (deviceName.includes('laptop') || targetPath.includes('users')) {
            return 'laptop';
        } else if (deviceName.includes('desktop') || deviceName.includes('pc')) {
            return 'desktop';
        } else if (deviceName.includes('phone') || deviceName.includes('mobile')) {
            return 'smartphone';
        } else if (deviceName.includes('tablet') || deviceName.includes('ipad')) {
            return 'tablet';
        } else if (deviceName.includes('server')) {
            return 'server';
        } else if (targetPath.includes('hdd') || deviceName.includes('hard drive')) {
            return 'hdd';
        } else if (targetPath.includes('ssd') || deviceName.includes('solid state')) {
            return 'ssd';
        } else if (deviceName.includes('monitor') || deviceName.includes('display')) {
            return 'monitor';
        } else if (deviceName.includes('printer')) {
            return 'printer';
        } else if (deviceName.includes('router') || deviceName.includes('network')) {
            return 'router';
        }
        
        // Default fallback
        return 'laptop';
    }

    /**
     * Mint a Green Token after successful wipe + certificate
     */
    async mintGreenToken(certData, wipeData, recipientAddress, orgName) {
        try {
            console.log('🌱 Minting Green Token for environmental impact...');
            
            // Detect device type
            const deviceType = this.detectDeviceType(wipeData);
            const co2Saved = this.co2Mappings[deviceType] || 50;
            
            console.log(`Device detected: ${deviceType}, CO₂ saved: ${co2Saved} kg`);
            
            // Prepare transaction
            const tx = await this.contract.mintGreenToken(
                recipientAddress,
                deviceType,
                certData.certHashHex,
                orgName || 'Unknown Organization'
            );
            
            console.log('Green Token minting transaction sent:', tx.hash);
            
            // Wait for confirmation
            const receipt = await tx.wait();
            console.log('Green Token minted successfully!');
            
            // Extract token ID from events
            const mintEvent = receipt.events?.find(e => e.event === 'GreenTokenMinted');
            const tokenId = mintEvent?.args?.tokenId?.toString();
            
            return {
                success: true,
                tokenId: tokenId,
                deviceType: deviceType,
                co2SavedKg: co2Saved,
                txHash: tx.hash,
                blockNumber: receipt.blockNumber,
                gasUsed: receipt.gasUsed.toString(),
                opensea: `https://testnets.opensea.io/assets/amoy/${this.contractAddress}/${tokenId}`
            };
            
        } catch (error) {
            console.error('Error minting Green Token:', error);
            throw error;
        }
    }

    /**
     * Get organization sustainability stats
     */
    async getOrganizationStats(orgAddress) {
        try {
            const stats = await this.contract.getOrganizationStats(orgAddress);
            
            return {
                orgName: stats[0],
                totalCO2Saved: parseInt(stats[1].toString()),
                devicesWiped: parseInt(stats[2].toString())
            };
        } catch (error) {
            console.error('Error getting org stats:', error);
            throw error;
        }
    }

    /**
     * Get global sustainability stats
     */
    async getGlobalStats() {
        try {
            const stats = await this.contract.getGlobalStats();
            
            return {
                totalCO2Saved: parseInt(stats[0].toString()),
                totalDevicesWiped: parseInt(stats[1].toString())
            };
        } catch (error) {
            console.error('Error getting global stats:', error);
            throw error;
        }
    }

    /**
     * Get token metadata
     */
    async getTokenMetadata(tokenId) {
        try {
            const metadata = await this.contract.getTokenMetadata(tokenId);
            
            return {
                deviceType: metadata.deviceType,
                certHash: metadata.certHash,
                co2SavedKg: parseInt(metadata.co2SavedKg.toString()),
                issuedTo: metadata.issuedTo,
                timestamp: parseInt(metadata.timestamp.toString()),
                timestampReadable: new Date(parseInt(metadata.timestamp.toString()) * 1000).toISOString()
            };
        } catch (error) {
            console.error('Error getting token metadata:', error);
            throw error;
        }
    }

    /**
     * Register organization name
     */
    async registerOrganization(orgAddress, orgName) {
        try {
            // Use impersonation or separate wallet for org registration
            const orgWallet = new ethers.Wallet(orgAddress, this.provider);
            const orgContract = new ethers.Contract(this.contractAddress, this.contract.interface, orgWallet);
            
            const tx = await orgContract.registerOrganization(orgName);
            await tx.wait();
            
            return {
                success: true,
                txHash: tx.hash,
                orgName: orgName
            };
        } catch (error) {
            console.error('Error registering organization:', error);
            throw error;
        }
    }

    /**
     * Generate NFT metadata JSON for OpenSea/marketplaces
     */
    generateNFTMetadata(tokenData) {
        const co2Tons = (tokenData.co2SavedKg / 1000).toFixed(2);
        
        return {
            name: `Green Wipe Credit #${tokenData.tokenId}`,
            description: `This NFT represents the environmental impact of securely wiping and recycling a ${tokenData.deviceType}. By choosing to reuse instead of discard, ${tokenData.issuedTo} prevented ${tokenData.co2SavedKg} kg (${co2Tons} tons) of CO₂ from entering the atmosphere.`,
            
            image: `https://api.onewipe.app/green-token/images/${tokenData.deviceType}.png`,
            external_url: `https://onewipe.app/green-tokens/${tokenData.tokenId}`,
            
            attributes: [
                {
                    trait_type: "Device Type",
                    value: tokenData.deviceType.charAt(0).toUpperCase() + tokenData.deviceType.slice(1)
                },
                {
                    trait_type: "CO₂ Saved (kg)",
                    value: tokenData.co2SavedKg,
                    display_type: "number"
                },
                {
                    trait_type: "CO₂ Saved (tons)",
                    value: parseFloat(co2Tons),
                    display_type: "number"
                },
                {
                    trait_type: "Organization",
                    value: tokenData.issuedTo
                },
                {
                    trait_type: "Issued Date",
                    value: new Date(tokenData.timestamp * 1000).toISOString().split('T')[0]
                },
                {
                    trait_type: "Certificate Hash",
                    value: tokenData.certHash
                }
            ],
            
            properties: {
                sustainability_impact: {
                    co2_saved_kg: tokenData.co2SavedKg,
                    device_type: tokenData.deviceType,
                    certification_hash: tokenData.certHash
                }
            }
        };
    }

    /**
     * Get leaderboard data
     */
    async getLeaderboard(limit = 10) {
        try {
            // This would typically require event filtering or a subgraph
            // For now, return mock data structure
            return {
                success: true,
                leaderboard: [
                    // This would be populated from blockchain events
                    // { orgName: "Org A", co2Saved: 10000, devicesWiped: 50, rank: 1 }
                ],
                note: "Leaderboard data requires event indexing - implement with subgraph or event logs"
            };
        } catch (error) {
            console.error('Error getting leaderboard:', error);
            throw error;
        }
    }
}

module.exports = { GreenTokenService };