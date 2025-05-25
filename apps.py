import psycopg2
import random
import csv

# Connexion à la base de données
conn = psycopg2.connect(
    dbname="the_big_match",
    user="postgres",
    password="ton_mot_de_passe",  # change ici
    host="localhost",
    port="5432"
)
cur = conn.cursor()

# Définition des catégories
apps_avis = {"The Fork", "LetterBox", "Netflix", "Youtube", "Audible", "Foodvisor", "iMDB", "TF1+", "M6", "HBO", "Paramount+"}
apps_social = {"Instagram", "TikTok", "Facebook", "Twitter", "Strava", "Twitch"}
apps_achat = {"Vinted", "KFC", "McDo", "Burger King", "Ticketmaster", "Amazon", "Uber Eats", "Shein", "H&M", "Balenciaga", "Louis Vuitton", "Hermes", "Emporio Armani"}

# Récupération des données de reseauExterne
cur.execute("SELECT idRE, nom_reseau FROM reseauExterne;")
reseaux = cur.fetchall()

# Ouverture des fichiers CSV
with open('CSV/appSocial.csv', 'w', newline='') as social_file, \
     open('CSV/appAvis.csv', 'w', newline='') as avis_file, \
     open('CSV/appAchat.csv', 'w', newline='') as achat_file:

    social_writer = csv.writer(social_file)
    avis_writer = csv.writer(avis_file)
    achat_writer = csv.writer(achat_file)

    # Écriture des headers
    social_writer.writerow(['idRE', 'nb_abonne'])
    avis_writer.writerow(['idRE', 'genre_pref', 'prefere'])
    achat_writer.writerow(['idRE', 'isPremium'])

    # Remplissage
    for idRE, nom_reseau in reseaux:
        if nom_reseau in apps_social:
            nb_abonne = random.randint(10, 50000)
            social_writer.writerow([idRE, nb_abonne])
        elif nom_reseau in apps_avis:
            genre_pref = random.choice(["Série", "Film", "Nourriture", "Livres", "Culture"])
            prefere = random.choice(list(apps_avis))
            avis_writer.writerow([idRE, genre_pref, prefere])
        elif nom_reseau in apps_achat:
            is_premium = random.choice(["true", "false"])
            achat_writer.writerow([idRE, is_premium])

# Fermeture de la connexion
cur.close()
conn.close()
