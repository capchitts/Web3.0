//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract Ecommerce{

    //counting the # of products
    uint counter = 1;
    //array of products
    Product[] public products;

    //events
    event registered(string _title , uint _productId, address _seller);
    event bought(uint _productId , address _buyer);
    event delivered(uint _productId);

    address  payable public manager;
    bool destroyed=false;

    modifier isNotDestroyed()
    {
        require(destroyed == false,"Contract does note exist");
        _;
    }

    //set the manager to be the person who deploys the contract
    constructor()
    {
        manager = payable(msg.sender);
    }

    struct Product{

        //product title and desc , id and price per unit
        string title;
        string desc;
        uint productId;
        uint price;

        //addres of seller and buyer
        address payable seller;
        address buyer;
        
        //boolean delivered or not
        bool delivered;
    }
    
    //seller will use this function to tregister their products 
    function registerProduct(string memory _title, string memory _desc, uint _price) public isNotDestroyed
    {
        require(_price > 0,"Price should be greater than 0.");
        Product memory tmpProduct;

        tmpProduct.title = _title;
        tmpProduct.desc = _desc;
        //convert ether to wei
        tmpProduct.price = _price* 10**18;
        //seller
        tmpProduct.seller = payable(msg.sender);
        tmpProduct.productId = counter;
        counter++;
        //push it in array
        products.push(tmpProduct);

        //emit the event
        emit registered(tmpProduct.title, tmpProduct.productId, tmpProduct.seller);
    }

    function buy(uint _productId) public payable isNotDestroyed
    {
        //buyer should not be seller
        require(msg.sender != products[_productId - 1].seller,"Seller cant be buyer");
        //pay the exact product price
        require(msg.value == products[_productId - 1].price, "Kindly pay the exact price of the item.");

        //update the buyer
        products[_productId - 1].buyer = msg.sender;

        //emit the event
        emit bought(_productId, msg.sender);

    }

    function deivery(uint _productId) public isNotDestroyed
    {
        require(msg.sender == products[_productId -1].buyer, "Only buyer can confirm delivery.");

        //update the delivery status of product
        products[_productId - 1].delivered = true;

        //once the delivery is done transfer the amount from buyer to seller
        products[_productId-1].seller.transfer(products[_productId-1].price);

        emit delivered(_productId);
    }

    function destroyContract() public isNotDestroyed
    {   
        //check the caller is manager
        require(msg.sender == manager,"Only manager can destroy the contract");
        //conrtact will be destroyed and ethers will be transferred to manager
        manager.transfer(address(this).balance);
        destroyed = true;

        selfdestruct(manager);
    }

    //this function will run when no other function will work after contract is destroyed
    fallback() payable external
    {
        //transfer back the ether to sender
        payable(msg.sender).transfer(msg.value);
    }

}
