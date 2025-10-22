apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app-${env}
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: "https://github.com/${repo_org}/${repo_name}.git"
    targetRevision: "main"
    path: ${apps_path}
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true