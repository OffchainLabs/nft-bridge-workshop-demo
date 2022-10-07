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
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./L1NftGateway.sol";
// solhint-disable-next-line compiler-version
pragma solidity >=0.6.9 <0.9.0;

contract L1ArbERC721 is ERC721, Ownable {
    constructor(string memory _name, string memory _symbol)
        public
        ERC721(_name, _symbol)
    {}

    function mint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function registerTokenToL2(
        address l1Gateway,
        address _l2Address,
        L2GasParams memory _l2GasParams,
        address refundAddress
    ) public {
        L1NftGateway(l1Gateway).registerTokenToL2(
            _l2Address,
            _l2GasParams,
            refundAddress
        );
    }
}
