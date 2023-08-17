// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * PaymentSplit 
 * @dev this contract will split ETH to other accounts when it receive token and those token save in this contract.
 * you can invoke release() function when each beneficiary need it.
 */
contract PaymentSplit {

    //event
    event PayeeAdded(address acc, uint256 shares); // add payee event
    event PaymentReleased(address to, uint256 amount); // beneficiary withdraw money event
    event PaymentReceived(address from, uint256 amount); // contract received event
    
    uint256 public totalShares; // total share
    uint256 public totalReleased; // total released

    mapping(address => uint256) public shares; // pre beneficiary share
    mapping(address => uint256) public released; // pay pre beneficiary amount
    address[] public payees; // beneficiary array

    /**
     * @dev init beneficiay share
     * @param _payees beneficiay array
     * @param _shares share array
     */
    constructor(address[] memory _payees, uint256[] memory _shares) payable {
        // check _payees and _shares the length is equal and Greater than 0
        require(_payees.length == _shares.length, "PaymentSplitter: payees and shares length mismatch");
        require(_payees.length > 0, "PaymentSplitter: no payees");
        // invoke _addPayee，update payees、shares and totalShares
        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _shares[i]);
        }
    }

    /**
     * @dev callback function，receive ETH and write PaymentReceived event
     */
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev any one can invoke this function that for beneficiary to cul amount should be give and transfer _account the ETH 
     */
    function release(address payable _account) public virtual {
        // account must has share
        require(shares[_account] > 0, "PaymentSplitter: account has no shares");
        // cul account eth
        uint256 payment = releasable(_account);
        // the eth can be extracted shound > 0
        require(payment != 0, "PaymentSplitter: account is not due payment");
        // update totalReleased and payment per beneficiary amount
        totalReleased += payment;
        released[_account] += payment;
        // transfer
        _account.transfer(payment);
        emit PaymentReleased(_account, payment);
    }

    /**
     * @dev cul this account can get amount of eth
     */
    function releasable(address _account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased;
        return pendingPayment(_account, totalReceived, released[_account]);
    }


    /**
     * @dev cul the current ETH for this beneficiary。
     */
    function pendingPayment(
        address _account,
        uint256 _totalReceived,
        uint256 _alreadyReleased
    ) public view returns (uint256) {
        // account ETH = all_ETH - already_get_ETH
        return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
    }


    /**
     * @dev add new beneficiary and share
     * @param _account account address
     * @param _accountShares share
     */
    function _addPayee(address _account, uint256 _accountShares) private {
        // check _account not is address(0)
        require(_account != address(0), "PaymentSplitter: account is the zero address");
        // check _accountShares not equel 0
        require(_accountShares > 0, "PaymentSplitter: shares are 0");
        // check _account not repeat
        require(shares[_account] == 0, "PaymentSplitter: account already has shares");
        // update payees，shares和totalShares
        payees.push(_account);
        shares[_account] = _accountShares;
        totalShares += _accountShares;
        
        emit PayeeAdded(_account, _accountShares);
    }
}