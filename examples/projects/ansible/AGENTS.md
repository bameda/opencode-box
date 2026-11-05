# Ansible project

- Only run playbooks and ad-hoc commands against the test inventory,
  `-i inventories/test`, whose hosts are disposable containers. Never use
  any other inventory, even with `--check`.
- After changing a role or playbook: run `ansible-lint`, then
  `ansible-playbook -i inventories/test <playbook>` twice. The second run
  must report `changed=0`; if not, fix the idempotence before finishing.
- The test hosts have no systemd. When a task manages services, say so
  instead of working around it in the role.
- Never write secrets in plain text. Reference vault variables and tell me
  which ones need to exist; the vault itself stays outside this box.
