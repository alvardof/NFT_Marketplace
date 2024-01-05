// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";



contract NFTMarket is AccessControl, ReentrancyGuardUpgradeable 
{

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 private commission;
    address private addressee;
    uint256 public token_ofert;

    AggregatorV3Interface internal priceFeedEther;

    IERC20 private dai;

    struct Ofert
    {
        address token_seller;
        address token_address;
        uint256 token_id;
        uint256 token_quantity;
        uint256 time_of_sale;
        uint256 token_price;
        bool sold;
        bool cancel;

    }


    mapping(uint256 => Ofert) public Oferts;



    function initialize()
    public
    {

        _grantRole(ADMIN_ROLE, msg.sender);
        commission = 1;
        token_ofert = 0;
        addressee = msg.sender;

        priceFeedEther = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    }




    function create_ofert
    (
        
        address _token_address,
        uint256 _token_id,
        uint256 _token_quantity,
        uint256 _time_of_sale,
        uint256 _token_price

    ) public
    {

        require(ERC1155(_token_address).isApprovedForAll(msg.sender, address(this)), "no permission to sell token");

        Oferts[token_ofert].token_seller = msg.sender;
        Oferts[token_ofert].token_address = _token_address;
        Oferts[token_ofert].token_id = _token_id;
        Oferts[token_ofert].token_quantity = _token_quantity;
        Oferts[token_ofert].time_of_sale = _time_of_sale;
        Oferts[token_ofert].token_price = _token_price;
        Oferts[token_ofert].sold = false;
        Oferts[token_ofert].cancel = false;

        emit createOfert(token_ofert);

        token_ofert += 1;

    }


    function buyETH(uint256 offerId) external payable nonReentrant
    {



        require(Oferts[offerId].sold == false, "tokens already sold");
        require(Oferts[offerId].cancel == false,"sale cancelled");


        int priceETH = getLatestPriceEth(); 

        uint256 priceToken = Oferts[offerId].token_price;

        uint256 percentSellUsd = (priceToken * 1) / 100;

        uint256 priceTokenEther = (1 ether * priceToken) / (uint256((priceETH)) / 1e6);

        require(priceTokenEther < msg.value,"Amount Insufficient"); 

        uint256 amountEtherCommission = (1 ether * percentSellUsd) / (uint256((priceETH)) / 1e6);

        uint256 tokenId = Oferts[offerId].token_id;

        uint256 tokenQuantity = Oferts[offerId].token_quantity;

        address seller = Oferts[offerId].token_seller;

        address addressToken = Oferts[offerId].token_address;


        (bool sent,) = seller.call{value: (priceTokenEther - amountEtherCommission)}("");

        (bool sent_commission,) = addressee.call{value: (amountEtherCommission)}("");

        require(sent,"payment not made ");

        require(sent_commission,"payment of commission not made");


        require(ERC1155(addressToken).isApprovedForAll(seller, address(this)), "no permission to sell token");


        ERC1155(address(addressToken)).safeTransferFrom(seller, msg.sender,tokenId , tokenQuantity, "");

        if(msg.value > priceTokenEther)
        {
            
            (bool sended,) = msg.sender.call{value: msg.value - (priceTokenEther)}("");
                
            require(sended, "funds not returned");
        }


        Oferts[offerId].sold = true;

        Oferts[offerId].cancel = true;

        emit sellToken("buy token paying with ETHER",offerId);


    }


    function buyDai(uint256 offerId) external payable nonReentrant
    {

        require(Oferts[offerId].sold == false, "tokens already sold");

        require(Oferts[offerId].cancel == false,"sale cancelled");

        uint256 tokenPrice = Oferts[offerId].token_price / 100;

        uint256 tokenQuantity = Oferts[offerId].token_quantity;

        uint256 amountPercent = (tokenPrice * commission) / 100;

        uint balaceUsdDai = dai.balanceOf(msg.sender) / 1e17;

        address seller = Oferts[offerId].token_seller;

        require(tokenPrice < balaceUsdDai, "Amount Insufficient");

        dai.transferFrom(msg.sender, seller, tokenPrice - amountPercent);

        dai.transferFrom(msg.sender, addressee, amountPercent);

        ERC1155(Oferts[offerId].token_address).safeTransferFrom(seller, msg.sender,offerId , tokenQuantity, "");

        Oferts[offerId].sold = true;

        Oferts[offerId].cancel = true;

        emit sellToken("buy token paying with DAI",offerId);

        
    }



    function getLatestPriceEth() public view returns (int) {
        
        (,int price,,,) = priceFeedEther.latestRoundData();

        return price;
    }



    function update_commission(uint256 _commission) public onlyRole(ADMIN_ROLE)
    {

        commission = _commission;

    }



    function update_addressee(address _addressee) public onlyRole(ADMIN_ROLE)
    {

        addressee = _addressee;

    }



    /* ========== EVENTS ========== */

	event createOfert(uint256 ofertId);
    event sellToken(string,uint256 ofertId);
    

}