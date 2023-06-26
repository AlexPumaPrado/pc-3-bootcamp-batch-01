// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PublicSale is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Mi Primer Token
    // Crear su setter
    IERC20Upgradeable miPrimerToken;
    function setMiPrimerToken(address tokenAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        miPrimerToken = IERC20Upgradeable(tokenAddress);
    }

    // 17 de Junio del 2023 GMT
    uint256 constant startDate = 1686960000;

    // Maximo price NFT
    uint256 constant MAX_PRICE_NFT = 50000 * 10 ** 18;

    // Gnosis Safe
    // Crear su setter
    address gnosisSafeWallet;
    function setGnosisSafeWallet(address walletAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        gnosisSafeWallet = walletAddress;
    }

    event DeliverNft(address winnerAccount, uint256 nftId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
    }

    function purchaseNftById(uint256 _id) external {
        // Realizar 3 validaciones:
        // 1 - el id no se haya vendido. Sugerencia: llevar la cuenta de ids vendidos
        //         * Mensaje de error: "Public Sale: id not available"
        // 2 - el msg.sender haya dado allowance a este contrato en suficiente de MPRTKN
        //         * Mensaje de error: "Public Sale: Not enough allowance"
        // 3 - el msg.sender tenga el balance suficiente de MPRTKN
        //         * Mensaje de error: "Public Sale: Not enough token balance"
        // 4 - el _id se encuentre entre 1 y 30
        //         * Mensaje de error: "NFT: Token id out of range" 
        require(!_isNftSold(_id), "Public Sale: id not available");
        // Obtener el precio segun el id
        uint256 priceNft = _getPriceById(_id);
        require(miPrimerToken.allowance(msg.sender, address(this)) >= priceNft, "Public Sale: Not enough allowance");
        require(miPrimerToken.balanceOf(msg.sender) >= priceNft, "Public Sale: Not enough token balance");
        require(_id >= 1 && _id <= 30, "NFT: Token id out of range");

        // Purchase fees
        // 10% para Gnosis Safe (fee)
        // 90% se quedan en este contrato (net)
        uint256 fee = priceNft * 10 / 100;
        uint256 net = priceNft - fee;
        // from: msg.sender - to: gnosisSafeWallet - amount: fee
        // from: msg.sender - to: address(this) - amount: net
        miPrimerToken.transferFrom(msg.sender, gnosisSafeWallet, fee);
        miPrimerToken.transferFrom(msg.sender, address(this), net);

        // EMITIR EVENTO para que lo escuche OPEN ZEPPELIN DEFENDER
        emit DeliverNft(msg.sender, _id);
    }

    function depositEthForARandomNft() public payable {
        // Realizar 2 validaciones
        // 1 - que el msg.value sea mayor o igual a 0.01 ether
        // 2 - que haya NFTs disponibles para hacer el random
        require(msg.value >= 0.01 ether, "Public Sale: Insufficient Ether amount");
        require(_hasAvailableNfts(), "Public Sale: No available NFTs");

        // Escgoer una id random de la lista de ids disponibles
        uint256 nftId = _getRandomNftId();
         (bool success, ) = payable(gnosisSafeWallet).call{value: msg.value}("");
        require(success, "Public Sale: Ether transfer to Gnosis Safe failed");

        // Enviar ether a Gnosis Safe
        // SUGERENCIA: Usar gnosisSafeWallet.call para enviar el ether
        // Validar los valores de retorno de 'call' para saber si se envio el ether correctamente
        uint256 change = msg.value - 0.01 ether;
        // Dar el cambio al usuario
        // El vuelto seria equivalente a: msg.value - 0.01 ether
        if (msg.value > 0.01 ether) {
            // logica para dar cambio
            // usar '.transfer' para enviar ether de vuelta al usuario
            payable(msg.sender).transfer(change);
        }

        // EMITIR EVENTO para que lo escuche OPEN ZEPPELIN DEFENDER
        emit DeliverNft(msg.sender, nftId);
    }

    // PENDING
    // Crear el metodo receive
    function receive() external payable {}

    ////////////////////////////////////////////////////////////////////////
    /////////                    Helper Methods                    /////////
    ////////////////////////////////////////////////////////////////////////

    // Devuelve un id random de NFT de una lista de ids disponibles
    function _getRandomNftId() internal view returns (uint256) {}

    // Según el id del NFT, devuelve el precio. Existen 3 grupos de precios
    function _getPriceById(uint256 _id) internal view returns (uint256) {
        uint256 priceGroupOne;
        uint256 priceGroupTwo;
        uint256 priceGroupThree;
        if (_id > 0 && _id < 11) {
            return priceGroupOne;
        } else if (_id > 10 && _id < 21) {
            return priceGroupTwo;
        } else {
            return priceGroupThree;
        }
    }
    mapping(uint256 => bool) private soldNfts;
    uint256 private availableNfts;

    function _hasAvailableNfts() internal view returns (bool) {
    return availableNfts > 0;
    }

    function _isNftSold(uint256 _id) internal view returns (bool) {
    return soldNfts[_id];
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}
}
