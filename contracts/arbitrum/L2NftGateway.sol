// // SPDX-License-Identifier: Apache-2.0

// /*
//  * Copyright 2020, Offchain Labs, Inc.
//  *
//  * Licensed under the Apache License, Version 2.0 (the "License");
//  * you may not use this file except in compliance with the License.
//  * You may obtain a copy of the License at
//  *
//  *    http://www.apache.org/licenses/LICENSE-2.0
//  *
//  * Unless required by applicable law or agreed to in writing, software
//  * distributed under the License is distributed on an "AS IS" BASIS,
//  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  * See the License for the specific language governing permissions and
//  * limitations under the License.
//  */

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "arbos-precompiles/arbos/builtin/ArbSys.sol";
import "./AddressAliasHelper.sol";
import "../ethereum/L1NftGateway.sol";
import "./L2ArbERC721.sol";

contract L2NftGateway is IERC721Receiver {
    mapping(address => address) public l1ToL2Token;
    address public counterpartL1Gateway;
    address public counterpartL1GatewayAliased;


    function initialize(address _counterpartL1Gateway) public {
        require(counterpartL1Gateway == address(0), "ALREADY_INIT");
        require(_counterpartL1Gateway != address(0), "BAD_COUNTERPART");
        counterpartL1Gateway = _counterpartL1Gateway;
        counterpartL1GatewayAliased = AddressAliasHelper.applyL1ToL2Alias(counterpartL1Gateway);
    }

    modifier onlyCounterpartL1Gateway() {
        require(
            msg.sender ==
                counterpartL1GatewayAliased,
            "ONLY_COUNTERPART_L1_GATEWAY"
        );
        _;
    }

    function withdraw(
        address l1Token,
        uint256 tokenId,
        address to
    ) external returns (uint256) {
        address l2Token = l1ToL2Token[l1Token];
        require(l2Token != address(0), "NOT_REGISTERED");

        // TODO: necessary?
        require(
            L2ArbERC721(l2Token).l1Address() == l1Token,
            "INVALID_TOKEN"
        );
        L2ArbERC721(l2Token).bridgeBurn(msg.sender, tokenId);

        bytes memory _l1MessageCallData = abi.encodeWithSelector(
            L1NftGateway.finalizeWithdraw.selector,
            l1Token,
            tokenId,
            to
        );

        return ArbSys(address(100)).sendTxToL1(counterpartL1Gateway, _l1MessageCallData);
    }

    function finalizeDeposit(
        address l1Token,
        address l2Token,
        uint256 tokenId,
        address to
    ) external onlyCounterpartL1Gateway {
        require(l1ToL2Token[l1Token] == l2Token, "WRONG_ADDRESS_PAIRING");
        L2ArbERC721(l2Token).bridgeMint(to, tokenId);
    }

    function finalizeRegistrationFromL1(address l1Address, address l2Address)
        external
        onlyCounterpartL1Gateway
    {
        l1ToL2Token[l1Address] = l2Address;
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
