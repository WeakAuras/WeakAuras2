if not WeakAuras.IsLibsOK() then return end

if (GAME_LOCALE or GetLocale()) ~= "itIT" then
  return
end

local L = WeakAuras.L

-- WeakAuras/Options
	L[" and |cFFFF0000mirrored|r"] = "e |cFFFF0000mirrored|r"
	L["-- Do not remove this comment, it is part of this aura: "] = "-- Non rimuovere questo commento, fa parte di quest'aura:"
	L[" rotated |cFFFF0000%s|r degrees"] = "ruotato |cFFFF0000%s|r gradi"
	--[[Translation missing --]]
	L["% - To show a percent sign"] = "% - To show a percent sign"
	L["% of Progress"] = "% di Progresso"
	L["%d |4aura:auras; added"] = "%d |4aura:auras; aggiunto"
	L["%d |4aura:auras; deleted"] = "%d |4aura:auras; cancellato"
	L["%d |4aura:auras; modified"] = "%d |4aura:auras; modificata"
	L["%d |4aura:auras; with meta data modified"] = "%d |4aura:auras; con dati meta modificati"
	L["%d displays loaded"] = "%d display caricato"
	L["%d displays not loaded"] = "%d display non caricato"
	L["%d displays on standby"] = "%d display in standby"
	L["%i auras selected"] = "%i aure selezionate"
	--[[Translation missing --]]
	L["%i."] = "%i."
	--[[Translation missing --]]
	L["%i. %s"] = "%i. %s"
	L["%s - %i. Trigger"] = "%s - %i. Attivazione "
	L["%s - Alpha Animation"] = "%s - Animazione Alfabeto "
	L["%s - Color Animation"] = "%s - Colore Animazione "
	L["%s - Condition Custom Chat %s"] = "%s - Condizioni Chat Personalizzata %s"
	L["%s - Condition Custom Check %s"] = "%s - Verifica Personalizzata delle Condizioni %s"
	L["%s - Condition Custom Code %s"] = "%s - Condizione Codice Personalizzato %s"
	L["%s - Custom Anchor"] = "%s - Ancoraggio Personalizzato"
	L["%s - Custom Grow"] = "%s - Crescita Personalizzata"
	L["%s - Custom Sort"] = "%s - Ordinamento Personalizzato"
	L["%s - Custom Text"] = "%s - Testo Personalizzato"
	L["%s - Finish"] = "%s - Termina"
	L["%s - Finish Action"] = "%s - Termina l'Azione"
	L["%s - Finish Custom Text"] = "%s - Termina il Testo Personalizzato"
	L["%s - Init Action"] = "%s - Azione di Inizializzazione"
	L["%s - Main"] = "%s - Principale"
	--[[Translation missing --]]
	L["%s - OnLoad"] = "%s - OnLoad"
	--[[Translation missing --]]
	L["%s - OnUnload"] = "%s - OnUnload"
	L["%s - Option #%i has the key %s. Please choose a different option key."] = "%s - L'opzione #%i ha la chiave %s. Scegli una chiave di opzione diversa."
	L["%s - Rotate Animation"] = "%s - Ruota Animazione"
	L["%s - Scale Animation"] = "%s - Scala Animazione"
	L["%s - Start"] = "%s - Avvia"
	L["%s - Start Action"] = "%s - Avvia Azione"
	L["%s - Start Custom Text"] = "%s - Avvia Testo Personalizzato"
	L["%s - Translate Animation"] = "%s - Traduci Animazione"
	L["%s - Trigger Logic"] = "%s - Logica di Attivazione"
	L["%s %s, Lines: %d, Frequency: %0.2f, Length: %d, Thickness: %d"] = "%s %s, Linee: %d, Frequenza: %0.2f, Lunghezza: %d, Spessore: %d"
	L["%s %s, Particles: %d, Frequency: %0.2f, Scale: %0.2f"] = "%s %s, Particelle: %d, Frequenza: %0.2f, Scala: %0.2f"
	L["%s %u. Overlay Function"] = "%s %u. Funzione di Sovrapposizione"
	--[[Translation missing --]]
	L["%s (%s)"] = "%s (%s)"
	L["%s Alpha: %d%%"] = "%s Alfabeto: %d%%"
	L["%s Color"] = "%s Colore"
	L["%s Custom Variables"] = "%s Variabili Personalizzate"
	L["%s Default Alpha, Zoom, Icon Inset, Aspect Ratio"] = "%s Alfabeto Predefinito, Zoom, Icona inserita, Proporzioni"
	L["%s Duration Function"] = "Funzione Durata %s"
	L["%s Icon Function"] = "Funzione Icona %s"
	L["%s Inset: %d%%"] = "%s Inserire: %d%%"
	L["%s is not a valid SubEvent for COMBAT_LOG_EVENT_UNFILTERED"] = "%s non è un evento secondario valido per COMBAT_LOG_EVENT_UNFILTERED"
	L["%s Keep Aspect Ratio"] = "%s Mantieni Proporzioni"
	L["%s Name Function"] = "%s Nome Funzione"
	L["%s Stacks Function"] = "%s Funzione Accumuli"
	L["%s stores around %s KB of data"] = "%s memorizza circa %s KB di dati"
	L["%s Texture"] = "%s Texture"
	L["%s Texture Function"] = "%s Funzione della Texture"
	L["%s total auras"] = "%s aure totali"
	L["%s Trigger Function"] = "Funzione di Attivazione %s"
	L["%s Untrigger Function"] = "%s Annulla Funzione di Attivazione"
	L["%s X offset by %d"] = "%s X deviazione di %d"
	L["%s Y offset by %d"] = "%s Y deviazione di %d"
	L["%s Zoom: %d%%"] = "%s Zoom: %d%%"
	L["%s, Border"] = "%s, Bordo"
	L["%s, Offset: %0.2f;%0.2f"] = "%s, Deviazione: %0.2f;%0.2f"
	L["%s, offset: %0.2f;%0.2f"] = "%s, deviazione: %0.2f;%0.2f"
	L["%s, Start Animation"] = "%s, Avvia l'animazione"
	L["%s|cFFFF0000custom|r texture with |cFFFF0000%s|r blend mode%s%s"] = "%s|cFFFF0000custom|r texture con |cFFFF0000%s|r modalità di fusione%s%s"
	L["(Right click to rename)"] = "(Tasto destro per rinominare)"
	L["|c%02x%02x%02x%02xCustom Color|r"] = "|c%02x%02x%02x%02xColore Personalizzato|r"
	L["|cff999999Triggers tracking multiple units will default to being active even while no affected units are found without a Unit Count or Match Count setting applied.|r"] = "|cff999999Attivazioni che tracciano più unità verranno attivati ​​per impostazione predefinita anche quando non viene trovata alcuna unità interessata senza l'applicazione di un'impostazione Conteggio unità o Conteggio corrispondenze.|r"
	L["|cFFE0E000Note:|r This sets the description only on '%s'"] = "|cFFE0E000Note:|r Imposta la descrizione solo su '%s'"
	L["|cFFE0E000Note:|r This sets the URL on all selected auras"] = "|cFFE0E000Note:|r Imposta l'URL su tutte le aure selezionate"
	L["|cFFE0E000Note:|r This sets the URL on this group and all its members."] = "|cFFE0E000Note:|r Imposta l'URL di questo gruppo e di tutti i suoi membri."
	L["|cFFFF0000Automatic|r length"] = "|cFFFF0000Automatic|r lunghezza"
	--[[Translation missing --]]
	L["|cFFFF0000default|r texture"] = "|cFFFF0000default|r texture"
	--[[Translation missing --]]
	L["|cFFFF0000desaturated|r "] = "|cFFFF0000desaturated|r "
	L["|cFFFF0000Note:|r The unit '%s' is not a trackable unit."] = "|cFFFF0000Note:|r L'unità '%s' non è un'unità tracciabile."
	--[[Translation missing --]]
	L["|cFFFF0000Note:|r The unit '%s' requires soft target cvars to be enabled."] = "|cFFFF0000Note:|r The unit '%s' requires soft target cvars to be enabled."
	L["|cFFffcc00Anchors:|r Anchored |cFFFF0000%s|r to frame's |cFFFF0000%s|r"] = "|cFFffcc00Anchors:|r Ancoraggio |cFFFF0000%s|r ai frame |cFFFF0000%s|r"
	L["|cFFffcc00Anchors:|r Anchored |cFFFF0000%s|r to frame's |cFFFF0000%s|r with offset |cFFFF0000%s/%s|r"] = "|cFFffcc00Anchors:|r Ancoraggio |cFFFF0000%s|r ai frame |cFFFF0000%s|r con deviazione |cFFFF0000%s/%s|r"
	L["|cFFffcc00Anchors:|r Anchored to frame's |cFFFF0000%s|r"] = "|cFFffcc00Anchors:|r Ancoraggio ai frame |cFFFF0000%s|r"
	L["|cFFffcc00Anchors:|r Anchored to frame's |cFFFF0000%s|r with offset |cFFFF0000%s/%s|r"] = "|cFFffcc00Anchors:|r Ancoraggio ai frame |cFFFF0000%s|r con deviazione |cFFFF0000%s/%s|r"
	L["|cFFffcc00Extra Options:|r"] = "|cFFffcc00Opzioni Extra:|r"
	L["|cFFffcc00Extra:|r %s and %s %s"] = "|cFFffcc00Extra:|r %s e %s %s"
	L["|cFFffcc00Font Flags:|r |cFFFF0000%s|r and shadow |c%sColor|r with offset |cFFFF0000%s/%s|r%s%s"] = "|cFFffcc00Font Flags:|r |cFFFF0000%s|r e ombra |c%sColor|r con deviazione |cFFFF0000%s/%s|r%s%s"
	L["|cFFffcc00Font Flags:|r |cFFFF0000%s|r and shadow |c%sColor|r with offset |cFFFF0000%s/%s|r%s%s%s"] = "|cFFffcc00Font Flags:|r |cFFFF0000%s|r e ombra |c%sColor|r con deviazione |cFFFF0000%s/%s|r%s%s%s"
	L["|cffffcc00Format Options|r"] = "|cffffcc00Opzioni Formato|r"
	L[ [=[• |cff00ff00Player|r, |cff00ff00Target|r, |cff00ff00Focus|r, and |cff00ff00Pet|r correspond directly to those individual unitIDs.
• |cff00ff00Specific Unit|r lets you provide a specific valid unitID to watch.
|cffff0000Note|r: The game will not fire events for all valid unitIDs, making some untrackable by this trigger.
• |cffffff00Party|r, |cffffff00Raid|r, |cffffff00Boss|r, |cffffff00Arena|r, and |cffffff00Nameplate|r can match multiple corresponding unitIDs.
• |cffffff00Smart Group|r adjusts to your current group type, matching just the "player" when solo, "party" units (including "player") in a party or "raid" units in a raid.
• |cffffff00Multi-target|r attempts to use the Combat Log events, rather than unitID, to track affected units.
|cffff0000Note|r: Without a direct relationship to actual unitIDs, results may vary.

|cffffff00*|r Yellow Unit settings can match multiple units and will default to being active even while no affected units are found without a Unit Count or Match Count setting.]=] ] = "• |cff00ff00Player|r, |cff00ff00Target|r, |cff00ff00Focus|r e |cff00ff00Pet|r corrispondono direttamente a quei singoli unitID.  • |cff00ff00Unità specifica|r consente di fornire uno specifico ID unità valido da guardare.  |cffff0000Nota|r: il gioco non attiverà eventi per tutti gli unitID validi, rendendone alcuni non tracciabili da questa attivazione.  • |cffffff00Party|r, |cffffff00Raid|r, |cffffff00Boss|r, |cffffff00Arena|r e |cffffff00Nameplate|r possono corrispondere a più ID unità corrispondenti.  • |cffffff00Smart Group|r si adatta al tipo di gruppo corrente, abbinando solo il \"giocatore\" in modalità solista, le unità \"party\" (incluso il \"giocatore\") in un party o le unità \"raid\" in un raid.  • |cffffff00Multi-target|r tenta di utilizzare gli eventi del registro di combattimento, anziché l'ID unità, per tenere traccia delle unità interessate.  |cffff0000Nota|r: senza una relazione diretta con gli ID unità effettivi, i risultati possono variare.  |cffffff00*|r Giallo Le impostazioni delle unità possono corrispondere a più unità e verranno attivate per impostazione predefinita anche quando non viene trovata alcuna unità interessata senza un'impostazione Conteggio unità o Conteggio corrispondenze."
	L["A 20x20 pixels icon"] = "Un' icona 20x20 pixel"
	L["A 32x32 pixels icon"] = "Un'icona 32x32 pixel"
	L["A 40x40 pixels icon"] = "Un'icona 40x40 pixel"
	L["A 48x48 pixels icon"] = "Un'icona 48x48 pixel"
	L["A 64x64 pixels icon"] = "Un'icona 64x64 pixel"
	L["A group that dynamically controls the positioning of its children"] = "Un gruppo che controlla dinamicamente la posizione dei propri figli"
	L[ [=[A timer will automatically be displayed according to default Interface Settings (overridden by some addons).
Enable this setting if you want this timer to be hidden, or when using a WeakAuras text to display the timer]=] ] = "Un timer verrà automaticamente visualizzato in base alle impostazioni dell'interfaccia predefinite (sostituite da alcuni componenti aggiuntivi). Abilita questa impostazione se vuoi che questo timer sia nascosto o quando usi un testo WeakAuras per visualizzare il timer"
	L["A Unit ID (e.g., party1)."] = "Un Unit ID (p.es., party1)"
	--[[Translation missing --]]
	L["Ace: Funkeh, Nevcairiel"] = "Ace: Funkeh, Nevcairiel"
	L["Active Aura Filters and Info"] = "Filtri e informazioni sull'aura attiva"
	L["Actual Spec"] = "Attuale Spec"
	L["Add %s"] = "Aggiungi %s"
	L["Add a new display"] = "Aggiungi un nuovo display"
	L["Add Condition"] = "Aggiungi Condizione"
	L["Add Entry"] = "Aggiungi Iscrizione "
	L["Add Extra Elements"] = "Aggiungi Elementi Extra"
	L["Add Option"] = "Aggiungi Opzione"
	L["Add Overlay"] = "Aggiungi Overlay"
	L["Add Property Change"] = "Aggiungi Cambio Caratteristica"
	L["Add Snippet"] = "Aggiungi Frammento "
	L["Add Sub Option"] = "Aggiungi opzione secondaria"
	L["Add to group %s"] = "Aggiungi al gruppo %s"
	L["Add to new Dynamic Group"] = "Aggiungi ad un nuovo Gruppo Dinamico"
	L["Add to new Group"] = "Aggiungi ad un nuoco Gruppo"
	L["Add Trigger"] = "Aggiungi attivazione "
	L["Additional Events"] = "Eventi Addizionali"
	L["Advanced"] = "Avanzate"
	L["Affected Unit Filters and Info"] = "Filtri e informazioni sulle unità interessate"
	L["Align"] = "Allinea"
	L["Alignment"] = "Allineamento"
	--[[Translation missing --]]
	L["All maintainers of the libraries we use, especially:"] = "All maintainers of the libraries we use, especially:"
	L["All of"] = "Tutto di"
	L["Allow Full Rotation"] = "Consenti rotazione completa"
	L["Anchor"] = "Ancora"
	--[[Translation missing --]]
	L["Anchor Mode"] = "Anchor Mode"
	L["Anchor Point"] = "Punto di ancoraggio"
	L["Anchored To"] = "Ancorato a"
	L["And "] = "E"
	L["and"] = "e"
	L["and %s"] = "e %s"
	L["and aligned left"] = "e allineato a sinistra"
	L["and aligned right"] = "e allineato a destra"
	--[[Translation missing --]]
	L["And our Patreons, Discord Regulars and Subscribers, and Friends of the Addon:"] = "And our Patreons, Discord Regulars and Subscribers, and Friends of the Addon:"
	L["and rotated left"] = "e ruotato a sinistra"
	L["and rotated right"] = "e ruotato a destra"
	L["and with width |cFFFF0000%s|r and %s"] = "e con larghezza |cFFFF0000%s|r e %s"
	L["Angle"] = "Angolo"
	L["Angle Between Auras"] = "Angolo tra le aure"
	L["Animate"] = "Animato"
	L["Animated Expand and Collapse"] = "Espansione e Compressione Animata"
	L["Animates progress changes"] = "Anima i cambi di avanzamento"
	L["Animation End"] = "Fine Animazione"
	L["Animation Mode"] = "Modalità Animazione"
	L["Animation relative duration description"] = "Descrizione della durata relativa dell'animazione"
	L["Animation Sequence"] = "Sequenza di Animazione"
	L["Animation Start"] = "Start Animazione "
	L["Any of"] = "Qualsiasi tra"
	L["Apply Template"] = "Applica Template"
	L["Arcane Orb"] = "Globo Arcano"
	--[[Translation missing --]]
	L["Area"] = "Area"
	L["At a position a bit left of Left HUD position."] = "In una posizione un po' a sinistra della posizione dell'HUD sinistro."
	L["At a position a bit left of Right HUD position"] = "In una posizione un po' a sinistra della posizione dell'HUD destro."
	L["At the same position as Blizzard's spell alert"] = "Nella stessa posizione dell'avviso magia della Blizzard"
	--[[Translation missing --]]
	L["Attach to Foreground"] = "Attach to Foreground"
	L[ [=[Aura is
Off Screen]=] ] = "L'aura è fuori dallo schermo"
	L["Aura Name Pattern"] = "Schema del Nome Aura"
	L["Aura Order"] = "Ordine dell'Aura"
	L["Aura received from: %s"] = "Aura ricevuta da: %s"
	--[[Translation missing --]]
	L["Aura: '%s'"] = "Aura: '%s'"
	L["Auto-Clone (Show All Matches)"] = "Auto-Clona (Mostra tutte le corrispondenze)"
	L["Automatic length"] = "Lunghezza automatica"
	L["Backdrop Color"] = "Colore Fondale"
	L["Backdrop in Front"] = "Fondale d'avanti"
	L["Backdrop Style"] = "Stile Fondale"
	L["Background Inner"] = "Sfondo interno"
	L["Background Offset"] = "Deviazione Sfondo"
	L["Background Texture"] = "Texture dello Sfondo"
	L["Bar Alpha"] = "Alfa della Barra"
	L["Bar Color Settings"] = "Impostazioni Colore Barra"
	L["Big Icon"] = "Icone Grandi"
	L["Blend Mode"] = "Modalità di Fusione"
	L["Blue Rune"] = "Runa Blu"
	L["Blue Sparkle Orb"] = "Sfera Luccicante Blu"
	L["Border %s"] = "Bordo %s"
	L["Border Anchor"] = "Ancora Bordo"
	L["Border Color"] = "Colore Bordo"
	L["Border in Front"] = "Bordi davanti"
	L["Border Inset"] = "Offset del Bordo"
	L["Border Offset"] = "Offset del Bordo"
	L["Border Settings"] = "Imbostazioni Bordo"
	L["Border Size"] = "Dimensioni Bordo"
	L["Border Style"] = "Stile Bordo"
	L["Bracket Matching"] = "Corrispondenza Parentesi"
	L["Browse Wago, the largest collection of auras."] = "Sfoglia Wago, la più grande collezione di aure."
	--[[Translation missing --]]
	L["By default this shows the information from the trigger selected via dynamic information. The information from a specific trigger can be shown via e.g. %2.p."] = "By default this shows the information from the trigger selected via dynamic information. The information from a specific trigger can be shown via e.g. %2.p."
	L["Can be a UID (e.g., party1)."] = "Può essere un UID (ad esempio, party1)."
	L["Can set to 0 if Columns * Width equal File Width"] = "Può essere impostato su 0 se Colonne * Larghezza è uguale alla Larghezza file"
	L["Can set to 0 if Rows * Height equal File Height"] = "Può essere impostato su 0 se Righe * Altezza è uguale all'altezza del file"
	--[[Translation missing --]]
	L["Case Insensitive"] = "Case Insensitive"
	L["Cast by a Player Character"] = "Cast da un personaggio giocante"
	L["Categories to Update"] = "Categorie da aggiornare"
	--[[Translation missing --]]
	L["Changelog"] = "Changelog"
	L["Chat with WeakAuras experts on our Discord server."] = "Chatta con gli esperti WeakAuras sul nostro server Discord."
	L["Check On..."] = "Controllare..."
	L["Check out our wiki for a large collection of examples and snippets."] = "Controlla la nostra wiki per un'ampia raccolta di esempi e frammenti."
	L["Children:"] = "Bambini:"
	L["Choose"] = "Scegliere"
	--[[Translation missing --]]
	L["Circular Texture %s"] = "Circular Texture %s"
	L["Clear Debug Logs"] = "Cancella registri di debug"
	L["Clear Saved Data"] = "Cancella dati salvati"
	L["Clip Overlays"] = "Sovrapposizioni di clip"
	--[[Translation missing --]]
	L["Clipped by Foreground"] = "Clipped by Foreground"
	L["Close"] = "Chiudi"
	L["Code Editor"] = "Editore di codice"
	L["Collapse"] = "Comprimi"
	L["Collapse all loaded displays"] = "Comprimi tutti i display caricati"
	L["Collapse all non-loaded displays"] = "Comprimi tutti i display non caricati"
	L["Collapse all pending Import"] = "Comprimi tutto in attesa di importazione"
	L["Collapsible Group"] = "Comprimi Gruppo"
	L["color"] = "Colore"
	L["Column Height"] = "Altezza Colonna"
	L["Column Space"] = "Spazio colonna"
	L["Columns"] = "Colonne"
	L["COMBAT_LOG_EVENT_UNFILTERED with no filter can trigger frame drops in raid environment."] = "COMBAT_LOG_EVENT_UNFILTERED senza filtro può attivare cadute di frame nell'ambiente raid."
	L["Combinations"] = "Combinazioni"
	L["Combine Matches Per Unit"] = "Combina partite per unità"
	L["Common Text"] = "Testo Comune"
	L["Compare against the number of units affected."] = "Confrontare con il numero di unità interessate."
	L["Compatibility Options"] = "Opzioni di compatibilità"
	L["Compress"] = "Comprimi"
	L["Configure what options appear on this panel."] = "Configura quali opzioni appaiono in questo pannello."
	L["Constant Factor"] = "Fattore Costante"
	L["Control-click to select multiple displays"] = "Fare clic tenendo premuto il tasto Control per selezionare più display"
	L["Controls the positioning and configuration of multiple displays at the same time"] = "Controlla il posizionamento e la configurazione di più display contemporaneamente"
	L["Convert to..."] = "Converti in..."
	L["Cooldown Numbers might be added by WoW. You can configure these in the game settings."] = "I numeri di Cooldown potrebbero essere aggiunti da WoW. Puoi configurarli nelle impostazioni del gioco."
	L["Copy"] = "Copia"
	L["Copy settings..."] = "Copia impostazioni..."
	L["Copy to all auras"] = "Copia in tutte le aure"
	--[[Translation missing --]]
	L["Could not parse '%s'. Expected a table."] = "Could not parse '%s'. Expected a table."
	L["Counts the number of matches over all units."] = "Conta il numero di corrispondenze su tutte le unità."
	L["Counts the number of matches per unit."] = "Conta il numero di corrispondenze per unità."
	L["Create a Copy"] = "Crea una copia"
	L["Creating buttons: "] = "Crea bottoni:"
	L["Creating options: "] = "Crea opzioni:"
	--[[Translation missing --]]
	L["Custom - Allows you to define a custom Lua function that returns a list of string values. %c1 will be replaced by the first value returned, %c2 by the second, etc."] = "Custom - Allows you to define a custom Lua function that returns a list of string values. %c1 will be replaced by the first value returned, %c2 by the second, etc."
	--[[Translation missing --]]
	L["Custom Code"] = "Custom Code"
	--[[Translation missing --]]
	L["Custom Code Viewer"] = "Custom Code Viewer"
	--[[Translation missing --]]
	L["Custom Frames"] = "Custom Frames"
	--[[Translation missing --]]
	L["Custom Functions"] = "Custom Functions"
	--[[Translation missing --]]
	L["Custom Init"] = "Custom Init"
	--[[Translation missing --]]
	L["Custom Load"] = "Custom Load"
	--[[Translation missing --]]
	L["Custom Options"] = "Custom Options"
	--[[Translation missing --]]
	L["Custom Text Update Throttle"] = "Custom Text Update Throttle"
	--[[Translation missing --]]
	L["Custom Trigger"] = "Custom Trigger"
	--[[Translation missing --]]
	L["Custom trigger event tooltip"] = [=[Choose which events cause the custom trigger to be checked. Multiple events can be specified using commas or spaces.
• "UNIT" events can use colons to define which unitIDs will be registered. In addition to UnitIDs Unit types can be used, they include "nameplate", "group", "raid", "party", "arena", "boss".
• "CLEU" can be used instead of COMBAT_LOG_EVENT_UNFILTERED and colons can be used to separate specific "subEvents" you want to receive.
• The keyword "TRIGGER" can be used, with colons separating trigger numbers, to have the custom trigger get updated when the specified trigger(s) update.

|cFF4444FFFor example:|r
UNIT_POWER_UPDATE:player, UNIT_AURA:nameplate:group PLAYER_TARGET_CHANGED CLEU:SPELL_CAST_SUCCESS TRIGGER:3:1
]=]
	--[[Translation missing --]]
	L["Custom trigger status tooltip"] = [=[Choose which events cause the custom trigger to be checked. Multiple events can be specified using commas or spaces.

• "UNIT" events can use colons to define which unitIDs will be registered. In addition to UnitIDs Unit types can be used, they include "nameplate", "group", "raid", "party", "arena", "boss".
• "CLEU" can be used instead of COMBAT_LOG_EVENT_UNFILTERED and colons can be used to separate specific "subEvents" you want to receive.
• The keyword "TRIGGER" can be used, with colons separating trigger numbers, to have the custom trigger get updated when the specified trigger(s) update.

Since this is a status-type trigger, the specified events may be called by WeakAuras without the expected arguments.

|cFF4444FFFor example:|r
UNIT_POWER_UPDATE:player, UNIT_AURA:nameplate:group PLAYER_TARGET_CHANGED CLEU:SPELL_CAST_SUCCESS TRIGGER:3:1
]=]
	--[[Translation missing --]]
	L["Custom trigger Update Throttle"] = "Custom trigger Update Throttle"
	--[[Translation missing --]]
	L["Custom Trigger: Ignore Lua Errors on OPTIONS event"] = "Custom Trigger: Ignore Lua Errors on OPTIONS event"
	--[[Translation missing --]]
	L["Custom Trigger: Send fake events instead of STATUS event"] = "Custom Trigger: Send fake events instead of STATUS event"
	--[[Translation missing --]]
	L["Custom Unload"] = "Custom Unload"
	--[[Translation missing --]]
	L["Custom Untrigger"] = "Custom Untrigger"
	--[[Translation missing --]]
	L["Debug Log"] = "Debug Log"
	--[[Translation missing --]]
	L["Debug Log:"] = "Debug Log:"
	--[[Translation missing --]]
	L["Default"] = "Default"
	--[[Translation missing --]]
	L["Default Color"] = "Default Color"
	--[[Translation missing --]]
	L["Delay"] = "Delay"
	--[[Translation missing --]]
	L["Delete"] = "Delete"
	--[[Translation missing --]]
	L["Delete all"] = "Delete all"
	--[[Translation missing --]]
	L["Delete children and group"] = "Delete children and group"
	--[[Translation missing --]]
	L["Delete Entry"] = "Delete Entry"
	--[[Translation missing --]]
	L["Deleting auras: "] = "Deleting auras: "
	--[[Translation missing --]]
	L["Description Text"] = "Description Text"
	--[[Translation missing --]]
	L["Determines how many entries can be in the table."] = "Determines how many entries can be in the table."
	--[[Translation missing --]]
	L["Differences"] = "Differences"
	--[[Translation missing --]]
	L["Disallow Entry Reordering"] = "Disallow Entry Reordering"
	--[[Translation missing --]]
	L["Discord"] = "Discord"
	--[[Translation missing --]]
	L["Display Name"] = "Display Name"
	--[[Translation missing --]]
	L["Display Text"] = "Display Text"
	--[[Translation missing --]]
	L["Displays a text, works best in combination with other displays"] = "Displays a text, works best in combination with other displays"
	--[[Translation missing --]]
	L["Distribute Horizontally"] = "Distribute Horizontally"
	--[[Translation missing --]]
	L["Distribute Vertically"] = "Distribute Vertically"
	--[[Translation missing --]]
	L["Do not group this display"] = "Do not group this display"
	--[[Translation missing --]]
	L["Do you want to enable updates for this aura"] = "Do you want to enable updates for this aura"
	--[[Translation missing --]]
	L["Do you want to ignore updates for this aura"] = "Do you want to ignore updates for this aura"
	--[[Translation missing --]]
	L["Documentation"] = "Documentation"
	--[[Translation missing --]]
	L["Done"] = "Done"
	--[[Translation missing --]]
	L["Drag to move"] = "Drag to move"
	--[[Translation missing --]]
	L["Duplicate"] = "Duplicate"
	--[[Translation missing --]]
	L["Duplicate All"] = "Duplicate All"
	--[[Translation missing --]]
	L["Duration (s)"] = "Duration (s)"
	--[[Translation missing --]]
	L["Duration Info"] = "Duration Info"
	--[[Translation missing --]]
	L["Dynamic Duration"] = "Dynamic Duration"
	--[[Translation missing --]]
	L["Dynamic Group"] = "Dynamic Group"
	--[[Translation missing --]]
	L["Dynamic Group Settings"] = "Dynamic Group Settings"
	--[[Translation missing --]]
	L["Dynamic Information"] = "Dynamic Information"
	--[[Translation missing --]]
	L["Dynamic information from first active trigger"] = "Dynamic information from first active trigger"
	--[[Translation missing --]]
	L["Dynamic information from Trigger %i"] = "Dynamic information from Trigger %i"
	--[[Translation missing --]]
	L["Dynamic Text Replacements"] = "Dynamic Text Replacements"
	--[[Translation missing --]]
	L["Ease Strength"] = "Ease Strength"
	--[[Translation missing --]]
	L["Ease type"] = "Ease type"
	--[[Translation missing --]]
	L["eliding"] = "eliding"
	--[[Translation missing --]]
	L["Else If"] = "Else If"
	--[[Translation missing --]]
	L["Else If %s"] = "Else If %s"
	--[[Translation missing --]]
	L["Empty Base Region"] = "Empty Base Region"
	--[[Translation missing --]]
	L["Enable \"Edge\" part of the overlay"] = "Enable \"Edge\" part of the overlay"
	--[[Translation missing --]]
	L["Enable \"swipe\" part of the overlay"] = "Enable \"swipe\" part of the overlay"
	--[[Translation missing --]]
	L["Enable Debug Log"] = "Enable Debug Log"
	--[[Translation missing --]]
	L["Enable Debug Logging"] = "Enable Debug Logging"
	--[[Translation missing --]]
	L["Enable Gradient"] = "Enable Gradient"
	--[[Translation missing --]]
	L["Enable Swipe"] = "Enable Swipe"
	--[[Translation missing --]]
	L["Enable the \"Swipe\" radial overlay"] = "Enable the \"Swipe\" radial overlay"
	--[[Translation missing --]]
	L["Enabled"] = "Enabled"
	--[[Translation missing --]]
	L["End Angle"] = "End Angle"
	--[[Translation missing --]]
	L["End of %s"] = "End of %s"
	--[[Translation missing --]]
	L["Enemy nameplate(s) found"] = "Enemy nameplate(s) found"
	--[[Translation missing --]]
	L["Enter a Spell ID. You can use the addon idTip to determine spell ids."] = "Enter a Spell ID. You can use the addon idTip to determine spell ids."
	--[[Translation missing --]]
	L["Enter an Aura Name, partial Aura Name, or Spell ID. A Spell ID will match any spells with the same name."] = "Enter an Aura Name, partial Aura Name, or Spell ID. A Spell ID will match any spells with the same name."
	--[[Translation missing --]]
	L["Enter Author Mode"] = "Enter Author Mode"
	--[[Translation missing --]]
	L["Enter in a value for the tick's placement."] = "Enter in a value for the tick's placement."
	--[[Translation missing --]]
	L["Enter static or relative values with %"] = "Enter static or relative values with %"
	--[[Translation missing --]]
	L["Enter User Mode"] = "Enter User Mode"
	--[[Translation missing --]]
	L["Enter user mode."] = "Enter user mode."
	--[[Translation missing --]]
	L["Entry %i"] = "Entry %i"
	--[[Translation missing --]]
	L["Entry limit"] = "Entry limit"
	--[[Translation missing --]]
	L["Entry Name Source"] = "Entry Name Source"
	L["Event Type"] = "Tipo di Evento"
	--[[Translation missing --]]
	L["Everything"] = "Everything"
	--[[Translation missing --]]
	L["Exact Item Match"] = "Exact Item Match"
	--[[Translation missing --]]
	L["Exact Spell Match"] = "Exact Spell Match"
	--[[Translation missing --]]
	L["Expand"] = "Expand"
	--[[Translation missing --]]
	L["Expand all loaded displays"] = "Expand all loaded displays"
	--[[Translation missing --]]
	L["Expand all non-loaded displays"] = "Expand all non-loaded displays"
	--[[Translation missing --]]
	L["Expand all pending Import"] = "Expand all pending Import"
	--[[Translation missing --]]
	L["Expansion is disabled because this group has no children"] = "Expansion is disabled because this group has no children"
	--[[Translation missing --]]
	L["Export debug table..."] = "Export debug table..."
	--[[Translation missing --]]
	L["Export..."] = "Export..."
	--[[Translation missing --]]
	L["Exporting"] = "Exporting"
	--[[Translation missing --]]
	L["External"] = "External"
	--[[Translation missing --]]
	L["Extra Height"] = "Extra Height"
	--[[Translation missing --]]
	L["Extra Width"] = "Extra Width"
	--[[Translation missing --]]
	L["Fade"] = "Fade"
	--[[Translation missing --]]
	L["Fadeout Sound"] = "Fadeout Sound"
	--[[Translation missing --]]
	L["Fadeout Time (seconds)"] = "Fadeout Time (seconds)"
	--[[Translation missing --]]
	L["Fetch Affected/Unaffected Names and Units"] = "Fetch Affected/Unaffected Names and Units"
	--[[Translation missing --]]
	L["Fetch Raid Mark Information"] = "Fetch Raid Mark Information"
	--[[Translation missing --]]
	L["Fetch Role Information"] = "Fetch Role Information"
	--[[Translation missing --]]
	L["Fetch Tooltip Information"] = "Fetch Tooltip Information"
	--[[Translation missing --]]
	L["File Height"] = "File Height"
	--[[Translation missing --]]
	L["File Width"] = "File Width"
	--[[Translation missing --]]
	L["Filter based on the spell Name string."] = "Filter based on the spell Name string."
	--[[Translation missing --]]
	L["Filter by Arena Spec"] = "Filter by Arena Spec"
	--[[Translation missing --]]
	L["Filter by Class"] = "Filter by Class"
	--[[Translation missing --]]
	L["Filter by Group Role"] = "Filter by Group Role"
	--[[Translation missing --]]
	L["Filter by Hostility"] = "Filter by Hostility"
	--[[Translation missing --]]
	L["Filter by Npc ID"] = "Filter by Npc ID"
	--[[Translation missing --]]
	L["Filter by Raid Role"] = "Filter by Raid Role"
	--[[Translation missing --]]
	L["Filter by Specialization"] = "Filter by Specialization"
	--[[Translation missing --]]
	L["Filter by Unit Name"] = "Filter by Unit Name"
	--[[Translation missing --]]
	L[ [=[Filter formats: 'Name', 'Name-Realm', '-Realm'.

Supports multiple entries, separated by commas
Can use \ to escape -.]=] ] = [=[Filter formats: 'Name', 'Name-Realm', '-Realm'.

Supports multiple entries, separated by commas
Can use \ to escape -.]=]
	--[[Translation missing --]]
	L[ [=[Filter to only dispellable de/buffs of the given type(s)
Bleed classification via LibDispel]=] ] = [=[Filter to only dispellable de/buffs of the given type(s)
Bleed classification via LibDispel]=]
	--[[Translation missing --]]
	L["Find Auras"] = "Find Auras"
	--[[Translation missing --]]
	L["Finish"] = "Finish"
	--[[Translation missing --]]
	L["Finishing..."] = "Finishing..."
	--[[Translation missing --]]
	L["Fire Orb"] = "Fire Orb"
	--[[Translation missing --]]
	L["Flat Framelevels"] = "Flat Framelevels"
	--[[Translation missing --]]
	L["Foreground Texture"] = "Foreground Texture"
	--[[Translation missing --]]
	L["Format for %s"] = "Format for %s"
	--[[Translation missing --]]
	L["Found a Bug?"] = "Found a Bug?"
	--[[Translation missing --]]
	L["Frame"] = "Frame"
	--[[Translation missing --]]
	L["Frame Count"] = "Frame Count"
	--[[Translation missing --]]
	L["Frame Height"] = "Frame Height"
	--[[Translation missing --]]
	L["Frame Rate"] = "Frame Rate"
	--[[Translation missing --]]
	L["Frame Strata"] = "Frame Strata"
	--[[Translation missing --]]
	L["Frame Width"] = "Frame Width"
	--[[Translation missing --]]
	L["Full Bar"] = "Full Bar"
	--[[Translation missing --]]
	L["Full Circle"] = "Full Circle"
	--[[Translation missing --]]
	L["Global Conditions"] = "Global Conditions"
	--[[Translation missing --]]
	L["Glow %s"] = "Glow %s"
	--[[Translation missing --]]
	L["Glow Action"] = "Glow Action"
	--[[Translation missing --]]
	L["Glow Anchor"] = "Glow Anchor"
	--[[Translation missing --]]
	L["Glow Color"] = "Glow Color"
	--[[Translation missing --]]
	L["Glow Frame Type"] = "Glow Frame Type"
	--[[Translation missing --]]
	L["Glow Type"] = "Glow Type"
	--[[Translation missing --]]
	L["Green Rune"] = "Green Rune"
	--[[Translation missing --]]
	L["Grid direction"] = "Grid direction"
	--[[Translation missing --]]
	L["Group (verb)"] = "Group"
	--[[Translation missing --]]
	L["Group Alpha"] = "Group Alpha"
	--[[Translation missing --]]
	L[ [=[Group and anchor each auras by frame.

- Nameplates: attach to nameplates per unit.
- Unit Frames: attach to unit frame buttons per unit.
- Custom Frames: choose which frame each region should be anchored to.]=] ] = [=[Group and anchor each auras by frame.

- Nameplates: attach to nameplates per unit.
- Unit Frames: attach to unit frame buttons per unit.
- Custom Frames: choose which frame each region should be anchored to.]=]
	--[[Translation missing --]]
	L["Group aura count description"] = [=[The amount of units of type '%s' which must be affected by one or more of the given auras for the display to trigger.
If the entered number is a whole number (e.g. 5), the number of affected units will be compared with the entered number.
If the entered number is a decimal (e.g. 0.5), fraction (e.g. 1/2), or percentage (e.g. 50%%), then that fraction of the %s must be affected.

|cFF4444FFFor example:|r
|cFF00CC00> 0|r will trigger when any unit of type '%s' is affected
|cFF00CC00= 100%%|r will trigger when every unit of type '%s' is affected
|cFF00CC00!= 2|r will trigger when the number of units of type '%s' affected is not exactly 2
|cFF00CC00<= 0.8|r will trigger when less than 80%% of the units of type '%s' is affected (4 of 5 party members, 8 of 10 or 20 of 25 raid members)
|cFF00CC00> 1/2|r will trigger when more than half of the units of type '%s' is affected
]=]
	--[[Translation missing --]]
	L["Group by Frame"] = "Group by Frame"
	--[[Translation missing --]]
	L["Group Description"] = "Group Description"
	--[[Translation missing --]]
	L["Group Icon"] = "Group Icon"
	--[[Translation missing --]]
	L["Group key"] = "Group key"
	--[[Translation missing --]]
	L["Group Options"] = "Group Options"
	--[[Translation missing --]]
	L["Group player(s) found"] = "Group player(s) found"
	--[[Translation missing --]]
	L["Group Role"] = "Group Role"
	--[[Translation missing --]]
	L["Group Scale"] = "Group Scale"
	--[[Translation missing --]]
	L["Group Settings"] = "Group Settings"
	--[[Translation missing --]]
	L["Hawk"] = "Hawk"
	--[[Translation missing --]]
	L["Help"] = "Help"
	--[[Translation missing --]]
	L["Hide Background"] = "Hide Background"
	--[[Translation missing --]]
	L["Hide Glows applied by this aura"] = "Hide Glows applied by this aura"
	--[[Translation missing --]]
	L["Hide on"] = "Hide on"
	--[[Translation missing --]]
	L["Hide this group's children"] = "Hide this group's children"
	--[[Translation missing --]]
	L["Highlights"] = "Highlights"
	--[[Translation missing --]]
	L["Horizontal Align"] = "Horizontal Align"
	--[[Translation missing --]]
	L["Horizontal Bar"] = "Horizontal Bar"
	--[[Translation missing --]]
	L["Huge Icon"] = "Huge Icon"
	--[[Translation missing --]]
	L["Hybrid Position"] = "Hybrid Position"
	--[[Translation missing --]]
	L["Hybrid Sort Mode"] = "Hybrid Sort Mode"
	--[[Translation missing --]]
	L["Icon - The icon associated with the display"] = "Icon - The icon associated with the display"
	--[[Translation missing --]]
	L["Icon Info"] = "Icon Info"
	--[[Translation missing --]]
	L["Icon Inset"] = "Icon Inset"
	--[[Translation missing --]]
	L["Icon Picker"] = "Icon Picker"
	--[[Translation missing --]]
	L["Icon Position"] = "Icon Position"
	--[[Translation missing --]]
	L["Icon Settings"] = "Icon Settings"
	--[[Translation missing --]]
	L["Icon Source"] = "Icon Source"
	--[[Translation missing --]]
	L["If"] = "If"
	--[[Translation missing --]]
	L["If %s"] = "If %s"
	--[[Translation missing --]]
	L["If checked, then the combo box in the User settings will be sorted."] = "If checked, then the combo box in the User settings will be sorted."
	--[[Translation missing --]]
	L["If checked, then the user will see a multi line edit box. This is useful for inputting large amounts of text."] = "If checked, then the user will see a multi line edit box. This is useful for inputting large amounts of text."
	--[[Translation missing --]]
	L["If checked, then this group will not merge with other group when selecting multiple auras."] = "If checked, then this group will not merge with other group when selecting multiple auras."
	--[[Translation missing --]]
	L["If checked, then this option group can be temporarily collapsed by the user."] = "If checked, then this option group can be temporarily collapsed by the user."
	--[[Translation missing --]]
	L["If checked, then this option group will start collapsed."] = "If checked, then this option group will start collapsed."
	--[[Translation missing --]]
	L["If checked, then this separator will include text. Otherwise, it will be just a horizontal line."] = "If checked, then this separator will include text. Otherwise, it will be just a horizontal line."
	--[[Translation missing --]]
	L["If checked, then this space will span across multiple lines."] = "If checked, then this space will span across multiple lines."
	--[[Translation missing --]]
	L["If unchecked, then a default color will be used (usually yellow)"] = "If unchecked, then a default color will be used (usually yellow)"
	--[[Translation missing --]]
	L["If unchecked, then this space will fill the entire line it is on in User Mode."] = "If unchecked, then this space will fill the entire line it is on in User Mode."
	--[[Translation missing --]]
	L["Ignore out of casting range"] = "Ignore out of casting range"
	--[[Translation missing --]]
	L["Ignore out of checking range"] = "Ignore out of checking range"
	--[[Translation missing --]]
	L["Ignore Wago updates"] = "Ignore Wago updates"
	--[[Translation missing --]]
	L["Ignored"] = "Ignored"
	--[[Translation missing --]]
	L["Ignored Aura Name"] = "Ignored Aura Name"
	--[[Translation missing --]]
	L["Ignored Exact Spell ID(s)"] = "Ignored Exact Spell ID(s)"
	--[[Translation missing --]]
	L["Ignored Name(s)"] = "Ignored Name(s)"
	--[[Translation missing --]]
	L["Ignored Spell ID"] = "Ignored Spell ID"
	--[[Translation missing --]]
	L["Import"] = "Import"
	--[[Translation missing --]]
	L["Import / Export"] = "Import / Export"
	--[[Translation missing --]]
	L["Import a display from an encoded string"] = "Import a display from an encoded string"
	--[[Translation missing --]]
	L["Import as Copy"] = "Import as Copy"
	--[[Translation missing --]]
	L["Import has no UID, cannot be matched to existing auras."] = "Import has no UID, cannot be matched to existing auras."
	--[[Translation missing --]]
	L["Importing"] = "Importing"
	--[[Translation missing --]]
	L["Importing %s"] = "Importing %s"
	--[[Translation missing --]]
	L["Importing a group with %s child auras."] = "Importing a group with %s child auras."
	--[[Translation missing --]]
	L["Importing a stand-alone aura."] = "Importing a stand-alone aura."
	--[[Translation missing --]]
	L["Importing...."] = "Importing...."
	--[[Translation missing --]]
	L["Incompatible changes to group region types detected"] = "Incompatible changes to group region types detected"
	--[[Translation missing --]]
	L["Incompatible changes to group structure detected"] = "Incompatible changes to group structure detected"
	--[[Translation missing --]]
	L["Indent Size"] = "Indent Size"
	--[[Translation missing --]]
	L["Inner"] = "Inner"
	--[[Translation missing --]]
	L["Insert text replacement codes to make text dynamic."] = "Insert text replacement codes to make text dynamic."
	--[[Translation missing --]]
	L["Invalid Item ID"] = "Invalid Item ID"
	--[[Translation missing --]]
	L["Invalid Item Name/ID/Link"] = "Invalid Item Name/ID/Link"
	--[[Translation missing --]]
	L["Invalid Spell ID"] = "Invalid Spell ID"
	--[[Translation missing --]]
	L["Invalid Spell Name/ID/Link"] = "Invalid Spell Name/ID/Link"
	--[[Translation missing --]]
	L["Invalid target aura"] = "Invalid target aura"
	--[[Translation missing --]]
	L["Invalid type for '%s'. Expected 'bool', 'number', 'select', 'string', 'timer' or 'elapsedTimer'."] = "Invalid type for '%s'. Expected 'bool', 'number', 'select', 'string', 'timer' or 'elapsedTimer'."
	--[[Translation missing --]]
	L["Invalid type for property '%s' in '%s'. Expected '%s'"] = "Invalid type for property '%s' in '%s'. Expected '%s'"
	--[[Translation missing --]]
	L["Inverse Slant"] = "Inverse Slant"
	--[[Translation missing --]]
	L["Invert the direction of progress"] = "Invert the direction of progress"
	--[[Translation missing --]]
	L["Is Boss Debuff"] = "Is Boss Debuff"
	--[[Translation missing --]]
	L["Is Stealable"] = "Is Stealable"
	--[[Translation missing --]]
	L["Is Unit"] = "Is Unit"
	--[[Translation missing --]]
	L["Justify"] = "Justify"
	--[[Translation missing --]]
	L["Keep Aspect Ratio"] = "Keep Aspect Ratio"
	--[[Translation missing --]]
	L["Keep your Wago imports up to date with the Companion App."] = "Keep your Wago imports up to date with the Companion App."
	--[[Translation missing --]]
	L["Large Input"] = "Large Input"
	--[[Translation missing --]]
	L["Leaf"] = "Leaf"
	--[[Translation missing --]]
	L["Left 2 HUD position"] = "Left 2 HUD position"
	--[[Translation missing --]]
	L["Left HUD position"] = "Left HUD position"
	--[[Translation missing --]]
	L["Length of |cFFFF0000%s|r"] = "Length of |cFFFF0000%s|r"
	--[[Translation missing --]]
	L["LibCompress: Galmok"] = "LibCompress: Galmok"
	--[[Translation missing --]]
	L["LibCustomGlow: Dooez"] = "LibCustomGlow: Dooez"
	--[[Translation missing --]]
	L["LibDeflate: Yoursafety"] = "LibDeflate: Yoursafety"
	--[[Translation missing --]]
	L["LibDispel: Simpy"] = "LibDispel: Simpy"
	--[[Translation missing --]]
	L["LibSerialize: Sanjo"] = "LibSerialize: Sanjo"
	--[[Translation missing --]]
	L["LibSpecialization: Funkeh"] = "LibSpecialization: Funkeh"
	--[[Translation missing --]]
	L["Limit"] = "Limit"
	--[[Translation missing --]]
	L["Line"] = "Line"
	--[[Translation missing --]]
	L["Linear Texture %s"] = "Linear Texture %s"
	--[[Translation missing --]]
	L["Linked aura: "] = "Linked aura: "
	--[[Translation missing --]]
	L["Linked Auras"] = "Linked Auras"
	--[[Translation missing --]]
	L["Load"] = "Load"
	--[[Translation missing --]]
	L["Loaded"] = "Loaded"
	--[[Translation missing --]]
	L["Loaded/Standby"] = "Loaded/Standby"
	--[[Translation missing --]]
	L["Lock Positions"] = "Lock Positions"
	--[[Translation missing --]]
	L["Low Mana"] = "Low Mana"
	--[[Translation missing --]]
	L["Magnetically Align"] = "Magnetically Align"
	--[[Translation missing --]]
	L["Main"] = "Main"
	--[[Translation missing --]]
	L["Manual with %i/%i"] = "Manual with %i/%i"
	--[[Translation missing --]]
	L["Matches the height setting of a horizontal bar or width for a vertical bar."] = "Matches the height setting of a horizontal bar or width for a vertical bar."
	--[[Translation missing --]]
	L["Max"] = "Max"
	--[[Translation missing --]]
	L["Max Length"] = "Max Length"
	--[[Translation missing --]]
	L["Maximum"] = "Maximum"
	--[[Translation missing --]]
	L["Media Type"] = "Media Type"
	--[[Translation missing --]]
	L["Medium Icon"] = "Medium Icon"
	--[[Translation missing --]]
	L["Min"] = "Min"
	--[[Translation missing --]]
	L["Minimum"] = "Minimum"
	--[[Translation missing --]]
	L["Model %s"] = "Model %s"
	--[[Translation missing --]]
	L["Model Picker"] = "Model Picker"
	--[[Translation missing --]]
	L["Model Settings"] = "Model Settings"
	--[[Translation missing --]]
	L["ModelPaths could not be loaded, the addon is %s"] = "ModelPaths could not be loaded, the addon is %s"
	--[[Translation missing --]]
	L["Move Above Group"] = "Move Above Group"
	--[[Translation missing --]]
	L["Move Below Group"] = "Move Below Group"
	--[[Translation missing --]]
	L["Move Down"] = "Move Down"
	--[[Translation missing --]]
	L["Move Entry Down"] = "Move Entry Down"
	--[[Translation missing --]]
	L["Move Entry Up"] = "Move Entry Up"
	--[[Translation missing --]]
	L["Move Into Above Group"] = "Move Into Above Group"
	--[[Translation missing --]]
	L["Move Into Below Group"] = "Move Into Below Group"
	--[[Translation missing --]]
	L["Move this display down in its group's order"] = "Move this display down in its group's order"
	--[[Translation missing --]]
	L["Move this display up in its group's order"] = "Move this display up in its group's order"
	--[[Translation missing --]]
	L["Move Up"] = "Move Up"
	--[[Translation missing --]]
	L["Moving auras: "] = "Moving auras: "
	--[[Translation missing --]]
	L["Multiple Displays"] = "Multiple Displays"
	--[[Translation missing --]]
	L["Multiselect ignored tooltip"] = [=[|cFFFF0000Ignored|r - |cFF777777Single|r - |cFF777777Multiple|r
This option will not be used to determine when this display should load]=]
	--[[Translation missing --]]
	L["Multiselect multiple tooltip"] = [=[|cFF777777Ignored|r - |cFF777777Single|r - |cFF00FF00Multiple|r
Any number of matching values can be picked]=]
	--[[Translation missing --]]
	L["Multiselect single tooltip"] = [=[|cFF777777Ignored|r - |cFF00FF00Single|r - |cFF777777Multiple|r
Only a single matching value can be picked]=]
	--[[Translation missing --]]
	L["Must be a power of 2"] = "Must be a power of 2"
	--[[Translation missing --]]
	L["Name - The name of the display (usually an aura name), or the display's ID if there is no dynamic name"] = "Name - The name of the display (usually an aura name), or the display's ID if there is no dynamic name"
	--[[Translation missing --]]
	L["Name Info"] = "Name Info"
	--[[Translation missing --]]
	L["Name Pattern Match"] = "Name Pattern Match"
	--[[Translation missing --]]
	L["Name:"] = "Name:"
	--[[Translation missing --]]
	L["Negator"] = "Not"
	--[[Translation missing --]]
	L["New Aura"] = "New Aura"
	--[[Translation missing --]]
	L["New Template"] = "New Template"
	--[[Translation missing --]]
	L["New Value"] = "New Value"
	--[[Translation missing --]]
	L["No Children"] = "No Children"
	--[[Translation missing --]]
	L["No Logs saved."] = "No Logs saved."
	--[[Translation missing --]]
	L["Not a table"] = "Not a table"
	--[[Translation missing --]]
	L["Not all children have the same value for this option"] = "Not all children have the same value for this option"
	--[[Translation missing --]]
	L["Not Loaded"] = "Not Loaded"
	--[[Translation missing --]]
	L["Note: Automated Messages to SAY and YELL are blocked outside of Instances."] = "Note: Automated Messages to SAY and YELL are blocked outside of Instances."
	--[[Translation missing --]]
	L["Note: This progress source does not provide a total value/duration. A total value/duration must be set via \"Set Maximum Progress\""] = "Note: This progress source does not provide a total value/duration. A total value/duration must be set via \"Set Maximum Progress\""
	--[[Translation missing --]]
	L["Number of Entries"] = "Number of Entries"
	--[[Translation missing --]]
	L[ [=[Occurrence of the event, reset when aura is unloaded
Can be a range of values
Can have multiple values separated by a comma or a space

Examples:
2nd 5th and 6th events: 2, 5, 6
2nd to 6th: 2-6
every 2 events: /2
every 3 events starting from 2nd: 2/3
every 3 events starting from 2nd and ending at 11th: 2-11/3]=] ] = [=[Occurrence of the event, reset when aura is unloaded
Can be a range of values
Can have multiple values separated by a comma or a space

Examples:
2nd 5th and 6th events: 2, 5, 6
2nd to 6th: 2-6
every 2 events: /2
every 3 events starting from 2nd: 2/3
every 3 events starting from 2nd and ending at 11th: 2-11/3]=]
	--[[Translation missing --]]
	L["OFF"] = "OFF"
	--[[Translation missing --]]
	L["Offer a guided way to create auras for your character"] = "Offer a guided way to create auras for your character"
	--[[Translation missing --]]
	L["Offset by |cFFFF0000%s|r/|cFFFF0000%s|r"] = "Offset by |cFFFF0000%s|r/|cFFFF0000%s|r"
	--[[Translation missing --]]
	L["Offset by 1px"] = "Offset by 1px"
	--[[Translation missing --]]
	L["Okay"] = "Okay"
	--[[Translation missing --]]
	L["ON"] = "ON"
	--[[Translation missing --]]
	L["On Hide"] = "On Hide"
	--[[Translation missing --]]
	L["On Show"] = "On Show"
	--[[Translation missing --]]
	L["Only Match auras cast by a player (not an npc)"] = "Only Match auras cast by a player (not an npc)"
	--[[Translation missing --]]
	L["Only match auras cast by people other than the player or their pet"] = "Only match auras cast by people other than the player or their pet"
	--[[Translation missing --]]
	L["Only match auras cast by the player or their pet"] = "Only match auras cast by the player or their pet"
	--[[Translation missing --]]
	L["Operator"] = "Operator"
	--[[Translation missing --]]
	L["Option %i"] = "Option %i"
	--[[Translation missing --]]
	L["Option key"] = "Option key"
	--[[Translation missing --]]
	L["Option Type"] = "Option Type"
	--[[Translation missing --]]
	L["Options will open after combat ends."] = "Options will open after combat ends."
	--[[Translation missing --]]
	L["or"] = "or"
	--[[Translation missing --]]
	L["or %s"] = "or %s"
	--[[Translation missing --]]
	L["Orange Rune"] = "Orange Rune"
	--[[Translation missing --]]
	L["Our translators (too many to name)"] = "Our translators (too many to name)"
	--[[Translation missing --]]
	L["Outer"] = "Outer"
	--[[Translation missing --]]
	L["Overflow"] = "Overflow"
	--[[Translation missing --]]
	L["Overlay %s Info"] = "Overlay %s Info"
	--[[Translation missing --]]
	L["Overlays"] = "Overlays"
	--[[Translation missing --]]
	L["Own Only"] = "Own Only"
	--[[Translation missing --]]
	L["Paste Action Settings"] = "Paste Action Settings"
	--[[Translation missing --]]
	L["Paste Animations Settings"] = "Paste Animations Settings"
	--[[Translation missing --]]
	L["Paste Author Options Settings"] = "Paste Author Options Settings"
	--[[Translation missing --]]
	L["Paste Condition Settings"] = "Paste Condition Settings"
	--[[Translation missing --]]
	L["Paste Custom Configuration"] = "Paste Custom Configuration"
	--[[Translation missing --]]
	L["Paste Display Settings"] = "Paste Display Settings"
	--[[Translation missing --]]
	L["Paste Group Settings"] = "Paste Group Settings"
	--[[Translation missing --]]
	L["Paste Load Settings"] = "Paste Load Settings"
	--[[Translation missing --]]
	L["Paste Settings"] = "Paste Settings"
	--[[Translation missing --]]
	L["Paste text below"] = "Paste text below"
	--[[Translation missing --]]
	L["Paste Trigger Settings"] = "Paste Trigger Settings"
	--[[Translation missing --]]
	L["Places a tick on the bar"] = "Places a tick on the bar"
	--[[Translation missing --]]
	L["Play Sound"] = "Play Sound"
	--[[Translation missing --]]
	L["Portrait Zoom"] = "Portrait Zoom"
	--[[Translation missing --]]
	L["Position and Size Settings"] = "Position and Size Settings"
	--[[Translation missing --]]
	L["Preferred Match"] = "Preferred Match"
	--[[Translation missing --]]
	L["Premade Auras"] = "Premade Auras"
	--[[Translation missing --]]
	L["Premade Snippets"] = "Premade Snippets"
	--[[Translation missing --]]
	L["Preparing auras: "] = "Preparing auras: "
	--[[Translation missing --]]
	L["Press Ctrl+C to copy"] = "Press Ctrl+C to copy"
	--[[Translation missing --]]
	L["Press Ctrl+C to copy the URL"] = "Press Ctrl+C to copy the URL"
	--[[Translation missing --]]
	L["Prevent Merging"] = "Prevent Merging"
	--[[Translation missing --]]
	L["Progress - The remaining time of a timer, or a non-timer value"] = "Progress - The remaining time of a timer, or a non-timer value"
	--[[Translation missing --]]
	L["Progress Bar"] = "Progress Bar"
	--[[Translation missing --]]
	L["Progress Bar Settings"] = "Progress Bar Settings"
	--[[Translation missing --]]
	L["Progress Settings"] = "Progress Settings"
	--[[Translation missing --]]
	L["Progress Texture"] = "Progress Texture"
	--[[Translation missing --]]
	L["Progress Texture Settings"] = "Progress Texture Settings"
	--[[Translation missing --]]
	L["Purple Rune"] = "Purple Rune"
	--[[Translation missing --]]
	L["Put this display in a group"] = "Put this display in a group"
	--[[Translation missing --]]
	L["Range in yards"] = "Range in yards"
	--[[Translation missing --]]
	L["Ready for Install"] = "Ready for Install"
	--[[Translation missing --]]
	L["Ready for Update"] = "Ready for Update"
	--[[Translation missing --]]
	L["Re-center X"] = "Re-center X"
	--[[Translation missing --]]
	L["Re-center Y"] = "Re-center Y"
	--[[Translation missing --]]
	L["Reciprocal TRIGGER:# requests will be ignored!"] = "Reciprocal TRIGGER:# requests will be ignored!"
	--[[Translation missing --]]
	L["Redo"] = "Redo"
	--[[Translation missing --]]
	L["Regions of type \"%s\" are not supported."] = "Regions of type \"%s\" are not supported."
	--[[Translation missing --]]
	L["Remove"] = "Remove"
	--[[Translation missing --]]
	L["Remove All Sounds"] = "Remove All Sounds"
	--[[Translation missing --]]
	L["Remove All Text To Speech"] = "Remove All Text To Speech"
	--[[Translation missing --]]
	L["Remove this display from its group"] = "Remove this display from its group"
	--[[Translation missing --]]
	L["Remove this property"] = "Remove this property"
	--[[Translation missing --]]
	L["Rename"] = "Rename"
	--[[Translation missing --]]
	L["Repeat After"] = "Repeat After"
	--[[Translation missing --]]
	L["Repeat every"] = "Repeat every"
	--[[Translation missing --]]
	L["Report bugs on our issue tracker."] = "Report bugs on our issue tracker."
	--[[Translation missing --]]
	L["Require unit from trigger"] = "Require unit from trigger"
	--[[Translation missing --]]
	L["Required for Activation"] = "Required for Activation"
	--[[Translation missing --]]
	L["Requires LibSpecialization, that is e.g. a up-to date WeakAuras version"] = "Requires LibSpecialization, that is e.g. a up-to date WeakAuras version"
	--[[Translation missing --]]
	L["Reset all options to their default values."] = "Reset all options to their default values."
	--[[Translation missing --]]
	L["Reset Entry"] = "Reset Entry"
	--[[Translation missing --]]
	L["Reset to Defaults"] = "Reset to Defaults"
	--[[Translation missing --]]
	L["Right 2 HUD position"] = "Right 2 HUD position"
	--[[Translation missing --]]
	L["Right HUD position"] = "Right HUD position"
	--[[Translation missing --]]
	L["Right-click for more options"] = "Right-click for more options"
	--[[Translation missing --]]
	L["Rotate"] = "Rotate"
	--[[Translation missing --]]
	L["Rotate In"] = "Rotate In"
	--[[Translation missing --]]
	L["Rotate Out"] = "Rotate Out"
	--[[Translation missing --]]
	L["Rotate Text"] = "Rotate Text"
	--[[Translation missing --]]
	L["Rotation Mode"] = "Rotation Mode"
	--[[Translation missing --]]
	L["Row Space"] = "Row Space"
	--[[Translation missing --]]
	L["Row Width"] = "Row Width"
	--[[Translation missing --]]
	L["Rows"] = "Rows"
	--[[Translation missing --]]
	L["Run on..."] = "Run on..."
	--[[Translation missing --]]
	L["Same"] = "Same"
	--[[Translation missing --]]
	L["Same texture as Foreground"] = "Same texture as Foreground"
	--[[Translation missing --]]
	L["Saved Data"] = "Saved Data"
	--[[Translation missing --]]
	L["Scale Factor"] = "Scale Factor"
	--[[Translation missing --]]
	L["Search API"] = "Search API"
	--[[Translation missing --]]
	L["Select Talent"] = "Select Talent"
	--[[Translation missing --]]
	L["Select the auras you always want to be listed first"] = "Select the auras you always want to be listed first"
	--[[Translation missing --]]
	L["Selected Frame"] = "Selected Frame"
	--[[Translation missing --]]
	L["Send To"] = "Send To"
	--[[Translation missing --]]
	L["Separator Text"] = "Separator Text"
	--[[Translation missing --]]
	L["Separator text"] = "Separator text"
	--[[Translation missing --]]
	L["Set Maximum Progress"] = "Set Maximum Progress"
	--[[Translation missing --]]
	L["Set Minimum Progress"] = "Set Minimum Progress"
	--[[Translation missing --]]
	L["Set Parent to Anchor"] = "Set Parent to Anchor"
	--[[Translation missing --]]
	L["Set Thumbnail Icon"] = "Set Thumbnail Icon"
	--[[Translation missing --]]
	L["Sets the anchored frame as the aura's parent, causing the aura to inherit attributes such as visibility and scale."] = "Sets the anchored frame as the aura's parent, causing the aura to inherit attributes such as visibility and scale."
	--[[Translation missing --]]
	L["Settings"] = "Settings"
	--[[Translation missing --]]
	L["Shadow Color"] = "Shadow Color"
	--[[Translation missing --]]
	L["Shadow X Offset"] = "Shadow X Offset"
	--[[Translation missing --]]
	L["Shadow Y Offset"] = "Shadow Y Offset"
	--[[Translation missing --]]
	L["Shift-click to create chat link"] = "Shift-click to create a |cFF8800FF[Chat Link]"
	--[[Translation missing --]]
	L["Show \"Edge\""] = "Show \"Edge\""
	--[[Translation missing --]]
	L["Show \"Swipe\""] = "Show \"Swipe\""
	--[[Translation missing --]]
	L["Show and Clone Settings"] = "Show and Clone Settings"
	--[[Translation missing --]]
	L["Show Border"] = "Show Border"
	--[[Translation missing --]]
	L["Show Circular Texture"] = "Show Circular Texture"
	--[[Translation missing --]]
	L["Show Debug Logs"] = "Show Debug Logs"
	--[[Translation missing --]]
	L["Show Glow"] = "Show Glow"
	--[[Translation missing --]]
	L["Show Icon"] = "Show Icon"
	--[[Translation missing --]]
	L["Show If Unit Does Not Exist"] = "Show If Unit Does Not Exist"
	--[[Translation missing --]]
	L["Show Linear Texture"] = "Show Linear Texture"
	--[[Translation missing --]]
	L["Show Matches for"] = "Show Matches for"
	--[[Translation missing --]]
	L["Show Matches for Units"] = "Show Matches for Units"
	--[[Translation missing --]]
	L["Show Model"] = "Show Model"
	--[[Translation missing --]]
	L["Show model of unit "] = "Show model of unit "
	--[[Translation missing --]]
	L["Show Sound Setting"] = "Show Sound Setting"
	--[[Translation missing --]]
	L["Show Spark"] = "Show Spark"
	--[[Translation missing --]]
	L["Show Stop Motion"] = "Show Stop Motion"
	--[[Translation missing --]]
	L["Show Text"] = "Show Text"
	--[[Translation missing --]]
	L["Show Text To Speech Setting"] = "Show Text To Speech Setting"
	--[[Translation missing --]]
	L["Show Texture"] = "Show Texture"
	--[[Translation missing --]]
	L["Show this group's children"] = "Show this group's children"
	--[[Translation missing --]]
	L["Show Tick"] = "Show Tick"
	--[[Translation missing --]]
	L["Shows a 3D model from the game files"] = "Shows a 3D model from the game files"
	--[[Translation missing --]]
	L["Shows a border"] = "Shows a border"
	--[[Translation missing --]]
	L["Shows a Circular Progress Texture"] = "Shows a Circular Progress Texture"
	--[[Translation missing --]]
	L["Shows a custom texture"] = "Shows a custom texture"
	--[[Translation missing --]]
	L["Shows a glow"] = "Shows a glow"
	--[[Translation missing --]]
	L["Shows a Linear Progress Texture"] = "Shows a Linear Progress Texture"
	--[[Translation missing --]]
	L["Shows a model"] = "Shows a model"
	--[[Translation missing --]]
	L["Shows a progress bar with name, timer, and icon"] = "Shows a progress bar with name, timer, and icon"
	--[[Translation missing --]]
	L["Shows a spell icon with an optional cooldown overlay"] = "Shows a spell icon with an optional cooldown overlay"
	--[[Translation missing --]]
	L["Shows a Stop Motion"] = "Shows a Stop Motion"
	--[[Translation missing --]]
	L["Shows a stop motion texture"] = "Shows a stop motion texture"
	--[[Translation missing --]]
	L["Shows a Texture"] = "Shows a Texture"
	--[[Translation missing --]]
	L["Shows a texture that changes based on duration"] = "Shows a texture that changes based on duration"
	--[[Translation missing --]]
	L["Shows nothing, except sub elements"] = "Shows nothing, except sub elements"
	--[[Translation missing --]]
	L["Shows one or more lines of text, which can include dynamic information such as progress or stacks"] = "Shows one or more lines of text, which can include dynamic information such as progress or stacks"
	--[[Translation missing --]]
	L["Size"] = "Size"
	--[[Translation missing --]]
	L["Slant Amount"] = "Slant Amount"
	--[[Translation missing --]]
	L["Slant Mode"] = "Slant Mode"
	--[[Translation missing --]]
	L["Slanted"] = "Slanted"
	--[[Translation missing --]]
	L["Slide"] = "Slide"
	--[[Translation missing --]]
	L["Slide In"] = "Slide In"
	--[[Translation missing --]]
	L["Slide Out"] = "Slide Out"
	--[[Translation missing --]]
	L["Slider Step Size"] = "Slider Step Size"
	--[[Translation missing --]]
	L["Small Icon"] = "Small Icon"
	--[[Translation missing --]]
	L["Smooth Progress"] = "Smooth Progress"
	--[[Translation missing --]]
	L["Snippets"] = "Snippets"
	--[[Translation missing --]]
	L["Soft Max"] = "Soft Max"
	--[[Translation missing --]]
	L["Soft Min"] = "Soft Min"
	--[[Translation missing --]]
	L["Sort"] = "Sort"
	--[[Translation missing --]]
	L["Sound Channel"] = "Sound Channel"
	--[[Translation missing --]]
	L["Sound File Path"] = "Sound File Path"
	--[[Translation missing --]]
	L["Sound Kit ID"] = "Sound Kit ID"
	--[[Translation missing --]]
	L["Space Horizontally"] = "Space Horizontally"
	--[[Translation missing --]]
	L["Space Vertically"] = "Space Vertically"
	--[[Translation missing --]]
	L["Spark Settings"] = "Spark Settings"
	--[[Translation missing --]]
	L["Spark Texture"] = "Spark Texture"
	--[[Translation missing --]]
	L["Specific Currency ID"] = "Specific Currency ID"
	--[[Translation missing --]]
	L["Spell Selection Filters"] = "Spell Selection Filters"
	--[[Translation missing --]]
	L["Stack Info"] = "Stack Info"
	--[[Translation missing --]]
	L["Stacks - The number of stacks of an aura (usually)"] = "Stacks - The number of stacks of an aura (usually)"
	--[[Translation missing --]]
	L["Standby"] = "Standby"
	--[[Translation missing --]]
	L["Star"] = "Star"
	--[[Translation missing --]]
	L["Start"] = "Start"
	--[[Translation missing --]]
	L["Start Angle"] = "Start Angle"
	--[[Translation missing --]]
	L["Start Collapsed"] = "Start Collapsed"
	--[[Translation missing --]]
	L["Start of %s"] = "Start of %s"
	--[[Translation missing --]]
	L["Step Size"] = "Step Size"
	--[[Translation missing --]]
	L["Stop Motion %s"] = "Stop Motion %s"
	--[[Translation missing --]]
	L["Stop Motion Settings"] = "Stop Motion Settings"
	--[[Translation missing --]]
	L["Stop Sound"] = "Stop Sound"
	--[[Translation missing --]]
	L["Stretched by Foreground"] = "Stretched by Foreground"
	--[[Translation missing --]]
	L["Sub Elements"] = "Sub Elements"
	--[[Translation missing --]]
	L["Sub Option %i"] = "Sub Option %i"
	--[[Translation missing --]]
	L["Subevent"] = "Subevent"
	--[[Translation missing --]]
	L["Subevent Suffix"] = "Subevent Suffix"
	--[[Translation missing --]]
	L["Swipe Overlay Settings"] = "Swipe Overlay Settings"
	--[[Translation missing --]]
	L["Templates could not be loaded, the addon is %s"] = "Templates could not be loaded, the addon is %s"
	--[[Translation missing --]]
	L["Temporary Group"] = "Temporary Group"
	--[[Translation missing --]]
	L["Text %s"] = "Text %s"
	--[[Translation missing --]]
	L["Text Color"] = "Text Color"
	--[[Translation missing --]]
	L["Text Settings"] = "Text Settings"
	--[[Translation missing --]]
	L["Texture %s"] = "Texture %s"
	--[[Translation missing --]]
	L["Texture Info"] = "Texture Info"
	--[[Translation missing --]]
	L["Texture Selection Mode"] = "Texture Selection Mode"
	--[[Translation missing --]]
	L["Texture Settings"] = "Texture Settings"
	--[[Translation missing --]]
	L["Texture Wrap"] = "Texture Wrap"
	--[[Translation missing --]]
	L["Texture X Offset"] = "Texture X Offset"
	--[[Translation missing --]]
	L["Texture Y Offset"] = "Texture Y Offset"
	--[[Translation missing --]]
	L["Thanks"] = "Thanks"
	--[[Translation missing --]]
	L["The addon ElvUI is enabled. It might add cooldown numbers to the swipe. You can configure these in the ElvUI settings"] = "The addon ElvUI is enabled. It might add cooldown numbers to the swipe. You can configure these in the ElvUI settings"
	--[[Translation missing --]]
	L["The addon OmniCC is enabled. It might add cooldown numbers to the swipe. You can configure these in the OmniCC settings"] = "The addon OmniCC is enabled. It might add cooldown numbers to the swipe. You can configure these in the OmniCC settings"
	--[[Translation missing --]]
	L["The duration of the animation in seconds."] = "The duration of the animation in seconds."
	--[[Translation missing --]]
	L["The duration of the animation in seconds. The finish animation does not start playing until after the display would normally be hidden."] = "The duration of the animation in seconds. The finish animation does not start playing until after the display would normally be hidden."
	--[[Translation missing --]]
	L["The group and all direct children will share the same base frame level."] = "The group and all direct children will share the same base frame level."
	--[[Translation missing --]]
	L["The trigger number is optional. When no trigger number is specified, the trigger selected via dynamic information will be used."] = "The trigger number is optional. When no trigger number is specified, the trigger selected via dynamic information will be used."
	--[[Translation missing --]]
	L["The type of trigger"] = "The type of trigger"
	--[[Translation missing --]]
	L["The WeakAuras Options Addon version %s doesn't match the WeakAuras version %s. If you updated the addon while the game was running, try restarting World of Warcraft. Otherwise try reinstalling WeakAuras"] = "The WeakAuras Options Addon version %s doesn't match the WeakAuras version %s. If you updated the addon while the game was running, try restarting World of Warcraft. Otherwise try reinstalling WeakAuras"
	--[[Translation missing --]]
	L["Then "] = "Then "
	--[[Translation missing --]]
	L["There are several special codes available to make this text dynamic. Click to view a list with all dynamic text codes."] = "There are several special codes available to make this text dynamic. Click to view a list with all dynamic text codes."
	--[[Translation missing --]]
	L["This adds %raidMark as text replacements."] = "This adds %raidMark as text replacements."
	--[[Translation missing --]]
	L["This adds %role, %roleIcon as text replacements. Does nothing if the unit is not a group member."] = "This adds %role, %roleIcon as text replacements. Does nothing if the unit is not a group member."
	--[[Translation missing --]]
	L["This adds %tooltip, %tooltip1, %tooltip2, %tooltip3 and %tooltip4 as text replacements and also allows filtering based on the tooltip content/values."] = "This adds %tooltip, %tooltip1, %tooltip2, %tooltip3 and %tooltip4 as text replacements and also allows filtering based on the tooltip content/values."
	--[[Translation missing --]]
	L[ [=[This aura contains custom Lua code.
Make sure you can trust the person who sent it!]=] ] = [=[This aura contains custom Lua code.
Make sure you can trust the person who sent it!]=]
	--[[Translation missing --]]
	L["This aura is marked as an update to an aura '%s', but cannot be used to update that aura. This usually happens if an aura is moved out of a group."] = "This aura is marked as an update to an aura '%s', but cannot be used to update that aura. This usually happens if an aura is moved out of a group."
	--[[Translation missing --]]
	L["This aura is marked as an update to auras '%s', but cannot be used to update them. This usually happens if an aura is moved out of a group."] = "This aura is marked as an update to auras '%s', but cannot be used to update them. This usually happens if an aura is moved out of a group."
	--[[Translation missing --]]
	L[ [=[This aura was created with a different version (%s) of World of Warcraft.
It might not work correctly!]=] ] = [=[This aura was created with a different version (%s) of World of Warcraft.
It might not work correctly!]=]
	--[[Translation missing --]]
	L[ [=[This aura was created with a newer version of WeakAuras.
Upgrade your version of WeakAuras or wait for next release before installing this aura.]=] ] = [=[This aura was created with a newer version of WeakAuras.
Upgrade your version of WeakAuras or wait for next release before installing this aura.]=]
	--[[Translation missing --]]
	L["This display is currently loaded"] = "This display is currently loaded"
	--[[Translation missing --]]
	L["This display is not currently loaded"] = "This display is not currently loaded"
	--[[Translation missing --]]
	L["This display is on standby, it will be loaded when needed."] = "This display is on standby, it will be loaded when needed."
	--[[Translation missing --]]
	L["This enables the collection of debug logs. Custom code can add debug information to the log through the function DebugPrint."] = "This enables the collection of debug logs. Custom code can add debug information to the log through the function DebugPrint."
	--[[Translation missing --]]
	L["This is a modified version of your aura, |cff9900FF%s.|r"] = "This is a modified version of your aura, |cff9900FF%s.|r"
	--[[Translation missing --]]
	L["This is a modified version of your group: |cff9900FF%s|r"] = "This is a modified version of your group: |cff9900FF%s|r"
	--[[Translation missing --]]
	L["This region of type \"%s\" is not supported."] = "This region of type \"%s\" is not supported."
	--[[Translation missing --]]
	L["This setting controls what widget is generated in user mode."] = "This setting controls what widget is generated in user mode."
	--[[Translation missing --]]
	L["Thumbnail Icon"] = "Thumbnail Icon"
	--[[Translation missing --]]
	L["Tick %s"] = "Tick %s"
	--[[Translation missing --]]
	L["Tick Area %s"] = "Tick Area %s"
	--[[Translation missing --]]
	L["Tick Center %s"] = "Tick Center %s"
	--[[Translation missing --]]
	L["Tick Mode"] = "Tick Mode"
	--[[Translation missing --]]
	L["Tick Placement"] = "Tick Placement"
	--[[Translation missing --]]
	L["Time in"] = "Time in"
	--[[Translation missing --]]
	L["Tiny Icon"] = "Tiny Icon"
	--[[Translation missing --]]
	L["To Frame's"] = "To Frame's"
	--[[Translation missing --]]
	L["To Group's"] = "To Group's"
	--[[Translation missing --]]
	L["To Personal Ressource Display's"] = "To Personal Ressource Display's"
	--[[Translation missing --]]
	L["To Region's"] = "To Region's"
	--[[Translation missing --]]
	L["To Screen's"] = "To Screen's"
	--[[Translation missing --]]
	L["Toggle the visibility of all loaded displays"] = "Toggle the visibility of all loaded displays"
	--[[Translation missing --]]
	L["Toggle the visibility of all non-loaded displays"] = "Toggle the visibility of all non-loaded displays"
	--[[Translation missing --]]
	L["Toggle the visibility of this display"] = "Toggle the visibility of this display"
	--[[Translation missing --]]
	L["Tooltip Content"] = "Tooltip Content"
	--[[Translation missing --]]
	L["Tooltip on Mouseover"] = "Tooltip on Mouseover"
	--[[Translation missing --]]
	L["Tooltip Pattern Match"] = "Tooltip Pattern Match"
	--[[Translation missing --]]
	L["Tooltip Text"] = "Tooltip Text"
	--[[Translation missing --]]
	L["Tooltip Value"] = "Tooltip Value"
	--[[Translation missing --]]
	L["Tooltip Value #"] = "Tooltip Value #"
	--[[Translation missing --]]
	L["Top HUD position"] = "Top HUD position"
	--[[Translation missing --]]
	L["Total"] = "Total"
	--[[Translation missing --]]
	L["Total - The maximum duration of a timer, or a maximum non-timer value"] = "Total - The maximum duration of a timer, or a maximum non-timer value"
	--[[Translation missing --]]
	L["Total Angle"] = "Total Angle"
	--[[Translation missing --]]
	L["Total Time"] = "Total Time"
	--[[Translation missing --]]
	L["Trigger %i: %s"] = "Trigger %i: %s"
	--[[Translation missing --]]
	L["Trigger Combination"] = "Trigger Combination"
	--[[Translation missing --]]
	L["Type 'select' for '%s' requires a values member'"] = "Type 'select' for '%s' requires a values member'"
	--[[Translation missing --]]
	L["Undo"] = "Undo"
	--[[Translation missing --]]
	L["Ungroup"] = "Ungroup"
	--[[Translation missing --]]
	L["Unit %s is not a valid unit for RegisterUnitEvent"] = "Unit %s is not a valid unit for RegisterUnitEvent"
	--[[Translation missing --]]
	L["Unit Count"] = "Unit Count"
	--[[Translation missing --]]
	L["Unknown"] = "Unknown"
	--[[Translation missing --]]
	L["Unknown Encounter's Spell Id"] = "Unknown Encounter's Spell Id"
	--[[Translation missing --]]
	L["Unknown property '%s' found in '%s'"] = "Unknown property '%s' found in '%s'"
	--[[Translation missing --]]
	L["Unknown Spell"] = "Unknown Spell"
	--[[Translation missing --]]
	L["Unlike the start or finish animations, the main animation will loop over and over until the display is hidden."] = "Unlike the start or finish animations, the main animation will loop over and over until the display is hidden."
	--[[Translation missing --]]
	L["Update"] = "Update"
	--[[Translation missing --]]
	L["Update Auras"] = "Update Auras"
	--[[Translation missing --]]
	L["Update Custom Text On..."] = "Update Custom Text On..."
	--[[Translation missing --]]
	L["URL"] = "URL"
	--[[Translation missing --]]
	L["Url: %s"] = "Url: %s"
	--[[Translation missing --]]
	L["Use Display Info Id"] = "Use Display Info Id"
	--[[Translation missing --]]
	L["Use SetTransform"] = "Use SetTransform"
	--[[Translation missing --]]
	L["Used in Auras:"] = "Used in Auras:"
	--[[Translation missing --]]
	L["Used in auras:"] = "Used in auras:"
	--[[Translation missing --]]
	L["Uses Texture Coordinates to rotate the texture."] = "Uses Texture Coordinates to rotate the texture."
	--[[Translation missing --]]
	L["Uses UnitIsVisible() to check if game client has loaded a object for this unit. This distance is around 100 yards. This is polled every second."] = "Uses UnitIsVisible() to check if game client has loaded a object for this unit. This distance is around 100 yards. This is polled every second."
	--[[Translation missing --]]
	L["Value"] = "Value"
	--[[Translation missing --]]
	L["Value %i"] = "Value %i"
	--[[Translation missing --]]
	L["Values are in normalized rgba format."] = "Values are in normalized rgba format."
	--[[Translation missing --]]
	L["Values/Remaining Time above this value are displayed as full progress."] = "Values/Remaining Time above this value are displayed as full progress."
	--[[Translation missing --]]
	L["Values/Remaining Time below this value are displayed as zero progress."] = "Values/Remaining Time below this value are displayed as zero progress."
	--[[Translation missing --]]
	L["Values:"] = "Values:"
	--[[Translation missing --]]
	L["Version: "] = "Version: "
	--[[Translation missing --]]
	L["Version: %s"] = "Version: %s"
	--[[Translation missing --]]
	L["Vertical Align"] = "Vertical Align"
	--[[Translation missing --]]
	L["Vertical Bar"] = "Vertical Bar"
	--[[Translation missing --]]
	L["View"] = "View"
	--[[Translation missing --]]
	L["View custom code"] = "View custom code"
	--[[Translation missing --]]
	L["Voice Settings"] = "Voice Settings"
	--[[Translation missing --]]
	L["We thank"] = "We thank"
	--[[Translation missing --]]
	L["WeakAuras %s on WoW %s"] = "WeakAuras %s on WoW %s"
	--[[Translation missing --]]
	L["What do you want to do?"] = "What do you want to do?"
	--[[Translation missing --]]
	L["Whole Area"] = "Whole Area"
	--[[Translation missing --]]
	L["wrapping"] = "wrapping"
	--[[Translation missing --]]
	L["X Offset"] = "X Offset"
	--[[Translation missing --]]
	L["X Rotation"] = "X Rotation"
	--[[Translation missing --]]
	L["X Scale"] = "X Scale"
	--[[Translation missing --]]
	L["x-Offset"] = "x-Offset"
	--[[Translation missing --]]
	L["Y Offset"] = "Y Offset"
	--[[Translation missing --]]
	L["Y Rotation"] = "Y Rotation"
	--[[Translation missing --]]
	L["Y Scale"] = "Y Scale"
	--[[Translation missing --]]
	L["Yellow Rune"] = "Yellow Rune"
	--[[Translation missing --]]
	L["y-Offset"] = "y-Offset"
	--[[Translation missing --]]
	L["You already have this group/aura. Importing will create a duplicate."] = "You already have this group/aura. Importing will create a duplicate."
	--[[Translation missing --]]
	L["You are about to delete %d aura(s). |cFFFF0000This cannot be undone!|r Would you like to continue?"] = "You are about to delete %d aura(s). |cFFFF0000This cannot be undone!|r Would you like to continue?"
	--[[Translation missing --]]
	L["You are about to delete a trigger. |cFFFF0000This cannot be undone!|r Would you like to continue?"] = "You are about to delete a trigger. |cFFFF0000This cannot be undone!|r Would you like to continue?"
	--[[Translation missing --]]
	L[ [=[You can add a comma-separated list of state values here that (when changed) WeakAuras should also run the Anchor Code on.

WeakAuras will always run custom anchor code if you include 'changed' in this list, or when a region is added, removed, or re-ordered.]=] ] = [=[You can add a comma-separated list of state values here that (when changed) WeakAuras should also run the Anchor Code on.

WeakAuras will always run custom anchor code if you include 'changed' in this list, or when a region is added, removed, or re-ordered.]=]
	--[[Translation missing --]]
	L[ [=[You can add a comma-separated list of state values here that (when changed) WeakAuras should also run the Grow Code on.

WeakAuras will always run custom grow code if you include 'changed' in this list, or when a region is added, removed, or re-ordered.]=] ] = [=[You can add a comma-separated list of state values here that (when changed) WeakAuras should also run the Grow Code on.

WeakAuras will always run custom grow code if you include 'changed' in this list, or when a region is added, removed, or re-ordered.]=]
	--[[Translation missing --]]
	L["You can add a comma-separated list of state values here that (when changed) WeakAuras should also run the sort code on.WeakAuras will always run custom sort code if you include 'changed' in this list, or when a region is added, removed."] = "You can add a comma-separated list of state values here that (when changed) WeakAuras should also run the sort code on.WeakAuras will always run custom sort code if you include 'changed' in this list, or when a region is added, removed."
	--[[Translation missing --]]
	L["Your Saved Snippets"] = "Your Saved Snippets"
	--[[Translation missing --]]
	L["Z Offset"] = "Z Offset"
	--[[Translation missing --]]
	L["Z Rotation"] = "Z Rotation"
	--[[Translation missing --]]
	L["Zoom In"] = "Zoom In"
	--[[Translation missing --]]
	L["Zoom Out"] = "Zoom Out"