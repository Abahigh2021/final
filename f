# SPR100 Final Test
 
 *Course:* SPR100 - Introduction to Computer Systems and Security  
 *Duration:* 90 minutes  
 *Coverage:* Labs 04, 05, 06  
 *Form:* Semi-open-book (see Rules)  
 *Weight:* 30% of final grade  
 *Total Marks:* 30 marks
 
 ---
 
 ## Purpose
 
 The final test validates your mastery of the Lab 04–06 skillset: Linux file permissions and ACLs, user-level persistence controls, and live network traffic inspection with tshark. Complete the steps independently to demonstrate practical fluency.
 
 ---
 
 ## Rules (Semi‑Open‑Book)
 
 - Perform all work on the designated security lab computer. Personal laptops are not permitted.
 - You may reference: textbooks/manuals, your own lab notes and submissions, the course GitHub repository, and VMs already on your SSD.
 - You may NOT use: general Internet searches (other than GitHub), AI assistants, or communicate with classmates.
 - *Academic Integrity:* Any cheating, plagiarism, or unauthorized collaboration results in immediate failure and an academic integrity investigation.
 
 ---
 
 ## Question Policy during the Test
 
 - No task-specific questions will be answered. Examples of disallowed questions:
   - “Am I supposed to do XXXXX in Task YYY?”
   - “How do I copy/move files between the VM and host?”
   - “Is this the right answer or format for the sheet?”
   - “This script/errors out, what should I fix?”
 - If your lab computer malfunctions, raise your hand to request a different station. No technical troubleshooting will be provided.
 
 ---
 
 ## What You Will Submit
 
 Create a folder named final at the root of your SPR100_Labs repository. Copy the answer sheet template, complete it, and include any artifacts requested in the tasks:
 
 
 SPR100_Labs/
 ├── Lab04/
 ├── Lab05/
 ├── Lab06/
 └── final/
     ├── final_exam_answer_sheet.md
     ├── task1/
     ├── task2/
     └── task3/
 
 
 - Use Final_Test/final_exam_answer_sheet_template.md as the starting point.  
 - Include any scripts, logs, or capture files requested in their respective task subfolders.
 
 ---
 
 ## How to Submit (with REQUIRED finalization command)
 
 From your SPR100_Labs folder:
 
 bash
 # REQUIRED finalization command
 
 # Linux / Ubuntu / Matrix shell:
 git commit --allow-empty -m "Final" && git commit --allow-empty -m "Completed" && git push
 
 # Windows PowerShell (Windows VM):
 git commit --allow-empty -m "Final" ; git commit --allow-empty -m "Completed" ; git push
 
 
 - If you skip the finalization command, the automated grading scripts cannot detect your submission and marks will be deducted.
 
 ---
 
 ## Test Tasks
 
 Complete every task and record the requested evidence in final_exam_answer_sheet.md.  
 ⚠️ *Replace every placeholder [like this] with your real answer and remove the brackets.* Any leftover brackets will be treated as blank answers.
 
 You must use the helper scripts provided in Final_Test/ when a task references them:
 
 - task_acl_token.py (Task 1 token)
 - task_watch_token.py (Task 2 token)
 - task_network.py (Task 3 token + HTTPS traffic)
 
Make the scripts executable if necessary (chmod +x scriptname). Run them with python3.

Each helper emits a verification token named TASK?-TOKEN. Copy the string exactly
into your answer sheet so instructors can decode and verify your work.
 
 ---
 
### Task 1: Vault Custodian (10 marks)

*Scenario:* The Systems Guild needs a verifiable vault log that enforces least privilege using Unix permissions and ACLs.

*Environment:* Ubuntu VM.

*Kick-off steps (follow exactly before continuing on your own):*
1. Prepare workspace:
   bash
   mkdir -p ~/SPR100_Labs/final/task1
   cd ~/SPR100_Labs/final/task1
   
2. Ensure the ACL tooling is present from previous labs, but if not, install it:
   bash
   sudo apt install -y acl
   
3. Create the auditor account if it does not already exist:
   bash
   sudo adduser auditor --disabled-password --gecos "" || true
   

*Your objectives (no more step-by-step hints):*
- Construct vault.log so that the first line records an ISO-8601 UTC timestamp and the hostname, then apply base permissions that enforce rw-r----- for your user and primary group.
- Using Lab 04 knowledge, grant the auditor user read-only access via POSIX ACL without changing the base mode bits. Ensure the mask reflects the final effective permissions.
- Devise and document the commands you run to prove auditor can read the file but cannot append to it.
- Capture the evidence required for the answer sheet (ls -l, stat, getfacl lines, etc.).
- When the file state is correct, run the verification helper:
  bash
  python3 Final_Test/task_acl_token.py ~/SPR100_Labs/final/task1/vault.log [YourStudentNumber]
  
  The script emits a verification token (TASK1-TOKEN) that you must paste into the answer sheet. Without the token, you will not get marks for this task.

*Answer sheet requirements for Task 1:*
- Hostname and current username used for the task
- Full ls -l vault.log line
- Output of stat --format '%U|%G|%a|%s' vault.log
- getfacl line for user:auditor and the mask line
- Result of sudo -u auditor cat ... (first line only)
- TASK1-TOKEN line from task_acl_token.py
 
 ---
 
### Task 2: Sentinel Service (10 marks)

*Scenario:* Configure a benign user-level persistence mechanism, prove it runs, and capture reliable evidence for incident responders.

*Environment:* Ubuntu VM.

