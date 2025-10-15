# 🧠 AI-Generated NFT Smart Contract

A minimal **Solidity smart contract** that creates **AI-generated NFTs** with **dynamic on-chain metadata** — built **without imports or constructors**.  

Each NFT’s JSON metadata and SVG image are generated entirely **on-chain**, using blockchain data to make every artwork unique.

---

## ✨ Features  
- 🪙 Parameterless `mint()` — anyone can mint NFTs  
- 🎨 On-chain SVG + JSON (no IPFS or external files)  
- 🔢 Unique metadata per token based on block data  
- 🧩 Minimal ERC-721-style logic (transfer, approve, etc.)  
- 🧠 No imports, no constructor, no dependencies  

---

## 🚀 How to Deploy  
1. Open [Remix IDE](https://remix.ethereum.org)  
2. Paste the Solidity code  
3. Compile with **Solidity 0.8.19**  
4. Deploy `AIGeneratedNFT` (no arguments)  
5. Call `mint()` to create your first NFT  

---

## 🧾 Example Metadata  
```json
{
  "name": "AI Artwork #1",
  "description": "On-chain AI-generated art NFT.",
  "attributes": [
    {"trait_type": "palette", "value": "#aabbcc / #112233"},
    {"trait_type": "shape", "value": "Star Polygon"}
  ],
  "image": "data:image/svg+xml;utf8,<svg>...</svg>"
}
```

---

## 👤 Deployed By  
**Creator Address:** `0x9c76d08a6B0D1934C2f1AD3Af096ea920D37310E`  

---

## 📄 License  
MIT License — free to use, modify, and build upon.  
