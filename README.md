# 📘 Intellex – Intellectual Property Rights on the Blockchain

**Intellex** is a Clarity smart contract designed to empower creators and innovators by enabling decentralized **registration**, **management**, and **monetization** of intellectual property (IP) rights. With Intellex, ownership is transparent, licensing is programmable, and royalties are fairly and automatically distributed.

---

## 🔐 Key Features

* **IP Registration**: Creators can register unique intellectual property (IP) items (e.g. content, code, art, trademarks) on-chain, establishing immutable proof of ownership.
* **Licensing Framework**: Supports various license types (exclusive, non-exclusive) with custom terms and usage permissions.
* **Royalty Distribution**: Automated royalty payments to IP owners and collaborators based on predefined splits.
* **Usage Tracking**: Logs authorized license usage and flags unauthorized access attempts.
* **Transfer & Delegation**: Ownership rights can be transferred or delegated to third parties.
* **Dispute Resolution**: Records evidence and handles IP disputes in a transparent way.

---

## 🧱 Contract Components

### 1. **Data Structures**

* `ip-assets`: Map of all registered IP items with metadata and ownership.
* `licenses`: Tracks licenses issued per IP, including terms and recipient.
* `royalties`: Maps payment rules and shares for each licensed asset.

### 2. **Core Functions**

* `(register-ip ...)`: Allows creators to register an IP asset with metadata.
* `(issue-license ...)`: Issues a license to another principal under specific terms.
* `(record-usage ...)`: Logs usage events tied to licensed content.
* `(distribute-royalties ...)`: Distributes payment to IP stakeholders.
* `(transfer-ip ...)`: Transfers ownership of a registered IP to another principal.

---

## ✅ Usage Examples

```clojure
;; Register a new IP asset
(register-ip "Artwork #42" ip-hash "Digital painting by Alice" (list owner collaborator) (list 70 30))

;; Issue a license
(issue-license ip-id licensee-principal "non-exclusive" expiration-block)

;; Record usage event
(record-usage ip-id licensee-principal usage-details)

;; Distribute royalties after license fee payment
(distribute-royalties ip-id license-fee)
```

---

## 🔄 License Model Types

* `exclusive`: One licensee only; others restricted.
* `non-exclusive`: Multiple parties can hold licenses.
* `time-bound`: Expires after a set block height.
* `revocable`: Can be revoked by the owner before expiry.

---

## 🛡 Security & Trust

Intellex ensures:

* **Immutability** of IP records.
* **Tamper-proof licensing** terms.
* **Fair revenue** sharing.
* **Transparent dispute resolution** using on-chain evidence.

---

## 🌍 Vision

Intellex aims to redefine IP rights for the digital age—giving power back to creators, protecting original work, and enabling global innovation without middlemen.

---

## 📜 License

MIT License — open for community use and enhancement.