*Kick-off steps:*
1. Create the workspace:
   bash
   mkdir -p ~/SPR100_Labs/final/task2
   cd ~/SPR100_Labs/final/task2
   
2. Start the watcher script. We give you the header; finish the behavior based on Lab 05 ideas (include timestamps and host data in each line):
   bash
   cat <<'EOF' > watcher.sh
   #!/usr/bin/env bash
   LOG="$HOME/SPR100_Labs/final/task2/watchdog.log"
   # TODO: Add commands that append a meaningful line to "$LOG"
   EOF
   chmod 700 watcher.sh
   
3. Create the user service file with the basic structure (fill in the TODO later):
   bash
   [Unit]
   Description=SPR100 final watch logger

   [Service]
   Type=oneshot
   # TODO: Add what you need to add after this line

   
   # Do not add anything after this line

   [Install]
   WantedBy=default.target

   

*Your objectives (design the rest yourself):*
- Update watcher.sh so every execution appends a single line containing a UTC ISO timestamp, hostname, and a short status tag.
- Modify the provided final-watch.service so it runs watcher.sh once per invocation and automatically starts each time you log in (Lab 05 reference: user services + systemctl --user). Remove the placeholder ExecStart=/bin/true once your command is correct.
- Trigger the service multiple times so watchdog.log contains at least two distinct entries you can cite in your evidence.
- Add an @reboot cron entry for redundancy (Lab 05 cron section). Document the exact line you install.
- Capture the same categories of evidence listed in the answer sheet (ls -l watcher.sh, service file contents, log tail, systemctl --user status, latest journal entry, crontab -l output).
- When satisfied, run the verification helper:
  bash
  python3 Final_Test/task_watch_token.py ~/SPR100_Labs/final/task2/watchdog.log [YourStudentNumber]
  
  Record the resulting TASK2-TOKEN string in your answer sheet so instructors can validate the log contents.

*Answer sheet requirements for Task 2:*
- ls -l watcher.sh line
- Contents of final-watch.service
- Last two lines of watchdog.log
- Active: line from systemctl --user status final-watch.service
- Most recent journal entry (one line) showing the service run
- Exact @reboot line from crontab -l
- TASK2-TOKEN line from task_watch_token.py
 
 ---
 
 ### Task 3: Traffic Examiner (10 marks)
 
 *Scenario:* Capture a controlled HTTPS session, then use tshark to extract TLS metadata.
 
 *Environment:* Ubuntu VM with tshark installed.
 
 1. Prepare workspace:
    bash
    mkdir -p ~/SPR100_Labs/final/task3
    cd ~/SPR100_Labs/final/task3
    
 2. Identify your active interface (tshark -D). Pick the interface that routes to the Internet (e.g., eth0, ens33).
 3. Start a capture for 15 seconds, and save the capture to a file named final_capture.pcapng.  
4. While the capture runs, execute the network task script in a separate terminal:
    bash
    python3 Final_Test/task_network.py --student-number [YourStudentNumber]
    
5. Wait for the capture to finish.  
6. Analyze the capture using tshark or Wireshark.
7. From the capture results, determine the destination host, the protocol(s) in use, and describe what network activity occurred during the script run. Your explanation must reference evidence from the packets you captured.
8. Record file metadata for grading:
   bash
   ls -l final_capture.pcapng
   
 
*Answer sheet requirements for Task 3:*
- Interface name used for capture
- frame.number, ip.dst, tls.handshake.extensions_server_name, and tls.handshake.version from the first TLS ClientHello
- Interpreted TLS version (e.g., 0x0303 = TLS 1.2)
- io,stat line that shows TLS counts
- Destination host/IP, protocol(s), and a brief description of the observed activity — all derived from your packet capture
- ls -l final_capture.pcapng line
- TASK3-TOKEN line from task_network.py
 
 Store final_capture.pcapng (and any supporting CSVs you create) inside ~/SPR100_Labs/final/task3/.
 
 ---
 
### Task B (Bonus) — Firewall Sentinel (5 marks)

*Eligibility:* You must complete Tasks 1–3 before attempting Task B. Bonus marks are only awarded if all mandatory tasks are finished and submitted.

*Scenario:* After you identify the destination host(s) in Task 3, the Systems Guild wants proof that you can enforce a precise outbound firewall policy using ufw (Lab 07 skill). Only the websites contacted by the Task 3 Python script should be blocked; all other web traffic must remain unaffected.

*Environment:* Ubuntu VM with ufw available.

1. For destination host observed in Task 3, add an outbound ufw rule that blocks traffic to that destination. Do *not* block other unrelated sites.
   bash
   sudo ufw deny out to [IP_ADDRESS] proto tcp
   
3. Verify the block by running:
   - python3 Final_Test/task_network.py --student-number [YourStudentNumber]
   - A manual command that reaches a different site to prove normal traffic still succeeds.
4. Capture evidence:
   bash
   sudo ufw status numbered
   
   - Show the command output from the blocked script run (the connection attempt should fail).
   - Show the successful access to an unrelated site.

*Answer sheet requirements for Task B (Bonus, 5 marks):*
- List of domains/IPs you blocked (derived from your Task 3 capture)
- Commands used to add the ufw rules
- sudo ufw status numbered output (trimmed to relevant entries)
- Evidence showing the Task 3 script (or equivalent curl) is blocked
- Evidence showing another unrelated website still works

---

 *Good luck! Work methodically, verify each step, and keep your documentation precise.*
