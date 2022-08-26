pragma solidity >=0.5.16 <0.6.0;

import "../coffeecore/Ownable.sol";
import "../coffeeaccesscontrol/FarmerRole.sol";
import "../coffeeaccesscontrol/DistributorRole.sol";
import "../coffeeaccesscontrol/RetailerRole.sol";
import "../coffeeaccesscontrol/ConsumerRole.sol";
// Define a contract 'Supplychain'
contract SupplyChain is Ownable, FarmerRole, DistributorRole, RetailerRole, ConsumerRole {

    // Define a variable called 'upc' for Universal Product Code (UPC)
    uint  upc;

    // Define a variable called 'sku' for Stock Keeping Unit (SKU)
    uint  sku;

    // Define a public mapping 'items' that maps the UPC to an Item.
    mapping(uint => Item) items;

    // Define enum 'State' with the following values:
    enum State
    {
        Harvested, // 0
        Processed, // 1
        Packed, // 2
        ForSale, // 3
        Sold, // 4
        Shipped, // 5
        Received, // 6
        Purchased   // 7
    }

    State constant defaultState = State.Harvested;

    // Define a struct 'Item' with the following fields:
    struct Item {
        uint sku;  // Stock Keeping Unit (SKU)
        uint upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
        address ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
        address originFarmerID; // Metamask-Ethereum address of the Farmer
        string originFarmName; // Farmer Name
        string originFarmInformation;  // Farmer Information
        string originFarmLatitude; // Farm Latitude
        string originFarmLongitude;  // Farm Longitude
        uint productID;  // Product ID potentially a combination of upc + sku
        string productNotes; // Product Notes
        uint productPrice; // Product Price
        State itemState;  // Product State as represented in the enum above
        address distributorID;  // Metamask-Ethereum address of the Distributor
        address retailerID; // Metamask-Ethereum address of the Retailer
        address payable consumerID; // Metamask-Ethereum address of the Consumer
    }

    // Define 8 events with the same 8 state values and accept 'upc' as input argument
    event Harvested(uint upc);
    event Processed(uint upc);
    event Packed(uint upc);
    event ForSale(uint upc);
    event Sold(uint upc);
    event Shipped(uint upc);
    event Received(uint upc);
    event Purchased(uint upc);

    // Define a modifer that verifies the Caller
    modifier verifyCaller (address _address) {
        require(msg.sender == _address);
        _;
    }

    // Define a modifier that checks if the paid amount is sufficient to cover the price
    modifier paidEnough(uint _price) {
        require(msg.value >= _price);
        _;
    }

    // Define a modifier that checks the price and refunds the remaining balance
    modifier checkValue(uint _upc) {
        _;
        uint _price = items[_upc].productPrice;
        uint amountToReturn = msg.value - _price;
        items[_upc].consumerID.transfer(amountToReturn);
    }

    // Define a modifier that checks if an item does not exist
    modifier doesNotExist(uint _upc) {
        require(items[_upc].upc != _upc);
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Harvested
    modifier harvested(uint _upc) {
        require(items[_upc].itemState == State.Harvested);
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Processed
    modifier processed(uint _upc) {
        require(items[_upc].itemState == State.Processed);
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Packed
    modifier packed(uint _upc) {
        require(items[_upc].itemState == State.Packed);
        _;
    }

    // Define a modifier that checks if an item.state of a upc is ForSale
    modifier forSale(uint _upc) {
        require(items[_upc].itemState == State.ForSale);
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Sold
    modifier sold(uint _upc) {
        require(items[_upc].itemState == State.Sold);
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Shipped
    modifier shipped(uint _upc) {
        require(items[_upc].itemState == State.Shipped);
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Received
    modifier received(uint _upc) {
        require(items[_upc].itemState == State.Received);
        _;
    }

    // Define a modifier that checks if an item.state of a upc is Purchased
    modifier purchased(uint _upc) {
        require(items[_upc].itemState == State.Purchased);
        _;
    }

    // In the constructor set 'owner' to the address that instantiated the contract
    // and set 'sku' to 0
    // and set 'upc' to 1
    constructor() public payable {
        sku = 1;
        upc = 1;
    }

    // Define a function 'kill' if required
    function kill() public onlyOwner {
        selfdestruct(owner());
    }

    // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
    function harvestItem(
        uint _upc,
        address _originFarmerID,
        string memory _originFarmName,
        string memory _originFarmInformation,
        string memory _originFarmLatitude,
        string memory _originFarmLongitude,
        string memory _productNotes) public onlyFarmer doesNotExist(_upc)
    {
        items[_upc] = Item(
            sku,
            _upc,
            msg.sender,
            _originFarmerID,
            _originFarmName,
            _originFarmInformation,
            _originFarmLatitude,
            _originFarmLongitude,
            _upc + sku,
            _productNotes,
            0,
            State.Harvested,
            address(0),
            address(0),
            address(0)
        );

        sku = sku + 1;

        emit Harvested(_upc);
    }

    // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
    function processItem(uint _upc) public onlyFarmer harvested(_upc) verifyCaller(items[_upc].originFarmerID)
    {
        items[_upc].itemState = State.Processed;

        emit Processed(_upc);
    }

    // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
    function packItem(uint _upc) public onlyFarmer processed(_upc) verifyCaller(items[_upc].originFarmerID)
    {
        items[_upc].itemState = State.Packed;

        emit Packed(_upc);
    }

    // Define a function 'markItemForSale' that allows a farmer to mark an item 'ForSale'
    function markItemForSale(uint _upc, uint _price) public onlyFarmer packed(_upc) verifyCaller(items[_upc].originFarmerID)
    {
        items[_upc].productPrice = _price;
        items[_upc].itemState = State.ForSale;

        emit ForSale(_upc);
    }

    // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
    // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough,
    // and any excess ether sent is refunded back to the buyer
    function buyItem(uint _upc) public payable onlyDistributor forSale(_upc) paidEnough(items[_upc].productPrice) checkValue(_upc) {
        Item storage item = items[_upc];

        address itemOwnerID = item.ownerID;

        item.ownerID = msg.sender;
        item.distributorID = msg.sender;
        item.itemState = State.Sold;

        // Transfer money to farmer
        (bool success,) = itemOwnerID.call.value(item.productPrice)("");
        require(success, "Money transfer to the previous owner failed.");

        // emit the appropriate event
        emit Sold(_upc);
    }

    // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
    // Use the above modifers to check if the item is sold
    function shipItem(uint _upc) public onlyDistributor sold(_upc) verifyCaller(items[_upc].distributorID)
    {
        items[_upc].itemState = State.Shipped;

        emit Shipped(_upc);
    }

    // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
    // Use the above modifiers to check if the item is shipped
    function receiveItem(uint _upc) public onlyRetailer shipped(_upc)
    {
        Item storage item = items[_upc];

        item.ownerID = msg.sender;
        item.retailerID = msg.sender;
        item.itemState = State.Received;

        emit Received(_upc);
    }

    // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
    // Use the above modifiers to check if the item is received
    function purchaseItem(uint _upc) public onlyConsumer received(_upc)
    {
        Item storage item = items[_upc];

        item.ownerID = msg.sender;
        item.consumerID = msg.sender;
        item.itemState = State.Purchased;

        emit Purchased(_upc);
    }

    function fetchItemBufferOne(uint _upc) public view returns (
        uint itemSKU,
        uint itemUPC,
        address ownerID,
        address originFarmerID,
        string  memory originFarmName,
        string  memory originFarmInformation,
        string  memory originFarmLatitude,
        string  memory originFarmLongitude
    )
    {
        Item memory item = items[_upc];

        itemSKU = item.sku;
        itemUPC = _upc;
        ownerID = item.ownerID;
        originFarmerID = item.originFarmerID;
        originFarmName = item.originFarmName;
        originFarmInformation = item.originFarmInformation;
        originFarmLatitude = item.originFarmLatitude;
        originFarmLongitude = item.originFarmLongitude;
    }

    function fetchItemBufferTwo(uint _upc) public view returns (
        uint itemSKU,
        uint itemUPC,
        uint productID,
        string  memory productNotes,
        uint productPrice,
        uint itemState,
        address distributorID,
        address retailerID,
        address consumerID
    )
    {
        Item memory item = items[_upc];

        itemSKU = item.sku;
        itemUPC = item.upc;
        productID = item.productID;
        productNotes = item.productNotes;
        productPrice = item.productPrice;
        itemState = uint(item.itemState);
        distributorID = item.distributorID;
        retailerID = item.retailerID;
        consumerID = item.consumerID;
    }
}