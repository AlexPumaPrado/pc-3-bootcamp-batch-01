require("dotenv").config();

const {
  getRole,
  verify,
  ex,
  printAddress,
  deploySC,
  deploySCNoUp,
} = require("../utils");

var MINTER_ROLE = getRole("MINTER_ROLE");
var BURNER_ROLE = getRole("BURNER_ROLE");

async function deployMumbai() {
  var relayerAddress = "0xeb0868cf925105ac466c2b19039301e904061514";
  var name = "Mi Primer NFT";
  var symbol = "MPRNFT";
  var nftContract = await deploySC("MiPrimerNft", [name, symbol]);
  var implementation = await printAddress("NFT", nftContract.address);

  // set up
  await ex(nftTknContract, "grantRole", [MINTER_ROLE, relayerAddress], "GR");

  await verify(implementation, "MiPrimerNft", []);
}

async function deployGoerli() {
  // gnosis safe
  var gnosis={address:"0x1a42979EDB230080cA294C312e682c0e62399384"};
  // Crear un gnosis safe en https://gnosis-safe.io/app/
  // Extraer el address del gnosis safe y pasarlo al contrato con un setter
  var myTokenContract = await deploySCNoUp("MyTokenMiPrimerToken");
  await ex(
    myTokenContract,
    "setGnosisAddress",
    [gnosis.address],
    "Setting Gnosis address failed"
  );
  console.log("MyTokenMiPrimerToken deployed on Goerli");


  var MiPrimerToken = await hre.ethers.getContractFactory("MiPrimerToken");
  var miPrimerToken = await MiPrimerToken.deploy();
  var tx = await miPrimerToken.deployed();
  console.log("Contract MyPrimerToken address:", miPrimerToken.address);
  
    await tx.deployTransaction.wait(5);
  
  console.log(`Deploy at ${miPrimerToken.address}`);
  
  await hre.run("verify:verify", {
    address: miPrimerToken.address,
    constructorArguments: [],
    contract: "contracts/MiPrimerToken.sol:MiPrimerToken",
  });
}

// deployMumbai()
deployGoerli()
  //
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });