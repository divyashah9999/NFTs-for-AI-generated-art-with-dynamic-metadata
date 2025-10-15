// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*
  A minimal ERC-721 style contract (no imports, no constructor).
  - Parameterless mint() mints to msg.sender and generates on-chain dynamic metadata.
  - tokenURI returns a data:application/json;utf8, ... string containing JSON with an SVG image (data:image/svg+xml;utf8,...).
  - Minimal approvals, transfers, and events implemented to be ERC-721 compatible.
  - No external libraries or constructor used.
*/

contract AIGeneratedNFT {
    // ERC-721 events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public constant name = "AI Generated Art";
    string public constant symbol = "AIGA";

    // token data
    uint256 private _nextTokenId = 1; // start token IDs at 1
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ---------- ERC-721 read functions ----------
    function balanceOf(address ownerAddr) public view returns (uint256) {
        require(ownerAddr != address(0), "zero address");
        return _balances[ownerAddr];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address ownerAddr = _owners[tokenId];
        require(ownerAddr != address(0), "nonexistent token");
        return ownerAddr;
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address ownerAddr, address operator) public view returns (bool) {
        return _operatorApprovals[ownerAddr][operator];
    }

    // ---------- Minting (no input fields) ----------
    // Parameterless mint(): mints a new token to msg.sender
    function mint() public returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _owners[tokenId] = msg.sender;
        _balances[msg.sender] += 1;

        emit Transfer(address(0), msg.sender, tokenId);
        return tokenId;
    }

    // ---------- Approvals ----------
    function approve(address to, uint256 tokenId) public {
        address ownerAddr = ownerOf(tokenId);
        require(to != ownerAddr, "approval to current owner");
        require(msg.sender == ownerAddr || isApprovedForAll(ownerAddr, msg.sender), "not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerAddr, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // ---------- Transfers ----------
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address ownerAddr = ownerOf(tokenId);
        return (spender == ownerAddr || getApproved(tokenId) == spender || isApprovedForAll(ownerAddr, spender));
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "not approved or owner");
        require(ownerOf(tokenId) == from, "from not owner");
        require(to != address(0), "transfer to zero");

        // clear approvals
        _tokenApprovals[tokenId] = address(0);

        // update balances & ownership
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // Minimal safeTransferFrom (calls onERC721Received if recipient is a contract)
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId);
    }

    // ---------- Minimal receiver check ----------
    // If 'to' is a contract, call onERC721Received(address,uint256,bytes) signature:
    // bytes4(keccak256("onERC721Received(address,uint256,bytes)")) == 0x150b7a02
    function _checkOnERC721Received(address from, address to, uint256 tokenId) internal {
        uint256 codeSize;
        assembly { codeSize := extcodesize(to) }
        if (codeSize > 0) {
            // attempt low-level call; ignore revert message but require correct selector if returned
            (bool success, bytes memory ret) = to.call(
                abi.encodeWithSelector(0x150b7a02, msg.sender, tokenId, "")
            );
            // If contract did not return the required selector, revert
            bytes4 returned = ret.length >= 4 ? bytes4(ret[0]) | (bytes4(ret[1]) >> 8) | (bytes4(ret[2]) >> 16) | (bytes4(ret[3]) >> 24) : bytes4(0);
            require(success && returned == 0x150b7a02, "ERC721Receiver not implemented");
        }
    }

    // ---------- Dynamic metadata (on-chain JSON + SVG) ----------
    // tokenURI returns a data:application/json;utf8,<json> string. The JSON contains an "image" field which is data:image/svg+xml;utf8,<svg...>
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_owners[tokenId] != address(0), "nonexistent token");

        // create a seed derived deterministically from on-chain data + tokenId so metadata is dynamic-per-token
        uint256 seed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp, tokenId, address(this))));

        // generate some simple attributes: two colors and a shape selection
        uint24 colorA = uint24(seed >> 24); // lower 24 bits for color
        uint24 colorB = uint24(seed >> 48);
        uint8 shapeKind = uint8(seed % 3); // 0,1,2

        string memory svg = _generateSVG(tokenId, colorA, colorB, shapeKind);
        // build JSON metadata
        string memory nameStr = string(abi.encodePacked("AI Artwork #", _uintToString(tokenId)));
        string memory description = "An AI-generated artwork whose appearance is derived on-chain from blockchain entropy.";
        string memory imageData = string(abi.encodePacked("data:image/svg+xml;utf8,", svg));

        // Build JSON. Note: not base64 encoded; returned as utf8 data URI.
        string memory json = string(
            abi.encodePacked(
                '{"name":"', _escapeJson(nameStr),
                '","description":"', _escapeJson(description),
                '","attributes":[{"trait_type":"palette","value":"', _colorPairString(colorA,colorB),
                '"},{"trait_type":"shape","value":"', _shapeName(shapeKind),
                '"}],"image":"', _escapeJson(imageData),
                '"}'
            )
        );

        return string(abi.encodePacked("data:application/json;utf8,", json));
    }

    // ---------- Helpers: SVG + small utilities ----------
    function _generateSVG(uint256 tokenId, uint24 colorA, uint24 colorB, uint8 shape) internal pure returns (string memory) {
        // Simple responsive SVG that uses two colors and a shape determined by 'shape'
        string memory c1 = _toHexColor(colorA);
        string memory c2 = _toHexColor(colorB);
        string memory idStr = _uintToString(tokenId);

        string memory centerShape;
        if (shape == 0) {
            // concentric circles
            centerShape = string(abi.encodePacked(
                '<g>',
                  '<circle cx="200" cy="200" r="120" fill="#', c1, '" opacity="0.95"/>',
                  '<circle cx="200" cy="200" r="70" fill="#', c2, '" opacity="0.85"/>',
                '</g>'
            ));
        } else if (shape == 1) {
            // rectangle rotated
            centerShape = string(abi.encodePacked(
                '<g transform="translate(200,200) rotate(25)">',
                  '<rect x="-120" y="-120" width="240" height="240" rx="30" fill="#', c1, '" />',
                  '<rect x="-90" y="-90" width="180" height="180" rx="25" fill="#', c2, '" opacity="0.9" />',
                '</g>'
            ));
        } else {
            // polygon star
            centerShape = string(abi.encodePacked(
                '<g>',
                  '<polygon points="200,70 230,170 330,170 250,220 280,320 200,260 120,320 150,220 70,170 170,170" fill="#', c1, '" />',
                  '<circle cx="200" cy="200" r="45" fill="#', c2, '" />',
                '</g>'
            ));
        }

        // Add some text with token id
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400">',
                  '<defs>',
                    '<linearGradient id="g" x1="0" x2="1" y1="0" y2="1">',
                      '<stop offset="0%" stop-color="#', c1, '"/>',
                      '<stop offset="100%" stop-color="#', c2, '"/>',
                    '</linearGradient>',
                  '</defs>',
                  '<rect width="100%" height="100%" fill="url(#g)"/>',
                  centerShape,
                  '<text x="200" y="380" font-family="Arial, Helvetica, sans-serif" font-size="14" fill="#ffffff" text-anchor="middle">AI Artwork #', idStr, '</text>',
                '</svg>'
            )
        );

        return svg;
    }

    // Convert a 24-bit color to 6-char hex (no #)
    function _toHexColor(uint24 c) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        bytes memory out = new bytes(6);
        for (uint i = 0; i < 6; ++i) {
            // take 4 bits per nibble from most significant to least
            uint shift = 20 - 4*i;
            uint8 nibble = uint8((c >> shift) & 0xf);
            out[i] = hexChars[nibble];
        }
        return string(out);
    }

    // helper to produce human friendly color pair string
    function _colorPairString(uint24 a, uint24 b) internal pure returns (string memory) {
        return string(abi.encodePacked("#", _toHexColor(a), " / #", _toHexColor(b)));
    }

    function _shapeName(uint8 s) internal pure returns (string memory) {
        if (s == 0) return "Concentric Circles";
        if (s == 1) return "Rounded Rectangles";
        return "Star Polygon";
    }

    // small uint -> string
    function _uintToString(uint256 v) internal pure returns (string memory str) {
        if (v == 0) {
            return "0";
        }
        uint256 temp = v;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (v != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(v % 10)));
            v /= 10;
        }
        return string(buffer);
    }

    // Minimal JSON-escape for quotes and backslashes (keeps it small)
    function _escapeJson(string memory input) internal pure returns (string memory) {
        bytes memory b = bytes(input);
        // worst case every char becomes two chars, so allocate 2x
        bytes memory out = new bytes(b.length * 2);
        uint256 j = 0;
        for (uint256 i = 0; i < b.length; ++i) {
            bytes1 ch = b[i];
            if (ch == 0x22) { // "
                out[j++] = 0x5C; // '\'
                out[j++] = 0x22; // '"'
            } else if (ch == 0x5C) { // \
                out[j++] = 0x5C;
                out[j++] = 0x5C;
            } else {
                out[j++] = ch;
            }
        }
        bytes memory trimmed = new bytes(j);
        for (uint256 k = 0; k < j; ++k) trimmed[k] = out[k];
        return string(trimmed);
    }
}
