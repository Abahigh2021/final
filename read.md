# SPR100 Final Test — Answer Sheet

> ⚠️ Replace every `[placeholder]` with your real answer and delete the brackets.

## Student Information
- **Full Name:** [First Last]
- **Seneca Username:** [myseneca]
- **Student Number:** [123456789]
- **Security Lab Computer #:** [e.g., PC-07]

## Submission Checklist
- [ ] `final_exam_answer_sheet.md` saved in `SPR100_Labs/final/`
- [ ] `task1/`, `task2/`, `task3/` folders added with required artifacts
- [ ] Final commit pushed with the REQUIRED finalization command

---

## Task 1 — Vault Custodian

| Item | Your Evidence |
| --- | --- |
| Hostname | `[Fill in your hostname]` |
| Username used | `[Fill in your username]` |
| `ls -l vault.log` | `[Fill in here]` |
| `stat --format ... vault.log` | `[owner/group/mode/size]` |
| `getfacl` user line | `[user:auditor:...]` |
| `getfacl` mask line | `[mask:...]` |
| `sudo -u auditor cat ...` (first line) | `[line text]` |
| `TASK1-TOKEN` | `[TASK1-TOKEN:...]` |

Notes (optional, max 2 sentences):  
`[brief observation]`

---

## Task 2 — Sentinel Service

- `ls -l watcher.sh`: `[Fill in here]`
- `final-watch.service` contents:
  ```
  [unit file text]
  ```
- Last two `watchdog.log` lines:
  ```
  [Fill in line -2 here]
  [Fill in line -1 here]
  ```
- `Active:` line from `systemctl --user status final-watch.service`: `[Active: ...]`
- Latest journal entry (single line): `[timestamp unit message]`
- `@reboot` cron line: `[@reboot bash ...]`
- `TASK2-TOKEN`: `[TASK2-TOKEN:...]`

Mitigation reminder after grading (do NOT do during test): `[describe how you will remove hooks later]`

---

## Task 3 — Traffic Examiner

- Capture interface: `[Fill in here. e.g., eth0]`
- TLS ClientHello fields (`frame/ip.dst/SNI/version`): `[Fill in here. e.g., frame #:IP:SNI:0xXXXX]`
- TLS version interpreted: `[Fill in here. e.g., TLS 1.2]`
- `io,stat` TLS/HTTP line: `[Fill in here.]`
- Host/IP + protocol(s) from capture evidence: `[Fill in here. describe based on packets]`
- `ls -l final_capture.pcapng`: `[Fill in here.]`
- `TASK3-TOKEN`: `[TASK3-TOKEN:...]`

Optional Notes (max 2 sentences to describe what the python program `task_network.py` does):  
`[brief observation]`

---

## Task B — Firewall Sentinel (Bonus)

- Domains/IPs blocked (from Task 3 analysis): `[Fill in here]`
- Commands used to add `ufw` rules:
  ```
  [Fill in here]
  ```
- `sudo ufw status numbered` (trimmed output):
  ```
  [Fill in here]
  ```
- Evidence that Task 3 script is blocked:
  ```
  [Error/output snippet]
  ```
- Evidence that other sites still work:
  ```
  [Successful command/output]
  ```

---

## Final Confirmation
- I confirm I followed all rules and performed the work independently. `[Yes/No]`
- Timestamp of final push (`date -u`): `[YYYY-MM-DDTHH:MM:SSZ]`

**Signature (type your name):** `[Your Name]`

