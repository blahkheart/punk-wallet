// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ETHDenverAdmin is AccessControl, Ownable{
    event NewOrder(string id, address vendorId, address userId, uint256 amount, uint256 time, bool done);
    event DoneOrder(string id, address vendorId, address userId, uint256 amount, uint256 time, bool done);
    event Register(address userId, uint256 time, bool isVendor);

    ERC20 public buidlBuxx;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VENDOR_ROLE = keccak256("VENDOR_ROLE");
    bytes32 public constant ATTENDEE_ROLE = keccak256("ADTTENDEE_ROLE");

    uint256 public airdropToken = 100;

    struct Order {
        string id;
        address userId;
        address vendorId;
        uint256 amount;
        uint256 time;
        bool done;
    }

    Order[] public allOrders;
    mapping(string => Order) public orders;
    mapping(address => bool) public attendees;
    // address[] public allAttendees;
    mapping(address => bool) public vendors;
    // address[] public allVendors;
    mapping(address => uint256) vendorBalance;
    mapping(address => mapping(string => bool)) public claims;
    mapping(address => uint256) public lastClaim;
    mapping(string => bool)public validOrderIds;


    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Only Admin");
        _;
    }
    
    modifier onlyVendor() {
        require(hasRole(VENDOR_ROLE, msg.sender), "Only Vendor");
        _;
    }
    
    modifier onlyAttendee() {
        require(hasRole(ATTENDEE_ROLE, msg.sender), "Only Attendee");
        _;
    }

    function setBuidlToken(ERC20 _buidlTokenAddress)public onlyAdmin{
        buidlBuxx = _buidlTokenAddress;
    }
    
    function grantAdminRole(address _newAdmin)public onlyOwner{
        _grantRole(ADMIN_ROLE, _newAdmin);
    }

    function setAirdropToken(uint256 _amount)public payable onlyAdmin{
        airdropToken = _amount;
    }

    function register(address _userId, bool _isVendor)public {
        if(_isVendor) {
            require(vendors[_userId]==false, "Already a Vendor");
            require(attendees[_userId] == false, "Attendees can't register as Vendor");
            vendors[_userId] = true;
            _grantRole(VENDOR_ROLE, _userId);
            emit Register(_userId, block.timestamp, _isVendor);
            return;
        }
        require(attendees[_userId]== false, "Already registered");
        attendees[_userId] = true;
        _grantRole(ATTENDEE_ROLE, _userId);
        emit Register(_userId, block.timestamp, _isVendor);
    }

    function completeOrder(string memory _orderId)public onlyVendor{
        Order memory _order = orders[_orderId];
        require(keccak256(abi.encodePacked(orders[_orderId].id)) == keccak256(abi.encodePacked(_orderId)), "Invalid orderId");
        require(msg.sender == _order.vendorId, "Caller not Vendor");
        require(_order.done == false,"Already completed");
        _order.done = true;
        _order.time = block.timestamp;
        emit DoneOrder(_orderId,_order.vendorId, _order.userId, _order.amount, _order.time, _order.done);
    }

    function purchase(string memory _orderId, uint256 _amount, address _vendorId, ERC20 _token)public payable onlyAttendee{
        Order memory _order;
         uint256 tokenBalance = _token.balanceOf(msg.sender);
         require(keccak256(abi.encodePacked(orders[_orderId].id)) != keccak256(abi.encodePacked(_orderId)), "Order exists");
         require(tokenBalance >= _amount, "Insufficient balance");
         require(vendors[_vendorId], "Invalid Vendor" );
        if(address(_token) == address(buidlBuxx)){
        _token.transferFrom(msg.sender, _vendorId, _amount * 10e2);
        }else{
        _token.transferFrom(msg.sender, _vendorId, _amount * 10e18);
        }
        _order.id = _orderId;
        _order.userId = msg.sender;
        _order.vendorId = _vendorId;
        _order.amount = _amount;
        _order.time = block.timestamp;
        _order.done = false;
        orders[_orderId] = _order;
        allOrders.push(_order);
        emit NewOrder( _order.id, _order.vendorId, _order.userId, _order.amount, _order.time, _order.done);
    }

    function claimToken(string memory _orderId)public onlyAttendee {
        // TODOs
        uint256 _lastClaim = lastClaim[msg.sender];
        require(!claims[msg.sender][_orderId], "Already claimed");
        require(block.timestamp - _lastClaim >= 86400, "Last claim less than 24 hours");
        claims[msg.sender][_orderId] = true;
        lastClaim[msg.sender] = block.timestamp;
    }





}