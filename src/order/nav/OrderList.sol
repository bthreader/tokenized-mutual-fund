// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {AbstractOrderList} from "../AbstractOrderList.sol";
import {Order} from "../Order.sol";

contract OrderList is AbstractOrderList {
    mapping(uint256 => Order) private _orders;

    constructor () {
        _headId = 0;
        _tailId = 0;
        _incrementer = 1;
    }
    
    function enqueue(address addr, uint256 shares) 
        public 
        override 
        returns (uint) 
    {
        uint256 newId;
        uint256 prevId;

        // Empty LL
        if (_headId == 0) {
            newId = _incrementer = 1;
            
            // Set the order as the head and tail
            _headId = _tailId = newId;
            
            prevId = 0;
        }

        // Non-empty LL
        else {
            newId = _incrementer;
            // Update the tail
            _orders[_tailId].setNextId(newId);
            _tailId = newId;
            
            prevId = _tailId;
        }

        // Add the order information to LL
        _orders[newId] = new Order({
            id : newId,
            nextId : 0,
            prevId : prevId,
            addr : addr,
            shares : shares
        });

        return newId;
    }

    function dequeue() public override {
        // Single order case
        if (_headId == _tailId) {
            delete _orders[_headId];
            _headId = _tailId = 0;
            return;
        }

        uint256 oldHeadId = _headId;

        // Over-write pointer
        _headId = _orders[_headId]._nextId();
        _orders[_headId].setPrevId(0);

        // Delete
        delete _orders[oldHeadId];
    }

    function deleteId(uint256 id) public override {
        uint256 prevId = _orders[id]._prevId();
        uint256 nextId = _orders[id]._nextId();
        
        // Single order case
        if ((prevId == 0) && (nextId == 0)) {
            _headId = 0;
            _tailId = 0;
        }

        // Order is first entry
        else if (prevId == 0) {
            _orders[nextId].setPrevId(0);
            _headId = _orders[nextId]._id();
        }

        // Order is last entry
        else if (nextId == 0) {
            _orders[prevId].setNextId(0);
            _tailId = _orders[prevId]._id();
        }

        // Sandwich case
        else {
            _orders[prevId].setNextId(nextId);
            _orders[nextId].setPrevId(prevId);
        }
        
        delete _orders[id];
    }

    function changeSharesOnId(uint256 id, bool add, uint256 shares) 
        public
        override 
    {
        uint256 newSharesCount;
        
        if (add) {
            newSharesCount = _orders[id]._shares() + shares;
        }
        else {
            require(
                _orders[id]._shares() >= shares,
                "Can't remove more shares than are in the order"
            );

            newSharesCount = _orders[id]._shares() - shares;
        }

        _orders[id].setShares(newSharesCount);
    }
}