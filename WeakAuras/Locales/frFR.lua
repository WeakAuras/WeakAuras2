if (GAME_LOCALE or GetLocale()) ~= "frFR" then
  return
end

local L = WeakAuras.L

-- WeakAuras
L[ [=[ Filter formats: 'Name', 'Name-Realm', '-Realm'. 

Supports multiple entries, separated by commas
Can use \ to escape -.]=] ] = "Filtres supportés : 'Pseudo', 'Pseudo-Serveur', '-Serveur'. Supporte les entrées multiples, séparées par des virgules; utiliser \\ pour \"échapper\" à -."
L["%s Overlay Color"] = "%s couleur de la superposition"
L["* Suffix"] = "* Suffixe"
L["/wa help - Show this message"] = "/wa help - Affiche ce message"
L["/wa minimap - Toggle the minimap icon"] = "/wa minimap - Afficher l'icône sur la mini-carte"
L["/wa pprint - Show the results from the most recent profiling"] = "/wa pprint - Affiche les résultats du profilage le plus récent"
L["/wa pstart - Start profiling. Optionally include a duration in seconds after which profiling automatically stops. To profile the next combat/encounter, pass a \"combat\" or \"encounter\" argument."] = "/wa pstart - Démarre le profilage. Vous pouvez inclure une durée en secondes après laquelle le profilage s'arrête automatiquement. Pour établir le profil du prochain combat / contretemps, passez un argument \"combat\" ou \"rencontre\"."
L["/wa pstop - Finish profiling"] = "/wa pstop - Arrêter le profilage"
L["/wa repair - Repair tool"] = "/wa repair - Utilitaire de réparation"
L["|cffeda55fLeft-Click|r to toggle showing the main window."] = "|cffeda55fClic-Gauche|r pour déclencher l'affichage de la fenêtre principale."
L["|cffeda55fMiddle-Click|r to toggle the minimap icon on or off."] = "Clique du milieu pour activer ou désactiver l'icône de la mini-carte."
L["|cffeda55fRight-Click|r to toggle performance profiling window."] = "|cffeda55fClic-Droit|r pour basculer la fenêtre de profilage des performances."
L["|cffeda55fShift-Click|r to pause addon execution."] = "|cffeda55fMaj-Clic|r Pour suspendre l'exécution de l'addon."
L["|cffff0000deprecated|r"] = "|cffff0000obsolète|r"
L["|cFFFF0000Not|r Item Bonus Id Equipped"] = "ID du bonus de l'objet |cFFFF0000non|r équipé"
L["|cFFFF0000Not|r Item Equipped"] = "Objet |cFFFF0000non|r équipé"
L["|cFFFF0000Not|r Player Name/Realm"] = "|cFFFF0000Not|r Nom du joueur / serveur"
L["|cFFFF0000Not|r Spell Known"] = "|cFFFF0000Sort|r non connu"
L[ [=[|cFFFF0000Support for unfiltered COMBAT_LOG_EVENT_UNFILTERED is deprecated|r
COMBAT_LOG_EVENT_UNFILTERED without a filter are disabled as it’s very performance costly.
Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers#events]=] ] = "|cFFFF0000La prise en charge des événements COMBAT_LOG_EVENT_UNFILTERED non filtrés est obsolète|r Les événements COMBAT_LOG_EVENT_UNFILTERED sans filtre sont désactivés, car ils nuisent fortement aux performances. Plus d'informations : https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers#events"
L["|cFFffcc00Extra Options:|r %s"] = "|cFFffcc00Options supplémentaires :|r %s"
L["|cFFffcc00Extra Options:|r None"] = "|cFFffcc00Options supplémentaires :|r aucun"
L[ [=[• |cff00ff00Player|r, |cff00ff00Target|r, |cff00ff00Focus|r, and |cff00ff00Pet|r correspond directly to those individual unitIDs.
• |cff00ff00Specific Unit|r lets you provide a specific valid unitID to watch.
|cffff0000Note|r: The game will not fire events for all valid unitIDs, making some untrackable by this trigger.
• |cffffff00Party|r, |cffffff00Raid|r, |cffffff00Boss|r, |cffffff00Arena|r, and |cffffff00Nameplate|r can match multiple corresponding unitIDs.
• |cffffff00Smart Group|r adjusts to your current group type, matching just the "player" when solo, "party" units (including "player") in a party or "raid" units in a raid.

|cffffff00*|r Yellow Unit settings will create clones for each matching unit while this trigger is providing Dynamic Info to the Aura.]=] ] = "• |cff00ff00Joueur|r, |cff00ff00Cible|r, |cff00ff00Focalisation|r et |cff00ff00Familier|r correspondent directement à ces identifiants d’unité spécifiques. • |cff00ff00Unité spécifique|r vous permet d’indiquer un identifiant d’unité valide à surveiller. |cffff0000Remarque|r : Le jeu ne déclenche pas d’événements pour tous les identifiants d’unité valides, ce qui rend certains non traçables par ce déclencheur. • |cffffff00Groupe|r, |cffffff00Raid|r, |cffffff00Boss|r, |cffffff00Arène|r et |cffffff00Barre de vie|r peuvent correspondre à plusieurs identifiants d’unité associés. • |cffffff00Groupe intelligent|r s’ajuste en fonction de votre type de groupe actuel : il correspond uniquement au \"joueur\" en solo, aux unités du \"groupe\" (y compris le joueur) en groupe, ou aux unités du \"raid\" en raid. |cffffff00*|r Les paramètres d’unité en jaune créeront des clones pour chaque unité correspondante tant que ce déclencheur fournit des informations dynamiques à l’aura."
L["1. Profession 1. Accessory"] = "1. Profession 1. Accessoire"
L["1. Profession 2. Accessory"] = "1. Profession 2. Accessoire"
L["1. Professsion Tool"] = "1. Outil de profession"
L["10 Man Raid"] = "Raid 10 Joueurs"
L["10 Player Raid"] = "Raid à 10 Joueurs"
L["10 Player Raid (Heroic)"] = "Raid à 10 Joueurs (Héroïque)"
L["10 Player Raid (Normal)"] = "Raid à 10 Joueurs (Normal)"
L["2. Profession 1. Accessory"] = "2. Profession 1. Accessoire"
--[[Translation missing --]]
L["2. Profession 2. Accessory"] = "2. Profession 2. Accessory"
--[[Translation missing --]]
L["2. Professsion Tool"] = "2. Professsion Tool"
L["20 Man Raid"] = "Raid 20 Joueurs"
L["20 Player Raid"] = "Raid à 20 joueurs"
L["25 Man Raid"] = "Raid 25 Joueurs"
L["25 Player Raid"] = "Raid à 25 joueurs"
L["25 Player Raid (Heroic)"] = "Raid 25 Joueurs (Héroïque)"
L["25 Player Raid (Normal)"] = "Raid 25 Joueurs (Normal)"
L["40 Man Raid"] = "Raid 40 Personnes"
L["40 Player Raid"] = "Raid 40 Joueurs"
L["5 Man Dungeon"] = "Donjon 5 joueurs"
--[[Translation missing --]]
L[ [=[A detailed overview of your auras and WeakAuras systems
Copy the whole text to Weakaura's Discord if you need assistance.]=] ] = [=[A detailed overview of your auras and WeakAuras systems
Copy the whole text to Weakaura's Discord if you need assistance.]=]
--[[Translation missing --]]
L["A trigger in this aura is set up to track a soft target unit, but you don't have the CVars set up for this to work correctly. Consider either changing the unit tracked, or configuring the Soft Target CVars."] = "A trigger in this aura is set up to track a soft target unit, but you don't have the CVars set up for this to work correctly. Consider either changing the unit tracked, or configuring the Soft Target CVars."
L["Abbreviate"] = "Abréger"
L["AbbreviateLargeNumbers (Blizzard)"] = "AbrégerGrandsNombres (Blizzard)"
L["AbbreviateNumbers (Blizzard)"] = "AbrégerNombres (Blizzard)"
L["Absorb"] = "Absorbe"
--[[Translation missing --]]
L["Absorb and Healing"] = "Absorb and Healing"
--[[Translation missing --]]
L["Absorb Heal Overlay"] = "Absorb Heal Overlay"
--[[Translation missing --]]
L["Absorb Overlay"] = "Absorb Overlay"
L["Absorbed"] = "Absorbé"
L["Action Button Glow"] = "Bouton d'action brillant"
L["Actions"] = "Actions"
L["Active"] = [=[Actif
]=]
L[ [=[Active boss mod addon: |cFFffcc00BigWigs|r

Note: This trigger will use BigWigs or DBM, in that order if both are installed.]=] ] = "Addon de boss actif : |cFFffcc00BigWigs|r Remarque : ce déclencheur utilisera BigWigs ou DBM, dans cet ordre si les deux sont installés."
L[ [=[Active boss mod addon: |cFFffcc00DBM|r

Note: This trigger will use BigWigs or DBM, in that order if both are installed.]=] ] = "Addon de boss actif : |cFFffcc00DBM|r Remarque : ce déclencheur utilisera BigWigs ou DBM, dans cet ordre si les deux sont installés."
L["Add"] = "Ajouter"
L["Add Missing Auras"] = "Ajouter les auras manquantes"
--[[Translation missing --]]
L["Advanced Caster's Target Check"] = "Advanced Caster's Target Check"
L["Affected"] = "Affecté"
L["Affected Unit Count"] = "Nombre d'unités Affectées"
--[[Translation missing --]]
L["Afk"] = "Afk"
L["Aggro"] = "Aggro"
L["Agility"] = "Agilité"
L["Ahn'Qiraj"] = "Ahn'Qiraj"
L["Alert Type"] = "Type d'alerte"
L["Alive"] = "En vie"
L["All"] = "Tous"
L["All children of this aura will also not be loaded, to minimize the chance of further corruption."] = "Tous les éléments enfants de cette aura ne seront également pas chargés, afin de minimiser le risque de corruption supplémentaire."
L["All States table contains a non table at key: '%s'."] = "La table All States contient une valeur non-table à la clé : « %s »."
L["All Triggers"] = "Tous les déclencheurs"
L["Alliance"] = "Alliance"
L["Allow partial matches"] = "Permettre les correspondances partielles"
L["Alpha"] = "Opacité"
L["Alternate Power"] = "Puissance alternative"
L["Always"] = "Toujours"
L["Always active trigger"] = "Déclencheur toujours actif"
L["Always include realm"] = "Toujours inclure le royaume"
L["Always True"] = "Toujours Vrai"
L["Amount"] = "Quantité"
L["Anchoring"] = "Ancrage"
L["And Talent"] = "Et talent"
L["Angle and Radius"] = "Angle et rayon"
L["Animations"] = "Animations"
L["Anticlockwise"] = "Sens anti-horaire"
L["Anub'Rekhan"] = "Anub'Rekhan"
L["Any"] = "N'importe lequel"
L["Any Triggers"] = "Au moins un déclencheur"
L["AOE"] = "AOE"
L["Arcane Resistance"] = "Résistance aux arcanes"
L[ [=[Are you sure you want to run the |cffff0000EXPERIMENTAL|r repair tool?
This will overwrite any changes you have made since the last database upgrade.
Last upgrade: %s]=] ] = "Êtes-vous sûr de vouloir exécuter l'outil de réparation |cffff0000expérimental|r ? Cela écrasera toutes les modifications que vous avez apportées depuis la dernière mise à niveau de la base de données. Dernière mise à jour : %s"
L["Arena"] = "Arène"
L["Armor (%)"] = "Armure (%)"
L["Armor against Target (%)"] = "Armure contre Cible (%)"
L["Armor Rating"] = "Categorie d'armure"
L["Array"] = "Tableau"
L["Ascending"] = "Croissant"
L["Assigned Role"] = "Rôle assigné"
L["Assigned Role Icon"] = "Icône de rôle assigné"
L["Assist"] = "Assister"
--[[Translation missing --]]
L["Assisted Combat Next Cast"] = "Assisted Combat Next Cast"
L["At Least One Enemy"] = "Au moins un ennemi"
L["At missing Value"] = "À la valeur manquante"
L["At Percent"] = "À pourcentage"
L["At Value"] = "À la valeur"
--[[Translation missing --]]
L["At War"] = "At War"
L["Attach to End"] = "Attacher à la Fin"
L["Attach to End, backwards"] = "Attacher à la fin, en arrière"
L["Attach to Point"] = "Attacher au point"
L["Attach to Start"] = "Attacher au Début"
L["Attack Power"] = "Puissance d'attaque"
L["Attackable"] = "Attaquable"
L["Attackable Target"] = "Cible attaquable"
L["Aura"] = "Aura"
L["Aura '%s': %s"] = "Aura '%s' : %s"
L["Aura Applied"] = "Aura appliquée"
L["Aura Applied Dose"] = "Dose de l'aura appliquée"
L["Aura Broken"] = "Aura Cassée"
L["Aura Broken Spell"] = "Sort de l'Aura Cassée"
L["Aura is using deprecated SetDurationInfo"] = "L’aura utilise la fonction obsolète SetDurationInfo"
L["Aura loaded"] = "Aura chargée"
L["Aura Name"] = "Nom de l'aura"
L["Aura Names"] = "Nom des auras"
L["Aura Refresh"] = "Aura rafraichie"
L["Aura Removed"] = "Aura Supprimé"
L["Aura Removed Dose"] = "Aura Supprimé Dose"
L["Aura Stack"] = "Pile d'aura"
L["Aura Type"] = "Type Aura"
L["Aura Version: %s"] = "Version de l’aura : %s"
L["Aura(s) Found"] = "Aura(s) Trouvée(s)"
L["Aura(s) Missing"] = "Aura(s) Manquante"
L["Aura:"] = "Aura:"
L["Auras"] = "Auras"
L["Auras:"] = "Auras:"
L["Author Options"] = "Options de l'auteur"
L["Auto"] = "auto"
--[[Translation missing --]]
L["Autocast Shine"] = "Autocast Shine"
L["Automatic"] = "Automatique"
L["Automatic Length"] = "Longueur automatique"
L["Automatic Rotation"] = "Rotation automatique"
--[[Translation missing --]]
L["Available features: %s"] = "Available features: %s"
L["Avoidance (%)"] = "Evitement (%)"
L["Avoidance Rating"] = "Pourcentage Evitement "
L["Ayamiss the Hunter"] = "Ayamiss le Chasseur"
L["Azuregos"] = "Azuregos"
L["Back and Forth"] = "D'avant en arrière"
L["Background"] = "Arrière-plan"
L["Background Color"] = "Couleur d'arrière-plan"
L["Balnazzar"] = "Balnazzar"
L["Bar Color/Gradient Start"] = "Couleur/gradient de départ de la barre"
L["Bar enabled in BigWigs settings"] = "Barre activée dans les paramètres de BigWigs"
L["Bar enabled in Boss Mod addon settings"] = "Barre activée dans les paramètres de l’addon de boss mod"
L["Bar enabled in DBM settings"] = [=[Barre activée dans les paramètres de DBM








]=]
L["Bar Texture"] = "Texture de la barre"
--[[Translation missing --]]
L["Bar Type"] = "Bar Type"
L["Baron Geddon"] = "Baron Geddon"
L["Battle for Azeroth"] = "Battle for Azeroth"
L["Battle.net Whisper"] = "Message Battle.net"
L["Battleground"] = [=[Champ De Bataille 
]=]
L["Battleguard Sartura"] = "Garde de guerre Sartura"
--[[Translation missing --]]
L["Beastmaster"] = "Beastmaster"
--[[Translation missing --]]
L["Beatrix"] = "Beatrix"
L["BG>Raid>Party>Say"] = "BG>Raid>Groupe>Dire"
L["BG-System Alliance"] = "Système-BG Alliance"
L["BG-System Horde"] = "Système-BG Horde"
L["BG-System Neutral"] = "Système-BG Neutre"
L["Big Number"] = "Grand nombre"
L["BigWigs Addon"] = "Addon BigWigs"
L["BigWigs Message"] = "Message BigWigs"
--[[Translation missing --]]
L["BigWigs Stage"] = "BigWigs Stage"
L["BigWigs Timer"] = "Temps BigWigs"
--[[Translation missing --]]
L["Black Wing Lair"] = "Black Wing Lair"
--[[Translation missing --]]
L["Bleed"] = "Bleed"
L["Blizzard Combat Text"] = "Texte de Combat Blizzard"
L["Blizzard Cooldown Reduction"] = "Réduction du temps de recharge de Blizzard"
L["Block"] = "Bloc"
L["Block (%)"] = "Blocage"
L["Block against Target (%)"] = "Blocage contre la cible"
L["Block Value"] = "Valeur du bloc"
L["Blocked"] = "Bloqué"
--[[Translation missing --]]
L["Blood"] = "Blood"
L["Blood Rune #1"] = "Rune de sang #1"
--[[Translation missing --]]
L["Blood Rune #2"] = "Blood Rune #2"
L["Bloodlord Mandokir"] = "Seigneur sanglant Mandokir"
--[[Translation missing --]]
L["Bonus Reputation Gain"] = "Bonus Reputation Gain"
L["Border"] = "Encadrement"
L["Boss"] = "Boss"
L["Boss Emote"] = "Emote de boss"
--[[Translation missing --]]
L["Boss Mod Announce"] = "Boss Mod Announce"
--[[Translation missing --]]
L["Boss Mod Stage"] = "Boss Mod Stage"
--[[Translation missing --]]
L["Boss Mod Stage (Event)"] = "Boss Mod Stage (Event)"
--[[Translation missing --]]
L["Boss Mod Timer"] = "Boss Mod Timer"
L["Boss Whisper"] = "Chuchotement de Boss"
L["Bottom"] = "Bas"
L["Bottom Left"] = "Bas Gauche"
L["Bottom Right"] = "Bas Droite"
L["Bottom to Top"] = "De Bas en Haut"
L["Bounce"] = "Rebond"
L["Bounce with Decay"] = "Rebond décroissant"
--[[Translation missing --]]
L["Break"] = "Break"
--[[Translation missing --]]
L["BreakUpLargeNumbers (Blizzard)"] = "BreakUpLargeNumbers (Blizzard)"
--[[Translation missing --]]
L["Broodlord Lashlayer"] = "Broodlord Lashlayer"
L["Buff"] = "Amélioration"
L["Buff/Debuff"] = "Amélioration / affaiblissement"
L["Buffed/Debuffed"] = "Amélioré/Affaiblit"
--[[Translation missing --]]
L["Burning Crusade"] = "Burning Crusade"
L["Buru the Gorger"] = "Buru Grandgosier"
--[[Translation missing --]]
L["Caldoran"] = "Caldoran"
--[[Translation missing --]]
L["Callback function"] = "Callback function"
L["Can be used for e.g. checking if \"boss1target\" is the same as \"player\"."] = "Peut être utilisé pour par exemple vérifier si l'unité \"boss1target\" est la même que \"player\"."
L["Cancel"] = "Annuler"
--[[Translation missing --]]
L[ [=[Cannot change secure frame in combat lockdown. Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames]=] ] = [=[Cannot change secure frame in combat lockdown. Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames]=]
--[[Translation missing --]]
L["Can't schedule timer with %i, due to a World of Warcraft bug with high computer uptime. (Uptime: %i). Please restart your computer."] = "Can't schedule timer with %i, due to a World of Warcraft bug with high computer uptime. (Uptime: %i). Please restart your computer."
--[[Translation missing --]]
L["Capped"] = "Capped"
--[[Translation missing --]]
L["Capped at Season Max"] = "Capped at Season Max"
--[[Translation missing --]]
L["Capped at Weekly Max"] = "Capped at Weekly Max"
L["Cast"] = "Incantation"
L["Cast Bar"] = "Barre d'incantation"
L["Cast Failed"] = "Incantation ratée"
L["Cast Start"] = "Incantation débutée"
L["Cast Success"] = "Incantation réussie"
L["Cast Type"] = "Type d'incantation"
L["Caster"] = "Lanceur de sort"
L["Caster Name"] = "Nom du Lanceur de sort "
L["Caster Realm"] = "Royaume du Lanceur de sort"
L["Caster Unit"] = "Unité lanceur de sort"
--[[Translation missing --]]
L["Casters Name/Realm"] = "Casters Name/Realm"
L["Caster's Target"] = "Cible du Lanceur de sort"
L["Cataclysm"] = "Cataclysm"
L["Ceil"] = "Cellule"
L["Center"] = "Centre"
L["Center, then alternating bottom and top"] = "Centrer, puis alterner bas et haut"
L["Center, then alternating left and right"] = "Centrer, puis alterner gauche et droite"
L["Center, then alternating right and left"] = "Centrer, puis alterner droite et gauche"
L["Center, then alternating top and bottom"] = "Centrer, puis alterner haut et bas"
L["Centered Horizontal"] = "Centrer horizontalement"
L["Centered Horizontal, then Centered Vertical"] = "Centrer horizontalement, puis centrer verticalement"
L["Centered Horizontal, then Down"] = "Centrer horizontalement, puis vers le haut"
L["Centered Horizontal, then Up"] = "Centrer horizontalement, puis vers le bas"
L["Centered Vertical"] = "Centré verticalement"
--[[Translation missing --]]
L["Centered Vertical, then Centered Horizontal"] = "Centered Vertical, then Centered Horizontal"
--[[Translation missing --]]
L["Centered Vertical, then Left"] = "Centered Vertical, then Left"
--[[Translation missing --]]
L["Centered Vertical, then Right"] = "Centered Vertical, then Right"
L["Changed"] = "Modifié"
L["Channel"] = "Canal"
L["Channel (Spell)"] = "Canalisation"
--[[Translation missing --]]
L["Character GUID"] = "Character GUID"
--[[Translation missing --]]
L["Character Name"] = "Character Name"
L["Character Stats"] = "Stats Personnage"
--[[Translation missing --]]
L["Character Transferred Quantity"] = "Character Transferred Quantity"
L["Character Type"] = "Type de Personnage"
L["Charge gained/lost"] = "Charge gagné/perdu"
--[[Translation missing --]]
L["Charged Combo Points"] = "Charged Combo Points"
L["Charges"] = "Charges"
--[[Translation missing --]]
L["Charges Changed Event"] = "Charges Changed Event"
--[[Translation missing --]]
L["Charging"] = "Charging"
L["Chat Frame"] = "Fenêtre de discussion"
L["Chat Message"] = "Message écrit"
--[[Translation missing --]]
L["Check if a single talent match a Rank"] = "Check if a single talent match a Rank"
--[[Translation missing --]]
L["Check nameplate's target every 0.2s"] = "Check nameplate's target every 0.2s"
L["Chromaggus"] = "Chromaggus"
L["Circle"] = "Cercle"
--[[Translation missing --]]
L["Circular Texture"] = "Circular Texture"
L["Clamp"] = "Attache"
L["Class"] = "Classe"
L["Class and Specialization"] = "Classe et spécialisation"
L["Classic"] = "Classic"
L["Classification"] = "Classification"
L["Clockwise"] = "Sens horaire"
--[[Translation missing --]]
L["Clone per Character"] = "Clone per Character"
L["Clone per Event"] = "Clone pour chaque Évènement"
L["Clone per Match"] = "Clone pour chaque Correspondance"
--[[Translation missing --]]
L["Coin Precision"] = "Coin Precision"
L["Color"] = "Couleur"
--[[Translation missing --]]
L["Color Animation"] = "Color Animation"
L["Combat Log"] = "Journal de combat"
--[[Translation missing --]]
L["Communities"] = "Communities"
--[[Translation missing --]]
L["Condition Custom Test"] = "Condition Custom Test"
L["Conditions"] = "Conditions"
L["Contains"] = "Contient"
--[[Translation missing --]]
L["Continuously update Movement Speed"] = "Continuously update Movement Speed"
L["Cooldown"] = "Temps de recharge"
--[[Translation missing --]]
L["Cooldown bars show time before an ability is ready to be use, BigWigs prefix them with '~'"] = "Cooldown bars show time before an ability is ready to be use, BigWigs prefix them with '~'"
L["Cooldown Progress (Item)"] = "Progression du temps de recharge (Objet)"
--[[Translation missing --]]
L["Cooldown Progress (Slot)"] = "Cooldown Progress (Slot)"
--[[Translation missing --]]
L["Cooldown Ready Event"] = "Cooldown Ready Event"
--[[Translation missing --]]
L["Cooldown Ready Event (Item)"] = "Cooldown Ready Event (Item)"
--[[Translation missing --]]
L["Cooldown Ready Event (Slot)"] = "Cooldown Ready Event (Slot)"
--[[Translation missing --]]
L["Cooldown Reduction changes the duration of seconds instead of showing the real time seconds."] = "Cooldown Reduction changes the duration of seconds instead of showing the real time seconds."
--[[Translation missing --]]
L["Cooldown/Charges/Count"] = "Cooldown/Charges/Count"
--[[Translation missing --]]
L["Copper"] = "Copper"
--[[Translation missing --]]
L["Could not load WeakAuras Archive, the addon is %s"] = "Could not load WeakAuras Archive, the addon is %s"
L["Count"] = "Nombre"
L["Counter Clockwise"] = "Sens Antihoraire"
L["Create"] = "Créer"
--[[Translation missing --]]
L["Creature Family"] = "Creature Family"
--[[Translation missing --]]
L["Creature Family Name"] = "Creature Family Name"
--[[Translation missing --]]
L["Creature Type"] = "Creature Type"
--[[Translation missing --]]
L["Creature Type Name"] = "Creature Type Name"
L["Critical"] = "Critique"
L["Critical (%)"] = "Critique (%)"
L["Critical Rating"] = "Évaluation Critique"
--[[Translation missing --]]
L["Crop X"] = "Crop X"
--[[Translation missing --]]
L["Crop Y"] = "Crop Y"
L["Crowd Controlled"] = "Contrôlé"
L["Crushing"] = "Ecrasant"
L["C'thun"] = "C'thun"
--[[Translation missing --]]
L["Cumulated time used during profiling"] = "Cumulated time used during profiling"
--[[Translation missing --]]
L["Currency"] = "Currency"
--[[Translation missing --]]
L["Current Essence"] = "Current Essence"
--[[Translation missing --]]
L["Current Experience"] = "Current Experience"
--[[Translation missing --]]
L["Current Instance"] = "Current Instance"
--[[Translation missing --]]
L["Current Movement Speed (%)"] = "Current Movement Speed (%)"
--[[Translation missing --]]
L["Current Stage"] = "Current Stage"
--[[Translation missing --]]
L["Current Zone"] = "Current Zone"
--[[Translation missing --]]
L["Current Zone Group"] = "Current Zone Group"
L["Curse"] = "Malédiction"
L["Custom"] = "Personnalisé"
--[[Translation missing --]]
L["Custom Action"] = "Custom Action"
--[[Translation missing --]]
L["Custom Anchor"] = "Custom Anchor"
--[[Translation missing --]]
L["Custom Check"] = "Custom Check"
L["Custom Color"] = "Couleur personnalisée"
--[[Translation missing --]]
L["Custom Condition Code"] = "Custom Condition Code"
L["Custom Configuration"] = "Configuration personnalisée"
--[[Translation missing --]]
L["Custom Fade Animation"] = "Custom Fade Animation"
L["Custom Function"] = "Fonction personnalisée"
--[[Translation missing --]]
L["Custom Grow"] = "Custom Grow"
--[[Translation missing --]]
L["Custom Sort"] = "Custom Sort"
--[[Translation missing --]]
L["Custom Text Function"] = "Custom Text Function"
--[[Translation missing --]]
L["Custom Trigger Combination"] = "Custom Trigger Combination"
--[[Translation missing --]]
L["Custom Variables"] = "Custom Variables"
L["Damage"] = "Dégâts"
L["Damage Shield"] = "Bouclier de dégâts"
L["Damage Shield Missed"] = "Bouclier de dégâts raté"
L["Damage Split"] = "Répartition des dégâts"
L["DBM Announce"] = "Annonce DBM"
--[[Translation missing --]]
L["DBM Stage"] = "DBM Stage"
L["DBM Timer"] = "Temps DBM"
--[[Translation missing --]]
L["Dead"] = "Dead"
--[[Translation missing --]]
L["Death"] = "Death"
L["Death Knight Rune"] = "Rune de Chevalier de la Mort"
L["Debuff"] = "Affaiblissement"
--[[Translation missing --]]
L["Debuff Class"] = "Debuff Class"
--[[Translation missing --]]
L["Debuff Class Icon"] = "Debuff Class Icon"
L["Debuff Type"] = "Type d’affaiblissement"
--[[Translation missing --]]
L["Debug Log contains more than 1000 entries"] = "Debug Log contains more than 1000 entries"
--[[Translation missing --]]
L["Debug Logging enabled"] = "Debug Logging enabled"
--[[Translation missing --]]
L["Debug Logging enabled for '%s'"] = "Debug Logging enabled for '%s'"
--[[Translation missing --]]
L["Defensive Stats"] = "Defensive Stats"
L["Deflect"] = "Déviation"
--[[Translation missing --]]
L["Delve"] = "Delve"
L["Desaturate"] = "Désaturer"
L["Desaturate Background"] = "Désaturer l'Arrière-plan"
L["Desaturate Foreground"] = "Désaturer le Premier-plan"
L["Descending"] = "Décroissant"
L["Description"] = "Description"
L["Dest Raid Mark"] = "Marqueur de raid"
--[[Translation missing --]]
L["Destination Affiliation"] = "Destination Affiliation"
--[[Translation missing --]]
L["Destination GUID"] = "Destination GUID"
--[[Translation missing --]]
L["Destination Info"] = "Destination Info"
L["Destination Name"] = "Nom de destination"
--[[Translation missing --]]
L["Destination NPC Id"] = "Destination NPC Id"
--[[Translation missing --]]
L["Destination Object Type"] = "Destination Object Type"
--[[Translation missing --]]
L["Destination Reaction"] = "Destination Reaction"
L["Destination Unit"] = "Unité de destination"
--[[Translation missing --]]
L["Destination unit's raid mark index"] = "Destination unit's raid mark index"
--[[Translation missing --]]
L["Destination unit's raid mark texture"] = "Destination unit's raid mark texture"
--[[Translation missing --]]
L["Difficulty"] = "Difficulty"
L["Disable Spell Known Check"] = "Désactiver la vérification des sorts connus"
--[[Translation missing --]]
L["Disabled"] = "Disabled"
--[[Translation missing --]]
L["Disabled feature %q"] = "Disabled feature %q"
L["Disabled Spell Known Check"] = "Vérification des sorts connus désactivées"
--[[Translation missing --]]
L["Discovered"] = "Discovered"
L["Disease"] = "Maladie"
L["Dispel"] = "Dissipation"
L["Dispel Failed"] = "Dissipation échouée"
L["Display"] = "Affichage"
L["Distance"] = "Distance"
--[[Translation missing --]]
L["Do Not Disturb"] = "Do Not Disturb"
L["Dodge"] = "Esquive"
L["Dodge (%)"] = "Esquive (%)"
L["Dodge Rating"] = "Pourcentage Esquive"
L["Down"] = "Bas"
--[[Translation missing --]]
L["Down, then Centered Horizontal"] = "Down, then Centered Horizontal"
L["Down, then Left"] = "Bas puis Gauche"
L["Down, then Right"] = "Bas puis Droite"
L["Dragonflight"] = "Dragonflight"
L["Drain"] = "Drain"
L["Dropdown Menu"] = "Menu Déroulant"
--[[Translation missing --]]
L["Dumping table"] = "Dumping table"
--[[Translation missing --]]
L["Dungeon (Celestial)"] = "Dungeon (Celestial)"
L["Dungeon (Heroic)"] = "Donjon (Héroïque)"
L["Dungeon (Mythic)"] = "Donjon (Mythique)"
--[[Translation missing --]]
L["Dungeon (Mythic+)"] = "Dungeon (Mythic+)"
L["Dungeon (Normal)"] = "Donjon (Normal)"
L["Dungeon (Timewalking)"] = "Donjon (Marcheurs du temps)"
L["Dungeons"] = "Donjons"
L["Durability Damage"] = "Perte de durabilité"
L["Durability Damage All"] = "Perte de durabilité sur tout"
--[[Translation missing --]]
L["Duration"] = "Duration"
--[[Translation missing --]]
L["Duration Function"] = "Duration Function"
--[[Translation missing --]]
L["Duration Function (fallback state)"] = "Duration Function (fallback state)"
--[[Translation missing --]]
L["Ease In"] = "Ease In"
L["Ease In and Out"] = "Faciliter l'entrée et la sortie"
--[[Translation missing --]]
L["Ease Out"] = "Ease Out"
L["Ebonroc"] = "Rochébène"
--[[Translation missing --]]
L["Eclipse Direction"] = "Eclipse Direction"
L["Edge"] = "Marge"
--[[Translation missing --]]
L["Edge of Madness"] = "Edge of Madness"
--[[Translation missing --]]
L["Effective Spell Id"] = "Effective Spell Id"
L["Elide"] = "Elider"
--[[Translation missing --]]
L["Elite"] = "Elite"
L["Emote"] = "Emote"
--[[Translation missing --]]
L["Empower Cast End"] = "Empower Cast End"
--[[Translation missing --]]
L["Empower Cast Interrupt"] = "Empower Cast Interrupt"
--[[Translation missing --]]
L["Empower Cast Start"] = "Empower Cast Start"
--[[Translation missing --]]
L["Empowered"] = "Empowered"
--[[Translation missing --]]
L["Empowered 1"] = "Empowered 1"
--[[Translation missing --]]
L["Empowered 2"] = "Empowered 2"
--[[Translation missing --]]
L["Empowered 3"] = "Empowered 3"
--[[Translation missing --]]
L["Empowered 4"] = "Empowered 4"
--[[Translation missing --]]
L["Empowered 5"] = "Empowered 5"
--[[Translation missing --]]
L["Empowered Cast"] = "Empowered Cast"
--[[Translation missing --]]
L["Empowered Cast Fully Charged"] = "Empowered Cast Fully Charged"
--[[Translation missing --]]
L["Empowered Fully Charged"] = "Empowered Fully Charged"
L["Empty"] = "Vide"
--[[Translation missing --]]
L["Enabled feature %q"] = "Enabled feature %q"
--[[Translation missing --]]
L["Enables (incorrect) round down of seconds, which was the previous default behavior."] = "Enables (incorrect) round down of seconds, which was the previous default behavior."
L["Enchant Applied"] = "Enchantement appliqué"
L["Enchant Found"] = "Enchantement présent"
--[[Translation missing --]]
L["Enchant ID"] = "Enchant ID"
L["Enchant Missing"] = "Enchantement manquant"
L["Enchant Name or ID"] = "Nom ou ID de l'Enchantement"
L["Enchant Removed"] = "Enchantement retiré"
L["Enchanted"] = "Enchanté"
L["Encounter ID(s)"] = "ID de la Rencontre"
L["Energize"] = "Gain d'énergie"
L["Enrage"] = "Enrager"
--[[Translation missing --]]
L["Enter a name or a spellId"] = "Enter a name or a spellId"
L["Entering"] = "Entrer"
L["Entering/Leaving Combat"] = "Entrer / sortir de combat"
--[[Translation missing --]]
L["Entering/Leaving Encounter"] = "Entering/Leaving Encounter"
--[[Translation missing --]]
L["Entry Order"] = "Entry Order"
L["Environment Type"] = "Type d'environnement"
L["Environmental"] = "Environnement"
L["Equipment"] = "Équipement"
L["Equipment Set"] = "Ensemble d'équipement"
L["Equipment Set Equipped"] = "Ensemble d'équipement équipé"
L["Equipment Slot"] = "Emplacement d'équipement"
L["Equipped"] = "Équipé "
L["Error"] = "Erreur"
--[[Translation missing --]]
L[ [=[Error '%s' created a secure clone. We advise deleting the aura. For more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames]=] ] = [=[Error '%s' created a secure clone. We advise deleting the aura. For more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames]=]
--[[Translation missing --]]
L["Error decoding."] = "Error decoding."
--[[Translation missing --]]
L["Error decompressing"] = "Error decompressing"
--[[Translation missing --]]
L["Error decompressing. This doesn't look like a WeakAuras import."] = "Error decompressing. This doesn't look like a WeakAuras import."
--[[Translation missing --]]
L["Error deserializing"] = "Error deserializing"
L["Error Frame"] = "Fenêtre d'erreur"
--[[Translation missing --]]
L["ERROR in '%s' unknown or incompatible sub element type '%s'"] = "ERROR in '%s' unknown or incompatible sub element type '%s'"
--[[Translation missing --]]
L["Error in Aura '%s'"] = "Error in Aura '%s'"
L["Error not receiving display information from %s"] = "Erreur de non-réception d'informations d'affichage de %s"
--[[Translation missing --]]
L["Essence"] = "Essence"
L["Essence #1"] = "Essence #1"
--[[Translation missing --]]
L["Essence #2"] = "Essence #2"
--[[Translation missing --]]
L["Essence #3"] = "Essence #3"
--[[Translation missing --]]
L["Essence #4"] = "Essence #4"
--[[Translation missing --]]
L["Essence #5"] = "Essence #5"
--[[Translation missing --]]
L["Essence #6"] = "Essence #6"
L["Evade"] = "Evite"
L["Event"] = "Evènement"
L["Event(s)"] = "Evènement(s)"
L["Every Frame"] = "Chaque image"
L["Every Frame (High CPU usage)"] = "Chaque image (utilisation importante du CPU)"
--[[Translation missing --]]
L["Evoker Essence"] = "Evoker Essence"
L["Exact Spell ID(s)"] = "Correspondance exacte de l'ID du/des sort(s)"
--[[Translation missing --]]
L["Execute Conditions"] = "Execute Conditions"
L["Experience (%)"] = "Expérience (%)"
--[[Translation missing --]]
L["Expertise Bonus"] = "Expertise Bonus"
--[[Translation missing --]]
L["Expertise Rating"] = "Expertise Rating"
L["Extend Outside"] = "Étendre à l'extérieur"
L["Extra Amount"] = "Quantité extra"
L["Extra Attacks"] = "Attaques supplémentaires"
--[[Translation missing --]]
L["Extra Spell Id"] = "Extra Spell Id"
L["Extra Spell Name"] = "Nom de Sort supplémentaire"
L["Faction"] = "Faction"
L["Faction Name"] = "Nom de la Faction"
L["Faction Reputation"] = "Réputation envers la Faction"
--[[Translation missing --]]
L["Fade Animation"] = "Fade Animation"
L["Fade In"] = "Fondu entrant"
L["Fade Out"] = "Fondu sortant"
L["Fail Alert"] = "Alerte d'échec"
L["False"] = "Faux"
--[[Translation missing --]]
L["Fankriss the Unyielding"] = "Fankriss the Unyielding"
--[[Translation missing --]]
L["Feature %q is already disabled"] = "Feature %q is already disabled"
--[[Translation missing --]]
L["Feature %q is already enabled"] = "Feature %q is already enabled"
--[[Translation missing --]]
L["Fetch Absorb"] = "Fetch Absorb"
--[[Translation missing --]]
L["Fetch Heal Absorb"] = "Fetch Heal Absorb"
--[[Translation missing --]]
L["Fetch Legendary Power"] = "Fetch Legendary Power"
--[[Translation missing --]]
L["Fetches the name and icon of the Legendary Power that matches this bonus id."] = "Fetches the name and icon of the Legendary Power that matches this bonus id."
--[[Translation missing --]]
L["Fill Area"] = "Fill Area"
--[[Translation missing --]]
L["Filter messages with format <message>"] = "Filter messages with format <message>"
L["Fire Resistance"] = "Résistance au feu"
L["Firemaw"] = "Gueule-de-feu"
L["First"] = "Premier"
L["First Value of Tooltip Text"] = "Première Valeur du Texte de l'Info-bulle"
L["Fixed"] = "Fixé"
--[[Translation missing --]]
L["Fixed Names"] = "Fixed Names"
--[[Translation missing --]]
L["Fixed Size"] = "Fixed Size"
--[[Translation missing --]]
L["Flamegor"] = "Flamegor"
L["Flash"] = "Flash"
L["Flex Raid"] = "Raid Dynamique"
L["Flip"] = "Retourner"
L["Floor"] = "Plancher"
L["Focus"] = "Focalisation"
--[[Translation missing --]]
L["Follower Dungeon"] = "Follower Dungeon"
--[[Translation missing --]]
L["Font"] = "Font"
L["Font Size"] = "Taille de Police"
--[[Translation missing --]]
L["Forbidden function or table: %s"] = "Forbidden function or table: %s"
L["Foreground"] = "Premier plan"
L["Foreground Color"] = "Couleur de Premier Plan"
L["Form"] = "Forme"
L["Format"] = "Format"
--[[Translation missing --]]
L["Format Gold"] = "Format Gold"
--[[Translation missing --]]
L["Formats |cFFFFCC00%unit|r"] = "Formats |cFFFFCC00%unit|r"
--[[Translation missing --]]
L["Formats Player's |cFFFFCC00%guid|r"] = "Formats Player's |cFFFFCC00%guid|r"
--[[Translation missing --]]
L["Forward"] = "Forward"
--[[Translation missing --]]
L["Forward, Reverse Loop"] = "Forward, Reverse Loop"
--[[Translation missing --]]
L["Fourth Value of Tooltip Text"] = "Fourth Value of Tooltip Text"
--[[Translation missing --]]
L["Frame Selector"] = "Frame Selector"
L["Frequency"] = "Fréquence"
L["Friendly"] = "Amical"
L["Friendly Fire"] = "Tir ami"
--[[Translation missing --]]
L["Friendship Max Rank"] = "Friendship Max Rank"
--[[Translation missing --]]
L["Friendship Rank"] = "Friendship Rank"
--[[Translation missing --]]
L["Friendship Reputation"] = "Friendship Reputation"
--[[Translation missing --]]
L["Frost"] = "Frost"
L["Frost Resistance"] = "Résistance au givre"
L["Frost Rune #1"] = "Rune de givre n°1"
--[[Translation missing --]]
L["Frost Rune #2"] = "Frost Rune #2"
L["Full"] = "Plein"
--[[Translation missing --]]
L["Full Region"] = "Full Region"
L["Full/Empty"] = "Plein/Vide"
--[[Translation missing --]]
L["Gahz'ranka"] = "Gahz'ranka"
L["Gained"] = "Gagné"
--[[Translation missing --]]
L["Garr"] = "Garr"
--[[Translation missing --]]
L["Gehennas"] = "Gehennas"
--[[Translation missing --]]
L["General"] = "General"
--[[Translation missing --]]
L["General Rajaxx"] = "General Rajaxx"
--[[Translation missing --]]
L["GetNameAndIcon Function (fallback state)"] = "GetNameAndIcon Function (fallback state)"
L["Glancing"] = "Erafle"
L["Global Cooldown"] = "Temps de recharge global"
L["Glow"] = "Brillance"
L["Glow External Element"] = "Élément externe brillant"
--[[Translation missing --]]
L["Gluth"] = "Gluth"
--[[Translation missing --]]
L["Glyph"] = "Glyph"
--[[Translation missing --]]
L["Gold"] = "Gold"
--[[Translation missing --]]
L["Golemagg the Incinerator"] = "Golemagg the Incinerator"
--[[Translation missing --]]
L["Gothik the Harvester"] = "Gothik the Harvester"
L["Gradient"] = "Dégradé"
--[[Translation missing --]]
L["Gradient Enabled"] = "Gradient Enabled"
--[[Translation missing --]]
L["Gradient End"] = "Gradient End"
--[[Translation missing --]]
L["Gradient Orientation"] = "Gradient Orientation"
L["Gradient Pulse"] = "Pulsation dégradée"
--[[Translation missing --]]
L["Grand Widow Faerlina"] = "Grand Widow Faerlina"
L["Grid"] = "Grille"
--[[Translation missing --]]
L["Grobbulus"] = "Grobbulus"
L["Group"] = "Groupe"
L["Group Arrangement"] = "Arrangement du Groupe"
--[[Translation missing --]]
L["Group Leader/Assist"] = "Group Leader/Assist"
--[[Translation missing --]]
L["Group Size"] = "Group Size"
--[[Translation missing --]]
L["Group Type"] = "Group Type"
L["Grow"] = "Grandir"
L["GTFO Alert"] = "Alerte GTFO"
--[[Translation missing --]]
L["Guardian"] = "Guardian"
L["Guild"] = "Guilde"
--[[Translation missing --]]
L["Hakkar"] = "Hakkar"
--[[Translation missing --]]
L["Hardcore"] = "Hardcore"
L["Has Target"] = "A une Cible"
L["Has Vehicle UI"] = "Interface véhicule"
L["HasPet"] = "Avoir un familier (vivant)"
L["Haste (%)"] = "Hâte (%)"
L["Haste Rating"] = "Score de hâte"
L["Heal"] = "Soin"
--[[Translation missing --]]
L["Heal Absorb"] = "Heal Absorb"
--[[Translation missing --]]
L["Heal Absorbed"] = "Heal Absorbed"
L["Health"] = "Vie"
L["Health (%)"] = "Vie (%)"
--[[Translation missing --]]
L["Health Deficit"] = "Health Deficit"
--[[Translation missing --]]
L["Heigan the Unclean"] = "Heigan the Unclean"
L["Height"] = "Hauteur"
--[[Translation missing --]]
L["Hero Talent"] = "Hero Talent"
--[[Translation missing --]]
L["Heroic Party"] = "Heroic Party"
L["Hide"] = "Cacher"
--[[Translation missing --]]
L["Hide 0 cooldowns"] = "Hide 0 cooldowns"
L["Hide Timer Text"] = "Masquer le texte du minuteur"
L["High Damage"] = "Dégâts élevés"
--[[Translation missing --]]
L["High Priest Thekal"] = "High Priest Thekal"
--[[Translation missing --]]
L["High Priest Venoxis"] = "High Priest Venoxis"
--[[Translation missing --]]
L["High Priestess Arlokk"] = "High Priestess Arlokk"
--[[Translation missing --]]
L["High Priestess Jeklik"] = "High Priestess Jeklik"
--[[Translation missing --]]
L["High Priestess Mar'li"] = "High Priestess Mar'li"
L["Higher Than Tank"] = "Plus haut que le tank"
--[[Translation missing --]]
L["Highest Spell Id"] = "Highest Spell Id"
--[[Translation missing --]]
L["Hit (%)"] = "Hit (%)"
--[[Translation missing --]]
L["Hit Rating"] = "Hit Rating"
L["Holy Resistance"] = "Résistance au sacré"
L["Horde"] = "Horde"
--[[Translation missing --]]
L["Horizontal"] = "Horizontal"
L["Hostile"] = "Hostile"
L["Hostility"] = "Hostilité"
L["Humanoid"] = "Humanoïde"
L["Hybrid"] = "Hybride"
L["Icon"] = "Icône"
--[[Translation missing --]]
L["Icon Function"] = "Icon Function"
--[[Translation missing --]]
L["Icon Function (fallback state)"] = "Icon Function (fallback state)"
--[[Translation missing --]]
L["ID"] = "ID"
--[[Translation missing --]]
L["Id"] = "Id"
--[[Translation missing --]]
L["If you require additional assistance, please open a ticket on GitHub or visit our Discord at https://discord.gg/weakauras!"] = "If you require additional assistance, please open a ticket on GitHub or visit our Discord at https://discord.gg/weakauras!"
L["Ignore Dead"] = "Ignorer la mort"
L["Ignore Disconnected"] = "Ignorer les déconnectés"
L["Ignore Rune CD"] = "Ignorer le rechargement des runes"
L["Ignore Rune CDs"] = "Ignorer les rechargements des runes"
L["Ignore Self"] = "Ignorer soi-même"
--[[Translation missing --]]
L["Ignore Spell Cooldown/Charges"] = "Ignore Spell Cooldown/Charges"
--[[Translation missing --]]
L["Ignore Spell Override"] = "Ignore Spell Override"
L["Immune"] = "Immunité"
L["Important"] = "Important"
--[[Translation missing --]]
L["Importing will start after combat ends."] = "Importing will start after combat ends."
L["In Combat"] = "En combat"
L["In Encounter"] = "En rencontre"
L["In Group"] = "En groupe"
L["In Party"] = "En groupe"
L["In Pet Battle"] = "En combat de mascottes"
L["In Raid"] = "En raid"
--[[Translation missing --]]
L["In Range"] = "In Range"
L["In Vehicle"] = "Dans un véhicule"
L["In War Mode"] = "En mode guerre"
L["Include Bank"] = "Inclure la Banque"
L["Include Charges"] = "Inclure charges"
L["Include Death Runes"] = "Inclure les Runes de la mort"
L["Include Pets"] = "Inclure les familiers"
L["Include War Band Bank"] = "Inclure la Banque de bataillon"
L["Incoming Heal"] = "Soins en Cours"
--[[Translation missing --]]
L["Increase Precision Below"] = "Increase Precision Below"
--[[Translation missing --]]
L["Increases by one per stage or intermission."] = "Increases by one per stage or intermission."
L["Information"] = "Information"
L["Inherited"] = "Hérité"
L["Instakill"] = "Mort instant."
--[[Translation missing --]]
L["Install the addons BugSack and BugGrabber for detailed error logs."] = "Install the addons BugSack and BugGrabber for detailed error logs."
L["Instance"] = "Instance"
L["Instance Difficulty"] = "Difficulté de l'Instance"
--[[Translation missing --]]
L["Instance ID"] = "Instance ID"
--[[Translation missing --]]
L["Instance Id"] = "Instance Id"
--[[Translation missing --]]
L["Instance Info"] = "Instance Info"
--[[Translation missing --]]
L["Instance Name"] = "Instance Name"
L["Instance Size Type"] = "Taille de l'instance"
L["Instance Type"] = "Type d'instance"
--[[Translation missing --]]
L["Instructor Razuvious"] = "Instructor Razuvious"
L["Insufficient Resources"] = "Ressources insuffisantes"
L["Intellect"] = "Intelligence"
L["Interrupt"] = "Interruption"
--[[Translation missing --]]
L["Interrupt School"] = "Interrupt School"
--[[Translation missing --]]
L["Interrupted School Text"] = "Interrupted School Text"
L["Interruptible"] = "Interruptible"
L["Inverse"] = "Inverser"
L["Inverse Pet Behavior"] = "Inverser le comportement du familier"
--[[Translation missing --]]
L["Is Away from Keyboard"] = "Is Away from Keyboard"
--[[Translation missing --]]
L["Is Current Specialization"] = "Is Current Specialization"
--[[Translation missing --]]
L["Is Death Rune"] = "Is Death Rune"
L["Is Exactly"] = "Est exactement"
L["Is Moving"] = "Est en mouvement"
L["Is Off Hand"] = "Est une Main gauche"
--[[Translation missing --]]
L["Is Paragon Reputation"] = "Is Paragon Reputation"
--[[Translation missing --]]
L["Is Paused"] = "Is Paused"
L["is useable"] = "est utilisable"
--[[Translation missing --]]
L["Is Weekly Renown Capped"] = "Is Weekly Renown Capped"
--[[Translation missing --]]
L["Island Expedition (Heroic)"] = "Island Expedition (Heroic)"
--[[Translation missing --]]
L["Island Expedition (Mythic)"] = "Island Expedition (Mythic)"
--[[Translation missing --]]
L["Island Expedition (Normal)"] = "Island Expedition (Normal)"
--[[Translation missing --]]
L["Island Expeditions (PvP)"] = "Island Expeditions (PvP)"
L["Item"] = "Objet"
L["Item Bonus Id"] = "ID du bonus de l'objet"
L["Item Bonus Id Equipped"] = "ID du bonus de l'objet équipé"
L["Item Count"] = "Nombre d'objets"
L["Item Equipped"] = "Objet équipé"
--[[Translation missing --]]
L["Item Id"] = "Item Id"
L["Item in Range"] = "Objet à porté"
--[[Translation missing --]]
L["Item Name"] = "Item Name"
L["Item Set Equipped"] = "Ensemble d'objets équipé"
L["Item Set Id"] = "ID de l'Ensemble d'Equipement"
--[[Translation missing --]]
L["Item Slot"] = "Item Slot"
--[[Translation missing --]]
L["Item Slot String"] = "Item Slot String"
L["Item Type"] = "Type d'objet"
L["Item Type Equipped"] = "Type d'objet équipé"
--[[Translation missing --]]
L["ItemId"] = "ItemId"
--[[Translation missing --]]
L["Jin'do the Hexxer"] = "Jin'do the Hexxer"
--[[Translation missing --]]
L["Journal Stage"] = "Journal Stage"
--[[Translation missing --]]
L["Kazzak"] = "Kazzak"
L["Keep Inside"] = "Garder à l'Intérieur"
--[[Translation missing --]]
L["Kel'Thuzad"] = "Kel'Thuzad"
--[[Translation missing --]]
L["Kurinnaxx"] = "Kurinnaxx"
L["Large"] = "Large"
--[[Translation missing --]]
L["Latency"] = "Latency"
--[[Translation missing --]]
L["Leader"] = "Leader"
L["Least remaining time"] = "Moins de temps restant"
L["Leaving"] = "Quitter"
L["Leech"] = "Drain"
L["Leech (%)"] = "Ponction (%)"
L["Leech Rating"] = "Score de ponction"
L["Left"] = "Gauche"
L["Left to Right"] = "De Gauche à Droite"
--[[Translation missing --]]
L["Left, then Centered Vertical"] = "Left, then Centered Vertical"
L["Left, then Down"] = "Gauche, puis bas"
L["Left, then Up"] = "Gauche, puis haut"
--[[Translation missing --]]
L["Legacy Looking for Raid"] = "Legacy Looking for Raid"
L["Legacy RGB Gradient"] = "Dégradé RVB Hérité"
L["Legacy RGB Gradient Pulse"] = "Impulsion de Dégradé RVB héritée"
--[[Translation missing --]]
L["Legion"] = "Legion"
L["Length"] = "Longueur"
L["Level"] = "Niveau"
--[[Translation missing --]]
L["LibSharedMedia"] = "LibSharedMedia"
--[[Translation missing --]]
L["Lillian Voss"] = "Lillian Voss"
L["Limited"] = "Limité"
--[[Translation missing --]]
L["Linear Texture"] = "Linear Texture"
--[[Translation missing --]]
L["Lines & Particles"] = "Lines & Particles"
L["Load Conditions"] = "Conditions de Chargement"
--[[Translation missing --]]
L["Loatheb"] = "Loatheb"
--[[Translation missing --]]
L["Location"] = "Location"
--[[Translation missing --]]
L["Looking for Raid"] = "Looking for Raid"
L["Loop"] = "Boucle"
--[[Translation missing --]]
L["Loot"] = "Loot"
--[[Translation missing --]]
L["Loot Specialization"] = "Loot Specialization"
--[[Translation missing --]]
L["Loot Specialization Id"] = "Loot Specialization Id"
--[[Translation missing --]]
L["Loot Specialization Name"] = "Loot Specialization Name"
--[[Translation missing --]]
L["Lorewalking"] = "Lorewalking"
L["Lost"] = "Perdu"
L["Low Damage"] = "Dégâts faibles"
L["Lower Than Tank"] = "Plus bas que le tank"
--[[Translation missing --]]
L["Lowest Spell Id"] = "Lowest Spell Id"
--[[Translation missing --]]
L["Lua error"] = "Lua error"
--[[Translation missing --]]
L["Lua error in Aura '%s': %s"] = "Lua error in Aura '%s': %s"
--[[Translation missing --]]
L["Lucifron"] = "Lucifron"
--[[Translation missing --]]
L["Maexxna"] = "Maexxna"
L["Magic"] = "Magique"
--[[Translation missing --]]
L["Magmadar"] = "Magmadar"
--[[Translation missing --]]
L["Main Character"] = "Main Character"
L["Main Stat"] = "Caractéristique principale"
--[[Translation missing --]]
L["Majordomo Executus"] = "Majordomo Executus"
L["Malformed WeakAuras link"] = "Lien WeakAuras mal formé"
--[[Translation missing --]]
L["Manual"] = "Manual"
--[[Translation missing --]]
L["Manual Icon"] = "Manual Icon"
L["Manual Rotation"] = "Rotation manuelle"
L["Marked First"] = "Marqué en premier"
L["Marked Last"] = "Marqué en dernier"
--[[Translation missing --]]
L["Mason"] = "Mason"
L["Master"] = "Maître"
L["Mastery (%)"] = "Maitrise (%)"
L["Mastery Rating"] = "Score de maîtrise"
L["Match Count"] = "taux de rencontre"
--[[Translation missing --]]
L["Match Count per Unit"] = "Match Count per Unit"
L["Matches (Pattern)"] = "Correspond (format)"
--[[Translation missing --]]
L[ [=[Matches stage number of encounter journal.
Intermissions are .5
E.g. 1;2;1;2;2.5;3]=] ] = [=[Matches stage number of encounter journal.
Intermissions are .5
E.g. 1;2;1;2;2.5;3]=]
--[[Translation missing --]]
L["Max Char "] = "Max Char "
--[[Translation missing --]]
L["Max Char"] = "Max Char"
L["Max Charges"] = "Charges Max"
--[[Translation missing --]]
L["Max Health"] = "Max Health"
--[[Translation missing --]]
L["Max Power"] = "Max Power"
--[[Translation missing --]]
L["Max Quantity"] = "Max Quantity"
L["Maximum Estimate"] = "Estimation Maximale"
--[[Translation missing --]]
L["Maximum Progress"] = "Maximum Progress"
--[[Translation missing --]]
L["Maximum time used on a single frame"] = "Maximum time used on a single frame"
--[[Translation missing --]]
L["Media"] = "Media"
L["Medium"] = "Moyen"
--[[Translation missing --]]
L["Melee"] = "Melee"
--[[Translation missing --]]
L["Melee Haste (%)"] = "Melee Haste (%)"
L["Message"] = "Message"
L["Message Type"] = "Type de message"
L["Message type:"] = "Type de message :"
L["Meta Data"] = "Métadonnées"
--[[Translation missing --]]
L["Mine"] = "Mine"
L["Minimum Estimate"] = "Estimation minimale"
--[[Translation missing --]]
L["Minimum Progress"] = "Minimum Progress"
--[[Translation missing --]]
L["Minus (Small Nameplate)"] = "Minus (Small Nameplate)"
L["Mirror"] = "Miroir"
--[[Translation missing --]]
L["Miscellaneous"] = "Miscellaneous"
L["Miss"] = "Raté"
L["Miss Type"] = "Type de raté"
L["Missed"] = "Raté"
L["Missing"] = "Manquant"
--[[Translation missing --]]
L["Mists of Pandaria"] = "Mists of Pandaria"
L["Moam"] = "Moam"
L["Model"] = "Modèle"
L["Modern Blizzard (1h 3m | 3m 7s | 10s | 2.4)"] = "Blizzard moderne (1h 3min | 3m 7s | 10s | 2.4)"
--[[Translation missing --]]
L["Modernize"] = "Modernize"
--[[Translation missing --]]
L["Molten Core"] = "Molten Core"
--[[Translation missing --]]
L["Money"] = "Money"
L["Monochrome"] = "Monochrome"
L["Monochrome Outline"] = "Contour monochrome"
L["Monochrome Thick Outline"] = "Contour épais monochrome"
L["Monster Emote"] = "Emote de Monstre"
L["Monster Party"] = "Groupe de Monstre"
L["Monster Say"] = "Dire de Monstre"
L["Monster Whisper"] = "Chuchotement de Monstre"
L["Monster Yell"] = "Cri de monstre"
--[[Translation missing --]]
L["Moon"] = "Moon"
L["Most remaining time"] = "Plus de temps restant"
L["Mounted"] = "En monture"
L["Mouse Cursor"] = "Curseur de la souris"
L["Movement Speed Rating"] = [=[Score de vitesse
]=]
L["Multi-target"] = "Multi-cibles"
L["Mythic Keystone"] = "Clé mythique"
L["Mythic+ Affix"] = "Affixe de Mythique +"
L["Name"] = "Nom"
--[[Translation missing --]]
L["Name Function"] = "Name Function"
--[[Translation missing --]]
L["Name Function (fallback state)"] = "Name Function (fallback state)"
L["Name of Caster's Target"] = "Nom de la cible du lanceur"
L["Name of the (sub-)zone currently shown above the minimap."] = "Nom de la (sous-)zone actuellement affichée au-dessus de la mini-carte."
--[[Translation missing --]]
L["Name(s)"] = "Name(s)"
L["Name/Realm of Caster's Target"] = "Nom/Royaume de la Cible du Lanceur de sort"
L["Nameplate"] = "Barre de vie"
L["Nameplates"] = "Barres de vie"
L["Names of affected Players"] = "Noms des joueurs affectés"
L["Names of unaffected Players"] = "Noms des joueurs non affectés"
L["Nature Resistance"] = "Résistance à la nature"
L["Naxxramas"] = "Naxxramas"
L["Nefarian"] = "Nefarian"
L["Neutral"] = "Neutre"
L["Never"] = "Jamais"
L["Next Combat"] = "Prochain combat"
--[[Translation missing --]]
L["Next Encounter"] = "Next Encounter"
--[[Translation missing --]]
L[ [=[No active boss mod addon detected.

Note: This trigger will use BigWigs or DBM, in that order if both are installed.]=] ] = [=[No active boss mod addon detected.

Note: This trigger will use BigWigs or DBM, in that order if both are installed.]=]
--[[Translation missing --]]
L["No Extend"] = "No Extend"
L["No Instance"] = "Aucune instance"
L["No Profiling information saved."] = "Aucune information de profilage enregistrée."
--[[Translation missing --]]
L["No Progress Information available."] = "No Progress Information available."
L["None"] = "Aucun"
L["Non-player Character"] = "Personnage non-joueur"
L["Normal"] = "Normal"
--[[Translation missing --]]
L["Normal Party"] = "Normal Party"
L["Not in Group"] = "N'est pas en groupe"
L["Not in Smart Group"] = "N'est pas dans un petit groupe"
L["Not on Cooldown"] = "Pas en recharge"
L["Not On Threat Table"] = "Pas sur la table de menace"
--[[Translation missing --]]
L["Note: Due to how complicated the swing timer behavior is and the lack of APIs from Blizzard, results are inaccurate in edge cases."] = "Note: Due to how complicated the swing timer behavior is and the lack of APIs from Blizzard, results are inaccurate in edge cases."
L["Note: 'Hide Alone' is not available in the new aura tracking system. A load option can be used instead."] = "Remarque: \"Cacher Seul\" n'est pas disponible dans le nouveau système de suivi d'aura. Une option de chargement peut être utilisée à la place."
L["Note: The available text replacements for multi triggers match the normal triggers now."] = "Remarque: Les remplacements de texte disponibles pour les déclencheurs multiples correspondent maintenant aux déclencheurs normaux."
--[[Translation missing --]]
L["Note: This trigger internally stores the shapeshift position, and thus is incompatible with learning stances on the fly, like e.g. the Gladiator Rune."] = "Note: This trigger internally stores the shapeshift position, and thus is incompatible with learning stances on the fly, like e.g. the Gladiator Rune."
--[[Translation missing --]]
L["Note: This trigger relies on the WoW API, which returns incorrect information in some cases."] = "Note: This trigger relies on the WoW API, which returns incorrect information in some cases."
L["Note: This trigger type estimates the range to the hitbox of a unit. The actual range of friendly players is usually 3 yards more than the estimate. Range checking capabilities depend on your current class and known abilities as well as the type of unit being checked. Some of the ranges may also not work with certain NPCs.|n|n|cFFAAFFAAFriendly Units:|r %s|n|cFFFFAAAAHarmful Units:|r %s|n|cFFAAAAFFMiscellanous Units:|r %s"] = "Remarque : Ce type de déclencheur estime la portée du masque de collision (hitbox) d'une unité. La portée réelle des joueurs amis est généralement supérieure de 3 mètres à l'estimation. Les capacités de vérification de la portée dépendent de votre classe actuelle et de vos capacités connues, ainsi que du type d'unité à vérifier. Certaines des portées peuvent également ne pas fonctionner avec certains PNJ.|n|n|cFFAAFFAAUnités amies :|r %s|n|cFFFFAAAAUnités nuisibles :|r %s|n|cFFAAAAFFUnités diverses :|r %s"
L["Noth the Plaguebringer"] = "Noth le Porte-peste"
L["NPC"] = "PNJ"
L["Npc ID"] = "ID PNJ"
L["Number"] = "Nombre"
L["Number Affected"] = "Nombre affecté"
L["Object"] = "Objet"
--[[Translation missing --]]
L[ [=[Occurrence of the event
Can be a range of values
Can have multiple values separated by a comma or a space

Examples:
2nd 5th and 6th events: 2, 5, 6
2nd to 6th: 2-6
every 2 events: /2
every 3 events starting from 2nd: 2/3
every 3 events starting from 2nd and ending at 11th: 2-11/3

Works only if Boss Mod addon show counter]=] ] = [=[Occurrence of the event
Can be a range of values
Can have multiple values separated by a comma or a space

Examples:
2nd 5th and 6th events: 2, 5, 6
2nd to 6th: 2-6
every 2 events: /2
every 3 events starting from 2nd: 2/3
every 3 events starting from 2nd and ending at 11th: 2-11/3

Works only if Boss Mod addon show counter]=]
--[[Translation missing --]]
L[ [=[Occurrence of the event, reset when aura is unloaded
Can be a range of values
Can have multiple values separated by a comma or a space

Examples:
2nd 5th and 6th events: 2, 5, 6
2nd to 6th: 2-6
every 2 events: /2
every 3 events starting from 2nd: 2/3
every 3 events starting from 2nd and ending at 11th: 2-11/3

Only if BigWigs shows it on it's bar]=] ] = [=[Occurrence of the event, reset when aura is unloaded
Can be a range of values
Can have multiple values separated by a comma or a space

Examples:
2nd 5th and 6th events: 2, 5, 6
2nd to 6th: 2-6
every 2 events: /2
every 3 events starting from 2nd: 2/3
every 3 events starting from 2nd and ending at 11th: 2-11/3

Only if BigWigs shows it on it's bar]=]
--[[Translation missing --]]
L[ [=[Occurrence of the event, reset when aura is unloaded
Can be a range of values
Can have multiple values separated by a comma or a space

Examples:
2nd 5th and 6th events: 2, 5, 6
2nd to 6th: 2-6
every 2 events: /2
every 3 events starting from 2nd: 2/3
every 3 events starting from 2nd and ending at 11th: 2-11/3

Only if DBM shows it on it's bar]=] ] = [=[Occurrence of the event, reset when aura is unloaded
Can be a range of values
Can have multiple values separated by a comma or a space

Examples:
2nd 5th and 6th events: 2, 5, 6
2nd to 6th: 2-6
every 2 events: /2
every 3 events starting from 2nd: 2/3
every 3 events starting from 2nd and ending at 11th: 2-11/3

Only if DBM shows it on it's bar]=]
L["Officer"] = "Officier"
--[[Translation missing --]]
L["Offset from progress"] = "Offset from progress"
L["Offset Timer"] = "Décalage de la durée"
L["Old Blizzard (2h | 3m | 10s | 2.4)"] = "Blizzard ancien (2h | 3m | 10s | 2.4)"
L["On Cooldown"] = "En recharge"
--[[Translation missing --]]
L["On Taxi"] = "On Taxi"
--[[Translation missing --]]
L["Only if on a different realm"] = "Only if on a different realm"
L["Only if Primary"] = "Seulement si primaire"
L["Onyxia"] = "Onyxia"
L["Opaque"] = "Opaque"
L["Option Group"] = "Option du groupe"
--[[Translation missing --]]
L["Options could not be loaded, the addon is %s"] = "Options could not be loaded, the addon is %s"
L["Options will finish loading after combat ends."] = "Les options finiront de se charger après la fin du combat."
L["Options will open after the login process has completed."] = "Les options s'ouvriront après la fin du chargement."
--[[Translation missing --]]
L["Or Talent"] = "Or Talent"
L["Orbit"] = "Orbite"
L["Orientation"] = "Orientation"
L["Ossirian the Unscarred"] = "Ossirian l'Intouché"
L["Other"] = "Autre"
L["Other Addons"] = "Autre Addons"
L["Other Events"] = "Autre Événements"
L["Ouro"] = "Ouro"
L["Outline"] = "Contour"
--[[Translation missing --]]
L["Over Energize"] = "Over Energize"
L["Overhealing"] = "Soin en excès"
L["Overkill"] = "Dégâts en excès"
L["Overlay %s"] = "Superposer %s"
L["Overlay Charged Combo Points"] = "Superposer les Points de combo chargés"
L["Overlay Cost of Casts"] = "Superposer le coût des incantations"
L["Overlay Latency"] = "Superposer la Latence"
--[[Translation missing --]]
L["Pad"] = "Pad"
--[[Translation missing --]]
L["Pad Mode"] = "Pad Mode"
--[[Translation missing --]]
L["Pad to"] = "Pad to"
--[[Translation missing --]]
L["Paragon Reputation"] = "Paragon Reputation"
--[[Translation missing --]]
L["Paragon Reward Pending"] = "Paragon Reward Pending"
--[[Translation missing --]]
L["Parent Frame"] = "Parent Frame"
--[[Translation missing --]]
L["Parent Zone"] = "Parent Zone"
L["Parry"] = "Parade"
L["Parry (%)"] = "Parade (%)"
L["Parry Rating"] = "Score de parade"
L["Party"] = "Groupe"
L["Party Kill"] = "Tué par le groupe"
--[[Translation missing --]]
L["Patchwerk"] = "Patchwerk"
--[[Translation missing --]]
L["Path of Ascension: Courage"] = "Path of Ascension: Courage"
--[[Translation missing --]]
L["Path of Ascension: Humility"] = "Path of Ascension: Humility"
--[[Translation missing --]]
L["Path of Ascension: Loyalty"] = "Path of Ascension: Loyalty"
--[[Translation missing --]]
L["Path of Ascension: Wisdom"] = "Path of Ascension: Wisdom"
L["Paused"] = "En pause"
L["Periodic Spell"] = "Sort périodique"
L["Personal Resource Display"] = "Cadre des ressources personnelles"
L["Pet"] = "Familier "
L["Pet Behavior"] = "Comportement du familier"
L["Pet Specialization"] = "Spécialisation du familier"
L["Pet Spell"] = "Sort du familier"
L["Pets only"] = "Familiers seulement"
L["Phase"] = "Phase"
L["Pixel Glow"] = "Pixel brillant"
L["Placement"] = "Placement"
--[[Translation missing --]]
L["Placement %i"] = "Placement %i"
--[[Translation missing --]]
L["Placement Mode"] = "Placement Mode"
L["Play"] = "Jouer"
L["Player"] = "Joueur"
L["Player Character"] = "Personnage Joueur"
L["Player Class"] = "Classe du joueur"
L["Player Effective Level"] = "Niveau effectif du joueur"
--[[Translation missing --]]
L["Player Experience"] = "Player Experience"
L["Player Faction"] = "Faction joueur"
L["Player Level"] = "Niveau du joueur"
--[[Translation missing --]]
L["Player Location ID(s)"] = "Player Location ID(s)"
--[[Translation missing --]]
L["Player Money"] = "Player Money"
L["Player Name/Realm"] = "Nom du joueur / serveur"
L["Player Race"] = "Race du joueur"
L["Player(s) Affected"] = "Joueur(s) affecté(s)"
L["Player(s) Not Affected"] = "Joueur(s) non affecté(s)"
--[[Translation missing --]]
L["Player/Unit Info"] = "Player/Unit Info"
L["Players and Pets"] = "Joueurs et familiers"
L["Poison"] = "Poison"
L["Power"] = "Puissance"
L["Power (%)"] = "Puissance (%)"
--[[Translation missing --]]
L["Power Deficit"] = "Power Deficit"
L["Power Type"] = "Type de puissance"
L["Precision"] = "Précision"
L["Preset"] = "Préréglé"
--[[Translation missing --]]
L["Primary Stats"] = "Primary Stats"
--[[Translation missing --]]
L["Princess Huhuran"] = "Princess Huhuran"
L["Print Profiling Results"] = "Afficher les résultats de profilage"
L["Proc Glow"] = "Génère une brillance"
L["Profiling already started."] = "Le profilage a déjà commencé."
--[[Translation missing --]]
L["Profiling automatically started."] = "Profiling automatically started."
L["Profiling not running."] = "Le profilage ne fonctionne pas."
L["Profiling started."] = "Le profilage a commencé."
--[[Translation missing --]]
L["Profiling started. It will end automatically in %d seconds"] = "Profiling started. It will end automatically in %d seconds"
L["Profiling still running, stop before trying to print."] = "Le profilage est toujours en cours, arrêtez avant d'essayer de l'afficher"
L["Profiling stopped."] = "Le profilage s'est arrêté."
L["Progress"] = "Progrès"
--[[Translation missing --]]
L["Progress Source"] = "Progress Source"
L["Progress Total"] = "Progrès Total"
L["Progress Value"] = "Valeur de progression"
--[[Translation missing --]]
L["Pull"] = "Pull"
L["Pulse"] = "Pulsation"
L["PvP Flagged"] = "JcJ activé"
--[[Translation missing --]]
L["PvP Talent Selected"] = "PvP Talent Selected"
L["PvP Talent selected"] = "Talent JcJ sélectionné"
--[[Translation missing --]]
L["Quality Id"] = "Quality Id"
--[[Translation missing --]]
L["Quantity"] = "Quantity"
--[[Translation missing --]]
L["Quantity earned this week"] = "Quantity earned this week"
--[[Translation missing --]]
L["Quest Party"] = "Quest Party"
--[[Translation missing --]]
L["Queued Action"] = "Queued Action"
L["Radius"] = "Rayon"
--[[Translation missing --]]
L["Ragnaros"] = "Ragnaros"
L["Raid"] = "Raid "
L["Raid (Heroic)"] = "Raid (Héroïque)"
L["Raid (Mythic)"] = "Raid (Mythique)"
L["Raid (Normal)"] = "Raid (Normal)"
L["Raid (Timewalking)"] = "Raid (Marcheurs du temps)"
L["Raid Mark"] = "Marque de raid"
L["Raid Mark Icon"] = "Icône pour la marque de raid"
L["Raid Role"] = "Rôle de raid"
L["Raid Warning"] = "Avertissement de raid"
L["Raids"] = "Raids RdR"
L["Range"] = "Portée"
L["Range Check"] = "Vérification de la portée"
--[[Translation missing --]]
L["Ranged"] = "Ranged"
--[[Translation missing --]]
L["Rank"] = "Rank"
L["Rare"] = "Rare"
--[[Translation missing --]]
L["Rare Elite"] = "Rare Elite"
L["Rated Arena"] = "Arène Coté"
L["Rated Battleground"] = "Champ de bataille Coté"
--[[Translation missing --]]
L["Raw Threat Percent"] = "Raw Threat Percent"
--[[Translation missing --]]
L["Razorgore the Untamed"] = "Razorgore the Untamed"
L["Ready Check"] = "Appel de Raid"
--[[Translation missing --]]
L["Reagent Quality"] = "Reagent Quality"
--[[Translation missing --]]
L["Reagent Quality Texture"] = "Reagent Quality Texture"
L["Realm"] = "Royaume"
L["Realm Name"] = "Nom du Royaume"
L["Realm of Caster's Target"] = "Royaume de la Cible du Lanceur de sort"
--[[Translation missing --]]
L["Reborn Council"] = "Reborn Council"
--[[Translation missing --]]
L["Receiving %s Bytes"] = "Receiving %s Bytes"
L["Receiving display information"] = "Réception d'information de graphique de %s..."
L["Reflect"] = "Renvoi"
L["Region type %s not supported"] = "Région de type %s non supporté"
L["Relative"] = "Relatif"
L["Relative X-Offset"] = "Décalage sur l'axe X"
L["Relative Y-Offset"] = "Décalage sur l'axe Y"
L["Remaining Duration"] = "Durée Restante"
L["Remaining Time"] = "Temps restant"
L["Remove Obsolete Auras"] = "Retirer les auras obsolètes"
--[[Translation missing --]]
L["Renown Level"] = "Renown Level"
--[[Translation missing --]]
L["Renown Max Level"] = "Renown Max Level"
--[[Translation missing --]]
L["Renown Reputation"] = "Renown Reputation"
L["Repair"] = "Réparer"
L["Repeat"] = "Répéter"
--[[Translation missing --]]
L["Report Summary"] = "Report Summary"
--[[Translation missing --]]
L["Reputation"] = "Reputation"
--[[Translation missing --]]
L["Reputation (%)"] = "Reputation (%)"
L["Requested display does not exist"] = "L'affichage demandé n'existe pas"
L["Requested display not authorized"] = "L'affichage demandé n'est pas autorisé"
L["Requesting display information from %s ..."] = "Demande des informations de l'affichage depuis %s ..."
L["Require Valid Target"] = "Exige une cible valide"
--[[Translation missing --]]
L["Requires syncing the specialization via LibSpecialization."] = "Requires syncing the specialization via LibSpecialization."
--[[Translation missing --]]
L["Resilience (%)"] = "Resilience (%)"
--[[Translation missing --]]
L["Resilience Rating"] = "Resilience Rating"
L["Resist"] = "Résiste"
--[[Translation missing --]]
L["Resistances"] = "Resistances"
L["Resisted"] = "Résisté"
L["Rested"] = "Reposé"
--[[Translation missing --]]
L["Rested Experience"] = "Rested Experience"
--[[Translation missing --]]
L["Rested Experience (%)"] = "Rested Experience (%)"
L["Resting"] = "Repos"
L["Resurrect"] = "Résurrection"
--[[Translation missing --]]
L["Resurrect Pending"] = "Resurrect Pending"
L["Right"] = "Droite"
L["Right to Left"] = "Droite à Gauche"
L["Right, then Centered Vertical"] = "Droite, puis centrer verticalement"
L["Right, then Down"] = "Droite, puis bas"
L["Right, then Up"] = "Droite, puis haut"
L["Role"] = "Rôle"
--[[Translation missing --]]
L["Rollback snapshot is complete. Thank you for your patience!"] = "Rollback snapshot is complete. Thank you for your patience!"
--[[Translation missing --]]
L["Rotate Animation"] = "Rotate Animation"
L["Rotate Left"] = "Rotation gauche"
L["Rotate Right"] = "Rotation droite"
L["Rotation"] = "Rotation"
L["Round"] = "Ronde"
--[[Translation missing --]]
L["Round Mode"] = "Round Mode"
L["Ruins of Ahn'Qiraj"] = "Ruines d'Ahn'Qiraj"
L["Run Custom Code"] = "Exécuter le code personnalisé"
--[[Translation missing --]]
L["Run Speed (%)"] = "Run Speed (%)"
L["Rune"] = "Rune"
L["Rune #1"] = "Rune #1"
L["Rune #2"] = "Rune #2"
L["Rune #3"] = "Rune #3"
L["Rune #4"] = "Rune #4"
L["Rune #5"] = "Rune #5"
L["Rune #6"] = "Rune #6"
--[[Translation missing --]]
L["Rune Count"] = "Rune Count"
--[[Translation missing --]]
L["Rune Count - Blood"] = "Rune Count - Blood"
--[[Translation missing --]]
L["Rune Count - Frost"] = "Rune Count - Frost"
--[[Translation missing --]]
L["Rune Count - Unholy"] = "Rune Count - Unholy"
--[[Translation missing --]]
L["Sapphiron"] = "Sapphiron"
L["Say"] = "Dire"
L["Scale"] = "Échelle"
--[[Translation missing --]]
L["Scarlet Enclave"] = "Scarlet Enclave"
L["Scenario"] = "Scénario"
--[[Translation missing --]]
L["Scenario (Heroic)"] = "Scenario (Heroic)"
--[[Translation missing --]]
L["Scenario (Normal)"] = "Scenario (Normal)"
--[[Translation missing --]]
L["Screen"] = "Screen"
L["Screen/Parent Group"] = "Écran/Groupe parent"
--[[Translation missing --]]
L["Season of Discovery"] = "Season of Discovery"
L["Second"] = "Deuxième"
L["Second Value of Tooltip Text"] = "Deuxième valeur du texte de l'info-bulle"
--[[Translation missing --]]
L["Secondary Stats"] = "Secondary Stats"
L["Seconds"] = "Secondes"
--[[Translation missing --]]
L[ [=[Secure frame detected. Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames]=] ] = [=[Secure frame detected. Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames]=]
L["Select Frame"] = "Sélectionner le cadre"
--[[Translation missing --]]
L["Select the type of timer to filter"] = "Select the type of timer to filter"
--[[Translation missing --]]
L["Selection Mode"] = "Selection Mode"
L["Separator"] = "Séparateur"
--[[Translation missing --]]
L["Set IDs can be found on websites such as wowhead.com/cata/item-sets"] = "Set IDs can be found on websites such as wowhead.com/cata/item-sets"
--[[Translation missing --]]
L["Set IDs can be found on websites such as wowhead.com/classic/item-sets"] = "Set IDs can be found on websites such as wowhead.com/classic/item-sets"
--[[Translation missing --]]
L["Set IDs can be found on websites such as wowhead.com/item-sets"] = "Set IDs can be found on websites such as wowhead.com/item-sets"
--[[Translation missing --]]
L["Set IDs can be found on websites such as wowhead.com/mop-classic/item-sets"] = "Set IDs can be found on websites such as wowhead.com/mop-classic/item-sets"
L["Shadow Resistance"] = "Résistance à l'ombre"
--[[Translation missing --]]
L["Shadowlands"] = "Shadowlands"
L["Shake"] = "Secouer"
--[[Translation missing --]]
L["Shazzrah"] = "Shazzrah"
L["Shift-Click to resume addon execution."] = "Maj-Clic pour reprendre l'exécution de l'addon."
L["Show"] = "Montrer"
L["Show CD of Charge"] = "Afficher le Temps de Recharge de la charge"
--[[Translation missing --]]
L["Show charged duration for empowered casts"] = "Show charged duration for empowered casts"
L["Show GCD"] = "Afficher GCD"
L["Show Global Cooldown"] = "Afficher le Temps de Recharge Global"
L["Show Incoming Heal"] = "Afficher les Soins en Cours"
--[[Translation missing --]]
L["Show Loss of Control"] = "Show Loss of Control"
L["Show On"] = "Afficher Sur"
L["Show Rested Overlay"] = "Superposer l'XP en reposé"
L["Shrink"] = "Rétrécir"
--[[Translation missing --]]
L["Silithid Royalty"] = "Silithid Royalty"
--[[Translation missing --]]
L["Silver"] = "Silver"
L["Simple"] = "Basique"
--[[Translation missing --]]
L["Since Active"] = "Since Active"
--[[Translation missing --]]
L["Since Apply"] = "Since Apply"
--[[Translation missing --]]
L["Since Apply/Refresh"] = "Since Apply/Refresh"
--[[Translation missing --]]
L["Since Charge Gain"] = "Since Charge Gain"
--[[Translation missing --]]
L["Since Charge Lost"] = "Since Charge Lost"
--[[Translation missing --]]
L["Since Ready"] = "Since Ready"
--[[Translation missing --]]
L["Since Stack Gain"] = "Since Stack Gain"
--[[Translation missing --]]
L["Since Stack Lost"] = "Since Stack Lost"
L["Size & Position"] = "Taille & Position"
--[[Translation missing --]]
L["Skyriding"] = "Skyriding"
--[[Translation missing --]]
L["Slide Animation"] = "Slide Animation"
L["Slide from Bottom"] = "Glisser d'en bas"
L["Slide from Left"] = "Glisser de la gauche"
L["Slide from Right"] = "Glisser de la droite"
L["Slide from Top"] = "Glisser d'en haut"
L["Slide to Bottom"] = "Glisser en bas"
L["Slide to Left"] = "Glisser à gauche"
L["Slide to Right"] = "Glisser à droite"
L["Slide to Top"] = "Glisser en haut"
--[[Translation missing --]]
L["Slider"] = "Slider"
L["Small"] = "Petit"
--[[Translation missing --]]
L["Smart Group"] = "Smart Group"
--[[Translation missing --]]
L["Soft Enemy"] = "Soft Enemy"
--[[Translation missing --]]
L["Soft Friend"] = "Soft Friend"
--[[Translation missing --]]
L["Solistrasza"] = "Solistrasza"
L["Sound"] = "Son"
L["Sound by Kit ID"] = "Son par Kit ID"
L["Source"] = "Source"
--[[Translation missing --]]
L["Source Affiliation"] = "Source Affiliation"
--[[Translation missing --]]
L["Source GUID"] = "Source GUID"
--[[Translation missing --]]
L["Source Info"] = "Source Info"
L["Source Name"] = "Nom de source"
--[[Translation missing --]]
L["Source NPC Id"] = "Source NPC Id"
--[[Translation missing --]]
L["Source Object Type"] = "Source Object Type"
--[[Translation missing --]]
L["Source Raid Mark"] = "Source Raid Mark"
--[[Translation missing --]]
L["Source Reaction"] = "Source Reaction"
L["Source Unit"] = "Unité source"
--[[Translation missing --]]
L["Source Unit Name/Realm"] = "Source Unit Name/Realm"
--[[Translation missing --]]
L["Source unit's raid mark index"] = "Source unit's raid mark index"
--[[Translation missing --]]
L["Source unit's raid mark texture"] = "Source unit's raid mark texture"
L["Space"] = "Ecart"
L["Spacing"] = "Ecartement"
L["Spark"] = "Étincelle"
--[[Translation missing --]]
L["Spec Position"] = "Spec Position"
--[[Translation missing --]]
L["Spec Role"] = "Spec Role"
--[[Translation missing --]]
L["Specialization"] = "Specialization"
--[[Translation missing --]]
L["Specific Currency"] = "Specific Currency"
L["Specific Type"] = "Type spécifique"
L["Specific Unit"] = "Unité spécifique"
L["Spell"] = "Sort"
L["Spell (Building)"] = "Sort (croissant)"
L["Spell Activation Overlay Glow"] = "Brillance pendant que le sort est actif"
--[[Translation missing --]]
L["Spell Cast Succeeded"] = "Spell Cast Succeeded"
L["Spell Cost"] = "Coût des sorts"
--[[Translation missing --]]
L["Spell Count"] = "Spell Count"
L["Spell ID"] = "ID de Sort"
L["Spell Id"] = "ID de Sort"
L["Spell ID:"] = "ID de sort:"
L["Spell IDs:"] = "IDs de sort"
L["Spell in Range"] = "Sort à portée"
L["Spell Known"] = "Sort connu"
L["Spell Name"] = "Nom du sort"
--[[Translation missing --]]
L["Spell Peneration Percent"] = "Spell Peneration Percent"
--[[Translation missing --]]
L["Spell Power"] = "Spell Power"
--[[Translation missing --]]
L["Spell School"] = "Spell School"
L["Spell Usable"] = "Sort Utilisable"
--[[Translation missing --]]
L["Spellname"] = "Spellname"
--[[Translation missing --]]
L["Spike"] = "Spike"
L["Spin"] = "Tourne"
L["Spiral"] = "Spirale"
L["Spiral In And Out"] = "Spirale entrante et sortante"
--[[Translation missing --]]
L["Spirit"] = "Spirit"
L["Stack Count"] = "Nombre de Piles"
--[[Translation missing --]]
L["Stack trace:"] = "Stack trace:"
L["Stacks"] = "Piles"
--[[Translation missing --]]
L["Stacks Function"] = "Stacks Function"
--[[Translation missing --]]
L["Stacks Function (fallback state)"] = "Stacks Function (fallback state)"
--[[Translation missing --]]
L["Stage"] = "Stage"
--[[Translation missing --]]
L["Stage Counter"] = "Stage Counter"
--[[Translation missing --]]
L["Stagger"] = "Stagger"
--[[Translation missing --]]
L["Stagger (%)"] = "Stagger (%)"
--[[Translation missing --]]
L["Stagger against Target (%)"] = "Stagger against Target (%)"
L["Stagger Scale"] = "espacer"
L["Stamina"] = "Endurance"
L["Stance/Form/Aura"] = "Posture/Forme/Aura"
--[[Translation missing --]]
L["Standing"] = "Standing"
--[[Translation missing --]]
L["Star Shake"] = "Star Shake"
--[[Translation missing --]]
L["Start Animation"] = "Start Animation"
--[[Translation missing --]]
L["Start Now"] = "Start Now"
--[[Translation missing --]]
L["Start Profiling"] = "Start Profiling"
L["Status"] = "Statut"
--[[Translation missing --]]
L["Status Bar"] = "Status Bar"
L["Stolen"] = "Volé"
L["Stop"] = "Arrêter"
--[[Translation missing --]]
L["Stop Motion"] = "Stop Motion"
--[[Translation missing --]]
L["Story Raid"] = "Story Raid"
L["Strength"] = "Force"
L["String"] = "Séquence"
--[[Translation missing --]]
L["Subevent Info"] = "Subevent Info"
--[[Translation missing --]]
L["Subtract Cast"] = "Subtract Cast"
--[[Translation missing --]]
L["Subtract Channel"] = "Subtract Channel"
--[[Translation missing --]]
L["Subtract GCD"] = "Subtract GCD"
--[[Translation missing --]]
L["Subzone Name"] = "Subzone Name"
--[[Translation missing --]]
L["Success"] = "Success"
--[[Translation missing --]]
L["Sulfuron Harbinger"] = "Sulfuron Harbinger"
L["Summon"] = "Invocation"
--[[Translation missing --]]
L["Summon Pending"] = "Summon Pending"
--[[Translation missing --]]
L["Sun"] = "Sun"
L["Supports multiple entries, separated by commas"] = "Prend en charge plusieurs entrées, séparées par des virgules"
L[ [=[Supports multiple entries, separated by commas
]=] ] = "Prend en charge plusieurs entrées, séparées par des virgules"
--[[Translation missing --]]
L["Supports multiple entries, separated by commas. Escape ',' with \\. Prefix with '-' for negation."] = "Supports multiple entries, separated by commas. Escape ',' with \\. Prefix with '-' for negation."
--[[Translation missing --]]
L["Supports multiple entries, separated by commas. Escape with \\. Prefix with '-' for negation."] = "Supports multiple entries, separated by commas. Escape with \\. Prefix with '-' for negation."
--[[Translation missing --]]
L["Supports multiple entries, separated by commas. Prefix with '-' for negation."] = "Supports multiple entries, separated by commas. Prefix with '-' for negation."
--[[Translation missing --]]
L[ [=[Supports multiple entries, separated by commas. To include child zone ids, prefix with 'c', e.g. 'c2022'.
Group Zone IDs must be prefixed with 'g', e.g. 'g277'. 
Supports Area IDs from https://wago.tools/db2/AreaTable prefixed with 'a'. 
Supports Instance IDs prefixed with 'i'.
Entries can be prefixed with '-' to negate.]=] ] = [=[Supports multiple entries, separated by commas. To include child zone ids, prefix with 'c', e.g. 'c2022'.
Group Zone IDs must be prefixed with 'g', e.g. 'g277'. 
Supports Area IDs from https://wago.tools/db2/AreaTable prefixed with 'a'. 
Supports Instance IDs prefixed with 'i'.
Entries can be prefixed with '-' to negate.]=]
L["Swing"] = "Coup"
L["Swing Timer"] = "Vitesse d'attaque"
L["Swipe"] = "Balayage"
--[[Translation missing --]]
L["Syntax /wa feature <toggle|on|enable|disable|off> <feature>"] = "Syntax /wa feature <toggle|on|enable|disable|off> <feature>"
L["System"] = "Système"
--[[Translation missing --]]
L["Systems"] = "Systems"
L["Tab "] = "Onglet"
--[[Translation missing --]]
L["Talent"] = "Talent"
--[[Translation missing --]]
L["Talent |cFFFF0000Not|r Known"] = "Talent |cFFFF0000Not|r Known"
--[[Translation missing --]]
L["Talent |cFFFF0000Not|r Selected"] = "Talent |cFFFF0000Not|r Selected"
--[[Translation missing --]]
L["Talent Known"] = "Talent Known"
L["Talent Selected"] = "Talent sélectionné"
L["Talent selected"] = "Talent sélectionné"
L["Talent Specialization"] = "Spécialisation"
L["Tanking And Highest"] = "Tank et le plus haut"
L["Tanking But Not Highest"] = "Tank mais pas le plus haut"
L["Target"] = "Cible"
L["Targeted"] = "Ciblé"
--[[Translation missing --]]
L["Tertiary Stats"] = "Tertiary Stats"
--[[Translation missing --]]
L["Test if bar is enabled in BigWigs settings"] = "Test if bar is enabled in BigWigs settings"
--[[Translation missing --]]
L["Test if bar is enabled in Boss Mod addon settings"] = "Test if bar is enabled in Boss Mod addon settings"
--[[Translation missing --]]
L["Test if bar is enabled in DBM settings"] = "Test if bar is enabled in DBM settings"
L["Text"] = "Texte"
--[[Translation missing --]]
L["Text To Speech"] = "Text To Speech"
--[[Translation missing --]]
L["Text-to-speech"] = "Text-to-speech"
--[[Translation missing --]]
L["Texture"] = "Texture"
--[[Translation missing --]]
L["Texture Function"] = "Texture Function"
--[[Translation missing --]]
L["Texture Function (fallback state)"] = "Texture Function (fallback state)"
--[[Translation missing --]]
L["Texture Picker"] = "Texture Picker"
--[[Translation missing --]]
L["Texture Rotation"] = "Texture Rotation"
--[[Translation missing --]]
L["Thaddius"] = "Thaddius"
--[[Translation missing --]]
L["The aura has overwritten the global '%s', this might affect other auras."] = "The aura has overwritten the global '%s', this might affect other auras."
--[[Translation missing --]]
L["The aura tried to overwrite the aura_env global, which is not allowed."] = "The aura tried to overwrite the aura_env global, which is not allowed."
L["The effective level differs from the level in e.g. Time Walking dungeons."] = "Le niveau effectif diffère du niveau dans les donjons des Marcheurs du temps, par exemple."
--[[Translation missing --]]
L["The Four Horsemen"] = "The Four Horsemen"
--[[Translation missing --]]
L["The 'ID' value can be found in the BigWigs options of a specific spell"] = "The 'ID' value can be found in the BigWigs options of a specific spell"
--[[Translation missing --]]
L["The Prophet Skeram"] = "The Prophet Skeram"
--[[Translation missing --]]
L["The total quantity a warband character can transfer after paying the transfer cost"] = "The total quantity a warband character can transfer after paying the transfer cost"
--[[Translation missing --]]
L["The total quantity after transferring everything to your current character and paying the transfer cost"] = "The total quantity after transferring everything to your current character and paying the transfer cost"
--[[Translation missing --]]
L["The War Within"] = "The War Within"
L["There are %i updates to your auras ready to be installed!"] = [=[
Il y a %i mises à jour de vos auras prêtes à être installées!]=]
L["Thick Outline"] = "Contour épais"
L["Thickness"] = "Épaisseur"
L["Third"] = "Troisième"
L["Third Value of Tooltip Text"] = "Troisième valeur du texte de l'info-bulle"
--[[Translation missing --]]
L["This aura calls GetData a lot, which is a slow function."] = "This aura calls GetData a lot, which is a slow function."
--[[Translation missing --]]
L["This aura has caused a Lua error."] = "This aura has caused a Lua error."
--[[Translation missing --]]
L["This aura is saving %s KB of data"] = "This aura is saving %s KB of data"
--[[Translation missing --]]
L["This aura plays a sound via a condition."] = "This aura plays a sound via a condition."
--[[Translation missing --]]
L["This aura plays a sound via an action."] = "This aura plays a sound via an action."
--[[Translation missing --]]
L["This aura plays a Text To Speech via a condition."] = "This aura plays a Text To Speech via a condition."
--[[Translation missing --]]
L["This aura plays a Text To Speech via an action."] = "This aura plays a Text To Speech via an action."
--[[Translation missing --]]
L["This filter has been moved to the Location trigger. Change your aura to use the new Location trigger or join the WeakAuras Discord server for help."] = "This filter has been moved to the Location trigger. Change your aura to use the new Location trigger or join the WeakAuras Discord server for help."
--[[Translation missing --]]
L["Threat Percent"] = "Threat Percent"
L["Threat Situation"] = "Situation de Menace"
--[[Translation missing --]]
L["Threat Value"] = "Threat Value"
L["Tick"] = "Coche"
--[[Translation missing --]]
L["Time"] = "Time"
--[[Translation missing --]]
L["Time Format"] = "Time Format"
--[[Translation missing --]]
L["Time in GCDs"] = "Time in GCDs"
--[[Translation missing --]]
L["Time since initial application"] = "Time since initial application"
--[[Translation missing --]]
L["Time since last refresh"] = "Time since last refresh"
--[[Translation missing --]]
L["Time since stack gain"] = "Time since stack gain"
--[[Translation missing --]]
L["Time since stack lost"] = "Time since stack lost"
L["Timed"] = "Temporisé"
--[[Translation missing --]]
L["Timed Progress"] = "Timed Progress"
--[[Translation missing --]]
L["Timer"] = "Timer"
--[[Translation missing --]]
L["Timer Id"] = "Timer Id"
L["Toggle"] = "Basculer"
L["Toggle List"] = "Basculer la liste"
L["Toggle Options Window"] = "Activer/Désactiver la Fenêtre d'Options"
--[[Translation missing --]]
L["Toggle Performance Profiling Window"] = "Toggle Performance Profiling Window"
L["Tooltip"] = "Info-bulle"
L["Tooltip 1"] = "Info-bulle 1"
L["Tooltip 2"] = "Info-bulle 2"
L["Tooltip 3"] = "Info-bulle 3"
L["Tooltip Value 1"] = "Valeur de l'info-bulle 1"
L["Tooltip Value 2"] = "Valeur de l'info-bulle 2"
L["Tooltip Value 3"] = "Valeur de l'info-bulle 3"
L["Tooltip Value 4"] = "Valeur de l'info-bulle 4"
L["Top"] = "Haut"
L["Top Left"] = "Haut Gauche"
L["Top Right"] = "Haut Droite"
L["Top to Bottom"] = "Haut en Bas"
--[[Translation missing --]]
L["Torghast"] = "Torghast"
L["Total Duration"] = "Duration Totale"
--[[Translation missing --]]
L["Total Earned in this Season"] = "Total Earned in this Season"
--[[Translation missing --]]
L["Total Essence"] = "Total Essence"
--[[Translation missing --]]
L["Total Experience"] = "Total Experience"
--[[Translation missing --]]
L["Total Match Count"] = "Total Match Count"
--[[Translation missing --]]
L["Total Reputation"] = "Total Reputation"
--[[Translation missing --]]
L["Total Stacks"] = "Total Stacks"
--[[Translation missing --]]
L["Total stacks over all matches"] = "Total stacks over all matches"
--[[Translation missing --]]
L["Total Stages"] = "Total Stages"
--[[Translation missing --]]
L["Total Unit Count"] = "Total Unit Count"
L["Total Units"] = "Unités Total"
L["Totem"] = "Totem"
L["Totem #%i"] = "Totem #%i"
--[[Translation missing --]]
L["Totem Icon"] = "Totem Icon"
L["Totem Name"] = "Nom Totem"
--[[Translation missing --]]
L["Totem Name Pattern Match"] = "Totem Name Pattern Match"
L["Totem Number"] = "Numéro du Totem"
L["Track Cooldowns"] = "Suivre les temps de recharge "
L["Tracking Charge %i"] = "Suivi de charge %i"
L["Tracking Charge CDs"] = "Suivi des CD de charge"
L["Tracking Only Cooldown"] = "Suivi du temps de recharge"
L["Transmission error"] = "Erreur de transmission"
L["Trigger"] = "Déclencheur"
--[[Translation missing --]]
L["Trigger %i"] = "Trigger %i"
--[[Translation missing --]]
L["Trigger %s"] = "Trigger %s"
L["Trigger 1"] = "Déclencheur 1"
L["Trigger State Updater (Advanced)"] = [=[
Mise à jour de l'état du déclencheur (Avancé)]=]
L["Trigger Update"] = "Mise-à-jour du déclencheur"
L["Trigger:"] = "Déclencheur :"
--[[Translation missing --]]
L["Trivial (Low Level)"] = "Trivial (Low Level)"
L["True"] = "Vrai"
--[[Translation missing --]]
L["Trying to repair broken conditions in %s likely caused by a WeakAuras bug."] = "Trying to repair broken conditions in %s likely caused by a WeakAuras bug."
--[[Translation missing --]]
L["Twin Emperors"] = "Twin Emperors"
L["Type"] = "Type"
--[[Translation missing --]]
L["Unable to modernize aura '%s'. This is probably due to corrupt data or a bad migration, please report this to the WeakAuras team."] = "Unable to modernize aura '%s'. This is probably due to corrupt data or a bad migration, please report this to the WeakAuras team."
L["Unaffected"] = "Non-affecté"
L["Undefined"] = "Non-défini"
--[[Translation missing --]]
L["Unholy"] = "Unholy"
--[[Translation missing --]]
L["Unholy Rune #1"] = "Unholy Rune #1"
--[[Translation missing --]]
L["Unholy Rune #2"] = "Unholy Rune #2"
L["Unit"] = "Unité"
L["Unit Characteristics"] = "Caractéristique d'unité"
L["Unit Destroyed"] = "Unité détruite"
L["Unit Died"] = "Unité morte"
--[[Translation missing --]]
L["Unit Dissipates"] = "Unit Dissipates"
--[[Translation missing --]]
L["Unit Frame"] = "Unit Frame"
L["Unit Frames"] = "Cadre d'unité"
L["Unit is Unit"] = "L'unité est l'unité"
L["Unit Name"] = "Nom de l'Unité"
--[[Translation missing --]]
L["Unit Name/Realm"] = "Unit Name/Realm"
L["Units Affected"] = "Unités Concernés"
--[[Translation missing --]]
L["Units of affected Players in a table format"] = "Units of affected Players in a table format"
--[[Translation missing --]]
L["Units of unaffected Players in a table format"] = "Units of unaffected Players in a table format"
--[[Translation missing --]]
L["Unknown action %q"] = "Unknown action %q"
--[[Translation missing --]]
L["Unknown feature %q"] = "Unknown feature %q"
--[[Translation missing --]]
L["unknown location"] = "unknown location"
L["Unlimited"] = "Illimité"
--[[Translation missing --]]
L["Untrigger %s"] = "Untrigger %s"
L["Up"] = "Haut"
L["Up, then Centered Horizontal"] = "Haut, puis centrer horizontalement"
L["Up, then Left"] = "Haut, puis gauche"
L["Up, then Right"] = "Haut, puis droite"
--[[Translation missing --]]
L["Update Position"] = "Update Position"
L["Usage:"] = "Utilisation:"
L["Use /wa minimap to show the minimap icon again."] = "Utilisez /wa minimap pour afficher à nouveau l’icône de la mini-carte."
L["Use Custom Color"] = "Utiliser couleur personnalisée"
--[[Translation missing --]]
L["Use Legacy floor rounding"] = "Use Legacy floor rounding"
--[[Translation missing --]]
L["Use Texture"] = "Use Texture"
--[[Translation missing --]]
L["Use Watched Faction"] = "Use Watched Faction"
--[[Translation missing --]]
L["Uses UnitInRange() to check if in range. Matches default raid frames out of range behavior, which is between 25 to 40 yards depending on your class and spec."] = "Uses UnitInRange() to check if in range. Matches default raid frames out of range behavior, which is between 25 to 40 yards depending on your class and spec."
L["Using WeakAuras.clones is deprecated. Use WeakAuras.GetRegion(id, cloneId) instead."] = "L'utilisation de WeakAuras.clones est obsolète. Utilisez plutôt WeakAuras.GetRegion(id, cloneId)."
L["Using WeakAuras.regions is deprecated. Use WeakAuras.GetRegion(id) instead."] = "L'utilisation de WeakAuras.regions est obsolète. Utilisez plutôt WeakAuras.GetRegion(id)."
L["Vaelastrasz the Corrupt"] = "Vaelastrasz le Corrompu"
L["Versatility (%)"] = "Polyvalence (%)"
L["Versatility Rating"] = "Score de Polyvalence"
L["Vertical"] = "Verticale"
L["Viscidus"] = "Viscidus"
L["Visibility"] = "Visibilité"
L["Visions of N'Zoth"] = "Visions de N'Zoth"
--[[Translation missing --]]
L["Warband Quantity Total"] = "Warband Quantity Total"
--[[Translation missing --]]
L["Warband Transfer Percentage"] = "Warband Transfer Percentage"
--[[Translation missing --]]
L["Warband Transferred Quantity"] = "Warband Transferred Quantity"
L["Warfront (Heroic)"] = "Front de guerre (Héroïque)"
L["Warfront (Normal)"] = "Front de guerre (Normal)"
L["Warlords of Draenor"] = "Warlords of Draenor"
L["Warning"] = "Attention"
--[[Translation missing --]]
L["Warning for unknown aura:"] = "Warning for unknown aura:"
--[[Translation missing --]]
L["Warning: Anchoring in aura '%s' is imposssible, due to an anchoring cycle"] = "Warning: Anchoring in aura '%s' is imposssible, due to an anchoring cycle"
L["Warning: Full Scan auras checking for both name and spell id can't be converted."] = "Avertissement : Les auras à balayage complet vérifiant à la fois le nom et l'identifiant du sort ne peuvent pas être converties."
--[[Translation missing --]]
L["Warning: Name info is now available via %affected, %unaffected. Number of affected group members via %unitCount. Some options behave differently now. This is not automatically adjusted."] = "Warning: Name info is now available via %affected, %unaffected. Number of affected group members via %unitCount. Some options behave differently now. This is not automatically adjusted."
--[[Translation missing --]]
L["Warning: Tooltip values are now available via %tooltip1, %tooltip2, %tooltip3 instead of %s. This is not automatically adjusted."] = "Warning: Tooltip values are now available via %tooltip1, %tooltip2, %tooltip3 instead of %s. This is not automatically adjusted."
--[[Translation missing --]]
L["WeakAuras Built-In (63:42 | 3:07 | 10 | 2.4)"] = "WeakAuras Built-In (63:42 | 3:07 | 10 | 2.4)"
--[[Translation missing --]]
L["WeakAuras has detected empty settings. If this is unexpected, ask for assitance on https://discord.gg/weakauras."] = "WeakAuras has detected empty settings. If this is unexpected, ask for assitance on https://discord.gg/weakauras."
--[[Translation missing --]]
L[ [=[WeakAuras has detected that it has been downgraded.
Your saved auras may no longer work properly.
Would you like to run the |cffff0000EXPERIMENTAL|r repair tool? This will overwrite any changes you have made since the last database upgrade.
Last upgrade: %s

|cffff0000You should BACKUP your WTF folder BEFORE pressing this button.|r]=] ] = [=[WeakAuras has detected that it has been downgraded.
Your saved auras may no longer work properly.
Would you like to run the |cffff0000EXPERIMENTAL|r repair tool? This will overwrite any changes you have made since the last database upgrade.
Last upgrade: %s

|cffff0000You should BACKUP your WTF folder BEFORE pressing this button.|r]=]
--[[Translation missing --]]
L["WeakAuras is creating a rollback snapshot of your auras. This snapshot will allow you to revert to the current state of your auras if something goes wrong. This process may cause your framerate to drop until it is complete."] = "WeakAuras is creating a rollback snapshot of your auras. This snapshot will allow you to revert to the current state of your auras if something goes wrong. This process may cause your framerate to drop until it is complete."
--[[Translation missing --]]
L["WeakAuras Profiling"] = "WeakAuras Profiling"
--[[Translation missing --]]
L["WeakAuras Profiling Report"] = "WeakAuras Profiling Report"
--[[Translation missing --]]
L["WeakAuras Version: %s"] = "WeakAuras Version: %s"
L["Weapon"] = "Arme"
L["Weapon Enchant"] = "Enchantement d'arme"
--[[Translation missing --]]
L["Weapon Enchant / Fishing Lure"] = "Weapon Enchant / Fishing Lure"
L["Whisper"] = "Chuchoter"
L["Width"] = "Largeur"
L["Wobble"] = "Osciller"
L["World Boss"] = "Boss de Monde"
--[[Translation missing --]]
L["World Bosses"] = "World Bosses"
L["Wrap"] = "Emballage, absorbe"
--[[Translation missing --]]
L["Wrath of the Lich King"] = "Wrath of the Lich King"
--[[Translation missing --]]
L["Writing to the WeakAuras table is not allowed."] = "Writing to the WeakAuras table is not allowed."
L["X-Offset"] = "Décalage X"
L["Yell"] = "Crier"
L["Y-Offset"] = "Décalage Y"
--[[Translation missing --]]
L["You have new auras ready to be installed!"] = "You have new auras ready to be installed!"
--[[Translation missing --]]
L["Your next encounter will automatically be profiled."] = "Your next encounter will automatically be profiled."
--[[Translation missing --]]
L["Your next instance of combat will automatically be profiled."] = "Your next instance of combat will automatically be profiled."
--[[Translation missing --]]
L["Your scheduled automatic profile has been cancelled."] = "Your scheduled automatic profile has been cancelled."
--[[Translation missing --]]
L["Your threat as a percentage of the tank's current threat."] = "Your threat as a percentage of the tank's current threat."
L["Your threat on the mob as a percentage of the amount required to pull aggro. Will pull aggro at 100."] = "Votre menace sur le monstre en pourcentage du montant requis pour attirer l'aggro. Monte l'aggro à 100."
L["Your total threat on the mob."] = "Votre menace totale sur le monstre."
L["Zone Group ID"] = "Zone Groupe ID"
L["Zone ID"] = "Zone ID"
L["Zone Name"] = "Nom de la zone"
L["Zoom"] = "Zoom"
--[[Translation missing --]]
L["Zoom Animation"] = "Zoom Animation"
L["Zul'Gurub"] = "Zul'Gurub"