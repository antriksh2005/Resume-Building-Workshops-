const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Starting deployment of Resume Building Workshops via Blockchain...");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);
  
  // Check deployer balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(balance), "ETH");

  if (balance < ethers.parseEther("0.01")) {
    console.warn("⚠️  Warning: Account balance is low. Make sure you have enough funds for deployment.");
  }

  try {
    // Get the contract factory
    console.log("📋 Getting Project contract factory...");
    const Project = await ethers.getContractFactory("Project");
    
    console.log("⏳ Deploying Project contract...");
    
    // Deploy the contract
    const project = await Project.deploy();
    
    // Wait for deployment to complete
    await project.waitForDeployment();
    
    const contractAddress = await project.getAddress();
    
    console.log("✅ Project contract deployed successfully!");
    console.log("📍 Contract address:", contractAddress);
    console.log("🔗 Transaction hash:", project.deploymentTransaction().hash);
    
    // Verify deployment
    console.log("🔍 Verifying deployment...");
    const code = await ethers.provider.getCode(contractAddress);
    if (code === "0x") {
      throw new Error("Contract deployment failed - no code at address");
    }
    
    console.log("✅ Contract verification successful!");
    
    // Get network information
    const network = await ethers.provider.getNetwork();
    console.log("🌐 Network:", network.name);
    console.log("🆔 Chain ID:", network.chainId.toString());
    
    // Display contract interaction information
    console.log("\n📋 Contract Information:");
    console.log("==========================================");
    console.log("Contract Name: Project");
    console.log("Contract Address:", contractAddress);
    console.log("Deployer Address:", deployer.address);
    console.log("Network:", network.name);
    console.log("Chain ID:", network.chainId.toString());
    console.log("Block Number:", await ethers.provider.getBlockNumber());
    console.log("==========================================");
    
    // Test basic contract functionality
    console.log("\n🧪 Testing basic contract functionality...");
    
    try {
      const workshopCounter = await project.workshopCounter();
      console.log("✅ Workshop counter initialized:", workshopCounter.toString());
      
      const certificateCounter = await project.certificateCounter();
      console.log("✅ Certificate counter initialized:", certificateCounter.toString());
      
      const platformFee = await project.platformFeePercentage();
      console.log("✅ Platform fee percentage:", platformFee.toString() + "%");
      
      // Check if deployer is set as instructor
      const isInstructor = await project.instructors(deployer.address);
      console.log("✅ Deployer instructor status:", isInstructor);
      
    } catch (error) {
      console.warn("⚠️  Warning: Could not test contract functionality:", error.message);
    }
    
    // Save deployment information
    const deploymentInfo = {
      contractName: "Project",
      contractAddress: contractAddress,
      deployerAddress: deployer.address,
      networkName: network.name,
      chainId: network.chainId.toString(),
      deploymentBlock: await ethers.provider.getBlockNumber(),
      deploymentTime: new Date().toISOString(),
      transactionHash: project.deploymentTransaction().hash,
    };
    
    console.log("\n💾 Deployment completed successfully!");
    console.log("📄 Save this information for your records:");
    console.log(JSON.stringify(deploymentInfo, null, 2));
    
    // Instructions for next steps
    console.log("\n📚 Next Steps:");
    console.log("1. Save the contract address:", contractAddress);
    console.log("2. Update your frontend configuration with the contract address");
    console.log("3. Verify the contract on the block explorer if needed");
    console.log("4. Test the contract functions using Hardhat console or your frontend");
    
    if (network.chainId.toString() === "1115") {
      console.log("5. View your contract on Core Testnet 2 Explorer:");
      console.log(`   https://scan.test2.btcs.network/address/${contractAddress}`);
    }
    
    return {
      contract: project,
      address: contractAddress,
      deploymentInfo: deploymentInfo
    };
    
  } catch (error) {
    console.error("❌ Deployment failed:");
    console.error("Error message:", error.message);
    
    if (error.code === 'INSUFFICIENT_FUNDS') {
      console.error("💸 Insufficient funds for deployment. Please add more funds to your account.");
    } else if (error.code === 'NETWORK_ERROR') {
      console.error("🌐 Network connection error. Please check your RPC endpoint.");
    } else if (error.message.includes('gas')) {
      console.error("⛽ Gas related error. Try adjusting gas settings in hardhat.config.js");
    }
    
    process.exit(1);
  }
}

// Execute deployment
main()
  .then(() => {
    console.log("🎉 Deployment script completed successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("💥 Deployment script failed:", error);
    process.exit(1);
  });
