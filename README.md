# open AI+ Protocol

open AI+ is a curation economy system for AI marketplace. For simplicity, hereafter collectively referred to as the curation economy. Smart contracts specify the interaction between the four roles (like creator, curator, delegator, developer) and the fair distribution of profits in the system.

![open AI+ protocol](resources/imgs/open AI+_arch2.png)

## Features

- Curation is essentially storytelling, and we support users who are good at storytelling to drive the sales of NFTs by creating high-quality content and curations.

- All content is seen as curation and will be minted into NFTs, including user profiles, plugins, llms, agents, various content, lists, feeds, Dapps, etc..

- All curations can accept staking to share value on a larger scale.

- Creators have the right to choose the selling method that best suits their own interests to sell their NFTs.

- Support future applications such as 1. Information Curation Applications; 2. Audio or video streaming applications; 3. book or comic applications. 4.Decentralized NFT Market Applications. 5. Decentralized e-Print archive, like arXiv.org, etc..

## Curation Overview

Curation, as an NFT, is the core of the protocol, that is, it can be cast into a profile that represents the user's identity, or it can be any form of content published by the user, which can be collected and pledged.

### Curation Types

- **$Self\ Curation$**: Presented as a CV or profile NFT that explains who we are, what we have and what we do.
  
- **$Single\ Curation$**: Expressed as basic posts, such as microblogs, articles, audio, video, etc., used to show the creator's gigs, ideas, work, life, knowledge, tastes, etc., which will be minted as NFTs by default, so they can be collected by fans and used as creator's soulband items.
  
- **$Combined\ Curation$**: Various organic combinations of content are also a way of curation, just like the mutual achievement of video and music in tiktok, which will produce a magical chemical reaction.
  
- **$Protfolio\ Curation$**: Equally and purposefully combine content into a list, such as a jazz playlist.
  
- **$Feed\ Curation$**: Featured or specific types of information streams, such as news, funny videos, audio novels, etc.

- **$Dapp\ Curation$**: Various types of applications developed based on open AI+ protocol.
  
![curation types](resources/imgs/curation_types.png)

### Stakeholders

Curation should allow nesting, each level of curation can share part of the revenue of NFT sales, and the stakeholders of NFT sales can also be multi-faceted, including creators, curators, delegators, and Developer.

- Creator: Creators publish microblogs, articles, pictures, audios, videos, Q&A, etc. as NFTs.
  
- Curator: Curators are also creators. However, They try to combine different elements to tell a story. Like a literati combining words into prose, like a musician combining notes into a symphony. It is worth noting that the main curation method of this article is combined curation, protfdio curation, and feed curation, excludes the other two special curation types. The open AI+ rewards Curators that tell a unique and valuable story earn a share of sale fees of NFTs and rewards.
- Delegator: Delegator are critical to the decentralized curation economy. They use their knowledge or intuition to assess and signal on the curations.  Delegator are economically incentivized to siganl early. By signalling on a curation, you will earn a share of all the curation share revenue that this curation generates. x% of all curation share revenue goes to the delegators pro-rata to their delegation shares.
- Developer: Create a feed curation or use existing data or feeds in a dapp.

As shown in the figure below, the system includes two value distribution modes: static and dynamic distribution. Static distribution occurs on a single curation entity, whose distribution is fixed. Whereas dynamic distribution is related to the context of each transaction, i.e. curation. When the curation is different, the benefit distribution will be different. For example, 2-level nested curation and 3-level nested curation allocation scheme will be different.

![static and dynamic distribution](resources/imgs/curation_nested.png)

## Contracts

### BardsHub

The BardsHub is a contract that has a registry of all protocol contract addresses. It also is the owner of all the contracts. The owner of the BardsHub is The Governor, which makes The Governor the address that can configure the whole protocol. The Governor is The Bards Council.

### Epoch Manager

Keeps track of protocol Epochs. Epochs are configured to be a certain block length, which is configurable by The Governor.

### Rewards Manager

Tracks how inflationary TBT rewards should be handed out. It relies on the Curation contract and the Staking contract. Signaled TBT in Curation determine what percentage of inflationary tokens go towards each curation.

### Bards Staking

The Staking contract allows Delegators to Stake on curations.

### NFT Market Moduels

Decentralized NFT trading market protocol, curators can freely choose any of the following trading methods when creating a curation.

- FixPriceMarketModule
- FreeMarketModule

### Programmable NFT Minter Modules

According to different scenarios and needs, curators can freely choose any of the following programmable NFT casting methods when creating a curation.

- TransferMinter
- CloneMinter

### The Bards Curation Token

An ERC-20 token (BCT) that is used as a work token to power the network incentives. The token is inflationary.

### The Bards Share Token

An ERC-20 token (BST) that is used as a share token. The delegator pledges BCT to the curation in exchange for BST to represent the stake.

## Contract Addresses

The testnet runs on Goerli, while mainnet is on Ethereum Mainnet. The addresses for both of these can be found in `./addresses.json`.

## Local Setup

To setup the contracts locally, checkout the `dev` branch, then run:

```bash
yarn
yarn build
```

## Testing

For testing details see [TESTING.md](./TESTING.md).

## Deploying Contracts

In order to run deployments, see [DEPLOYMENT.md](./DEPLOYMENT.md).

## Interacting with the contracts

There are three ways to interact with the contracts through this repo:

### Hardhat

The most straightforward way to interact with the contracts is through the hardhat console. We have extended the hardhat runtime environment to include all of the contracts. This makes it easy to run the console with autocomplete for all contracts and all functions. It is a quick and easy way to read and write to the contracts.

```
# A console to interact with testnet contracts
npx hardhat console --network goerli
```

### Hardhat Tasks

There are hardhat tasks under the `/tasks` folder. Most tasks are for complex queries to get back data from the protocol.

### CLI

There is a CLI that can be used to read or write to the contracts. It includes scripts to help with deployment.

## Environment

When running the Hardhat console or tasks you can set what network and accounts to use when sending transactions.

### Network

Selecting a network requires just passing `--network <name>` when running Hardhat. It's important that the network exists in the Hardhat configuration file.

_There is a special network called `localhost` that connects it to a node running on localhost._

### Accounts

The accounts used depends on a few environment variables:

- If MNEMONIC is set you will have available the set of addresses derived from the seed.
- If PRIVATE_KEY is set, just that account is imported. MNEMONIC always takes precedence over PRIVATE_KEY.
- If no MNEMONIC or PRIVATE_KEY is set it will use the remote accounts from the provider node.
- You can always get an account using `ethers.getSigner(<address>)`

Considerations when forking a chain:

- When running on the `localhost` network it will use by default a deterministic seed for testing purposes. If you want to connect to a local node that is forking while retaining the capability to impersonate accounts or use local accounts you need to set the FORK=true environment variable.
- 

## Development

## Contributing

Contributions are welcomed and encouraged! You can do so by:

- Creating an issue
- Opening a PR

If you are opening a PR, it is a good idea to first go to [The Bards Discord](https://discord.gg/HmWHB3Y5) and discuss your idea! Discussions on the Discord are another great way to contribute.

## Copyright

Copyright © 2022 The Bards Lab

Licensed under GPL license.
