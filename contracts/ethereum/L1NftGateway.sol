// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2020, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "arb-bridge-eth/contracts/bridge/interfaces/IInbox.sol";
import "arb-bridge-eth/contracts/bridge/interfaces/IOutbox.sol";
import "../arbitrum/L2NftGateway.sol";

struct L2GasParams {
    uint256 _maxSubmissionCost;
    uint256 _maxGas;
    uint256 _gasPriceBid;
}

contract L1NftGateway is IERC721Receiver {
    address public counterpartL2Gateway;
    address public inbox;
    address public bridge;
    mapping(address => address) public l1ToL2Token;

    function initialize(address _counterpartL2Gateway, address _inbox) public {
        require(counterpartL2Gateway == address(0), "ALREADY_INIT");
        require(_counterpartL2Gateway != address(0), "BAD_COUNTERPART");
        require(_inbox != address(0), "BAD_INBOX");
        address _bridge = address(IInbox(_inbox).bridge());

        counterpartL2Gateway = _counterpartL2Gateway;
        inbox = _inbox;
        bridge = _bridge;
    }

    modifier onlyCounterpartL2Gateway() {
        // a message coming from the counterpart gateway was executed by the bridge
        // NOTE: do we really need this?
        require(msg.sender == bridge, "NOT_FROM_BRIDGE");

        // and the outbox reports that the L2 address of the sender is the counterpart gateway
        IOutbox outbox = IOutbox(IBridge(bridge).activeOutbox());
        address l2ToL1Sender = outbox.l2ToL1Sender();

        require(
            l2ToL1Sender == counterpartL2Gateway,
            "ONLY_COUNTERPART_GATEWAY"
        );
        _;
    }

    function finalizeWithdraw(
        address _l1Token,
        uint256 _tokenId,
        address _to
    ) external onlyCounterpartL2Gateway {
        IERC721(_l1Token).safeTransferFrom(address(this), _to, _tokenId);
    }

    function getRegisterL2MessageCallData(
        address _l1Address,
        address _l2Address
    ) pure public returns (bytes memory) {
        return
            abi.encodeWithSelector(
                L2NftGateway.finalizeRegistrationFromL1.selector,
                _l1Address,
                _l2Address
            );
    }

    function registerTokenToL2(
        address _l2Address,
        L2GasParams memory _l2GasParams,
        address _refundAddress
    ) public payable returns (uint256) {
        address _l1Address = msg.sender;
        address currL2Addr = l1ToL2Token[_l1Address];
        if (currL2Addr != address(0)) {
            // if token is already set, don't allow it to set a different L2 address
            require(currL2Addr == _l2Address, "NO_UPDATE_TO_DIFFERENT_ADDR");
        }

        l1ToL2Token[_l1Address] = _l2Address;

        bytes memory _l2MessageCallData = getRegisterL2MessageCallData(_l1Address, _l2Address);

        uint256 seqNum = IInbox(inbox).createRetryableTicket{value: msg.value}(
            counterpartL2Gateway,
            0,
            _l2GasParams._maxSubmissionCost,
            _refundAddress,
            _refundAddress,
            _l2GasParams._maxGas,
            _l2GasParams._gasPriceBid,
            _l2MessageCallData
        );

        return seqNum;
    }

    function getDepositL2MessageCallData(
        address _l1Token,
        address _l2Token,
        uint256 _tokenId,
        address _to
    ) public pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                L2NftGateway.finalizeDeposit.selector,
                _l1Token,
                _l2Token,
                _tokenId,
                _to
            );
    }

    function deposit(
        address _l1Token,
        uint256 _tokenId,
        address _to,
        L2GasParams memory _l2GasParams,
        address _refundAddress
    ) external payable returns (uint256) {
        address l2Token = l1ToL2Token[_l1Token];
        require(l2Token != address(0), "NOT_REGISTERED");

        IERC721(_l1Token).safeTransferFrom(msg.sender, address(this), _tokenId);
        bytes memory _l2MessageCallData = getDepositL2MessageCallData(
            _l1Token,
            l2Token,
            _tokenId,
            _to
        );

        uint256 seqNum = IInbox(inbox).createRetryableTicket{value: msg.value}(
            counterpartL2Gateway,
            0,
            _l2GasParams._maxSubmissionCost,
            _refundAddress,
            _refundAddress,
            _l2GasParams._maxGas,
            _l2GasParams._gasPriceBid,
            _l2MessageCallData
        );

        return seqNum;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
