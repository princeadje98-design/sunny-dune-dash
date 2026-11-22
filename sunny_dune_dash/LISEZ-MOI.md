# Fabriquer l'app sans rien installer (avec GitHub)

1. Crée un compte gratuit sur github.com.
2. Clique sur "+" puis "New repository". Nom : sunny-dune-dash. Clique "Create repository".
3. Clique sur "uploading an existing file". Glisse TOUT le contenu du dossier (lib, tools, pubspec.yaml...).
   Clique "Commit changes".
4. Clique "Add file" > "Create new file". Dans le nom, tape exactement :
   .github/workflows/build.yml
   Colle le contenu du fichier build.yml fourni. Clique "Commit changes".
5. Onglet "Actions" : la construction démarre (10 min). Quand c'est vert, clique dessus,
   en bas "Artifacts" > télécharge sunny-dune-dash-apk.
6. Dézippe : sunny-TEST.apk (à installer sur ton téléphone pour tester).
