if (GAME_LOCALE or GetLocale()) ~= "itIT" then
  return
end

local L = WeakAuras.L

-- WeakAuras
--[[Translation missing --]]
L[ [=[ Filter formats: 'Name', 'Name-Realm', '-Realm'. 

Supports multiple entries, separated by commas
Can use \ to escape -.]=] ] = [=[ Filter formats: 'Name', 'Name-Realm', '-Realm'. 

Supports multiple entries, separated by commas
Can use \ to escape -.]=]
L["%s Overlay Color"] = "%s Colore Overlay"
L["* Suffix"] = "* Suffisso"
L["/wa help - Show this message"] = "/wa help - Mostra questo messaggio"
L["/wa minimap - Toggle the minimap icon"] = "/wa minimap - Mostra/Nascondi l'icona della minimappa"
L["/wa pprint - Show the results from the most recent profiling"] = "/wa pprint - Mostra i risultati del più recente profiling"
L["/wa pstart - Start profiling. Optionally include a duration in seconds after which profiling automatically stops. To profile the next combat/encounter, pass a \"combat\" or \"encounter\" argument."] = "/wa pstart - Inizia il profiling. Si può includere una durata in secondi dopo la quale il profiling termina automaticamente. Per profilare il prossimo combattimento, passare un argomento ''combat'' o ''encounter''."
L["/wa pstop - Finish profiling"] = "/wa pstop - Termina il profiling"
L["/wa repair - Repair tool"] = "/wa riparazione - Strumento di riparazione"
L["|cffeda55fLeft-Click|r to toggle showing the main window."] = "|cffeda55fClick Sinistro|r per mostrare/nascondere la finestra principale."
L["|cffeda55fMiddle-Click|r to toggle the minimap icon on or off."] = "|cffeda55fClick Centrale|r per mostrare/nascondere l'icona della minimappa."
L["|cffeda55fRight-Click|r to toggle performance profiling window."] = "|cffeda55fFare clic con il pulsante destro del mouse|r per attivare/disattivare la finestra di profilazione delle prestazioni."
L["|cffeda55fShift-Click|r to pause addon execution."] = "|cffeda55fShift Click|r per mettere in pausa l'addon."
--[[Translation missing --]]
L["|cffff0000deprecated|r"] = "|cffff0000deprecated|r"
L["|cFFFF0000Not|r Item Bonus Id Equipped"] = "|cFFFF0000Not|r Bonus Id oggetto equipaggiato"
L["|cFFFF0000Not|r Item Equipped"] = "|cFFFF0000Not|r Oggetto Equipaggiato "
L["|cFFFF0000Not|r Player Name/Realm"] = "|cFFFF0000Not|r Nome Giocatore/Reame"
L["|cFFFF0000Not|r Spell Known"] = "|cFFFF0000Not|r Incantesimo Conosciuto"
--[[Translation missing --]]
L[ [=[|cFFFF0000Support for unfiltered COMBAT_LOG_EVENT_UNFILTERED is deprecated|r
COMBAT_LOG_EVENT_UNFILTERED without a filter are disabled as it’s very performance costly.
Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers#events]=] ] = [=[|cFFFF0000Support for unfiltered COMBAT_LOG_EVENT_UNFILTERED is deprecated|r
COMBAT_LOG_EVENT_UNFILTERED without a filter are disabled as it’s very performance costly.
Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Custom-Triggers#events]=]
L["|cFFffcc00Extra Options:|r %s"] = "|cFFffcc00Opzioni Extra:|r %s"
L["|cFFffcc00Extra Options:|r None"] = "|cFFffcc00Opzioni Extra:|r Nessuna"
L[ [=[• |cff00ff00Player|r, |cff00ff00Target|r, |cff00ff00Focus|r, and |cff00ff00Pet|r correspond directly to those individual unitIDs.
• |cff00ff00Specific Unit|r lets you provide a specific valid unitID to watch.
|cffff0000Note|r: The game will not fire events for all valid unitIDs, making some untrackable by this trigger.
• |cffffff00Party|r, |cffffff00Raid|r, |cffffff00Boss|r, |cffffff00Arena|r, and |cffffff00Nameplate|r can match multiple corresponding unitIDs.
• |cffffff00Smart Group|r adjusts to your current group type, matching just the "player" when solo, "party" units (including "player") in a party or "raid" units in a raid.

|cffffff00*|r Yellow Unit settings will create clones for each matching unit while this trigger is providing Dynamic Info to the Aura.]=] ] = "• |cff00ff00Player|r, |cff00ff00Target|r, |cff00ff00Focus|r e |cff00ff00Pet|r corrispondono direttamente a quei singoli unitID.  • |cff00ff00Unità specifica|r consente di fornire uno specifico ID unità valido da guardare.  |cffff0000Nota|r: il gioco non attiverà eventi per tutti gli unitID validi, rendendone alcuni non tracciabili da questa attivazione.  • |cffffff00Party|r, |cffffff00Raid|r, |cffffff00Boss|r, |cffffff00Arena|r e |cffffff00Nameplate|r possono corrispondere a più ID unità corrispondenti.  • |cffffff00Smart Group|r si adatta al tipo di gruppo corrente, abbinando solo il \"giocatore\" in modalità solista, le unità \"party\" (incluso il \"giocatore\") in un party o le unità \"raid\" in un raid.  |cffffff00*|r Le impostazioni dell'unità gialla creeranno cloni per ciascuna unità corrispondente mentre questa attivazione fornisce informazioni dinamiche all'aura."
L["1. Profession 1. Accessory"] = "1. Professione 1. Accessorio"
L["1. Profession 2. Accessory"] = "1. Professione 2. Accessorio"
L["1. Professsion Tool"] = "1. Strumento Professione "
L["10 Man Raid"] = "Incursione da 10 giocatori"
L["10 Player Raid"] = "Raid da 10 giocatori"
L["10 Player Raid (Heroic)"] = "Raid da 10 giocatori (Eroico)"
L["10 Player Raid (Normal)"] = "Raid da 10 giocatori (Normale)"
L["2. Profession 1. Accessory"] = "2. Professione 1. Accessorio"
L["2. Profession 2. Accessory"] = "2. Professione 2. Accessorio"
L["2. Professsion Tool"] = "2. Strumento Professione"
L["20 Man Raid"] = "incursione da 20 giocatori"
L["20 Player Raid"] = "Raid da 20 giocatori"
L["25 Man Raid"] = "Incursione da 25 giocatori"
L["25 Player Raid"] = "Raid da 25 giocatori"
L["25 Player Raid (Heroic)"] = "Raid da 25 giocatori (Eroico)"
L["25 Player Raid (Normal)"] = "Raid da 25 giocatori (Normale)"
L["40 Man Raid"] = "incursione da 40 giocatori"
L["40 Player Raid"] = "Raid da 40 giocatori"
L["5 Man Dungeon"] = "Spedizione da 5 giocatori"
L[ [=[A detailed overview of your auras and WeakAuras systems
Copy the whole text to Weakaura's Discord if you need assistance.]=] ] = "Una panoramica dettagliata delle tue aure e dei sistemi WeakAuras, Copia l'intero testo su Discord di Weakaura se hai bisogno di assistenza."
--[[Translation missing --]]
L["A trigger in this aura is set up to track a soft target unit, but you don't have the CVars set up for this to work correctly. Consider either changing the unit tracked, or configuring the Soft Target CVars."] = "A trigger in this aura is set up to track a soft target unit, but you don't have the CVars set up for this to work correctly. Consider either changing the unit tracked, or configuring the Soft Target CVars."
L["Abbreviate"] = "Abbreviare"
L["AbbreviateLargeNumbers (Blizzard)"] = "AbbreviareGrandiNumeri (Blizzard)"
L["AbbreviateNumbers (Blizzard)"] = "Abbreviare i numeri (Blizzard)"
L["Absorb"] = "Assorbimento"
--[[Translation missing --]]
L["Absorb and Healing"] = "Absorb and Healing"
L["Absorb Heal Overlay"] = "Assorbe la copertura di guarigione"
--[[Translation missing --]]
L["Absorb Overlay"] = "Absorb Overlay"
L["Absorbed"] = "Assorbito"
L["Action Button Glow"] = "Bagliore Pulsante Azioni"
L["Actions"] = "Azioni"
L["Active"] = "Attivo"
L[ [=[Active boss mod addon: |cFFffcc00BigWigs|r

Note: This trigger will use BigWigs or DBM, in that order if both are installed.]=] ] = "Componente aggiuntivo mod boss attivo: |cFFffcc00BigWigs|r Nota: Questa attivazione utilizzerà BigWigs o DBM, in quest'ordine se entrambi sono installati."
L[ [=[Active boss mod addon: |cFFffcc00DBM|r

Note: This trigger will use BigWigs or DBM, in that order if both are installed.]=] ] = "Componente aggiuntivo mod boss attivo: |cFFffcc00DBM|r Nota: questa attivazione utilizzerà BigWigs o DBM, in quest'ordine se entrambi sono installati."
L["Add"] = "Aggiungi"
L["Add Missing Auras"] = "Aggiungi Aure Mancanti"
L["Advanced Caster's Target Check"] = "Controllo del bersaglio dell'incantatore avanzato"
L["Affected"] = "Affetto"
L["Affected Unit Count"] = "Conta Unità Interessate"
--[[Translation missing --]]
L["Afk"] = "Afk"
L["Aggro"] = "Aggro"
L["Agility"] = "Agilità"
L["Ahn'Qiraj"] = "Ahn'Qiraj"
L["Alert Type"] = "Tipo di Allerta"
L["Alive"] = "Vivo"
L["All"] = "Tutto"
L["All children of this aura will also not be loaded, to minimize the chance of further corruption."] = "Anche tutti i bambini di quest'aura non verranno caricati, per ridurre al minimo la possibilità di ulteriore corruzione."
--[[Translation missing --]]
L["All States table contains a non table at key: '%s'."] = "All States table contains a non table at key: '%s'."
L["All Triggers"] = "Tutte le attivazioni"
L["Alliance"] = "Alleanza"
L["Allow partial matches"] = "Permetti corrispondenze parziali"
L["Alpha"] = "Alfa"
L["Alternate Power"] = "Risorse Speciali"
L["Always"] = "Sempre"
L["Always active trigger"] = "Innesco sempre attivo"
L["Always include realm"] = "Includi sempre il reame"
L["Always True"] = "Sempre Vero"
L["Amount"] = "Quantità"
L["Anchoring"] = "Ancoraggio"
L["And Talent"] = "E Talento "
L["Angle and Radius"] = "Angolo e Raggio"
L["Animations"] = "Animazioni"
L["Anticlockwise"] = "Antiorario"
--[[Translation missing --]]
L["Anub'Rekhan"] = "Anub'Rekhan"
L["Any"] = "Qualsiasi"
L["Any Triggers"] = "Qualsiasi attivazione"
--[[Translation missing --]]
L["AOE"] = "AOE"
L["Arcane Resistance"] = "Resistenza Arcana"
L[ [=[Are you sure you want to run the |cffff0000EXPERIMENTAL|r repair tool?
This will overwrite any changes you have made since the last database upgrade.
Last upgrade: %s]=] ] = "Vuoi eseguire lo strumento di riparazione |cffff0000EXPERIMENTAL|r? Ciò sovrascriverà tutte le modifiche apportate dall'ultimo aggiornamento del database. Ultimo aggiornamento: %s"
L["Arena"] = "Arena"
L["Armor (%)"] = "Armatura (%)"
L["Armor against Target (%)"] = "Armatura contro il bersaglio (%)"
L["Armor Rating"] = "Grado di armatura"
--[[Translation missing --]]
L["Array"] = "Array"
L["Ascending"] = "Crescente"
L["Assigned Role"] = "Ruolo assegnato"
L["Assigned Role Icon"] = "Icona del ruolo assegnato"
--[[Translation missing --]]
L["Assist"] = "Assist"
--[[Translation missing --]]
L["Assisted Combat Next Cast"] = "Assisted Combat Next Cast"
L["At Least One Enemy"] = "Almeno un nemico"
L["At missing Value"] = "Al valore mancante"
L["At Percent"] = "In Percentuale"
L["At Value"] = "Al valore"
L["At War"] = "In guerra"
L["Attach to End"] = "Aggiungi alla Fine"
--[[Translation missing --]]
L["Attach to End, backwards"] = "Attach to End, backwards"
--[[Translation missing --]]
L["Attach to Point"] = "Attach to Point"
L["Attach to Start"] = "Aggiungi all'inizio"
L["Attack Power"] = "Potenza d'attacco"
L["Attackable"] = "Attaccabile"
L["Attackable Target"] = "Bersaglio attaccabile"
L["Aura"] = "Aura"
--[[Translation missing --]]
L["Aura '%s': %s"] = "Aura '%s': %s"
L["Aura Applied"] = "Aura applicata"
L["Aura Applied Dose"] = "Parte di aura applicata"
L["Aura Broken"] = "Aura finita"
L["Aura Broken Spell"] = "Aura di magia finita"
L["Aura is using deprecated SetDurationInfo"] = "Aura utilizza SetDurationInfo deprecato"
L["Aura loaded"] = "Aura caricata"
L["Aura Name"] = "Nome Aura"
L["Aura Names"] = "Nomi Aura"
L["Aura Refresh"] = "Aura rinnovata"
L["Aura Removed"] = "Aura rimossa"
L["Aura Removed Dose"] = "Parte di aura rimossa"
L["Aura Stack"] = "Aura Stack"
L["Aura Type"] = "Tipo di aura"
L["Aura Version: %s"] = "Versione dell'aura: %s"
L["Aura(s) Found"] = "Aura(e) Trovata(e)"
L["Aura(s) Missing"] = "Aura(e) Mancante(i)"
L["Aura:"] = "Aura:"
L["Auras"] = "Aure"
L["Auras:"] = "Aure:"
L["Author Options"] = "Opzioni Autore"
--[[Translation missing --]]
L["Auto"] = "Auto"
--[[Translation missing --]]
L["Autocast Shine"] = "Autocast Shine"
L["Automatic"] = "Automatico"
L["Automatic Length"] = "Lunghezza Automatica"
L["Automatic Rotation"] = "Rotazione Automatica"
L["Available features: %s"] = "Funzionalità disponibili: %s"
L["Avoidance (%)"] = "Elusione (%)"
L["Avoidance Rating"] = "Grado di Elusione"
L["Ayamiss the Hunter"] = "Ayamiss il Cacciatore"
--[[Translation missing --]]
L["Azuregos"] = "Azuregos"
L["Back and Forth"] = "Avanti e indietro"
L["Background"] = "Sfondo"
L["Background Color"] = "Colore Sfondo"
--[[Translation missing --]]
L["Balnazzar"] = "Balnazzar"
L["Bar Color/Gradient Start"] = "Inizio Colore/Inclinazione della Barra"
--[[Translation missing --]]
L["Bar enabled in BigWigs settings"] = "Bar enabled in BigWigs settings"
--[[Translation missing --]]
L["Bar enabled in Boss Mod addon settings"] = "Bar enabled in Boss Mod addon settings"
--[[Translation missing --]]
L["Bar enabled in DBM settings"] = "Bar enabled in DBM settings"
--[[Translation missing --]]
L["Bar Texture"] = "Bar Texture"
--[[Translation missing --]]
L["Bar Type"] = "Bar Type"
L["Baron Geddon"] = "Barone Geddon"
--[[Translation missing --]]
L["Battle for Azeroth"] = "Battle for Azeroth"
L["Battle.net Whisper"] = "Sussurri di Battle.net"
L["Battleground"] = "Campo di battaglia"
L["Battleguard Sartura"] = "Guardia di battaglia Sartura"
--[[Translation missing --]]
L["Beastmaster"] = "Beastmaster"
--[[Translation missing --]]
L["Beatrix"] = "Beatrix"
--[[Translation missing --]]
L["BG>Raid>Party>Say"] = "BG>Raid>Party>Say"
--[[Translation missing --]]
L["BG-System Alliance"] = "BG-System Alliance"
--[[Translation missing --]]
L["BG-System Horde"] = "BG-System Horde"
--[[Translation missing --]]
L["BG-System Neutral"] = "BG-System Neutral"
L["Big Number"] = "Grande Numero"
L["BigWigs Addon"] = "BigWigs Add-on"
L["BigWigs Message"] = "Messaggio di BigWigs"
--[[Translation missing --]]
L["BigWigs Stage"] = "BigWigs Stage"
L["BigWigs Timer"] = "Timer di BigWigs"
L["Black Wing Lair"] = "Sotterranei dell'Ala Nera"
--[[Translation missing --]]
L["Bleed"] = "Bleed"
L["Blizzard Combat Text"] = "Testo di combattimento Blizzard"
L["Blizzard Cooldown Reduction"] = "Riduzione Cooldown Blizzard"
L["Block"] = "Bloccare"
L["Block (%)"] = "Blocco (%)"
L["Block against Target (%)"] = "Blocco rispetto al target (%)"
L["Block Value"] = "Valore di Blocco"
L["Blocked"] = "Bloccato"
L["Blood"] = "Sangue"
L["Blood Rune #1"] = "Runa del sangue n. 1"
L["Blood Rune #2"] = "Runa del sangue n.2"
L["Bloodlord Mandokir"] = "Signore del Sangue Mandokir"
L["Bonus Reputation Gain"] = "Guadagno di reputazione bonus"
L["Border"] = "Bordo"
L["Boss"] = "Boss"
L["Boss Emote"] = "Boss Emote"
--[[Translation missing --]]
L["Boss Mod Announce"] = "Boss Mod Announce"
--[[Translation missing --]]
L["Boss Mod Stage"] = "Boss Mod Stage"
--[[Translation missing --]]
L["Boss Mod Stage (Event)"] = "Boss Mod Stage (Event)"
--[[Translation missing --]]
L["Boss Mod Timer"] = "Boss Mod Timer"
--[[Translation missing --]]
L["Boss Whisper"] = "Boss Whisper"
L["Bottom"] = "Basso"
L["Bottom Left"] = "Basso a sinistra"
L["Bottom Right"] = "Basso a destra"
L["Bottom to Top"] = "Basso verso l'alto"
L["Bounce"] = "Balzo"
L["Bounce with Decay"] = "Bounce with Decay"
--[[Translation missing --]]
L["Break"] = "Break"
--[[Translation missing --]]
L["BreakUpLargeNumbers (Blizzard)"] = "BreakUpLargeNumbers (Blizzard)"
L["Broodlord Lashlayer"] = "Signore della Progenie Lashlayer"
L["Buff"] = "Buff"
--[[Translation missing --]]
L["Buff/Debuff"] = "Buff/Debuff"
L["Buffed/Debuffed"] = "Buffato/Debuffato"
--[[Translation missing --]]
L["Burning Crusade"] = "Burning Crusade"
--[[Translation missing --]]
L["Buru the Gorger"] = "Buru the Gorger"
--[[Translation missing --]]
L["Caldoran"] = "Caldoran"
L["Callback function"] = "Funzione di richiamata"
L["Can be used for e.g. checking if \"boss1target\" is the same as \"player\"."] = "Può essere usato per esempio per controllare se \"boss1target\" sia uguale a \"player\"."
L["Cancel"] = "Cancella"
L[ [=[Cannot change secure frame in combat lockdown. Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames]=] ] = "Non è possibile modificare il frame protetto durante il blocco del combattimento. Trova ulteriori informazioni: https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames"
L["Can't schedule timer with %i, due to a World of Warcraft bug with high computer uptime. (Uptime: %i). Please restart your computer."] = "Impossibile programmare il timer con %i, a causa di un bug di World of Warcraft con tempi di attività elevati del computer.  (Tempo di attività: %i).  Riavvia il computer."
L["Capped"] = "Limitato"
L["Capped at Season Max"] = "Limitato alla stagione massima"
L["Capped at Weekly Max"] = "Limitato al massimo settimanale"
L["Cast"] = "Cast"
L["Cast Bar"] = "Barra del cast"
L["Cast Failed"] = "Cast fallito"
L["Cast Start"] = "Inizio cast"
L["Cast Success"] = "Cast terminato con successo"
L["Cast Type"] = "Tipo di cast"
--[[Translation missing --]]
L["Caster"] = "Caster"
L["Caster Name"] = "Nome del Caster"
L["Caster Realm"] = "Reame del Caster"
L["Caster Unit"] = "Unità del Caster"
L["Casters Name/Realm"] = "Nome/Reame dei Caster"
L["Caster's Target"] = "Bersaglio dei Caster"
--[[Translation missing --]]
L["Cataclysm"] = "Cataclysm"
--[[Translation missing --]]
L["Ceil"] = "Ceil"
L["Center"] = "Centro"
L["Center, then alternating bottom and top"] = "Al centro, poi alternando il basso e l'alto"
L["Center, then alternating left and right"] = "Al centro, poi alternando sinistra e destra"
L["Center, then alternating right and left"] = "Al centro, poi alternando destra e sinistra"
L["Center, then alternating top and bottom"] = "Al centro, poi alternando la parte superiore e quella inferiore"
L["Centered Horizontal"] = "Centrato orizzontalmente"
L["Centered Horizontal, then Centered Vertical"] = "Centrato orizzontalmente, poi centrato verticalmente"
L["Centered Horizontal, then Down"] = "Centrato orizzontalmente, poi in basso"
L["Centered Horizontal, then Up"] = "Centrato orizzontalmente, poi in alto"
L["Centered Vertical"] = "Centrato verticalmente"
L["Centered Vertical, then Centered Horizontal"] = "Centrato verticalmente, poi centrato orizzontalmente "
L["Centered Vertical, then Left"] = "Centrato verticalmente, poi a sinistra"
L["Centered Vertical, then Right"] = "Centrato verticalmente, poi a destra"
L["Changed"] = "Modificato"
L["Channel"] = "Canale"
L["Channel (Spell)"] = "Canale (Magia)"
--[[Translation missing --]]
L["Character GUID"] = "Character GUID"
--[[Translation missing --]]
L["Character Name"] = "Character Name"
L["Character Stats"] = "Statistiche del Personaggio "
--[[Translation missing --]]
L["Character Transferred Quantity"] = "Character Transferred Quantity"
L["Character Type"] = "Tipo di carattere"
L["Charge gained/lost"] = "Carica guadagnata/persa"
--[[Translation missing --]]
L["Charged Combo Points"] = "Charged Combo Points"
L["Charges"] = "Cariche"
L["Charges Changed Event"] = "Evento modificato caricato"
L["Charging"] = "In carica"
L["Chat Frame"] = "Cornice di chat"
L["Chat Message"] = "Messaggio di chat"
L["Check if a single talent match a Rank"] = "Controlla se un singolo talento corrisponde a un grado"
L["Check nameplate's target every 0.2s"] = "Controllare le barre del bersaglio ogni 0,2 s"
--[[Translation missing --]]
L["Chromaggus"] = "Chromaggus"
L["Circle"] = "Cerchio"
--[[Translation missing --]]
L["Circular Texture"] = "Circular Texture"
L["Clamp"] = "Morso"
L["Class"] = "Classe"
L["Class and Specialization"] = "Classe e Specializzazione"
--[[Translation missing --]]
L["Classic"] = "Classic"
L["Classification"] = "Classificazione"
L["Clockwise"] = "Senso Orario"
--[[Translation missing --]]
L["Clone per Character"] = "Clone per Character"
L["Clone per Event"] = "Clona per evento"
L["Clone per Match"] = "Clona per partita"
--[[Translation missing --]]
L["Coin Precision"] = "Coin Precision"
L["Color"] = "Colore"
L["Color Animation"] = "Animazione a colori"
L["Combat Log"] = "Registro di combattimento"
--[[Translation missing --]]
L["Communities"] = "Communities"
--[[Translation missing --]]
L["Condition Custom Test"] = "Condition Custom Test"
L["Conditions"] = "Condizioni"
L["Contains"] = "Contiene"
L["Continuously update Movement Speed"] = "Aggiorna continuamente la velocità di movimento"
--[[Translation missing --]]
L["Cooldown"] = "Cooldown"
L["Cooldown bars show time before an ability is ready to be use, BigWigs prefix them with '~'"] = "Le barre di Cooldown mostrano il tempo trascorso prima che un'abilità sia pronta per essere utilizzata, BigWigs le prefissa con '~'"
--[[Translation missing --]]
L["Cooldown Progress (Item)"] = "Cooldown Progress (Item)"
--[[Translation missing --]]
L["Cooldown Progress (Slot)"] = "Cooldown Progress (Slot)"
L["Cooldown Ready Event"] = "Cooldiwn evento pronto"
L["Cooldown Ready Event (Item)"] = "Cooldown evento pronto (Oggetto)"
L["Cooldown Ready Event (Slot)"] = "Cooldown evento pronto (Slot)"
L["Cooldown Reduction changes the duration of seconds instead of showing the real time seconds."] = "La riduzione del Cooldown modifica la durata dei secondi invece di mostrare i secondi in tempo reale."
L["Cooldown/Charges/Count"] = "Cooldown/Cariche/Conteggio "
--[[Translation missing --]]
L["Copper"] = "Copper"
L["Could not load WeakAuras Archive, the addon is %s"] = "Impossibile caricare l'archivio WeakAuras, il componente aggiuntivo è %s"
L["Count"] = "Conteggio "
L["Counter Clockwise"] = "Conteggio Antiorario"
L["Create"] = "Crea"
--[[Translation missing --]]
L["Creature Family"] = "Creature Family"
--[[Translation missing --]]
L["Creature Family Name"] = "Creature Family Name"
--[[Translation missing --]]
L["Creature Type"] = "Creature Type"
--[[Translation missing --]]
L["Creature Type Name"] = "Creature Type Name"
L["Critical"] = "Critico"
L["Critical (%)"] = "Critico (%)"
L["Critical Rating"] = "Grado del Critico"
--[[Translation missing --]]
L["Crop X"] = "Crop X"
--[[Translation missing --]]
L["Crop Y"] = "Crop Y"
--[[Translation missing --]]
L["Crowd Controlled"] = "Crowd Controlled"
L["Crushing"] = "Frantumazione "
--[[Translation missing --]]
L["C'thun"] = "C'thun"
L["Cumulated time used during profiling"] = "Tempo cumulativo utilizzato durante la profilazione"
L["Currency"] = "Corrente"
L["Current Essence"] = "Essenza Attuale"
L["Current Experience"] = "Esperienza Attuale"
L["Current Instance"] = "Spedizione Attuale "
L["Current Movement Speed (%)"] = "Velocità di movimento attuale (%)"
L["Current Stage"] = "Stage Attuale "
L["Current Zone"] = "Zona Attuale "
L["Current Zone Group"] = "Gruppo di Zona Attuale "
L["Curse"] = "Maledizione"
--[[Translation missing --]]
L["Custom"] = "Custom"
--[[Translation missing --]]
L["Custom Action"] = "Custom Action"
--[[Translation missing --]]
L["Custom Anchor"] = "Custom Anchor"
--[[Translation missing --]]
L["Custom Check"] = "Custom Check"
--[[Translation missing --]]
L["Custom Color"] = "Custom Color"
--[[Translation missing --]]
L["Custom Condition Code"] = "Custom Condition Code"
--[[Translation missing --]]
L["Custom Configuration"] = "Custom Configuration"
--[[Translation missing --]]
L["Custom Fade Animation"] = "Custom Fade Animation"
--[[Translation missing --]]
L["Custom Function"] = "Custom Function"
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
--[[Translation missing --]]
L["Damage"] = "Damage"
--[[Translation missing --]]
L["Damage Shield"] = "Damage Shield"
--[[Translation missing --]]
L["Damage Shield Missed"] = "Damage Shield Missed"
--[[Translation missing --]]
L["Damage Split"] = "Damage Split"
--[[Translation missing --]]
L["DBM Announce"] = "DBM Announce"
--[[Translation missing --]]
L["DBM Stage"] = "DBM Stage"
--[[Translation missing --]]
L["DBM Timer"] = "DBM Timer"
--[[Translation missing --]]
L["Dead"] = "Dead"
--[[Translation missing --]]
L["Death"] = "Death"
L["Death Knight Rune"] = "Rune del cavaliere della morte"
--[[Translation missing --]]
L["Debuff"] = "Debuff"
--[[Translation missing --]]
L["Debuff Class"] = "Debuff Class"
--[[Translation missing --]]
L["Debuff Class Icon"] = "Debuff Class Icon"
--[[Translation missing --]]
L["Debuff Type"] = "Debuff Type"
--[[Translation missing --]]
L["Debug Log contains more than 1000 entries"] = "Debug Log contains more than 1000 entries"
--[[Translation missing --]]
L["Debug Logging enabled"] = "Debug Logging enabled"
--[[Translation missing --]]
L["Debug Logging enabled for '%s'"] = "Debug Logging enabled for '%s'"
--[[Translation missing --]]
L["Defensive Stats"] = "Defensive Stats"
--[[Translation missing --]]
L["Deflect"] = "Deflect"
--[[Translation missing --]]
L["Delve"] = "Delve"
--[[Translation missing --]]
L["Desaturate"] = "Desaturate"
--[[Translation missing --]]
L["Desaturate Background"] = "Desaturate Background"
--[[Translation missing --]]
L["Desaturate Foreground"] = "Desaturate Foreground"
--[[Translation missing --]]
L["Descending"] = "Descending"
L["Description"] = "Descrizione"
--[[Translation missing --]]
L["Dest Raid Mark"] = "Dest Raid Mark"
--[[Translation missing --]]
L["Destination Affiliation"] = "Destination Affiliation"
--[[Translation missing --]]
L["Destination GUID"] = "Destination GUID"
--[[Translation missing --]]
L["Destination Info"] = "Destination Info"
--[[Translation missing --]]
L["Destination Name"] = "Destination Name"
--[[Translation missing --]]
L["Destination NPC Id"] = "Destination NPC Id"
--[[Translation missing --]]
L["Destination Object Type"] = "Destination Object Type"
--[[Translation missing --]]
L["Destination Reaction"] = "Destination Reaction"
--[[Translation missing --]]
L["Destination Unit"] = "Destination Unit"
--[[Translation missing --]]
L["Destination unit's raid mark index"] = "Destination unit's raid mark index"
--[[Translation missing --]]
L["Destination unit's raid mark texture"] = "Destination unit's raid mark texture"
--[[Translation missing --]]
L["Difficulty"] = "Difficulty"
--[[Translation missing --]]
L["Disable Spell Known Check"] = "Disable Spell Known Check"
--[[Translation missing --]]
L["Disabled"] = "Disabled"
--[[Translation missing --]]
L["Disabled feature %q"] = "Disabled feature %q"
--[[Translation missing --]]
L["Disabled Spell Known Check"] = "Disabled Spell Known Check"
--[[Translation missing --]]
L["Discovered"] = "Discovered"
--[[Translation missing --]]
L["Disease"] = "Disease"
--[[Translation missing --]]
L["Dispel"] = "Dispel"
--[[Translation missing --]]
L["Dispel Failed"] = "Dispel Failed"
--[[Translation missing --]]
L["Display"] = "Display"
L["Distance"] = "Distanza"
--[[Translation missing --]]
L["Do Not Disturb"] = "Do Not Disturb"
--[[Translation missing --]]
L["Dodge"] = "Dodge"
--[[Translation missing --]]
L["Dodge (%)"] = "Dodge (%)"
--[[Translation missing --]]
L["Dodge Rating"] = "Dodge Rating"
--[[Translation missing --]]
L["Down"] = "Down"
--[[Translation missing --]]
L["Down, then Centered Horizontal"] = "Down, then Centered Horizontal"
--[[Translation missing --]]
L["Down, then Left"] = "Down, then Left"
--[[Translation missing --]]
L["Down, then Right"] = "Down, then Right"
--[[Translation missing --]]
L["Dragonflight"] = "Dragonflight"
--[[Translation missing --]]
L["Drain"] = "Drain"
--[[Translation missing --]]
L["Dropdown Menu"] = "Dropdown Menu"
--[[Translation missing --]]
L["Dumping table"] = "Dumping table"
--[[Translation missing --]]
L["Dungeon (Celestial)"] = "Dungeon (Celestial)"
--[[Translation missing --]]
L["Dungeon (Heroic)"] = "Dungeon (Heroic)"
--[[Translation missing --]]
L["Dungeon (Mythic)"] = "Dungeon (Mythic)"
--[[Translation missing --]]
L["Dungeon (Mythic+)"] = "Dungeon (Mythic+)"
--[[Translation missing --]]
L["Dungeon (Normal)"] = "Dungeon (Normal)"
--[[Translation missing --]]
L["Dungeon (Timewalking)"] = "Dungeon (Timewalking)"
--[[Translation missing --]]
L["Dungeons"] = "Dungeons"
--[[Translation missing --]]
L["Durability Damage"] = "Durability Damage"
--[[Translation missing --]]
L["Durability Damage All"] = "Durability Damage All"
--[[Translation missing --]]
L["Duration"] = "Duration"
--[[Translation missing --]]
L["Duration Function"] = "Duration Function"
--[[Translation missing --]]
L["Duration Function (fallback state)"] = "Duration Function (fallback state)"
--[[Translation missing --]]
L["Ease In"] = "Ease In"
--[[Translation missing --]]
L["Ease In and Out"] = "Ease In and Out"
--[[Translation missing --]]
L["Ease Out"] = "Ease Out"
--[[Translation missing --]]
L["Ebonroc"] = "Ebonroc"
--[[Translation missing --]]
L["Eclipse Direction"] = "Eclipse Direction"
--[[Translation missing --]]
L["Edge"] = "Edge"
--[[Translation missing --]]
L["Edge of Madness"] = "Edge of Madness"
--[[Translation missing --]]
L["Effective Spell Id"] = "Effective Spell Id"
--[[Translation missing --]]
L["Elide"] = "Elide"
--[[Translation missing --]]
L["Elite"] = "Elite"
--[[Translation missing --]]
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
--[[Translation missing --]]
L["Empty"] = "Empty"
--[[Translation missing --]]
L["Enabled feature %q"] = "Enabled feature %q"
--[[Translation missing --]]
L["Enables (incorrect) round down of seconds, which was the previous default behavior."] = "Enables (incorrect) round down of seconds, which was the previous default behavior."
--[[Translation missing --]]
L["Enchant Applied"] = "Enchant Applied"
--[[Translation missing --]]
L["Enchant Found"] = "Enchant Found"
--[[Translation missing --]]
L["Enchant ID"] = "Enchant ID"
--[[Translation missing --]]
L["Enchant Missing"] = "Enchant Missing"
--[[Translation missing --]]
L["Enchant Name or ID"] = "Enchant Name or ID"
--[[Translation missing --]]
L["Enchant Removed"] = "Enchant Removed"
--[[Translation missing --]]
L["Enchanted"] = "Enchanted"
--[[Translation missing --]]
L["Encounter ID(s)"] = "Encounter ID(s)"
--[[Translation missing --]]
L["Energize"] = "Energize"
--[[Translation missing --]]
L["Enrage"] = "Enrage"
--[[Translation missing --]]
L["Enter a name or a spellId"] = "Enter a name or a spellId"
--[[Translation missing --]]
L["Entering"] = "Entering"
--[[Translation missing --]]
L["Entering/Leaving Combat"] = "Entering/Leaving Combat"
--[[Translation missing --]]
L["Entering/Leaving Encounter"] = "Entering/Leaving Encounter"
--[[Translation missing --]]
L["Entry Order"] = "Entry Order"
--[[Translation missing --]]
L["Environment Type"] = "Environment Type"
--[[Translation missing --]]
L["Environmental"] = "Environmental"
--[[Translation missing --]]
L["Equipment"] = "Equipment"
--[[Translation missing --]]
L["Equipment Set"] = "Equipment Set"
--[[Translation missing --]]
L["Equipment Set Equipped"] = "Equipment Set Equipped"
--[[Translation missing --]]
L["Equipment Slot"] = "Equipment Slot"
--[[Translation missing --]]
L["Equipped"] = "Equipped"
L["Error"] = "Errore"
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
--[[Translation missing --]]
L["Error Frame"] = "Error Frame"
--[[Translation missing --]]
L["ERROR in '%s' unknown or incompatible sub element type '%s'"] = "ERROR in '%s' unknown or incompatible sub element type '%s'"
--[[Translation missing --]]
L["Error in Aura '%s'"] = "Error in Aura '%s'"
--[[Translation missing --]]
L["Error not receiving display information from %s"] = "Error not receiving display information from %s"
--[[Translation missing --]]
L["Essence"] = "Essence"
--[[Translation missing --]]
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
--[[Translation missing --]]
L["Evade"] = "Evade"
L["Event"] = "Evento"
--[[Translation missing --]]
L["Event(s)"] = "Event(s)"
--[[Translation missing --]]
L["Every Frame"] = "Every Frame"
--[[Translation missing --]]
L["Every Frame (High CPU usage)"] = "Every Frame (High CPU usage)"
--[[Translation missing --]]
L["Evoker Essence"] = "Evoker Essence"
--[[Translation missing --]]
L["Exact Spell ID(s)"] = "Exact Spell ID(s)"
--[[Translation missing --]]
L["Execute Conditions"] = "Execute Conditions"
--[[Translation missing --]]
L["Experience (%)"] = "Experience (%)"
--[[Translation missing --]]
L["Expertise Bonus"] = "Expertise Bonus"
--[[Translation missing --]]
L["Expertise Rating"] = "Expertise Rating"
--[[Translation missing --]]
L["Extend Outside"] = "Extend Outside"
--[[Translation missing --]]
L["Extra Amount"] = "Extra Amount"
--[[Translation missing --]]
L["Extra Attacks"] = "Extra Attacks"
--[[Translation missing --]]
L["Extra Spell Id"] = "Extra Spell Id"
--[[Translation missing --]]
L["Extra Spell Name"] = "Extra Spell Name"
--[[Translation missing --]]
L["Faction"] = "Faction"
--[[Translation missing --]]
L["Faction Name"] = "Faction Name"
--[[Translation missing --]]
L["Faction Reputation"] = "Faction Reputation"
--[[Translation missing --]]
L["Fade Animation"] = "Fade Animation"
--[[Translation missing --]]
L["Fade In"] = "Fade In"
--[[Translation missing --]]
L["Fade Out"] = "Fade Out"
--[[Translation missing --]]
L["Fail Alert"] = "Fail Alert"
--[[Translation missing --]]
L["False"] = "False"
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
--[[Translation missing --]]
L["Fire Resistance"] = "Fire Resistance"
--[[Translation missing --]]
L["Firemaw"] = "Firemaw"
--[[Translation missing --]]
L["First"] = "First"
--[[Translation missing --]]
L["First Value of Tooltip Text"] = "First Value of Tooltip Text"
--[[Translation missing --]]
L["Fixed"] = "Fixed"
--[[Translation missing --]]
L["Fixed Names"] = "Fixed Names"
--[[Translation missing --]]
L["Fixed Size"] = "Fixed Size"
--[[Translation missing --]]
L["Flamegor"] = "Flamegor"
--[[Translation missing --]]
L["Flash"] = "Flash"
--[[Translation missing --]]
L["Flex Raid"] = "Flex Raid"
--[[Translation missing --]]
L["Flip"] = "Flip"
--[[Translation missing --]]
L["Floor"] = "Floor"
--[[Translation missing --]]
L["Focus"] = "Focus"
--[[Translation missing --]]
L["Follower Dungeon"] = "Follower Dungeon"
--[[Translation missing --]]
L["Font"] = "Font"
--[[Translation missing --]]
L["Font Size"] = "Font Size"
--[[Translation missing --]]
L["Forbidden function or table: %s"] = "Forbidden function or table: %s"
--[[Translation missing --]]
L["Foreground"] = "Foreground"
--[[Translation missing --]]
L["Foreground Color"] = "Foreground Color"
L["Form"] = "Forma"
--[[Translation missing --]]
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
--[[Translation missing --]]
L["Frequency"] = "Frequency"
--[[Translation missing --]]
L["Friendly"] = "Friendly"
--[[Translation missing --]]
L["Friendly Fire"] = "Friendly Fire"
--[[Translation missing --]]
L["Friendship Max Rank"] = "Friendship Max Rank"
--[[Translation missing --]]
L["Friendship Rank"] = "Friendship Rank"
--[[Translation missing --]]
L["Friendship Reputation"] = "Friendship Reputation"
--[[Translation missing --]]
L["Frost"] = "Frost"
--[[Translation missing --]]
L["Frost Resistance"] = "Frost Resistance"
--[[Translation missing --]]
L["Frost Rune #1"] = "Frost Rune #1"
--[[Translation missing --]]
L["Frost Rune #2"] = "Frost Rune #2"
--[[Translation missing --]]
L["Full"] = "Full"
--[[Translation missing --]]
L["Full Region"] = "Full Region"
--[[Translation missing --]]
L["Full/Empty"] = "Full/Empty"
--[[Translation missing --]]
L["Gahz'ranka"] = "Gahz'ranka"
--[[Translation missing --]]
L["Gained"] = "Gained"
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
--[[Translation missing --]]
L["Glancing"] = "Glancing"
--[[Translation missing --]]
L["Global Cooldown"] = "Global Cooldown"
--[[Translation missing --]]
L["Glow"] = "Glow"
--[[Translation missing --]]
L["Glow External Element"] = "Glow External Element"
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
--[[Translation missing --]]
L["Gradient"] = "Gradient"
--[[Translation missing --]]
L["Gradient Enabled"] = "Gradient Enabled"
--[[Translation missing --]]
L["Gradient End"] = "Gradient End"
--[[Translation missing --]]
L["Gradient Orientation"] = "Gradient Orientation"
--[[Translation missing --]]
L["Gradient Pulse"] = "Gradient Pulse"
--[[Translation missing --]]
L["Grand Widow Faerlina"] = "Grand Widow Faerlina"
--[[Translation missing --]]
L["Grid"] = "Grid"
--[[Translation missing --]]
L["Grobbulus"] = "Grobbulus"
--[[Translation missing --]]
L["Group"] = "Group"
--[[Translation missing --]]
L["Group Arrangement"] = "Group Arrangement"
--[[Translation missing --]]
L["Group Leader/Assist"] = "Group Leader/Assist"
--[[Translation missing --]]
L["Group Size"] = "Group Size"
--[[Translation missing --]]
L["Group Type"] = "Group Type"
--[[Translation missing --]]
L["Grow"] = "Grow"
--[[Translation missing --]]
L["GTFO Alert"] = "GTFO Alert"
--[[Translation missing --]]
L["Guardian"] = "Guardian"
--[[Translation missing --]]
L["Guild"] = "Guild"
--[[Translation missing --]]
L["Hakkar"] = "Hakkar"
--[[Translation missing --]]
L["Hardcore"] = "Hardcore"
--[[Translation missing --]]
L["Has Target"] = "Has Target"
--[[Translation missing --]]
L["Has Vehicle UI"] = "Has Vehicle UI"
--[[Translation missing --]]
L["HasPet"] = "HasPet"
--[[Translation missing --]]
L["Haste (%)"] = "Haste (%)"
--[[Translation missing --]]
L["Haste Rating"] = "Haste Rating"
--[[Translation missing --]]
L["Heal"] = "Heal"
--[[Translation missing --]]
L["Heal Absorb"] = "Heal Absorb"
--[[Translation missing --]]
L["Heal Absorbed"] = "Heal Absorbed"
--[[Translation missing --]]
L["Health"] = "Health"
--[[Translation missing --]]
L["Health (%)"] = "Health (%)"
--[[Translation missing --]]
L["Health Deficit"] = "Health Deficit"
--[[Translation missing --]]
L["Heigan the Unclean"] = "Heigan the Unclean"
--[[Translation missing --]]
L["Height"] = "Height"
--[[Translation missing --]]
L["Hero Talent"] = "Hero Talent"
--[[Translation missing --]]
L["Heroic Party"] = "Heroic Party"
--[[Translation missing --]]
L["Hide"] = "Hide"
--[[Translation missing --]]
L["Hide 0 cooldowns"] = "Hide 0 cooldowns"
--[[Translation missing --]]
L["Hide Timer Text"] = "Hide Timer Text"
--[[Translation missing --]]
L["High Damage"] = "High Damage"
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
--[[Translation missing --]]
L["Higher Than Tank"] = "Higher Than Tank"
--[[Translation missing --]]
L["Highest Spell Id"] = "Highest Spell Id"
--[[Translation missing --]]
L["Hit (%)"] = "Hit (%)"
--[[Translation missing --]]
L["Hit Rating"] = "Hit Rating"
--[[Translation missing --]]
L["Holy Resistance"] = "Holy Resistance"
--[[Translation missing --]]
L["Horde"] = "Horde"
--[[Translation missing --]]
L["Horizontal"] = "Horizontal"
--[[Translation missing --]]
L["Hostile"] = "Hostile"
--[[Translation missing --]]
L["Hostility"] = "Hostility"
--[[Translation missing --]]
L["Humanoid"] = "Humanoid"
--[[Translation missing --]]
L["Hybrid"] = "Hybrid"
--[[Translation missing --]]
L["Icon"] = "Icon"
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
--[[Translation missing --]]
L["Ignore Dead"] = "Ignore Dead"
--[[Translation missing --]]
L["Ignore Disconnected"] = "Ignore Disconnected"
--[[Translation missing --]]
L["Ignore Rune CD"] = "Ignore Rune CD"
--[[Translation missing --]]
L["Ignore Rune CDs"] = "Ignore Rune CDs"
--[[Translation missing --]]
L["Ignore Self"] = "Ignore Self"
--[[Translation missing --]]
L["Ignore Spell Cooldown/Charges"] = "Ignore Spell Cooldown/Charges"
--[[Translation missing --]]
L["Ignore Spell Override"] = "Ignore Spell Override"
--[[Translation missing --]]
L["Immune"] = "Immune"
--[[Translation missing --]]
L["Important"] = "Important"
--[[Translation missing --]]
L["Importing will start after combat ends."] = "Importing will start after combat ends."
--[[Translation missing --]]
L["In Combat"] = "In Combat"
--[[Translation missing --]]
L["In Encounter"] = "In Encounter"
--[[Translation missing --]]
L["In Group"] = "In Group"
--[[Translation missing --]]
L["In Party"] = "In Party"
--[[Translation missing --]]
L["In Pet Battle"] = "In Pet Battle"
--[[Translation missing --]]
L["In Raid"] = "In Raid"
--[[Translation missing --]]
L["In Range"] = "In Range"
--[[Translation missing --]]
L["In Vehicle"] = "In Vehicle"
--[[Translation missing --]]
L["In War Mode"] = "In War Mode"
--[[Translation missing --]]
L["Include Bank"] = "Include Bank"
--[[Translation missing --]]
L["Include Charges"] = "Include Charges"
--[[Translation missing --]]
L["Include Death Runes"] = "Include Death Runes"
--[[Translation missing --]]
L["Include Pets"] = "Include Pets"
--[[Translation missing --]]
L["Include War Band Bank"] = "Include War Band Bank"
--[[Translation missing --]]
L["Incoming Heal"] = "Incoming Heal"
--[[Translation missing --]]
L["Increase Precision Below"] = "Increase Precision Below"
--[[Translation missing --]]
L["Increases by one per stage or intermission."] = "Increases by one per stage or intermission."
--[[Translation missing --]]
L["Information"] = "Information"
--[[Translation missing --]]
L["Inherited"] = "Inherited"
--[[Translation missing --]]
L["Instakill"] = "Instakill"
--[[Translation missing --]]
L["Install the addons BugSack and BugGrabber for detailed error logs."] = "Install the addons BugSack and BugGrabber for detailed error logs."
--[[Translation missing --]]
L["Instance"] = "Instance"
--[[Translation missing --]]
L["Instance Difficulty"] = "Instance Difficulty"
--[[Translation missing --]]
L["Instance ID"] = "Instance ID"
--[[Translation missing --]]
L["Instance Id"] = "Instance Id"
--[[Translation missing --]]
L["Instance Info"] = "Instance Info"
--[[Translation missing --]]
L["Instance Name"] = "Instance Name"
--[[Translation missing --]]
L["Instance Size Type"] = "Instance Size Type"
--[[Translation missing --]]
L["Instance Type"] = "Instance Type"
--[[Translation missing --]]
L["Instructor Razuvious"] = "Instructor Razuvious"
--[[Translation missing --]]
L["Insufficient Resources"] = "Insufficient Resources"
--[[Translation missing --]]
L["Intellect"] = "Intellect"
--[[Translation missing --]]
L["Interrupt"] = "Interrupt"
--[[Translation missing --]]
L["Interrupt School"] = "Interrupt School"
--[[Translation missing --]]
L["Interrupted School Text"] = "Interrupted School Text"
--[[Translation missing --]]
L["Interruptible"] = "Interruptible"
--[[Translation missing --]]
L["Inverse"] = "Inverse"
--[[Translation missing --]]
L["Inverse Pet Behavior"] = "Inverse Pet Behavior"
--[[Translation missing --]]
L["Is Away from Keyboard"] = "Is Away from Keyboard"
--[[Translation missing --]]
L["Is Current Specialization"] = "Is Current Specialization"
--[[Translation missing --]]
L["Is Death Rune"] = "Is Death Rune"
--[[Translation missing --]]
L["Is Exactly"] = "Is Exactly"
--[[Translation missing --]]
L["Is Moving"] = "Is Moving"
--[[Translation missing --]]
L["Is Off Hand"] = "Is Off Hand"
--[[Translation missing --]]
L["Is Paragon Reputation"] = "Is Paragon Reputation"
--[[Translation missing --]]
L["Is Paused"] = "Is Paused"
--[[Translation missing --]]
L["is useable"] = "is useable"
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
--[[Translation missing --]]
L["Item"] = "Item"
--[[Translation missing --]]
L["Item Bonus Id"] = "Item Bonus Id"
--[[Translation missing --]]
L["Item Bonus Id Equipped"] = "Item Bonus Id Equipped"
--[[Translation missing --]]
L["Item Count"] = "Item Count"
--[[Translation missing --]]
L["Item Equipped"] = "Item Equipped"
--[[Translation missing --]]
L["Item Id"] = "Item Id"
--[[Translation missing --]]
L["Item in Range"] = "Item in Range"
--[[Translation missing --]]
L["Item Name"] = "Item Name"
--[[Translation missing --]]
L["Item Set Equipped"] = "Item Set Equipped"
--[[Translation missing --]]
L["Item Set Id"] = "Item Set Id"
--[[Translation missing --]]
L["Item Slot"] = "Item Slot"
--[[Translation missing --]]
L["Item Slot String"] = "Item Slot String"
--[[Translation missing --]]
L["Item Type"] = "Item Type"
--[[Translation missing --]]
L["Item Type Equipped"] = "Item Type Equipped"
--[[Translation missing --]]
L["ItemId"] = "ItemId"
--[[Translation missing --]]
L["Jin'do the Hexxer"] = "Jin'do the Hexxer"
--[[Translation missing --]]
L["Journal Stage"] = "Journal Stage"
--[[Translation missing --]]
L["Kazzak"] = "Kazzak"
--[[Translation missing --]]
L["Keep Inside"] = "Keep Inside"
--[[Translation missing --]]
L["Kel'Thuzad"] = "Kel'Thuzad"
--[[Translation missing --]]
L["Kurinnaxx"] = "Kurinnaxx"
--[[Translation missing --]]
L["Large"] = "Large"
--[[Translation missing --]]
L["Latency"] = "Latency"
--[[Translation missing --]]
L["Leader"] = "Leader"
--[[Translation missing --]]
L["Least remaining time"] = "Least remaining time"
--[[Translation missing --]]
L["Leaving"] = "Leaving"
--[[Translation missing --]]
L["Leech"] = "Leech"
--[[Translation missing --]]
L["Leech (%)"] = "Leech (%)"
--[[Translation missing --]]
L["Leech Rating"] = "Leech Rating"
--[[Translation missing --]]
L["Left"] = "Left"
--[[Translation missing --]]
L["Left to Right"] = "Left to Right"
--[[Translation missing --]]
L["Left, then Centered Vertical"] = "Left, then Centered Vertical"
--[[Translation missing --]]
L["Left, then Down"] = "Left, then Down"
--[[Translation missing --]]
L["Left, then Up"] = "Left, then Up"
--[[Translation missing --]]
L["Legacy Looking for Raid"] = "Legacy Looking for Raid"
--[[Translation missing --]]
L["Legacy RGB Gradient"] = "Legacy RGB Gradient"
--[[Translation missing --]]
L["Legacy RGB Gradient Pulse"] = "Legacy RGB Gradient Pulse"
--[[Translation missing --]]
L["Legion"] = "Legion"
--[[Translation missing --]]
L["Length"] = "Length"
--[[Translation missing --]]
L["Level"] = "Level"
--[[Translation missing --]]
L["LibSharedMedia"] = "LibSharedMedia"
--[[Translation missing --]]
L["Lillian Voss"] = "Lillian Voss"
--[[Translation missing --]]
L["Limited"] = "Limited"
--[[Translation missing --]]
L["Linear Texture"] = "Linear Texture"
--[[Translation missing --]]
L["Lines & Particles"] = "Lines & Particles"
--[[Translation missing --]]
L["Load Conditions"] = "Load Conditions"
--[[Translation missing --]]
L["Loatheb"] = "Loatheb"
--[[Translation missing --]]
L["Location"] = "Location"
--[[Translation missing --]]
L["Looking for Raid"] = "Looking for Raid"
--[[Translation missing --]]
L["Loop"] = "Loop"
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
--[[Translation missing --]]
L["Lost"] = "Lost"
--[[Translation missing --]]
L["Low Damage"] = "Low Damage"
--[[Translation missing --]]
L["Lower Than Tank"] = "Lower Than Tank"
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
--[[Translation missing --]]
L["Magic"] = "Magic"
--[[Translation missing --]]
L["Magmadar"] = "Magmadar"
--[[Translation missing --]]
L["Main Character"] = "Main Character"
--[[Translation missing --]]
L["Main Stat"] = "Main Stat"
--[[Translation missing --]]
L["Majordomo Executus"] = "Majordomo Executus"
--[[Translation missing --]]
L["Malformed WeakAuras link"] = "Malformed WeakAuras link"
--[[Translation missing --]]
L["Manual"] = "Manual"
--[[Translation missing --]]
L["Manual Icon"] = "Manual Icon"
--[[Translation missing --]]
L["Manual Rotation"] = "Manual Rotation"
--[[Translation missing --]]
L["Marked First"] = "Marked First"
--[[Translation missing --]]
L["Marked Last"] = "Marked Last"
--[[Translation missing --]]
L["Mason"] = "Mason"
--[[Translation missing --]]
L["Master"] = "Master"
--[[Translation missing --]]
L["Mastery (%)"] = "Mastery (%)"
--[[Translation missing --]]
L["Mastery Rating"] = "Mastery Rating"
--[[Translation missing --]]
L["Match Count"] = "Match Count"
--[[Translation missing --]]
L["Match Count per Unit"] = "Match Count per Unit"
--[[Translation missing --]]
L["Matches (Pattern)"] = "Matches (Pattern)"
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
--[[Translation missing --]]
L["Max Charges"] = "Max Charges"
--[[Translation missing --]]
L["Max Health"] = "Max Health"
--[[Translation missing --]]
L["Max Power"] = "Max Power"
--[[Translation missing --]]
L["Max Quantity"] = "Max Quantity"
--[[Translation missing --]]
L["Maximum Estimate"] = "Maximum Estimate"
--[[Translation missing --]]
L["Maximum Progress"] = "Maximum Progress"
--[[Translation missing --]]
L["Maximum time used on a single frame"] = "Maximum time used on a single frame"
--[[Translation missing --]]
L["Media"] = "Media"
--[[Translation missing --]]
L["Medium"] = "Medium"
--[[Translation missing --]]
L["Melee"] = "Melee"
--[[Translation missing --]]
L["Melee Haste (%)"] = "Melee Haste (%)"
--[[Translation missing --]]
L["Message"] = "Message"
--[[Translation missing --]]
L["Message Type"] = "Message Type"
--[[Translation missing --]]
L["Message type:"] = "Message type:"
--[[Translation missing --]]
L["Meta Data"] = "Meta Data"
--[[Translation missing --]]
L["Mine"] = "Mine"
--[[Translation missing --]]
L["Minimum Estimate"] = "Minimum Estimate"
--[[Translation missing --]]
L["Minimum Progress"] = "Minimum Progress"
--[[Translation missing --]]
L["Minus (Small Nameplate)"] = "Minus (Small Nameplate)"
--[[Translation missing --]]
L["Mirror"] = "Mirror"
--[[Translation missing --]]
L["Miscellaneous"] = "Miscellaneous"
--[[Translation missing --]]
L["Miss"] = "Miss"
--[[Translation missing --]]
L["Miss Type"] = "Miss Type"
--[[Translation missing --]]
L["Missed"] = "Missed"
--[[Translation missing --]]
L["Missing"] = "Missing"
--[[Translation missing --]]
L["Mists of Pandaria"] = "Mists of Pandaria"
--[[Translation missing --]]
L["Moam"] = "Moam"
--[[Translation missing --]]
L["Model"] = "Model"
--[[Translation missing --]]
L["Modern Blizzard (1h 3m | 3m 7s | 10s | 2.4)"] = "Modern Blizzard (1h 3m | 3m 7s | 10s | 2.4)"
--[[Translation missing --]]
L["Modernize"] = "Modernize"
--[[Translation missing --]]
L["Molten Core"] = "Molten Core"
--[[Translation missing --]]
L["Money"] = "Money"
--[[Translation missing --]]
L["Monochrome"] = "Monochrome"
--[[Translation missing --]]
L["Monochrome Outline"] = "Monochrome Outline"
--[[Translation missing --]]
L["Monochrome Thick Outline"] = "Monochrome Thick Outline"
--[[Translation missing --]]
L["Monster Emote"] = "Monster Emote"
--[[Translation missing --]]
L["Monster Party"] = "Monster Party"
--[[Translation missing --]]
L["Monster Say"] = "Monster Say"
--[[Translation missing --]]
L["Monster Whisper"] = "Monster Whisper"
--[[Translation missing --]]
L["Monster Yell"] = "Monster Yell"
--[[Translation missing --]]
L["Moon"] = "Moon"
--[[Translation missing --]]
L["Most remaining time"] = "Most remaining time"
--[[Translation missing --]]
L["Mounted"] = "Mounted"
--[[Translation missing --]]
L["Mouse Cursor"] = "Mouse Cursor"
--[[Translation missing --]]
L["Movement Speed Rating"] = "Movement Speed Rating"
--[[Translation missing --]]
L["Multi-target"] = "Multi-target"
--[[Translation missing --]]
L["Mythic Keystone"] = "Mythic Keystone"
--[[Translation missing --]]
L["Mythic+ Affix"] = "Mythic+ Affix"
--[[Translation missing --]]
L["Name"] = "Name"
--[[Translation missing --]]
L["Name Function"] = "Name Function"
--[[Translation missing --]]
L["Name Function (fallback state)"] = "Name Function (fallback state)"
--[[Translation missing --]]
L["Name of Caster's Target"] = "Name of Caster's Target"
--[[Translation missing --]]
L["Name of the (sub-)zone currently shown above the minimap."] = "Name of the (sub-)zone currently shown above the minimap."
--[[Translation missing --]]
L["Name(s)"] = "Name(s)"
--[[Translation missing --]]
L["Name/Realm of Caster's Target"] = "Name/Realm of Caster's Target"
--[[Translation missing --]]
L["Nameplate"] = "Nameplate"
--[[Translation missing --]]
L["Nameplates"] = "Nameplates"
--[[Translation missing --]]
L["Names of affected Players"] = "Names of affected Players"
--[[Translation missing --]]
L["Names of unaffected Players"] = "Names of unaffected Players"
--[[Translation missing --]]
L["Nature Resistance"] = "Nature Resistance"
--[[Translation missing --]]
L["Naxxramas"] = "Naxxramas"
--[[Translation missing --]]
L["Nefarian"] = "Nefarian"
--[[Translation missing --]]
L["Neutral"] = "Neutral"
--[[Translation missing --]]
L["Never"] = "Never"
--[[Translation missing --]]
L["Next Combat"] = "Next Combat"
--[[Translation missing --]]
L["Next Encounter"] = "Next Encounter"
--[[Translation missing --]]
L[ [=[No active boss mod addon detected.

Note: This trigger will use BigWigs or DBM, in that order if both are installed.]=] ] = [=[No active boss mod addon detected.

Note: This trigger will use BigWigs or DBM, in that order if both are installed.]=]
--[[Translation missing --]]
L["No Extend"] = "No Extend"
--[[Translation missing --]]
L["No Instance"] = "No Instance"
--[[Translation missing --]]
L["No Profiling information saved."] = "No Profiling information saved."
--[[Translation missing --]]
L["No Progress Information available."] = "No Progress Information available."
--[[Translation missing --]]
L["None"] = "None"
--[[Translation missing --]]
L["Non-player Character"] = "Non-player Character"
--[[Translation missing --]]
L["Normal"] = "Normal"
--[[Translation missing --]]
L["Normal Party"] = "Normal Party"
--[[Translation missing --]]
L["Not in Group"] = "Not in Group"
--[[Translation missing --]]
L["Not in Smart Group"] = "Not in Smart Group"
--[[Translation missing --]]
L["Not on Cooldown"] = "Not on Cooldown"
--[[Translation missing --]]
L["Not On Threat Table"] = "Not On Threat Table"
--[[Translation missing --]]
L["Note: Due to how complicated the swing timer behavior is and the lack of APIs from Blizzard, results are inaccurate in edge cases."] = "Note: Due to how complicated the swing timer behavior is and the lack of APIs from Blizzard, results are inaccurate in edge cases."
--[[Translation missing --]]
L["Note: 'Hide Alone' is not available in the new aura tracking system. A load option can be used instead."] = "Note: 'Hide Alone' is not available in the new aura tracking system. A load option can be used instead."
--[[Translation missing --]]
L["Note: The available text replacements for multi triggers match the normal triggers now."] = "Note: The available text replacements for multi triggers match the normal triggers now."
--[[Translation missing --]]
L["Note: This trigger internally stores the shapeshift position, and thus is incompatible with learning stances on the fly, like e.g. the Gladiator Rune."] = "Note: This trigger internally stores the shapeshift position, and thus is incompatible with learning stances on the fly, like e.g. the Gladiator Rune."
--[[Translation missing --]]
L["Note: This trigger relies on the WoW API, which returns incorrect information in some cases."] = "Note: This trigger relies on the WoW API, which returns incorrect information in some cases."
--[[Translation missing --]]
L["Note: This trigger type estimates the range to the hitbox of a unit. The actual range of friendly players is usually 3 yards more than the estimate. Range checking capabilities depend on your current class and known abilities as well as the type of unit being checked. Some of the ranges may also not work with certain NPCs.|n|n|cFFAAFFAAFriendly Units:|r %s|n|cFFFFAAAAHarmful Units:|r %s|n|cFFAAAAFFMiscellanous Units:|r %s"] = "Note: This trigger type estimates the range to the hitbox of a unit. The actual range of friendly players is usually 3 yards more than the estimate. Range checking capabilities depend on your current class and known abilities as well as the type of unit being checked. Some of the ranges may also not work with certain NPCs.|n|n|cFFAAFFAAFriendly Units:|r %s|n|cFFFFAAAAHarmful Units:|r %s|n|cFFAAAAFFMiscellanous Units:|r %s"
--[[Translation missing --]]
L["Noth the Plaguebringer"] = "Noth the Plaguebringer"
--[[Translation missing --]]
L["NPC"] = "NPC"
--[[Translation missing --]]
L["Npc ID"] = "Npc ID"
--[[Translation missing --]]
L["Number"] = "Number"
--[[Translation missing --]]
L["Number Affected"] = "Number Affected"
--[[Translation missing --]]
L["Object"] = "Object"
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
--[[Translation missing --]]
L["Officer"] = "Officer"
--[[Translation missing --]]
L["Offset from progress"] = "Offset from progress"
--[[Translation missing --]]
L["Offset Timer"] = "Offset Timer"
--[[Translation missing --]]
L["Old Blizzard (2h | 3m | 10s | 2.4)"] = "Old Blizzard (2h | 3m | 10s | 2.4)"
--[[Translation missing --]]
L["On Cooldown"] = "On Cooldown"
--[[Translation missing --]]
L["On Taxi"] = "On Taxi"
--[[Translation missing --]]
L["Only if on a different realm"] = "Only if on a different realm"
--[[Translation missing --]]
L["Only if Primary"] = "Only if Primary"
--[[Translation missing --]]
L["Onyxia"] = "Onyxia"
--[[Translation missing --]]
L["Opaque"] = "Opaque"
--[[Translation missing --]]
L["Option Group"] = "Option Group"
--[[Translation missing --]]
L["Options could not be loaded, the addon is %s"] = "Options could not be loaded, the addon is %s"
--[[Translation missing --]]
L["Options will finish loading after combat ends."] = "Options will finish loading after combat ends."
--[[Translation missing --]]
L["Options will open after the login process has completed."] = "Options will open after the login process has completed."
--[[Translation missing --]]
L["Or Talent"] = "Or Talent"
--[[Translation missing --]]
L["Orbit"] = "Orbit"
--[[Translation missing --]]
L["Orientation"] = "Orientation"
--[[Translation missing --]]
L["Ossirian the Unscarred"] = "Ossirian the Unscarred"
--[[Translation missing --]]
L["Other"] = "Other"
--[[Translation missing --]]
L["Other Addons"] = "Other Addons"
--[[Translation missing --]]
L["Other Events"] = "Other Events"
--[[Translation missing --]]
L["Ouro"] = "Ouro"
--[[Translation missing --]]
L["Outline"] = "Outline"
--[[Translation missing --]]
L["Over Energize"] = "Over Energize"
--[[Translation missing --]]
L["Overhealing"] = "Overhealing"
--[[Translation missing --]]
L["Overkill"] = "Overkill"
--[[Translation missing --]]
L["Overlay %s"] = "Overlay %s"
--[[Translation missing --]]
L["Overlay Charged Combo Points"] = "Overlay Charged Combo Points"
--[[Translation missing --]]
L["Overlay Cost of Casts"] = "Overlay Cost of Casts"
--[[Translation missing --]]
L["Overlay Latency"] = "Overlay Latency"
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
--[[Translation missing --]]
L["Parry"] = "Parry"
--[[Translation missing --]]
L["Parry (%)"] = "Parry (%)"
--[[Translation missing --]]
L["Parry Rating"] = "Parry Rating"
--[[Translation missing --]]
L["Party"] = "Party"
--[[Translation missing --]]
L["Party Kill"] = "Party Kill"
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
--[[Translation missing --]]
L["Paused"] = "Paused"
--[[Translation missing --]]
L["Periodic Spell"] = "Periodic Spell"
--[[Translation missing --]]
L["Personal Resource Display"] = "Personal Resource Display"
--[[Translation missing --]]
L["Pet"] = "Pet"
--[[Translation missing --]]
L["Pet Behavior"] = "Pet Behavior"
--[[Translation missing --]]
L["Pet Specialization"] = "Pet Specialization"
--[[Translation missing --]]
L["Pet Spell"] = "Pet Spell"
--[[Translation missing --]]
L["Pets only"] = "Pets only"
--[[Translation missing --]]
L["Phase"] = "Phase"
--[[Translation missing --]]
L["Pixel Glow"] = "Pixel Glow"
--[[Translation missing --]]
L["Placement"] = "Placement"
--[[Translation missing --]]
L["Placement %i"] = "Placement %i"
--[[Translation missing --]]
L["Placement Mode"] = "Placement Mode"
--[[Translation missing --]]
L["Play"] = "Play"
--[[Translation missing --]]
L["Player"] = "Player"
--[[Translation missing --]]
L["Player Character"] = "Player Character"
--[[Translation missing --]]
L["Player Class"] = "Player Class"
--[[Translation missing --]]
L["Player Effective Level"] = "Player Effective Level"
--[[Translation missing --]]
L["Player Experience"] = "Player Experience"
--[[Translation missing --]]
L["Player Faction"] = "Player Faction"
--[[Translation missing --]]
L["Player Level"] = "Player Level"
--[[Translation missing --]]
L["Player Location ID(s)"] = "Player Location ID(s)"
--[[Translation missing --]]
L["Player Money"] = "Player Money"
--[[Translation missing --]]
L["Player Name/Realm"] = "Player Name/Realm"
--[[Translation missing --]]
L["Player Race"] = "Player Race"
--[[Translation missing --]]
L["Player(s) Affected"] = "Player(s) Affected"
--[[Translation missing --]]
L["Player(s) Not Affected"] = "Player(s) Not Affected"
--[[Translation missing --]]
L["Player/Unit Info"] = "Player/Unit Info"
--[[Translation missing --]]
L["Players and Pets"] = "Players and Pets"
--[[Translation missing --]]
L["Poison"] = "Poison"
--[[Translation missing --]]
L["Power"] = "Power"
--[[Translation missing --]]
L["Power (%)"] = "Power (%)"
--[[Translation missing --]]
L["Power Deficit"] = "Power Deficit"
--[[Translation missing --]]
L["Power Type"] = "Power Type"
--[[Translation missing --]]
L["Precision"] = "Precision"
--[[Translation missing --]]
L["Preset"] = "Preset"
--[[Translation missing --]]
L["Primary Stats"] = "Primary Stats"
--[[Translation missing --]]
L["Princess Huhuran"] = "Princess Huhuran"
--[[Translation missing --]]
L["Print Profiling Results"] = "Print Profiling Results"
--[[Translation missing --]]
L["Proc Glow"] = "Proc Glow"
--[[Translation missing --]]
L["Profiling already started."] = "Profiling already started."
--[[Translation missing --]]
L["Profiling automatically started."] = "Profiling automatically started."
--[[Translation missing --]]
L["Profiling not running."] = "Profiling not running."
--[[Translation missing --]]
L["Profiling started."] = "Profiling started."
--[[Translation missing --]]
L["Profiling started. It will end automatically in %d seconds"] = "Profiling started. It will end automatically in %d seconds"
--[[Translation missing --]]
L["Profiling still running, stop before trying to print."] = "Profiling still running, stop before trying to print."
--[[Translation missing --]]
L["Profiling stopped."] = "Profiling stopped."
--[[Translation missing --]]
L["Progress"] = "Progress"
--[[Translation missing --]]
L["Progress Source"] = "Progress Source"
--[[Translation missing --]]
L["Progress Total"] = "Progress Total"
--[[Translation missing --]]
L["Progress Value"] = "Progress Value"
--[[Translation missing --]]
L["Pull"] = "Pull"
--[[Translation missing --]]
L["Pulse"] = "Pulse"
--[[Translation missing --]]
L["PvP Flagged"] = "PvP Flagged"
--[[Translation missing --]]
L["PvP Talent Selected"] = "PvP Talent Selected"
--[[Translation missing --]]
L["PvP Talent selected"] = "PvP Talent selected"
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
--[[Translation missing --]]
L["Radius"] = "Radius"
--[[Translation missing --]]
L["Ragnaros"] = "Ragnaros"
--[[Translation missing --]]
L["Raid"] = "Raid"
--[[Translation missing --]]
L["Raid (Heroic)"] = "Raid (Heroic)"
--[[Translation missing --]]
L["Raid (Mythic)"] = "Raid (Mythic)"
--[[Translation missing --]]
L["Raid (Normal)"] = "Raid (Normal)"
--[[Translation missing --]]
L["Raid (Timewalking)"] = "Raid (Timewalking)"
--[[Translation missing --]]
L["Raid Mark"] = "Raid Mark"
--[[Translation missing --]]
L["Raid Mark Icon"] = "Raid Mark Icon"
--[[Translation missing --]]
L["Raid Role"] = "Raid Role"
--[[Translation missing --]]
L["Raid Warning"] = "Raid Warning"
--[[Translation missing --]]
L["Raids"] = "Raids"
--[[Translation missing --]]
L["Range"] = "Range"
--[[Translation missing --]]
L["Range Check"] = "Range Check"
--[[Translation missing --]]
L["Ranged"] = "Ranged"
--[[Translation missing --]]
L["Rank"] = "Rank"
--[[Translation missing --]]
L["Rare"] = "Rare"
--[[Translation missing --]]
L["Rare Elite"] = "Rare Elite"
--[[Translation missing --]]
L["Rated Arena"] = "Rated Arena"
--[[Translation missing --]]
L["Rated Battleground"] = "Rated Battleground"
--[[Translation missing --]]
L["Raw Threat Percent"] = "Raw Threat Percent"
--[[Translation missing --]]
L["Razorgore the Untamed"] = "Razorgore the Untamed"
--[[Translation missing --]]
L["Ready Check"] = "Ready Check"
--[[Translation missing --]]
L["Reagent Quality"] = "Reagent Quality"
--[[Translation missing --]]
L["Reagent Quality Texture"] = "Reagent Quality Texture"
--[[Translation missing --]]
L["Realm"] = "Realm"
--[[Translation missing --]]
L["Realm Name"] = "Realm Name"
--[[Translation missing --]]
L["Realm of Caster's Target"] = "Realm of Caster's Target"
--[[Translation missing --]]
L["Reborn Council"] = "Reborn Council"
--[[Translation missing --]]
L["Receiving %s Bytes"] = "Receiving %s Bytes"
--[[Translation missing --]]
L["Receiving display information"] = "Receiving display information"
--[[Translation missing --]]
L["Reflect"] = "Reflect"
--[[Translation missing --]]
L["Region type %s not supported"] = "Region type %s not supported"
--[[Translation missing --]]
L["Relative"] = "Relative"
--[[Translation missing --]]
L["Relative X-Offset"] = "Relative X-Offset"
--[[Translation missing --]]
L["Relative Y-Offset"] = "Relative Y-Offset"
--[[Translation missing --]]
L["Remaining Duration"] = "Remaining Duration"
--[[Translation missing --]]
L["Remaining Time"] = "Remaining Time"
--[[Translation missing --]]
L["Remove Obsolete Auras"] = "Remove Obsolete Auras"
--[[Translation missing --]]
L["Renown Level"] = "Renown Level"
--[[Translation missing --]]
L["Renown Max Level"] = "Renown Max Level"
--[[Translation missing --]]
L["Renown Reputation"] = "Renown Reputation"
--[[Translation missing --]]
L["Repair"] = "Repair"
--[[Translation missing --]]
L["Repeat"] = "Repeat"
--[[Translation missing --]]
L["Report Summary"] = "Report Summary"
--[[Translation missing --]]
L["Reputation"] = "Reputation"
--[[Translation missing --]]
L["Reputation (%)"] = "Reputation (%)"
--[[Translation missing --]]
L["Requested display does not exist"] = "Requested display does not exist"
--[[Translation missing --]]
L["Requested display not authorized"] = "Requested display not authorized"
--[[Translation missing --]]
L["Requesting display information from %s ..."] = "Requesting display information from %s ..."
--[[Translation missing --]]
L["Require Valid Target"] = "Require Valid Target"
--[[Translation missing --]]
L["Requires syncing the specialization via LibSpecialization."] = "Requires syncing the specialization via LibSpecialization."
--[[Translation missing --]]
L["Resilience (%)"] = "Resilience (%)"
--[[Translation missing --]]
L["Resilience Rating"] = "Resilience Rating"
--[[Translation missing --]]
L["Resist"] = "Resist"
--[[Translation missing --]]
L["Resistances"] = "Resistances"
--[[Translation missing --]]
L["Resisted"] = "Resisted"
--[[Translation missing --]]
L["Rested"] = "Rested"
--[[Translation missing --]]
L["Rested Experience"] = "Rested Experience"
--[[Translation missing --]]
L["Rested Experience (%)"] = "Rested Experience (%)"
--[[Translation missing --]]
L["Resting"] = "Resting"
--[[Translation missing --]]
L["Resurrect"] = "Resurrect"
--[[Translation missing --]]
L["Resurrect Pending"] = "Resurrect Pending"
--[[Translation missing --]]
L["Right"] = "Right"
--[[Translation missing --]]
L["Right to Left"] = "Right to Left"
--[[Translation missing --]]
L["Right, then Centered Vertical"] = "Right, then Centered Vertical"
--[[Translation missing --]]
L["Right, then Down"] = "Right, then Down"
--[[Translation missing --]]
L["Right, then Up"] = "Right, then Up"
--[[Translation missing --]]
L["Role"] = "Role"
--[[Translation missing --]]
L["Rollback snapshot is complete. Thank you for your patience!"] = "Rollback snapshot is complete. Thank you for your patience!"
--[[Translation missing --]]
L["Rotate Animation"] = "Rotate Animation"
--[[Translation missing --]]
L["Rotate Left"] = "Rotate Left"
--[[Translation missing --]]
L["Rotate Right"] = "Rotate Right"
--[[Translation missing --]]
L["Rotation"] = "Rotation"
--[[Translation missing --]]
L["Round"] = "Round"
--[[Translation missing --]]
L["Round Mode"] = "Round Mode"
--[[Translation missing --]]
L["Ruins of Ahn'Qiraj"] = "Ruins of Ahn'Qiraj"
--[[Translation missing --]]
L["Run Custom Code"] = "Run Custom Code"
--[[Translation missing --]]
L["Run Speed (%)"] = "Run Speed (%)"
--[[Translation missing --]]
L["Rune"] = "Rune"
--[[Translation missing --]]
L["Rune #1"] = "Rune #1"
--[[Translation missing --]]
L["Rune #2"] = "Rune #2"
--[[Translation missing --]]
L["Rune #3"] = "Rune #3"
--[[Translation missing --]]
L["Rune #4"] = "Rune #4"
--[[Translation missing --]]
L["Rune #5"] = "Rune #5"
--[[Translation missing --]]
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
--[[Translation missing --]]
L["Say"] = "Say"
--[[Translation missing --]]
L["Scale"] = "Scale"
--[[Translation missing --]]
L["Scarlet Enclave"] = "Scarlet Enclave"
--[[Translation missing --]]
L["Scenario"] = "Scenario"
--[[Translation missing --]]
L["Scenario (Heroic)"] = "Scenario (Heroic)"
--[[Translation missing --]]
L["Scenario (Normal)"] = "Scenario (Normal)"
--[[Translation missing --]]
L["Screen"] = "Screen"
--[[Translation missing --]]
L["Screen/Parent Group"] = "Screen/Parent Group"
--[[Translation missing --]]
L["Season of Discovery"] = "Season of Discovery"
--[[Translation missing --]]
L["Second"] = "Second"
--[[Translation missing --]]
L["Second Value of Tooltip Text"] = "Second Value of Tooltip Text"
--[[Translation missing --]]
L["Secondary Stats"] = "Secondary Stats"
--[[Translation missing --]]
L["Seconds"] = "Seconds"
--[[Translation missing --]]
L[ [=[Secure frame detected. Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames]=] ] = [=[Secure frame detected. Find more information:
https://github.com/WeakAuras/WeakAuras2/wiki/Protected-Frames]=]
--[[Translation missing --]]
L["Select Frame"] = "Select Frame"
--[[Translation missing --]]
L["Select the type of timer to filter"] = "Select the type of timer to filter"
--[[Translation missing --]]
L["Selection Mode"] = "Selection Mode"
--[[Translation missing --]]
L["Separator"] = "Separator"
--[[Translation missing --]]
L["Set IDs can be found on websites such as wowhead.com/cata/item-sets"] = "Set IDs can be found on websites such as wowhead.com/cata/item-sets"
--[[Translation missing --]]
L["Set IDs can be found on websites such as wowhead.com/classic/item-sets"] = "Set IDs can be found on websites such as wowhead.com/classic/item-sets"
--[[Translation missing --]]
L["Set IDs can be found on websites such as wowhead.com/item-sets"] = "Set IDs can be found on websites such as wowhead.com/item-sets"
--[[Translation missing --]]
L["Set IDs can be found on websites such as wowhead.com/mop-classic/item-sets"] = "Set IDs can be found on websites such as wowhead.com/mop-classic/item-sets"
--[[Translation missing --]]
L["Shadow Resistance"] = "Shadow Resistance"
--[[Translation missing --]]
L["Shadowlands"] = "Shadowlands"
--[[Translation missing --]]
L["Shake"] = "Shake"
--[[Translation missing --]]
L["Shazzrah"] = "Shazzrah"
--[[Translation missing --]]
L["Shift-Click to resume addon execution."] = "Shift-Click to resume addon execution."
--[[Translation missing --]]
L["Show"] = "Show"
--[[Translation missing --]]
L["Show CD of Charge"] = "Show CD of Charge"
--[[Translation missing --]]
L["Show charged duration for empowered casts"] = "Show charged duration for empowered casts"
--[[Translation missing --]]
L["Show GCD"] = "Show GCD"
--[[Translation missing --]]
L["Show Global Cooldown"] = "Show Global Cooldown"
--[[Translation missing --]]
L["Show Incoming Heal"] = "Show Incoming Heal"
--[[Translation missing --]]
L["Show Loss of Control"] = "Show Loss of Control"
--[[Translation missing --]]
L["Show On"] = "Show On"
--[[Translation missing --]]
L["Show Rested Overlay"] = "Show Rested Overlay"
--[[Translation missing --]]
L["Shrink"] = "Shrink"
--[[Translation missing --]]
L["Silithid Royalty"] = "Silithid Royalty"
--[[Translation missing --]]
L["Silver"] = "Silver"
--[[Translation missing --]]
L["Simple"] = "Simple"
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
--[[Translation missing --]]
L["Size & Position"] = "Size & Position"
--[[Translation missing --]]
L["Skyriding"] = "Skyriding"
--[[Translation missing --]]
L["Slide Animation"] = "Slide Animation"
--[[Translation missing --]]
L["Slide from Bottom"] = "Slide from Bottom"
--[[Translation missing --]]
L["Slide from Left"] = "Slide from Left"
--[[Translation missing --]]
L["Slide from Right"] = "Slide from Right"
--[[Translation missing --]]
L["Slide from Top"] = "Slide from Top"
--[[Translation missing --]]
L["Slide to Bottom"] = "Slide to Bottom"
--[[Translation missing --]]
L["Slide to Left"] = "Slide to Left"
--[[Translation missing --]]
L["Slide to Right"] = "Slide to Right"
--[[Translation missing --]]
L["Slide to Top"] = "Slide to Top"
--[[Translation missing --]]
L["Slider"] = "Slider"
--[[Translation missing --]]
L["Small"] = "Small"
--[[Translation missing --]]
L["Smart Group"] = "Smart Group"
--[[Translation missing --]]
L["Soft Enemy"] = "Soft Enemy"
--[[Translation missing --]]
L["Soft Friend"] = "Soft Friend"
--[[Translation missing --]]
L["Solistrasza"] = "Solistrasza"
--[[Translation missing --]]
L["Sound"] = "Sound"
--[[Translation missing --]]
L["Sound by Kit ID"] = "Sound by Kit ID"
--[[Translation missing --]]
L["Source"] = "Source"
--[[Translation missing --]]
L["Source Affiliation"] = "Source Affiliation"
--[[Translation missing --]]
L["Source GUID"] = "Source GUID"
--[[Translation missing --]]
L["Source Info"] = "Source Info"
--[[Translation missing --]]
L["Source Name"] = "Source Name"
--[[Translation missing --]]
L["Source NPC Id"] = "Source NPC Id"
--[[Translation missing --]]
L["Source Object Type"] = "Source Object Type"
--[[Translation missing --]]
L["Source Raid Mark"] = "Source Raid Mark"
--[[Translation missing --]]
L["Source Reaction"] = "Source Reaction"
--[[Translation missing --]]
L["Source Unit"] = "Source Unit"
--[[Translation missing --]]
L["Source Unit Name/Realm"] = "Source Unit Name/Realm"
--[[Translation missing --]]
L["Source unit's raid mark index"] = "Source unit's raid mark index"
--[[Translation missing --]]
L["Source unit's raid mark texture"] = "Source unit's raid mark texture"
--[[Translation missing --]]
L["Space"] = "Space"
--[[Translation missing --]]
L["Spacing"] = "Spacing"
--[[Translation missing --]]
L["Spark"] = "Spark"
--[[Translation missing --]]
L["Spec Position"] = "Spec Position"
--[[Translation missing --]]
L["Spec Role"] = "Spec Role"
--[[Translation missing --]]
L["Specialization"] = "Specialization"
--[[Translation missing --]]
L["Specific Currency"] = "Specific Currency"
--[[Translation missing --]]
L["Specific Type"] = "Specific Type"
--[[Translation missing --]]
L["Specific Unit"] = "Specific Unit"
--[[Translation missing --]]
L["Spell"] = "Spell"
--[[Translation missing --]]
L["Spell (Building)"] = "Spell (Building)"
--[[Translation missing --]]
L["Spell Activation Overlay Glow"] = "Spell Activation Overlay Glow"
--[[Translation missing --]]
L["Spell Cast Succeeded"] = "Spell Cast Succeeded"
--[[Translation missing --]]
L["Spell Cost"] = "Spell Cost"
--[[Translation missing --]]
L["Spell Count"] = "Spell Count"
--[[Translation missing --]]
L["Spell ID"] = "Spell ID"
--[[Translation missing --]]
L["Spell Id"] = "Spell Id"
--[[Translation missing --]]
L["Spell ID:"] = "Spell ID:"
--[[Translation missing --]]
L["Spell IDs:"] = "Spell IDs:"
--[[Translation missing --]]
L["Spell in Range"] = "Spell in Range"
--[[Translation missing --]]
L["Spell Known"] = "Spell Known"
--[[Translation missing --]]
L["Spell Name"] = "Spell Name"
--[[Translation missing --]]
L["Spell Peneration Percent"] = "Spell Peneration Percent"
--[[Translation missing --]]
L["Spell Power"] = "Spell Power"
--[[Translation missing --]]
L["Spell School"] = "Spell School"
--[[Translation missing --]]
L["Spell Usable"] = "Spell Usable"
--[[Translation missing --]]
L["Spellname"] = "Spellname"
--[[Translation missing --]]
L["Spike"] = "Spike"
--[[Translation missing --]]
L["Spin"] = "Spin"
--[[Translation missing --]]
L["Spiral"] = "Spiral"
--[[Translation missing --]]
L["Spiral In And Out"] = "Spiral In And Out"
--[[Translation missing --]]
L["Spirit"] = "Spirit"
--[[Translation missing --]]
L["Stack Count"] = "Stack Count"
--[[Translation missing --]]
L["Stack trace:"] = "Stack trace:"
--[[Translation missing --]]
L["Stacks"] = "Stacks"
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
--[[Translation missing --]]
L["Stagger Scale"] = "Stagger Scale"
--[[Translation missing --]]
L["Stamina"] = "Stamina"
--[[Translation missing --]]
L["Stance/Form/Aura"] = "Stance/Form/Aura"
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
--[[Translation missing --]]
L["Status"] = "Status"
--[[Translation missing --]]
L["Status Bar"] = "Status Bar"
--[[Translation missing --]]
L["Stolen"] = "Stolen"
--[[Translation missing --]]
L["Stop"] = "Stop"
--[[Translation missing --]]
L["Stop Motion"] = "Stop Motion"
--[[Translation missing --]]
L["Story Raid"] = "Story Raid"
--[[Translation missing --]]
L["Strength"] = "Strength"
--[[Translation missing --]]
L["String"] = "String"
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
--[[Translation missing --]]
L["Summon"] = "Summon"
--[[Translation missing --]]
L["Summon Pending"] = "Summon Pending"
--[[Translation missing --]]
L["Sun"] = "Sun"
--[[Translation missing --]]
L["Supports multiple entries, separated by commas"] = "Supports multiple entries, separated by commas"
--[[Translation missing --]]
L[ [=[Supports multiple entries, separated by commas
]=] ] = [=[Supports multiple entries, separated by commas
]=]
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
--[[Translation missing --]]
L["Swing"] = "Swing"
--[[Translation missing --]]
L["Swing Timer"] = "Swing Timer"
--[[Translation missing --]]
L["Swipe"] = "Swipe"
--[[Translation missing --]]
L["Syntax /wa feature <toggle|on|enable|disable|off> <feature>"] = "Syntax /wa feature <toggle|on|enable|disable|off> <feature>"
--[[Translation missing --]]
L["System"] = "System"
--[[Translation missing --]]
L["Systems"] = "Systems"
--[[Translation missing --]]
L["Tab "] = "Tab "
--[[Translation missing --]]
L["Talent"] = "Talent"
--[[Translation missing --]]
L["Talent |cFFFF0000Not|r Known"] = "Talent |cFFFF0000Not|r Known"
--[[Translation missing --]]
L["Talent |cFFFF0000Not|r Selected"] = "Talent |cFFFF0000Not|r Selected"
--[[Translation missing --]]
L["Talent Known"] = "Talent Known"
--[[Translation missing --]]
L["Talent Selected"] = "Talent Selected"
--[[Translation missing --]]
L["Talent selected"] = "Talent selected"
--[[Translation missing --]]
L["Talent Specialization"] = "Talent Specialization"
--[[Translation missing --]]
L["Tanking And Highest"] = "Tanking And Highest"
--[[Translation missing --]]
L["Tanking But Not Highest"] = "Tanking But Not Highest"
--[[Translation missing --]]
L["Target"] = "Target"
--[[Translation missing --]]
L["Targeted"] = "Targeted"
--[[Translation missing --]]
L["Tertiary Stats"] = "Tertiary Stats"
--[[Translation missing --]]
L["Test if bar is enabled in BigWigs settings"] = "Test if bar is enabled in BigWigs settings"
--[[Translation missing --]]
L["Test if bar is enabled in Boss Mod addon settings"] = "Test if bar is enabled in Boss Mod addon settings"
--[[Translation missing --]]
L["Test if bar is enabled in DBM settings"] = "Test if bar is enabled in DBM settings"
--[[Translation missing --]]
L["Text"] = "Text"
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
--[[Translation missing --]]
L["The effective level differs from the level in e.g. Time Walking dungeons."] = "The effective level differs from the level in e.g. Time Walking dungeons."
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
--[[Translation missing --]]
L["There are %i updates to your auras ready to be installed!"] = "There are %i updates to your auras ready to be installed!"
--[[Translation missing --]]
L["Thick Outline"] = "Thick Outline"
--[[Translation missing --]]
L["Thickness"] = "Thickness"
--[[Translation missing --]]
L["Third"] = "Third"
--[[Translation missing --]]
L["Third Value of Tooltip Text"] = "Third Value of Tooltip Text"
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
--[[Translation missing --]]
L["Threat Situation"] = "Threat Situation"
--[[Translation missing --]]
L["Threat Value"] = "Threat Value"
--[[Translation missing --]]
L["Tick"] = "Tick"
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
--[[Translation missing --]]
L["Timed"] = "Timed"
--[[Translation missing --]]
L["Timed Progress"] = "Timed Progress"
--[[Translation missing --]]
L["Timer"] = "Timer"
--[[Translation missing --]]
L["Timer Id"] = "Timer Id"
--[[Translation missing --]]
L["Toggle"] = "Toggle"
--[[Translation missing --]]
L["Toggle List"] = "Toggle List"
--[[Translation missing --]]
L["Toggle Options Window"] = "Toggle Options Window"
--[[Translation missing --]]
L["Toggle Performance Profiling Window"] = "Toggle Performance Profiling Window"
--[[Translation missing --]]
L["Tooltip"] = "Tooltip"
--[[Translation missing --]]
L["Tooltip 1"] = "Tooltip 1"
--[[Translation missing --]]
L["Tooltip 2"] = "Tooltip 2"
--[[Translation missing --]]
L["Tooltip 3"] = "Tooltip 3"
--[[Translation missing --]]
L["Tooltip Value 1"] = "Tooltip Value 1"
--[[Translation missing --]]
L["Tooltip Value 2"] = "Tooltip Value 2"
--[[Translation missing --]]
L["Tooltip Value 3"] = "Tooltip Value 3"
--[[Translation missing --]]
L["Tooltip Value 4"] = "Tooltip Value 4"
--[[Translation missing --]]
L["Top"] = "Top"
--[[Translation missing --]]
L["Top Left"] = "Top Left"
--[[Translation missing --]]
L["Top Right"] = "Top Right"
--[[Translation missing --]]
L["Top to Bottom"] = "Top to Bottom"
--[[Translation missing --]]
L["Torghast"] = "Torghast"
--[[Translation missing --]]
L["Total Duration"] = "Total Duration"
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
--[[Translation missing --]]
L["Total Units"] = "Total Units"
--[[Translation missing --]]
L["Totem"] = "Totem"
--[[Translation missing --]]
L["Totem #%i"] = "Totem #%i"
--[[Translation missing --]]
L["Totem Icon"] = "Totem Icon"
--[[Translation missing --]]
L["Totem Name"] = "Totem Name"
--[[Translation missing --]]
L["Totem Name Pattern Match"] = "Totem Name Pattern Match"
--[[Translation missing --]]
L["Totem Number"] = "Totem Number"
--[[Translation missing --]]
L["Track Cooldowns"] = "Track Cooldowns"
--[[Translation missing --]]
L["Tracking Charge %i"] = "Tracking Charge %i"
--[[Translation missing --]]
L["Tracking Charge CDs"] = "Tracking Charge CDs"
--[[Translation missing --]]
L["Tracking Only Cooldown"] = "Tracking Only Cooldown"
--[[Translation missing --]]
L["Transmission error"] = "Transmission error"
--[[Translation missing --]]
L["Trigger"] = "Trigger"
--[[Translation missing --]]
L["Trigger %i"] = "Trigger %i"
--[[Translation missing --]]
L["Trigger %s"] = "Trigger %s"
--[[Translation missing --]]
L["Trigger 1"] = "Trigger 1"
--[[Translation missing --]]
L["Trigger State Updater (Advanced)"] = "Trigger State Updater (Advanced)"
--[[Translation missing --]]
L["Trigger Update"] = "Trigger Update"
--[[Translation missing --]]
L["Trigger:"] = "Trigger:"
--[[Translation missing --]]
L["Trivial (Low Level)"] = "Trivial (Low Level)"
--[[Translation missing --]]
L["True"] = "True"
--[[Translation missing --]]
L["Trying to repair broken conditions in %s likely caused by a WeakAuras bug."] = "Trying to repair broken conditions in %s likely caused by a WeakAuras bug."
--[[Translation missing --]]
L["Twin Emperors"] = "Twin Emperors"
--[[Translation missing --]]
L["Type"] = "Type"
--[[Translation missing --]]
L["Unable to modernize aura '%s'. This is probably due to corrupt data or a bad migration, please report this to the WeakAuras team."] = "Unable to modernize aura '%s'. This is probably due to corrupt data or a bad migration, please report this to the WeakAuras team."
--[[Translation missing --]]
L["Unaffected"] = "Unaffected"
--[[Translation missing --]]
L["Undefined"] = "Undefined"
--[[Translation missing --]]
L["Unholy"] = "Unholy"
--[[Translation missing --]]
L["Unholy Rune #1"] = "Unholy Rune #1"
--[[Translation missing --]]
L["Unholy Rune #2"] = "Unholy Rune #2"
--[[Translation missing --]]
L["Unit"] = "Unit"
--[[Translation missing --]]
L["Unit Characteristics"] = "Unit Characteristics"
--[[Translation missing --]]
L["Unit Destroyed"] = "Unit Destroyed"
--[[Translation missing --]]
L["Unit Died"] = "Unit Died"
--[[Translation missing --]]
L["Unit Dissipates"] = "Unit Dissipates"
--[[Translation missing --]]
L["Unit Frame"] = "Unit Frame"
--[[Translation missing --]]
L["Unit Frames"] = "Unit Frames"
--[[Translation missing --]]
L["Unit is Unit"] = "Unit is Unit"
--[[Translation missing --]]
L["Unit Name"] = "Unit Name"
--[[Translation missing --]]
L["Unit Name/Realm"] = "Unit Name/Realm"
--[[Translation missing --]]
L["Units Affected"] = "Units Affected"
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
--[[Translation missing --]]
L["Unlimited"] = "Unlimited"
--[[Translation missing --]]
L["Untrigger %s"] = "Untrigger %s"
--[[Translation missing --]]
L["Up"] = "Up"
--[[Translation missing --]]
L["Up, then Centered Horizontal"] = "Up, then Centered Horizontal"
--[[Translation missing --]]
L["Up, then Left"] = "Up, then Left"
--[[Translation missing --]]
L["Up, then Right"] = "Up, then Right"
--[[Translation missing --]]
L["Update Position"] = "Update Position"
--[[Translation missing --]]
L["Usage:"] = "Usage:"
--[[Translation missing --]]
L["Use /wa minimap to show the minimap icon again."] = "Use /wa minimap to show the minimap icon again."
--[[Translation missing --]]
L["Use Custom Color"] = "Use Custom Color"
--[[Translation missing --]]
L["Use Legacy floor rounding"] = "Use Legacy floor rounding"
--[[Translation missing --]]
L["Use Texture"] = "Use Texture"
--[[Translation missing --]]
L["Use Watched Faction"] = "Use Watched Faction"
--[[Translation missing --]]
L["Uses UnitInRange() to check if in range. Matches default raid frames out of range behavior, which is between 25 to 40 yards depending on your class and spec."] = "Uses UnitInRange() to check if in range. Matches default raid frames out of range behavior, which is between 25 to 40 yards depending on your class and spec."
--[[Translation missing --]]
L["Using WeakAuras.clones is deprecated. Use WeakAuras.GetRegion(id, cloneId) instead."] = "Using WeakAuras.clones is deprecated. Use WeakAuras.GetRegion(id, cloneId) instead."
--[[Translation missing --]]
L["Using WeakAuras.regions is deprecated. Use WeakAuras.GetRegion(id) instead."] = "Using WeakAuras.regions is deprecated. Use WeakAuras.GetRegion(id) instead."
--[[Translation missing --]]
L["Vaelastrasz the Corrupt"] = "Vaelastrasz the Corrupt"
--[[Translation missing --]]
L["Versatility (%)"] = "Versatility (%)"
--[[Translation missing --]]
L["Versatility Rating"] = "Versatility Rating"
--[[Translation missing --]]
L["Vertical"] = "Vertical"
--[[Translation missing --]]
L["Viscidus"] = "Viscidus"
--[[Translation missing --]]
L["Visibility"] = "Visibility"
--[[Translation missing --]]
L["Visions of N'Zoth"] = "Visions of N'Zoth"
--[[Translation missing --]]
L["Warband Quantity Total"] = "Warband Quantity Total"
--[[Translation missing --]]
L["Warband Transfer Percentage"] = "Warband Transfer Percentage"
--[[Translation missing --]]
L["Warband Transferred Quantity"] = "Warband Transferred Quantity"
--[[Translation missing --]]
L["Warfront (Heroic)"] = "Warfront (Heroic)"
--[[Translation missing --]]
L["Warfront (Normal)"] = "Warfront (Normal)"
--[[Translation missing --]]
L["Warlords of Draenor"] = "Warlords of Draenor"
--[[Translation missing --]]
L["Warning"] = "Warning"
--[[Translation missing --]]
L["Warning for unknown aura:"] = "Warning for unknown aura:"
--[[Translation missing --]]
L["Warning: Anchoring in aura '%s' is imposssible, due to an anchoring cycle"] = "Warning: Anchoring in aura '%s' is imposssible, due to an anchoring cycle"
--[[Translation missing --]]
L["Warning: Full Scan auras checking for both name and spell id can't be converted."] = "Warning: Full Scan auras checking for both name and spell id can't be converted."
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
--[[Translation missing --]]
L["Weapon"] = "Weapon"
--[[Translation missing --]]
L["Weapon Enchant"] = "Weapon Enchant"
--[[Translation missing --]]
L["Weapon Enchant / Fishing Lure"] = "Weapon Enchant / Fishing Lure"
--[[Translation missing --]]
L["Whisper"] = "Whisper"
--[[Translation missing --]]
L["Width"] = "Width"
--[[Translation missing --]]
L["Wobble"] = "Wobble"
--[[Translation missing --]]
L["World Boss"] = "World Boss"
--[[Translation missing --]]
L["World Bosses"] = "World Bosses"
--[[Translation missing --]]
L["Wrap"] = "Wrap"
--[[Translation missing --]]
L["Wrath of the Lich King"] = "Wrath of the Lich King"
--[[Translation missing --]]
L["Writing to the WeakAuras table is not allowed."] = "Writing to the WeakAuras table is not allowed."
--[[Translation missing --]]
L["X-Offset"] = "X-Offset"
--[[Translation missing --]]
L["Yell"] = "Yell"
--[[Translation missing --]]
L["Y-Offset"] = "Y-Offset"
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
--[[Translation missing --]]
L["Your threat on the mob as a percentage of the amount required to pull aggro. Will pull aggro at 100."] = "Your threat on the mob as a percentage of the amount required to pull aggro. Will pull aggro at 100."
--[[Translation missing --]]
L["Your total threat on the mob."] = "Your total threat on the mob."
--[[Translation missing --]]
L["Zone Group ID"] = "Zone Group ID"
--[[Translation missing --]]
L["Zone ID"] = "Zone ID"
--[[Translation missing --]]
L["Zone Name"] = "Zone Name"
--[[Translation missing --]]
L["Zoom"] = "Zoom"
--[[Translation missing --]]
L["Zoom Animation"] = "Zoom Animation"
--[[Translation missing --]]
L["Zul'Gurub"] = "Zul'Gurub"