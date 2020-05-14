pragma solidity ^0.4.26;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract TRC21 {
    // Function
    function totalSupply() public view returns (uint256 _totalSupply);
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function transferFrom(address _from, address _to, uint _amount) public;
    function transfer(address _to, uint _amount) public;
    function approve(address _spender, uint _amount) public;
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
}

contract WithdrawPoint is Ownable{
  address serverAddress;
  address itemAddress;
  TRC21 itemContract;
  uint withdrawPoint;
  mapping(bytes32 => bool) usedHash;

  constructor(address _serverAddress, address _itemAddress,uint _withdrawPoint) public{
      serverAddress = _serverAddress;
      itemAddress = _itemAddress;
      itemContract = TRC21(_itemAddress);
      withdrawPoint = _withdrawPoint;
  }
  function setServerAddress(address _serverAddress) onlyOwner external{
      serverAddress = _serverAddress;
  }

  function setItemAddress(address _itemAddress) onlyOwner external{
      itemAddress = _itemAddress;
      itemContract = TRC21(_itemAddress);
  }

  function setWithdrawPoint(uint _withdrawPoint) onlyOwner external {
      withdrawPoint = _withdrawPoint;
  }

  function ecverify(bytes32 hash, bytes signature) private pure returns(address sig_address) {
    require(signature.length == 65);

    bytes32 r;
    bytes32 s;
    uint8 v;

    // The signature format is a compact form of:
    //   {bytes32 r}{bytes32 s}{uint8 v}
    // Compact means, uint8 is not padded to 32 bytes.
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))

    // Here we are loading the last 32 bytes, including 31 bytes of 's'.
      v := byte(0, mload(add(signature, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible
    if (v < 27) {
      v += 27;
    }

    require(v == 27 || v == 28);
    sig_address = ecrecover(hash, v, r, s);

    // ecrecover returns zero on error
    require(sig_address != 0x0);
  }

  function valify(bytes32 hash, bytes signature) private view returns (bool){
      address sig_address = ecverify(hash, signature);
      return (sig_address == serverAddress);
  }

  function withdraw(bytes32 hash,  bytes signature) public{
      require(valify(hash,signature),"sign fail");
      require(!usedHash[hash], "this hash is already use");
      usedHash[hash] = true;
      itemContract.transfer(msg.sender,withdrawPoint);
  }
  function withdrawEther(uint256 valueWai) external onlyOwner{
        msg.sender.transfer(valueWai);
    }
  function withdrawToken(uint256 amount) external onlyOwner{
       itemContract.transfer(msg.sender,amount);
  }
}
