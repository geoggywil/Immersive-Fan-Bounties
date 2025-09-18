# 🎯 Immersive Fan Bounties

A decentralized platform where fans can propose creative challenges and stake tokens as bounties to reward talented creators transparently on the Stacks blockchain.

## ✨ Features

- 🎨 **Create Bounties**: Fans propose creative challenges (remix tracks, design art, write content)
- 💰 **Stake Rewards**: Lock STX tokens as bounties for successful submissions
- 📝 **Submit Entries**: Creators submit their work with content hashes and descriptions
- 🏆 **Transparent Rewards**: Winners are selected and rewarded automatically
- ⏰ **Time-bound Challenges**: Bounties have deadlines to ensure timely completion
- 📊 **Track Progress**: Monitor bounties, submissions, and user activities

## 🚀 Quick Start

### Prerequisites

- [Clarinet CLI](https://github.com/hirosystems/clarinet)
- [Stacks Wallet](https://wallet.hiro.so/)

### Installation

```bash
git clone https://github.com/geoggywil/Immersive-Fan-Bounties
cd Immersive-Fan-Bounties
clarinet check
```

## 📖 Contract Functions

### 🎯 Creating a Bounty

```clarity
(contract-call? .Immersive-Fan-Bounties create-bounty 
    "Remix My Track" 
    "Create an amazing remix of my latest song" 
    u1000000 
    u1000)
```

Parameters:
- `title`: Challenge title (max 100 chars)
- `description`: Detailed description (max 500 chars)  
- `reward-amount`: STX amount in microSTX
- `duration`: Deadline in blocks from current height

### 🎨 Submitting to a Bounty

```clarity
(contract-call? .Immersive-Fan-Bounties submit-to-bounty 
    u1 
    "QmX7Y8Z9..." 
    "My creative remix with electronic elements")
```

Parameters:
- `bounty-id`: Target bounty ID
- `content-hash`: IPFS/content hash of submission
- `description`: Submission description (max 300 chars)

### 🏆 Selecting a Winner

```clarity
(contract-call? .Immersive-Fan-Bounties select-winner u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

Parameters:
- `bounty-id`: Bounty to resolve
- `winner`: Principal address of winning creator

### ⚙️ Managing Bounties

#### Cancel Bounty (after expiration)
```clarity
(contract-call? .Immersive-Fan-Bounties cancel-bounty u1)
```

#### Extend Deadline
```clarity
(contract-call? .Immersive-Fan-Bounties extend-deadline u1 u500)
```

## 🔍 Read-Only Functions

### Get Bounty Details
```clarity
(contract-call? .Immersive-Fan-Bounties get-bounty u1)
```

### Check Bounty Status
```clarity
(contract-call? .Immersive-Fan-Bounties get-bounty-status u1)
```
Returns: `"active"`, `"expired"`, `"completed"`, or `"not-found"`

### Get User's Bounties
```clarity
(contract-call? .Immersive-Fan-Bounties get-user-bounties 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Get User's Submissions
```clarity
(contract-call? .Immersive-Fan-Bounties get-user-submissions 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## 🔒 Security Features

- ✅ Only bounty creators can select winners or cancel bounties
- ✅ Bounties must expire before winners can be selected
- ✅ Creators can only submit once per bounty
- ✅ STX tokens are held in contract until distributed
- ✅ Comprehensive error handling and validation

## 🎮 Usage Examples

### Example 1: Music Remix Challenge
```bash
# Fan creates a remix bounty with 1 STX reward
clarinet console
(contract-call? .Immersive-Fan-Bounties create-bounty 
    "Summer Vibes Remix" 
    "Turn my chill track into a high-energy dance remix" 
    u1000000 
    u2000)

# Artist submits remix
(contract-call? .Immersive-Fan-Bounties submit-to-bounty 
    u1 
    "QmRemixHash123..." 
    "High-energy electronic remix with drop at 1:30")

# After deadline, fan selects winner
(contract-call? .Immersive-Fan-Bounties select-winner u1 'SP1ARTIST...)
```

### Example 2: Art Design Contest
```bash
# Fan creates art bounty
(contract-call? .Immersive-Fan-Bounties create-bounty 
    "Logo Design" 
    "Design a futuristic logo for my NFT collection" 
    u2000000 
    u1500)

# Multiple artists can submit (each gets unique submission ID)
# Winner gets the full 2 STX reward
```

## 🛠️ Development

### Testing
```bash
clarinet test
```

### Deploy
```bash
clarinet deploy --testnet
```

## 📊 Contract Stats

- **Total Bounties**: Query with `get-total-bounties`
- **Total Submissions**: Query with `get-total-submissions`  
- **Contract Balance**: Query with `get-contract-balance`

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🌟 Roadmap

- [ ] Multi-token support (beyond STX)
- [ ] Voting mechanisms for winner selection
- [ ] Reputation system for creators
- [ ] Categories and tags for bounties
- [ ] Mobile-friendly interface

---

Built with ❤️ on [Stacks](https://stacks.co) | Empowering creators through decentralized bounties 🚀
