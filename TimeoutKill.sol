// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

import "./Utils.sol";
import "./Craftereum.sol";

/**
 * Contract that bets killer will kill target within the deadline
 * If so, the bettor wins the balance, else, the issuer wins the balance
 **/
contract TimeoutKill is Listener {
    Craftereum public craftereum;
    IEmeralds public emeralds;
    
    address payable public issuer;
    address payable public bettor; 
    
    string public killer;
    string public target;
    
    uint public expiration;
    uint public eventid;
    
    constructor(
        Craftereum _craftereum,
        address payable _bettor,
        string memory _killer,
        string memory _target,
        uint _expiration
    ){
        craftereum = _craftereum;
        emeralds = craftereum.emeralds();
        
        issuer = msg.sender;
        bettor = _bettor;
        
        killer = _killer;
        target = _target;
        expiration = _expiration;
        
        // Wait for a kill 
        eventid = craftereum.onkill(killer, target);
    }
    
    function balance() external returns (uint) {
        return emeralds.balance();
    }
    
    /**
     * Pay the bettor with blockchain EMRLD 
     **/
    function onkill(
        uint _eventid,
        string memory _killer,
        string memory _target
    ) external override {
        require(msg.sender == address(craftereum));
        require(block.timestamp < expiration);
        
        require(_eventid == eventid);
        require(Utils.equals(_target, target));
        require(Utils.equals(_killer, killer));
        
        craftereum.cancel(eventid);
        
        uint balance = emeralds.balance();
        emeralds.transfer(bettor, balance);
    }
    
    /**
     * Refund the issuer
     **/
    function refund() external {
        require(msg.sender == issuer);
        require(block.timestamp > expiration);
        
        craftereum.cancel(eventid);
        
        uint balance = emeralds.balance();
        emeralds.transfer(issuer, balance);
    }
}
