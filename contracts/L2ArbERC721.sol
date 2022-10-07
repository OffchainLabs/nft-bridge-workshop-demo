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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract L2ArbERC721 is ERC721 {
    address public gateway;
    address public l1Address;

    constructor(string memory _name, string memory _symbol)
        public
        ERC721(_name, _symbol)
    {}

    function bridgeInit(address _l1Address, address _gateway) external {
        gateway = gateway;
        l1Address = _l1Address;
    }

    modifier onlyGateway() {
        require(msg.sender == gateway, "NOT_GATEWAY");
        _;
    }

    function bridgeMint(address to, uint256 tokenId) external onlyGateway {
        _mint(to, tokenId);
    }

    function bridgeBurn(uint256 tokenId) external onlyGateway {
        _burn(tokenId);
    }
}
