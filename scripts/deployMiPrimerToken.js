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

async function deployUSDC() {
  const usdc = await deploySCNoUp("USDCoin",[]);
  await verify(usdc,"USDCoin",[]);
  return usdc;
}

async function deployMiPrimerToken() {
  const miPrimerToken =await deploySC("MiPrimerToken",[]);
  const implementationTokenAddress = await printAddress("MiPrimerToken es:",miPrimerToken.address);
  await verify(implementationTokenAddress,"MiPrimerToken",[]);
  return miPrimerToken;
}

async function deployPublicSale(miPrimerToken){
  var gnosis = {address:"0xC7D4BF59fCb3a3af480E2FC31c873C2846276662"};

  const publicSale=await deploySC("PublicSale",[]);

  await Promise.all([
    ex(publicSale,"setTokenAddress",[miPrimerToken.address],"setTokenAddress failed"),
    ex(publicSale,"setGnosisSafeWallet",[gnosis.address],"setGnosisSafeWallet failed")
  ]);

  await printAddress("PublicSale",publicSale.address);
  await verify(publicSale.address,"PublicSale",[]);

}
async function deployGoerly(){
  const usdcToken=await deployUSDC();
  const miPrimerToken= await deployMiPrimerToken();

  await deployPublicSale(miPrimerToken);

  console.log("USDCoin address: ", usdcToken.address);
}

deployGoerly().catch(console.error)




