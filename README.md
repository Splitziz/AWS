# AWS

Cet exercice a pour objectif d'apprendre comment utiliser Amazon Web Services.

## Pré-requis

Pour faire tourner ce projet vous avez besoin de :
- Terraform ^0.11.14
- Packer 1.4.1
- Un compte AWS

## Plan de reprise d'activité

Suivre les étapes suivantes après la création du compte AWS :

- Se placer sur la région de Londres (eu-west-2)
- Dérouler la liste des services puis cliquer sur le service `stockage : S3`
- Cliquer sur créer un compartiment
- Donner le nom de `mdssplitziz` au compartiment puis vérifier qu'on est bien sur la région UE (Londres) puis cliquer sur suivant
- Vérifier que rien ne soit coché, puis cocher dans la partie chiffrement par défaut, cocher : `Chiffrer automatiquement les objets lorsqu'ils sont stockés dans S3` puis cocher AES-256 dans la section qui apparait, puis cliquer sur suivant
- Cocher `Bloquer tout l'accès public` puis cliquer sur suivant
- Vérifier qu'il n'y a aucune erreur puis cliquer sur `Créer un compartiment`

##

- Dérouler ensuite la liste des services puis cliquer sur le service `Sécurité, Identité et Conformité : IAM`
- Dans le menu latéral, cliquer sur `Utilisateurs` puis cliquer ensuite sur `Ajouter un utilisateur`
- Créer l'utilisateur `Splitziz` puis cocher `Accès par programmation` et décocher le reste, cliquer sur suivant
- Sur cette page, cliquer sur `Attacher directement les stratégies existantes` puis cocher la ligne `AdministratorAccess`, cliquer sur suivant.
- Il n'y a pas besoin d'ajouter des balises, cliquer sur suivant
- Vérifier qu'il n'y a aucune erreur puis cliquer sur `Créer un utilisateur`
- Cliquer sur `Téléchargez .csv` puis enregistrer le fichier à la racine du projet, puis cliquer sur fermer

## Application

- Tout d'abord, créer une clé ssh dans le dossier `~/.ssh/` puis l'appeler `packer`
- Ensuite créer un fichier .env à la racine du projet.
- Le remplir avec les clés dans le fichier csv : exemple `export AWS_ACCESS_KEY=my_aws_access_key` et `export AWS_SECRET_KEY=my_aws_secret_key`
- Ouvrir une console, se placer à la racine du projet puis taper `source .env`, ce qui va mettre les clés d'accès AWS dans les variables d'environnement pour terraform
- Ensuite lancer la commande `packer build -var 'aws_access_key=YOUR ACCESS KEY' -var 'aws_secret_key=YOUR SECRET KEY' packer.json` en remplacer les valeurs des clés par les clés dans le csv.
- Patienter le temps que l'image se build sur AWS.
- Se placer ensuite dans le dossier `live/eu-west-2/database` puis taper `terraform init`
- Se replacer dans le dossier `live/eu-west-2/bastion`, taper `terraform init`, `terraform apply` et attendre la fin du lancement
- Une fois le lancement achevé, se placer à nouveau dans le dossier `live/eu-west-2/database` puis taper `terraform apply`

Votre application est enfin lancée.
