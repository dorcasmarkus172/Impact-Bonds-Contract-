# 📊 Impact Bonds Contract

🎯 **A Clarity smart contract demonstrating outcome-based financing through Social Impact Bonds**

## 🌟 Overview

This smart contract implements a Social Impact Bond system where investors provide upfront capital for social programs, and returns are paid based on measurable outcomes. It's a powerful demonstration of how blockchain technology can enable innovative financing mechanisms for social good.

## 🚀 Key Features

- 💰 **Bond Creation**: Issuers can create bonds with specific funding targets and outcome goals
- 🤝 **Investment Management**: Investors can fund bonds and track their contributions  
- 📈 **Outcome Reporting**: Transparent reporting of actual vs. target outcomes
- 💸 **Payout Calculation**: Automatic calculation of returns based on outcome success rates
- 🔒 **Secure Claims**: Protected withdrawal system for investor payouts

## 🏗️ How It Works

### 1. 📋 Bond Creation
Bond issuers create impact bonds with:
- Target funding amount
- Outcome goals (measurable targets)
- Maturity period
- Payout rates (100-200% based on success)

### 2. 💵 Investment Phase
Investors can:
- Invest STX tokens in active bonds
- Track investment amounts
- Monitor bond progress

### 3. 📊 Outcome Measurement
After maturity:
- Issuers report actual outcomes achieved
- System calculates success rates
- Payout amounts are determined automatically

### 4. 💎 Claim Rewards
Investors can:
- Claim payouts based on outcome success
- Receive returns proportional to impact achieved
- Access funds through secure withdrawal

## 🛠️ Usage Instructions

### Deploy Contract
```bash
clarinet deploy
```

### Create an Impact Bond
```clarity
(contract-call? .impact-bonds-contract create-bond 
  u1000000    ;; Target amount (1M microSTX)
  u100        ;; Target outcome (e.g., 100 beneficiaries served)
  u1440       ;; Maturity in blocks (~10 days)
  u150)       ;; Payout rate (150% max return)
```

### Invest in a Bond
```clarity
(contract-call? .impact-bonds-contract invest 
  u1          ;; Bond ID
  u100000)    ;; Investment amount (100k microSTX)
```

### Report Outcomes (Issuer Only)
```clarity
(contract-call? .impact-bonds-contract report-outcome 
  u1          ;; Bond ID
  u85)        ;; Actual outcome achieved
```

### Claim Payout
```clarity
(contract-call? .impact-bonds-contract claim-payout u1)
```

## 📖 Read-Only Functions

### Check Bond Details
```clarity
(contract-call? .impact-bonds-contract get-bond u1)
```

### View Investment Status
```clarity
(contract-call? .impact-bonds-contract get-investment u1 'SP1HTBVD3S...)
```

### Calculate Potential Payout
```clarity
(contract-call? .impact-bonds-contract calculate-payout u1 'SP1HTBVD3S...)
```

### Get Bond Status Summary
```clarity
(contract-call? .impact-bonds-contract get-bond-status u1)
```

## 🎯 Example Scenarios

### 🏥 Healthcare Impact Bond
- **Target**: Reduce hospital readmissions by 20%
- **Funding**: $500k from impact investors
- **Outcome**: 18% reduction achieved
- **Payout**: 90% of maximum return (135% of investment)

### 🎓 Education Impact Bond  
- **Target**: Improve graduation rates by 15%
- **Funding**: $1M from foundations
- **Outcome**: 16% improvement achieved  
- **Payout**: 106% of maximum return (159% of investment)

## ⚡ Error Codes

| Code | Description |
|------|-------------|
| `u1` | Unauthorized access |
| `u2` | Bond not found |
| `u3` | Invalid amount |
| `u4` | Bond closed |
| `u5` | Insufficient funds |
| `u6` | Already invested |
| `u7` | Not an investor |
| `u8` | Outcome already reported |
| `u9` | Bond not mature |
| `u10` | Invalid outcome |

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

## 🌍 Real-World Applications

- **Social Services**: Homelessness reduction programs
- **Healthcare**: Preventive care initiatives  
- **Education**: Literacy and graduation programs
- **Environment**: Carbon reduction projects
- **Employment**: Job training and placement programs

## 🔐 Security Features

- ✅ Owner-only functions for sensitive operations
- ✅ Input validation on all parameters
- ✅ Reentrancy protection
- ✅ Overflow/underflow protection
- ✅ Access control for critical functions

## 🤝 Contributing

This is an educational MVP demonstrating outcome-based financing concepts. Feel free to fork, extend, and improve the implementation!

## 📜 License

MIT License - Build amazing things! 🚀

---

*Built with ❤️ using Clarity and Clarinet*
