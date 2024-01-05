const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");

  const {  upgrades, ethers } = require("hardhat");


  describe("test", function () {


    async function deploy() {


        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount, otherAccount_2] = await ethers.getSigners();
    
        const Token = await ethers.getContractFactory("Token_ERC1155");
        const token = await Token.deploy();


        // DEPLOY MARKET


        const NFTMarket = await ethers.getContractFactory("NFTMarket");
        const nftMarket = await upgrades.deployProxy(NFTMarket,{

            initialize: "initialize",
            
        });

        const ContractnftMarket = await nftMarket.waitForDeployment();

        return {owner, otherAccount, token, ContractnftMarket , otherAccount_2 };

    }


    describe("Buy with ether", function () {




        it("Mint Token", async function () {

            // I create accounts
            const {owner, otherAccount, token, ContractnftMarket , otherAccount_2} = await loadFixture(deploy);

            const QuantityToken = 10;

            // url of token img
            const meta_data = 'QmS1NgXrU9NpNPFjMcZEDQAWBVckijXPjsPKGCRY7vrGCq'

            let balanceInitial = await token.connect(owner).balanceOf(owner,0);

            expect(String(balanceInitial)).to.be.equal(String(0)); 

            // I mine token to sell later
            let tx = await token.connect(owner).safeMint([meta_data],QuantityToken);
            let balanceAfter = await token.connect(owner).balanceOf(owner,0);
            expect(String(balanceAfter)).to.be.equal(String(QuantityToken)); 

        });




        it("Create Ofert", async function () {


            // I create accounts
            const {owner, otherAccount, token, ContractnftMarket , otherAccount_2} = await loadFixture(deploy);

            const QuantityToken = 10;

            // url of token img
            const meta_data = 'QmS1NgXrU9NpNPFjMcZEDQAWBVckijXPjsPKGCRY7vrGCq'

            let balanceInitial = await token.connect(owner).balanceOf(owner,0);

            // I mine token to sell later
            let tx = await token.connect(owner).safeMint([meta_data],QuantityToken);

            // Tokens approved for spending

            let approveToken = await token.connect(owner).isApprovedForAll(owner.address,ContractnftMarket.target);

            // I check that I am not approved to spend the tokens.
            expect(approveToken).to.be.equal(false); 


            // I approve my tokens to the sales market.
            let tx_1 = await token.connect(owner).setApprovalForAll(ContractnftMarket.target,true)
            let approveTokenAfter = await token.connect(owner).isApprovedForAll(owner.address,ContractnftMarket.target)
            expect(approveTokenAfter).to.be.equal(true); 

            
            // I create the offer in the sales market
            await expect(ContractnftMarket.connect(owner).create_ofert(token.target,0,10,5000,10000))
            .to.emit(ContractnftMarket, 'createOfert')
            .withArgs(0);


        });


        it("Buy With Ether", async function () {



            // I create accounts
            const {owner, otherAccount, token, ContractnftMarket , otherAccount_2} = await loadFixture(deploy);

            const QuantityToken = 10;

            // url of token img
            const meta_data = 'QmS1NgXrU9NpNPFjMcZEDQAWBVckijXPjsPKGCRY7vrGCq'

            // I mine token to sell later
            let tx = await token.connect(owner).safeMint([meta_data],QuantityToken);

            // Tokens approved for spending

            // I approve my tokens to the sales market.
            await token.connect(owner).setApprovalForAll(ContractnftMarket.target,true);
        
            // I create the offer in the sales market
            ContractnftMarket.connect(owner).create_ofert(token.target,0,10,5000,10000);

            // insufficient amount in ether to buy the tokens
            let ethAmount = String(ethers.parseEther("0.01"))

            // should reverse the transaction
            await expect(ContractnftMarket.connect(otherAccount).buyETH(0,{ value: ethAmount }))
            .to.be.revertedWith('Amount Insufficient');



            ethAmount = String(ethers.parseEther("0.1"))

            // make token purchase
            await expect(ContractnftMarket.connect(otherAccount).buyETH(0,{ value: ethAmount }))
            .to.emit(ContractnftMarket, 'sellToken')
            .withArgs("buy token paying with ETHER",0);

            // Trying to buy a token already sold

            await expect(ContractnftMarket.connect(otherAccount).buyETH(0,{ value: ethAmount }))
            .to.be.revertedWith('tokens already sold');

        });



        it("Buy With Dai", async function () {

            // I create accounts
            const {owner, otherAccount, token, ContractnftMarket , otherAccount_2} = await loadFixture(deploy);

            const QuantityToken = 10;

            const ADDRESS_IMPERSONATE = "0x88dfc989a1Fe3061065E33E6b8F8541f8405dFD5"

            await hre.network.provider.request({
                method: "hardhat_impersonateAccount",
                params: [ADDRESS_IMPERSONATE],
              });
              
            const SIGNER_IMPERSONATE = await ethers.getSigner(ADDRESS_IMPERSONATE)

            const ADDRESS_DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
            
            const DAI = await ethers.getContractAt('@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20', ADDRESS_DAI);

            // url of token img
            const meta_data = "QmS1NgXrU9NpNPFjMcZEDQAWBVckijXPjsPKGCRY7vrGCq"

            // I mine token to sell later
            let tx = await token.connect(owner).safeMint([meta_data],QuantityToken);

            // Tokens approved for spending

            // I approve my tokens to the sales market.
            await token.connect(owner).setApprovalForAll(ContractnftMarket.target,true);
     
            
            // I create the offer in the sales market
            ContractnftMarket.connect(owner).create_ofert(token.target,0,10,5000,10000);

            
            // try to buy with an unfunded account
            await expect(ContractnftMarket.connect(otherAccount).buyDai(0))
            .to.be.revertedWith('Amount Insufficient');

            // try to buy without having approved the payment tokens
            await expect(ContractnftMarket.connect(SIGNER_IMPERSONATE).buyDai(0))
            .to.be.revertedWith('Dai/insufficient-allowance');


            await DAI.connect(SIGNER_IMPERSONATE).approve(ContractnftMarket.target, 100)

            await expect(ContractnftMarket.connect(SIGNER_IMPERSONATE).buyDai(0))
            .to.emit(ContractnftMarket, 'sellToken')
            .withArgs("buy token paying with DAI",0);


        });


    });

});