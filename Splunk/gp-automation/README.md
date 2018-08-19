Ansible Roles/Plays to automate pulling from a git repo, and updating deployment server with apps whose branches have changed.

## Approach

An ansible playbook (Manage-Repo.yml) is called, which uses two ansible roles (update_repos, update_deployment_apps).  The latter is only called should the former detect new changes to one of the branches of one of the repos it's watching.

The admin can modify the remote URL/user of the repos, as well as add additional repos and branches to monitor.  Each in turn will create a separate Splunk app that will be deployed to servers of group splunk_ds (Deployment Servers). 

The ansible host pulls down the latest changes by branch, building out separate app directories for each.  When one is updated, Ansible will rsync this config (without .git directory and anything else not needed) to the deployment servers etc/deployment-apps directory.  "Splunk reload deploy-server" is run when changes to the app are detected, allowing clients checking in to pull down the new app version.

In order to trigger changes to a branch for testing, I wrote a simple shell script to automate a simple feature addition to the dev branch of one of the apps.  This would add a log entry to a file and push the change to the remote dev branch.  The next time the playbook was called it would see a change and execute the automation.  These scripts aren't included in the repo, but look like:

cd gp-app-1
git checkout -b auto-update-branch
echo "New Commit" >> auto-update.log
git add .
git commit -m "Auto-commit to trigger automation"
git checkout dev
git merge auto-update-branch
git branch -d auto-update-branch
git push origin dev:dev


## Change in repo leads to pull down locally, triggering app push to deployment server(s)
![alt text](images/Beta-Branch-New-Commit-2-DSs.png)

## Rerun shows all green, no changes, push to DS doesn't happen
![alt text](images/Play-Run-Update-Apps-No-Change.png)

## Dashboard utilizing internal and audit data to track app deployments to clients
![alt text](images/App-Status-Dashboard.png)


### Improvements on initial request

1. Not just one repo is maintained, but multiple with the same structure.  They can be pulled in to automation by just adding repo name to list variable.

2. Added dashboard to view app deployment status


### Ways to improve on current design

1. Current version considers all deployment servers equal.  Every DS will receive every branch of every app.  With multiple clients, it's possible not all will receive every app.  Client inventories should be created, and all DSs that receive a group of apps should be joined via group:children hierarchy in inventory.  Each group would maintain its own repos/branches lists.

2. A scheduler such as the one built into Ansible Tower / AWX should be used to maintain deployments.  It's possible you wouldn't want to deploy certain apps immediately should they affect a client's access to Splunk.  

3. Dynamic inventory should be utilized if possible.  Inventory maintenance is the most challenging piece of this and should not be done manually by Ansible developers.  If using AWS or some CMDB, ansible should dynamically pull the latest servers in need of apps from the centrally managed solution.

4. Depending on app contents, tests could be written to validate new features.  Post-validation could trigger the merge of dev into beta, and so on.  

5. serverclass.conf should be broken out by app.  If a new repo is added, it should deploy a new serverclass.conf part of a similarly named app to etc/apps on the deployment server.  Variables would need to be maintained indicating which hosts should receive it.  