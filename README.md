# ✨ So you want to run an audit

This `README.md` contains a set of checklists for our audit collaboration.

Your audit will use two repos: 
- **an _audit_ repo** (this one), which is used for scoping your audit and for providing information to wardens
- **a _findings_ repo**, where issues are submitted (shared with you after the audit) 

Ultimately, when we launch the audit, this repo will be made public and will contain the smart contracts to be reviewed and all the information needed for audit participants. The findings repo will be made public after the audit report is published and your team has mitigated the identified issues.

Some of the checklists in this doc are for **C4 (🐺)** and some of them are for **you as the audit sponsor (⭐️)**.

---

# Audit setup

## 🐺 C4: Set up repos
- [ ] Create a new private repo named `YYYY-MM-sponsorname` using this repo as a template.
- [ ] Rename this repo to reflect audit date (if applicable)
- [ ] Rename audit H1 below
- [ ] Update pot sizes
  - [ ] Remove the "Bot race findings opt out" section if there's no bot race.
- [ ] Fill in start and end times in audit bullets below
- [ ] Add link to submission form in audit details below
- [ ] Add the information from the scoping form to the "Scoping Details" section at the bottom of this readme.
- [ ] Add matching info to the Code4rena site
- [ ] Add sponsor to this private repo with 'maintain' level access.
- [ ] Send the sponsor contact the url for this repo to follow the instructions below and add contracts here. 
- [ ] Delete this checklist.

# Repo setup

## ⭐️ Sponsor: Add code to this repo

- [ ] Create a PR to this repo with the below changes:
- [ ] Confirm that this repo is a self-contained repository with working commands that will build (at least) all in-scope contracts, and commands that will run tests producing gas reports for the relevant contracts.
- [ ] Please have final versions of contracts and documentation added/updated in this repo **no less than 48 business hours prior to audit start time.**
- [ ] Be prepared for a 🚨code freeze🚨 for the duration of the audit — important because it establishes a level playing field. We want to ensure everyone's looking at the same code, no matter when they look during the audit. (Note: this includes your own repo, since a PR can leak alpha to our wardens!)

## ⭐️ Sponsor: Repo checklist

