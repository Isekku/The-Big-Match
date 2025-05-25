#!/bin/bash

# Variables de connexion (modifie-les si besoin)
DB_NAME="the_big_match"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"

# Exécution des commandes COPY
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -f insert_donnee_fixe.sql

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy utilisateur (nom_genre,type_genre,nom_orientation,nom,prenom,email,numero_tel,mdp_hash,age,taille,couleur_peau,couleur_yeux,corpulence,photo_profil_url,derniere_connexion,bio,isPremium,last_localisation_latitude,last_localisation_longitude) FROM 'CSV/utilisateur.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy genreUtilisateur (idU, nom_genre, type_genre, genre_assigne_naiss, pronom_preferes, transition_sociale, transition_medicale) FROM 'CSV/genre_utilisateur.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy aime (idU1, idU2) FROM 'CSV/aime.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy lieu (nom, adresse, description_lieu) FROM 'CSV/lieu.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy evenement (idL, nom, prix, description_event, date_event) FROM 'CSV/evenement.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy organisateur (idU, idE) FROM 'CSV/organisateur.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

# Import participation.csv en gérant les conflits (doublons)
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_participation (
    idU INT,
    idE INT,
    type_participation VARCHAR(200)
);

\copy temp_participation FROM 'CSV/participation.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO participation (idU, idE, type_participation)
SELECT idU, idE, type_participation FROM temp_participation
ON CONFLICT DO NOTHING;

DROP TABLE temp_participation;
EOF

# Import tagUtilisateur.csv
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_tagUtilisateur (
    idT INT,
    idU INT
);

\copy temp_tagUtilisateur FROM 'CSV/tagUtilisateur.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO tagUtilisateur (idT, idU)
SELECT idT, idU FROM temp_tagUtilisateur
ON CONFLICT DO NOTHING;

DROP TABLE temp_tagUtilisateur;
EOF

# Import tagLieu.csv
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_tagLieu (
    idT INT,
    idL INT
);

\copy temp_tagLieu FROM 'CSV/tagLieu.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO tagLieu (idT, idL)
SELECT idT, idL FROM temp_tagLieu
ON CONFLICT DO NOTHING;

DROP TABLE temp_tagLieu;
EOF

# Import tagEvenement.csv
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_tagEvenement (
    idT INT,
    idE INT
);

\copy temp_tagEvenement FROM 'CSV/tagEvenement.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO tagEvenement (idT, idE)
SELECT idT, idE FROM temp_tagEvenement
ON CONFLICT DO NOTHING;

DROP TABLE temp_tagEvenement;
EOF

# Import reseauExterne.csv
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_reseauExterne (
    idU INT,
    nom_reseau VARCHAR(200),
    pseudo VARCHAR(200)
);

\copy temp_reseauExterne FROM 'CSV/reseauExterne.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

DELETE FROM temp_reseauExterne WHERE nom_reseau = '';

INSERT INTO reseauExterne (idU, nom_reseau, pseudo)
SELECT idU, nom_reseau, pseudo FROM temp_reseauExterne
ON CONFLICT DO NOTHING;

DROP TABLE temp_reseauExterne;
EOF

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy appAchat (idRE, isPremium) FROM 'CSV/appAchat.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy appSocial (idRE, nb_abonne) FROM 'CSV/appSocial.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy appAvis (idRE, genre_pref, prefere) FROM 'CSV/appAvis.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy messageAppSocial (idAS, contenu, date_envoi) FROM 'CSV/messageAppSocial.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy compteSuivi (idAS, pseudo, nb_abonne, type_contenu) FROM 'CSV/compteSuivi.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

# Import evenementSuivi.csv avec gestion des doublons
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_evenementSuivi (
    idAS INT,
    nom_orga VARCHAR(200),
    nom_event VARCHAR(200),
    genre VARCHAR(200),
    nb_abonne INT
);

\copy temp_evenementSuivi FROM 'CSV/evenementSuivi.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO evenementSuivi (idAS, nom_orga, nom_event, genre, nb_abonne)
SELECT * FROM temp_evenementSuivi
ON CONFLICT (nom_orga, nom_event) DO NOTHING;

DROP TABLE temp_evenementSuivi;
EOF

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy evenementPasse (idAS, nom_event, date_event, organisateur, genre) FROM 'CSV/evenementPasse.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

# Import organisateurExterne.csv avec gestion des doublons
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_organisateurExterne (
    nom_orga VARCHAR(200),
    nom_event VARCHAR(200),
    idE INT,
    date_event DATE,
    lien_externe VARCHAR(255)
);

\copy temp_organisateurExterne FROM 'CSV/organisateurExterne.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO organisateurExterne (nom_orga, nom_event, idE, date_event, lien_externe)
SELECT * FROM temp_organisateurExterne
ON CONFLICT (nom_orga, nom_event, idE) DO NOTHING;

DROP TABLE temp_organisateurExterne;
EOF

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy objetAchete (idAAc, genre, prix, date_achat) FROM 'CSV/objetAchete.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy listeSouhait (idAAc, nom_objet, genre_objet) FROM 'CSV/listeSouhait.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy contenu (titre, createur, donnee) FROM 'CSV/contenu.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

# Import appAvisContenu.csv avec gestion des doublons
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_appAvisContenu (
    idAAv INT,
    titre VARCHAR(200),
    createur VARCHAR(200)
);

\copy temp_appAvisContenu FROM 'CSV/appAvisContenu.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO appAvisContenu (idAAv, titre, createur)
SELECT idAAv, titre, createur FROM temp_appAvisContenu
ON CONFLICT (idAAv, titre, createur) DO NOTHING;

DROP TABLE temp_appAvisContenu;
EOF

# Import avis.csv avec gestion des doublons
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_avis (
    idAAv INT,
    titre VARCHAR(200),
    createur VARCHAR(200),
    note INT,
    explication VARCHAR(200)
);

\copy temp_avis FROM 'CSV/avis.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO avis (idAAv, titre, createur, note, explication)
SELECT idAAv, titre, createur, note, explication FROM temp_avis
ON CONFLICT (idAAv, titre, createur) DO NOTHING;

DROP TABLE temp_avis;
EOF

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy souhait (idAAv, nom, genre) FROM 'CSV/souhait.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"