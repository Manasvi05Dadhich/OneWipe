// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract WipeCertificateRegistry {
    struct Certificate {
        string certHash; // SHA-256 hash of JSON/PDF cert
        uint256 timestamp;
        address issuer;
    }

    mapping(string => Certificate) private certificates;

    event CertificateStored(string indexed certID, string certHash, uint256 timestamp, address indexed issuer);

    function storeCertificate(string memory certID, string memory certHash) external {
        require(bytes(certificates[certID].certHash).length == 0, "Certificate already exists");
        certificates[certID] = Certificate(certHash, block.timestamp, msg.sender);
        emit CertificateStored(certID, certHash, block.timestamp, msg.sender);
    }

    function verifyCertificate(string memory certID, string memory certHash) external view returns (bool) {
        return keccak256(bytes(certificates[certID].certHash)) == keccak256(bytes(certHash));
    }

    function getCertificate(string memory certID) external view returns (string memory certHash, uint256 timestamp, address issuer) {
        Certificate memory c = certificates[certID];
        return (c.certHash, c.timestamp, c.issuer);
    }
}
