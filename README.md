```zsh
helm repo add runatlantis https://runatlantis.github.io/helm-charts

helm repo update

helm inspect values runatlantis/atlantis > values.yaml
```
