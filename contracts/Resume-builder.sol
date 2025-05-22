// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Project is Ownable, ReentrancyGuard {
    struct Workshop {
        uint256 id;
        string title;
        string description;
        uint256 duration; // in minutes
        uint256 fee;
        address instructor;
        bool isActive;
        uint256 maxParticipants;
        uint256 currentParticipants;
    }

    struct Certificate {
        uint256 workshopId;
        address participant;
        uint256 completionDate;
        string ipfsHash; // IPFS hash for certificate metadata
        bool isValid;
    }

    struct Participant {
        address wallet;
        string name;
        uint256[] completedWorkshops;
        uint256 totalCertificates;
        uint256 joinDate;
    }

    // State variables
    mapping(uint256 => Workshop) public workshops;
    mapping(uint256 => Certificate) public certificates;
    mapping(address => Participant) public participants;
    mapping(uint256 => mapping(address => bool)) public workshopParticipants;
    mapping(address => bool) public instructors;
    
    uint256 public workshopCounter;
    uint256 public certificateCounter;
    uint256 public platformFeePercentage = 5; // 5% platform fee

    // Events
    event WorkshopCreated(uint256 indexed workshopId, string title, address instructor);
    event ParticipantRegistered(uint256 indexed workshopId, address participant);
    event CertificateIssued(uint256 indexed certificateId, uint256 workshopId, address participant);
    event InstructorAdded(address instructor);
    event WorkshopCompleted(uint256 indexed workshopId, address participant);

    constructor() {
        instructors[msg.sender] = true;
    }

    modifier onlyInstructor() {
        require(instructors[msg.sender] || msg.sender == owner(), "Not authorized instructor");
        _;
    }

    // Core Function 1: Create Workshop
    function createWorkshop(
        string memory _title,
        string memory _description,
        uint256 _duration,
        uint256 _fee,
        uint256 _maxParticipants
    ) external onlyInstructor {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_duration > 0, "Duration must be greater than 0");
        require(_maxParticipants > 0, "Max participants must be greater than 0");

        workshopCounter++;
        
        workshops[workshopCounter] = Workshop({
            id: workshopCounter,
            title: _title,
            description: _description,
            duration: _duration,
            fee: _fee,
            instructor: msg.sender,
            isActive: true,
            maxParticipants: _maxParticipants,
            currentParticipants: 0
        });

        emit WorkshopCreated(workshopCounter, _title, msg.sender);
    }

    // Core Function 2: Register for Workshop
    function registerForWorkshop(uint256 _workshopId) external payable nonReentrant {
        Workshop storage workshop = workshops[_workshopId];
        
        require(workshop.id != 0, "Workshop does not exist");
        require(workshop.isActive, "Workshop is not active");
        require(workshop.currentParticipants < workshop.maxParticipants, "Workshop is full");
        require(!workshopParticipants[_workshopId][msg.sender], "Already registered");
        require(msg.value >= workshop.fee, "Insufficient payment");

        // Initialize participant if first time
        if (participants[msg.sender].joinDate == 0) {
            participants[msg.sender] = Participant({
                wallet: msg.sender,
                name: "",
                completedWorkshops: new uint256[](0),
                totalCertificates: 0,
                joinDate: block.timestamp
            });
        }

        workshopParticipants[_workshopId][msg.sender] = true;
        workshop.currentParticipants++;

        // Handle payment distribution
        if (workshop.fee > 0) {
            uint256 platformFee = (workshop.fee * platformFeePercentage) / 100;
            uint256 instructorPayment = workshop.fee - platformFee;
            
            // Transfer payment to instructor
            payable(workshop.instructor).transfer(instructorPayment);
            // Platform fee stays in contract
        }

        // Refund excess payment
        if (msg.value > workshop.fee) {
            payable(msg.sender).transfer(msg.value - workshop.fee);
        }

        emit ParticipantRegistered(_workshopId, msg.sender);
    }

    // Core Function 3: Issue Certificate
    function issueCertificate(
        uint256 _workshopId,
        address _participant,
        string memory _ipfsHash
    ) external onlyInstructor {
        require(workshops[_workshopId].id != 0, "Workshop does not exist");
        require(workshopParticipants[_workshopId][_participant], "Participant not registered");
        require(bytes(_ipfsHash).length > 0, "IPFS hash cannot be empty");

        certificateCounter++;
        
        certificates[certificateCounter] = Certificate({
            workshopId: _workshopId,
            participant: _participant,
            completionDate: block.timestamp,
            ipfsHash: _ipfsHash,
            isValid: true
        });

        // Update participant data
        participants[_participant].completedWorkshops.push(_workshopId);
        participants[_participant].totalCertificates++;

        emit CertificateIssued(certificateCounter, _workshopId, _participant);
        emit WorkshopCompleted(_workshopId, _participant);
    }

    // Additional utility functions
    function addInstructor(address _instructor) external onlyOwner {
        instructors[_instructor] = true;
        emit InstructorAdded(_instructor);
    }

    function removeInstructor(address _instructor) external onlyOwner {
        instructors[_instructor] = false;
    }

    function updateWorkshopStatus(uint256 _workshopId, bool _isActive) external onlyInstructor {
        require(workshops[_workshopId].instructor == msg.sender || msg.sender == owner(), "Not authorized");
        workshops[_workshopId].isActive = _isActive;
    }

    function revokeCertificate(uint256 _certificateId) external onlyOwner {
        certificates[_certificateId].isValid = false;
    }

    function getParticipantWorkshops(address _participant) external view returns (uint256[] memory) {
        return participants[_participant].completedWorkshops;
    }

    function verifyCertificate(uint256 _certificateId) external view returns (bool) {
        return certificates[_certificateId].isValid && certificates[_certificateId].participant != address(0);
    }

    function withdrawPlatformFees() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setPlatformFeePercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 20, "Fee cannot exceed 20%");
        platformFeePercentage = _percentage;
    }

    // Emergency functions
    function pause() external onlyOwner {
        // Implementation for pausing contract operations
    }

    function unpause() external onlyOwner {
        // Implementation for unpausing contract operations
    }
}