- [ ] Modify the [Overview](#overview) section of this `README.md` file. Describe how your code is supposed to work with links to any relevent documentation and any other criteria/details that the auditors should keep in mind when reviewing. (Here are two well-constructed examples: [Ajna Protocol](https://github.com/code-423n4/2023-05-ajna) and [Maia DAO Ecosystem](https://github.com/code-423n4/2023-05-maia))
- [ ] Review the Gas award pool amount, if applicable. This can be adjusted up or down, based on your preference - just flag it for Code4rena staff so we can update the pool totals across all comms channels.
- [ ] Optional: pre-record a high-level overview of your protocol (not just specific smart contract functions). This saves wardens a lot of time wading through documentation.
- [ ] [This checklist in Notion](https://code4rena.notion.site/Key-info-for-Code4rena-sponsors-f60764c4c4574bbf8e7a6dbd72cc49b4#0cafa01e6201462e9f78677a39e09746) provides some best practices for Code4rena audit repos.

## ⭐️ Sponsor: Final touches
- [ ] Review and confirm the pull request created by the Scout (technical reviewer) who was assigned to your contest. *Note: any files not listed as "in scope" will be considered out of scope for the purposes of judging, even if the file will be part of the deployed contracts.*
- [ ] Check that images and other files used in this README have been uploaded to the repo as a file and then linked in the README using absolute path (e.g. `https://github.com/code-423n4/yourrepo-url/filepath.png`)
- [ ] Ensure that *all* links and image/file paths in this README use absolute paths, not relative paths
- [ ] Check that all README information is in markdown format (HTML does not render on Code4rena.com)
- [ ] Delete this checklist and all text above the line below when you're ready.

---

# IQ AI audit details
- Total Prize Pool: $35,000 in USDC
  - HM awards: $23,900 in USDC
  - QA awards: $1,000 in USDC
  - Judge awards: $2,800 in USDC
  - Validator awards: $1,800 in USDC 
  - Scout awards: $500 in USDC
  - Mitigation Review: $5,000 USDC
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts January 29, 2025 20:00 UTC
- Ends February 7, 2025 20:00 UTC

**Note re: risk level upgrades/downgrades**

Two important notes about judging phase risk adjustments: 
- High- or Medium-risk submissions downgraded to Low-risk (QA) will be ineligible for awards.
- Upgrading a Low-risk finding from a QA report to a Medium- or High-risk finding is not supported.

As such, wardens are encouraged to select the appropriate risk level carefully during the submission phase.

## Automated Findings / Publicly Known Issues

The 4naly3er report can be found [here](https://github.com/code-423n4/2025-01-iq-ai/blob/main/4naly3er-report.md).



_Note for C4 wardens: Anything included in this `Automated Findings / Publicly Known Issues` section is considered a publicly known issue and is ineligible for awards._
## 🐺 C4: Begin Gist paste here (and delete this line)





# Scope

*See [scope.txt](https://github.com/code-423n4/2025-01-iq-ai/blob/main/scope.txt)*

### Files in scope


| File   | Logic Contracts | Interfaces | nSLOC | Purpose | Libraries used |
| ------ | --------------- | ---------- | ----- | -----   | ------------ |
| /src/AIToken.sol | 1| **** | 38 | |@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol<br>@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol<br>@openzeppelin/contracts/utils/Nonces.sol<br>@openzeppelin/contracts/utils/types/Time.sol|
| /src/Agent.sol | 1| **** | 63 | |@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol<br>@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/proxy/Proxy.sol|
| /src/AgentFactory.sol | 1| **** | 217 | |@openzeppelin/contracts/interfaces/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/access/Ownable.sol<br>@openzeppelin/contracts/access/Ownable2Step.sol|
| /src/AgentRouter.sol | 1| **** | 100 | |@openzeppelin/contracts/interfaces/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol<br>dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol|
| /src/BootstrapPool.sol | 1| **** | 137 | |@openzeppelin/contracts/interfaces/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>@openzeppelin/contracts/utils/ReentrancyGuard.sol|
| /src/LiquidityManager.sol | 1| **** | 146 | |@openzeppelin/contracts/interfaces/IERC20.sol<br>@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol<br>dev-fraxswap/src/contracts/core/interfaces/IFraxswapPair.sol<br>dev-fraxswap/src/contracts/core/interfaces/IFraxswapFactory.sol<br>dev-fraxswap/src/contracts/core/libraries/Math.sol|
| /src/TokenGovernor.sol | 1| **** | 77 | |@openzeppelin/contracts/governance/Governor.sol<br>@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol<br>@openzeppelin/contracts/governance/extensions/GovernorVotes.sol<br>@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol<br>@openzeppelin/contracts/governance/utils/IVotes.sol<br>@openzeppelin/contracts/utils/types/Time.sol|
| **Totals** | **7** | **** | **778** | | |

### Files out of scope

*See [out_of_scope.txt](https://github.com/code-423n4/2025-01-iq-ai/blob/main/out_of_scope.txt)*

| File         |
| ------------ |
| ./script/Base.s.sol |
| ./script/Deploy.s.sol |
| ./src/interface/IBAMM.sol |
| ./src/interface/IBAMMFactory.sol |
| ./test/AITokenTest.sol |
| ./test/AgentFactoryTest.sol |
| ./test/AgentRouterTest.sol |
| ./test/AgentTest.sol |
| ./test/BootstrapPoolTest.sol |
| ./test/Helpers/SigUtils.sol |
| ./test/MoveLiquidityTest.sol |
| ./test/ProxyTest.sol |
| ./test/TokenGovernorTest.sol |
| Totals: 13 |

