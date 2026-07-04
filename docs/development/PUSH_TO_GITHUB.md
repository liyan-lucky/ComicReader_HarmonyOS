# 推送 App 主仓库

目标仓库：

```text
https://github.com/liyan-lucky/ComicReader_HarmonyOS.git
```

执行：

```bash
cd ComicReader_HarmonyOS_app_repo
git init
git add .
git commit -m "initial HarmonyOS comic reader app"
git branch -M main
git remote add origin https://github.com/liyan-lucky/ComicReader_HarmonyOS.git
git push -u origin main
```

如果远程仓库已经有 README 初始化提交，执行：

```bash
git pull origin main --allow-unrelated-histories --no-rebase
git push -u origin main
```

App 默认规则更新地址：

```text
https://raw.githubusercontent.com/liyan-lucky/ComicReader_Rules/main/generated/index.json
```
