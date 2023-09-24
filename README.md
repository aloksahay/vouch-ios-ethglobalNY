# Technologies Used

- XMTP: The messaging protocol is built upon XMTP with a layer of authentication built upon it.
- WalletConnect: The XMTP SDK for iOS uses Wallet Connect to Pair with the Dapp
- Base: The inspiration behind this project was my Coinbase wallet that frequently gets spammed by bot messages, so a way to authenticate users would be a great addition
- NextID: We use web3.bio to fetch user's known credentials. We used nextID API to fetch bio on top of ENS since ENS has its own points of failure
- ApeCoin: ApeCoin DAO and NFT community members are frequently subjected to phishing attacks that are quite sophisticated. We account for all edge cases to protect the community members.
- NounsDAO: Nouns DAO and NFT community members are frequently subjected to phishing attacks that are quite sophisticated. We account for all edge cases to protect the community members.
- Lens Protocol: We used Lens socials to verify sender authenticity.
- ENS: Super easy to use API, adds a layer of authentication to the user sending the message


XMTP integration inspirated by: https://github.com/xmtp/xmtp-ios
