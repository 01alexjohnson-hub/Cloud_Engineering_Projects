# Git Push Commands

```bash
cd ~/Desktop/Cloud\ Engineer\ Projects/Cloud\ Engineer

rm -rf .git

echo '.DS_Store' > .gitignore
git init
git branch -m main
git add .
git commit -m "feat: FedRAMP-ready AWS landing zone v1.0.0 — 77 resources, 17 NIST 800-53 controls"
git tag -a v1.0.0 -m "First release: 77 Terraform resources, 7 modules, 44% NIST 800-53 score"

git remote add origin https://01alexjohnson-hub:YOUR_TOKEN@github.com/01alexjohnson-hub/Cloud_Engineering_Projects.git
git push -u origin main
git push origin v1.0.0
```
