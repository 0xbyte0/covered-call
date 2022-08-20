// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./coveredCallNFT.sol";
import "./counter.sol";

/// @title A minimal ERC721 covered call vaults
/// @author 0xosas
/// @notice ERC721 covered call vaults
contract coveredCall is coveredCallNFT, Ownable, ERC721Holder{ 
    using Counters for Counters.Counter;

    ///////////////////////////////////////////////////////////////////////////////
    //                                  EVENTS                                   //
    ///////////////////////////////////////////////////////////////////////////////
    event NewVault(uint256 indexed vaultId, address indexed from, address indexed token, uint256 tokenId);
    event InitiatedWithdrawal(uint256 indexed vaultId, address indexed from);
    event Withdrawal(uint256 indexed vaultId, address indexed from);
    event Harvested(address indexed from, uint256 amount);
    event ExercisedOption(uint256 indexed vaultId, address indexed from);
    event PurchasedOption(uint256 indexed vaultId, address indexed from, address indexed token);


    ///////////////////////////////////////////////////////////////////////////////
    //                                  BIT WIDTHS                               //
    ///////////////////////////////////////////////////////////////////////////////

    uint256 private constant BITWIDTH_TOKEN_ADDRESS = 160;

    uint256 private constant BITWIDTH_TOKEN_ID = 14;

    uint256 private constant BITWIDTH_TOKEN_DATA = BITWIDTH_TOKEN_ID + BITWIDTH_TOKEN_ADDRESS;

    uint256 private constant BITWIDTH_EXPIRY = 32;

    uint256 private constant BITWIDTH_STARTED = 32;

    uint256 private constant BITWIDTH_TIME_DATA = BITWIDTH_EXPIRY + BITWIDTH_STARTED;

    uint256 private constant BITWIDTH_STRIKE_PRICE = 10;

    uint256 private constant BITWIDTH_CALL_DATA = BITWIDTH_STRIKE_PRICE + BITWIDTH_TIME_DATA;

    uint256 private constant BITWIDTH_MISC = 4;

    ///////////////////////////////////////////////////////////////////////////////
    //                                  BIT MASKS                                //
    ///////////////////////////////////////////////////////////////////////////////

    uint256 private constant BITMASK_MISC = (1 << BITWIDTH_MISC) - 1;

    /// Bitmask for token data
    uint256 private constant BITMASK_TOKEN_ADDRESS = (1 << BITWIDTH_TOKEN_ADDRESS) - 1;

    uint256 private constant BITMASK_TOKEN_ID = (1 << BITWIDTH_TOKEN_ID) - 1;

    uint256 private constant BITMASK_TOKEN_DATA = (1 << BITWIDTH_TOKEN_DATA) - 1;

    /// Bitmask for time data
    uint256 private constant BITMASK_EXPIRY = (1 << BITWIDTH_EXPIRY) - 1;

    uint256 private constant BITMASK_STARTED = (1 << BITWIDTH_STARTED) - 1;

    uint256 private constant BITMASK_TIME = (1 << BITWIDTH_TIME_DATA) - 1;
    
    /// Bitmask for call data
    uint256 private constant BITMASK_STRIKE_PRICE = (1 << BITWIDTH_STRIKE_PRICE) - 1;

    uint256 private constant BITMASK_CALL_DATA = (1 << BITWIDTH_CALL_DATA) - 1;

    uint256 internal s_defaultFeeRate = 30;

    uint256 public protocolUnclaimedFees;

    uint256 internal s_defaultPriceDecrement = 2;

    Counters.Counter s_totalVaults;

    /// @notice Mapping of vault vaultId -> vault data
    mapping(uint256 => uint256) internal s_vault;

    /// @notice The unharvested balance in eth of each account.
    mapping(address => uint256) public s_ethBalance;

    function setFee(uint256 _newFee) external onlyOwner {
        require(_newFee < 15, "fee must not exceed 15%");
        s_defaultFeeRate = _newFee;
    }

    /// @notice creates a new vault
    /// @return vaultId is the new vault's id
    function newVault(
        uint256 tokenId,
        address tokenAddr,
        uint256 startsAt,
        uint256 endsAt,
        uint256 strikePrice
    ) external returns(uint256 vaultId) {
        require(tokenId > 0, "invalid tokenId");
        require(endsAt > block.timestamp, "duration too small");
        require(tokenAddr != address(0), "invalid token address");
        require(strikePrice > 0, "strikePrice too small");

        uint256 tokenData = (uint256(uint160(tokenAddr)) << BITWIDTH_TOKEN_ID) | tokenId;
        uint256 timeData = (startsAt << BITWIDTH_EXPIRY) | endsAt;
        uint256 callData = (strikePrice << BITWIDTH_TIME_DATA) | timeData;
        uint256 v = (callData << BITWIDTH_TOKEN_DATA) | tokenData;
        v = v << BITWIDTH_MISC;

        _safeMint(msg.sender, 1);

        s_totalVaults.increment();
        vaultId = s_totalVaults.current();

        s_vault[vaultId] = v;

        emit NewVault(vaultId, msg.sender, tokenAddr, tokenId);

        ERC721(tokenAddr).safeTransferFrom(msg.sender, address(this), tokenId);
        return vaultId;
    }

    /// @notice Get the current dutch auction strike
    /// @param startsAt is the timestamp for when the vailt initiated
    /// @param startingPrice is the strike used to initiate the vault
    /// @return newStrike is the strike based on dutch auction
    function getStrike(uint startsAt, uint startingPrice) public view returns (uint256){
        uint timeElapsed = block.timestamp - startsAt;
        return startingPrice - (timeElapsed * s_defaultPriceDecrement);
    }

    // /// @notice Purchase an option on the vault  at a price dependent on the dutch auction.
    // ///         the premium is sent to the vault beneficiary
    // /// @param vaultId the id of the vault
    // function purchaseOption(uint256 vaultId) external payable {
    //     require(vaultId <= s_totalVaults.current(), "vault does not exists");

    //     uint256 _vault = s_vault[vaultId]; 

    //     (uint v_tokenId, address v_tokenAddress, 
    //     uint v_endsAt, uint v_startsAt, 
    //     uint v_strikePrice, uint v_misc) = getVaultData(_vault);

    //     require(block.timestamp >= v_startsAt, "not started");
    //     require(block.timestamp < v_endsAt, "expired");

    //     v_strikePrice = v_strikePrice * 1 ether; /// insinuate that the prices are in whole numbers

    //     require(msg.value >= getStrike(v_startsAt, v_strikePrice), "insufficient eth sent");
    //     require((_vault >> 3) & 1 == 0, "already withdrawing");
    //     require((_vault >> 2) & 1 == 0, "vault exercised");

    //     address _owner = ownerOf(vaultId);

    //     // force transfer to `msg.sender`
    //     _forceTransfer(msg.sender, vaultId);

    //     unchecked {
    //         s_ethBalance[_owner] += msg.value;
    //     }

    //     emit PurchasedOption(vaultId, msg.sender, v_tokenAddress);
    // }

    function exerciseOption(uint256 vaultId) external payable {
        require(msg.sender == ownerOf(vaultId), "You are not the owner");
        uint256 _vault = s_vault[vaultId];
        
        require((_vault >> 2) & 1 == 0, "vault exercised");

        (uint v_tokenId, address v_tokenAddress, 
        uint v_endsAt, uint v_startsAt, 
        uint v_strikePrice, uint v_misc) = getVaultData(_vault);

        require(block.timestamp < v_endsAt, "expired");

        v_strikePrice = v_strikePrice * 1 ether;

        require(msg.value >= getStrike(v_startsAt, v_strikePrice), "insufficient eth sent");

        // set vault as exercised
        s_vault[vaultId] = _vault | (1 << 2);

        // ex: 3% fees means s_defaultFeeRate == 30
        uint256 fee = (msg.value * s_defaultFeeRate) / 1000;

        unchecked {
            protocolUnclaimedFees += fee;
            s_ethBalance[ownerOf(vaultId)] += msg.value - fee;    
        }

        ERC721(v_tokenAddress).safeTransferFrom(address(this), msg.sender, v_tokenId);

        emit ExercisedOption(vaultId, msg.sender);
    }

    /// @notice Initiates a withdrawal, this way the vault will no longer sell
    ///         another call once the currently active call option has expired.
    /// @param vaultId is the tokenId of the vault to initiate a withdrawal on
    function initiateWithdraw(uint256 vaultId) external {
        require(msg.sender == ownerOf(vaultId), "not owner");

        uint256 _vault = s_vault[vaultId];

        // check vault is not already withdrawing
        require((_vault >> 3) & 1 == 0, "already withdrawing");

        // set vault as withdrawing
        s_vault[vaultId] = _vault | (1 << 3);

        emit InitiatedWithdrawal(vaultId, msg.sender);
    }

    /// @notice Sends the underlying assets back to the vault owner and claims any
    ///         unharvested premiums for the owner. The vault NFT and it's associated
    ///         option NFT are burned.
    /// @param vaultId is the vault id to withdraw
    function withdraw(uint256 vaultId) external {
        require(msg.sender == ownerOf(vaultId), "not owner");

        uint256 _vault = s_vault[vaultId];

        (uint v_tokenId, address v_tokenAddress, 
        uint v_endsAt, uint v_startsAt, 
        uint v_strikePrice, uint v_misc) = getVaultData(_vault);

        require((_vault >> 3) & 1 == 1, "vault not in withdrawing state");
        require((_vault >> 2) & 1 == 0, "vault exercised");
        require(block.timestamp > v_endsAt, "vault still active");

        _burn(vaultId);

        emit Withdrawal(vaultId, msg.sender);

        harvest();

        ERC721(v_tokenAddress).safeTransferFrom(address(this), msg.sender, v_tokenId);
    }

    /// @notice Sends any unclaimed ETH to the msg.sender
    /// @return amount The amount of ETH that was harvested
    function harvest() public returns (uint256 amount) {
        amount = s_ethBalance[msg.sender];
        s_ethBalance[msg.sender] = 0;

        emit Harvested(msg.sender, amount);

        // transfer eth to msg.sender
        payable(msg.sender).send(amount);
    }

    /// @notice Gets a the vault value with `vaultId`
    /// @param vaultId the id of the vault
    /// @return vault the value of the vault
    function vaults(uint256 vaultId) external view returns (uint) {
        return s_vault[vaultId];
    }

    /// @notice Extracts data from a vault
    /// @param _vault is the vault value 
    /// @return tokenId is the id of the token in the vault
    /// @return tokenAddress is the token address in the vault
    /// @return endsAt is the vault expiry data
    /// @return startsAt is the timestamp for when vault started counting
    /// @return strikePrice is the vaults strike price
    function getVaultData(
        uint256 _vault
    ) public pure returns (
        uint tokenId, 
        address tokenAddress, 
        uint endsAt,
        uint startsAt, 
        uint strikePrice,
        uint misc
    ) {
        misc = _vault & BITMASK_MISC;
        _vault = _vault >> BITWIDTH_MISC;
        tokenAddress = address(uint160((_vault >> BITWIDTH_TOKEN_ID) & BITMASK_TOKEN_ADDRESS));
        tokenId = _vault & BITMASK_TOKEN_ID;

        _vault = _vault >> BITWIDTH_TOKEN_DATA;
        strikePrice = (_vault >> BITWIDTH_TIME_DATA) & BITMASK_STRIKE_PRICE;
        endsAt = _vault & BITMASK_EXPIRY;
        startsAt = (_vault >> BITWIDTH_EXPIRY) & BITMASK_STARTED;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) { }
}