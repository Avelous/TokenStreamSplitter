//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ISuperfluid, ISuperToken, ISuperApp} from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import {SuperTokenV1Library} from "@superfluid-finance/ethereum-contracts/contracts/apps/SuperTokenV1Library.sol";

error Unauthorized();

contract StreamSplitter {
  // ---------------------------------------------------------------------------------------------
  // EVENTS

  event EqualTokenStreams(
    uint256 indexed id,
    address indexed sender,
    address[] recipients,
    int96 flowRate,
    ISuperToken token,
    string tokenName
  );

  event UnequalTokenStreams(
    uint256 indexed id,
    address indexed sender,
    address[] recipients,
    int96[] flowRates,
    ISuperToken token,
    string tokenName
  );

  // STATE VARIABLES

  /// @notice Owner.
  address public owner;

  /// @notice CFA Library.
  using SuperTokenV1Library for ISuperToken;

  /// @notice Allow list.
  mapping(address => bool) public accountList;

  /// @notice Split Ids
  uint256 id;

  constructor(address _owner) {
    owner = _owner;
    id = 1;
  }

  /// @notice Add account to allow list.
  /// @param _account Account to allow.
  function allowAccount(address _account) external {
    if (msg.sender != owner) revert Unauthorized();

    accountList[_account] = true;
  }

  /// @notice Removes account from allow list.
  /// @param _account Account to disallow.
  function removeAccount(address _account) external {
    if (msg.sender != owner) revert Unauthorized();

    accountList[_account] = false;
  }

  /// @notice Transfer ownership.
  /// @param _newOwner New owner account.
  function changeOwner(address _newOwner) external {
    if (msg.sender != owner) revert Unauthorized();

    owner = _newOwner;
  }

  /// @notice Send a lump sum of super tokens into the contract.
  /// @dev This requires a super token ERC20 approval.
  /// @param token Super Token to transfer.
  /// @param amount Amount to transfer.
  function sendLumpSumToContract(ISuperToken token, uint256 amount) external {
    if (!accountList[msg.sender] && msg.sender != owner) revert Unauthorized();

    token.transferFrom(msg.sender, address(this), amount);
  }

  /// @notice Create a stream into the contract.
  /// @dev This requires the contract to be a flowOperator for the msg sender.
  /// @param token Token to stream.
  /// @param flowRate Flow rate per second to stream.
  function createFlowIntoContract(ISuperToken token, int96 flowRate) external {
    if (!accountList[msg.sender] && msg.sender != owner) revert Unauthorized();

    token.createFlowFrom(msg.sender, address(this), flowRate);
  }

  /// @notice Update an existing stream being sent into the contract by msg sender.
  /// @dev This requires the contract to be a flowOperator for the msg sender.
  /// @param token Token to stream.
  /// @param flowRate Flow rate per second to stream.
  function updateFlowIntoContract(ISuperToken token, int96 flowRate) external {
    if (!accountList[msg.sender] && msg.sender != owner) revert Unauthorized();

    token.updateFlowFrom(msg.sender, address(this), flowRate);
  }

  /// @notice Delete a stream that the msg.sender has open into the contract.
  /// @param token Token to quit streaming.
  function deleteFlowIntoContract(ISuperToken token) external {
    if (!accountList[msg.sender] && msg.sender != owner) revert Unauthorized();

    token.deleteFlow(msg.sender, address(this));
  }

  /// @notice Withdraw funds from the contract.
  /// @param token Token to withdraw.
  /// @param amount Amount to withdraw.
  function withdrawFunds(ISuperToken token, uint256 amount) external {
    if (!accountList[msg.sender] && msg.sender != owner) revert Unauthorized();

    token.transfer(msg.sender, amount);
  }

  /// @notice Create flow from contract to specified address.
  /// @param token Token to stream.
  /// @param receiver Receiver of stream.
  /// @param flowRate Flow rate per second to stream.
  function createFlowFromContract(ISuperToken token, address receiver, int96 flowRate) public {
    if (!accountList[msg.sender] && msg.sender != owner) revert Unauthorized();

    token.createFlow(receiver, flowRate);
  }

  /// @notice Update flow from contract to specified address.
  /// @param token Token to stream.
  /// @param receiver Receiver of stream.
  /// @param flowRate Flow rate per second to stream.
  function updateFlowFromContract(ISuperToken token, address receiver, int96 flowRate) external {
    if (!accountList[msg.sender] && msg.sender != owner) revert Unauthorized();

    token.updateFlow(receiver, flowRate);
  }

  /// @notice Delete flow from contract to specified address.
  /// @param token Token to stop streaming.
  /// @param receiver Receiver of stream.
  function deleteFlowFromContract(ISuperToken token, address receiver) external {
    if (!accountList[msg.sender] && msg.sender != owner) revert Unauthorized();

    token.deleteFlow(address(this), receiver);
  }

  // Splitting functions

  /// @notice Create equal flows from contract to multiple addresses.
  /// @param token Token to stream.
  /// @param recipients Recipients of stream.
  /// @param flowRateForEach Flow rate per second to stream.
  function streamTokensEqually(address[] memory recipients, ISuperToken token, int96 flowRateForEach) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      createFlowFromContract(token, recipients[i], flowRateForEach);
    }

    emit EqualTokenStreams(id, msg.sender, recipients, flowRateForEach, token, token.name());

    id += 1;
  }

  /// @notice Create equal flows from contract to multiple addresses.
  /// @param token Token to stream.
  /// @param recipients Recipients of stream.
  /// @param flowRateForEach Flow rate per second to stream for each recipient.
  function streamTokensUnequally(
    address[] memory recipients,
    ISuperToken token,
    int96[] memory flowRateForEach
  ) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      createFlowFromContract(token, recipients[i], flowRateForEach[i]);
    }

    emit UnequalTokenStreams(id, msg.sender, recipients, flowRateForEach, token, token.name());
    id += 1;
  }
}
