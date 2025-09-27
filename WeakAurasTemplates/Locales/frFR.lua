if not WeakAuras.IsLibsOK() then return end

if (GAME_LOCALE or GetLocale()) ~= "frFR" then
  return
end

local L = WeakAuras.L

-- WeakAuras/Templates
	L["(Dwarf)"] = "(Nain)"
	L["(Dwarf/Human)"] = "(Nain/Humain)"
	L["(Human)"] = "(Humain)"
	L["(Night Elf)"] = "(Elfe de la nuit)"
	L["(Troll)"] = "(Troll)"
	L["(Undead)"] = "(Mort-vivant)"
	L["Abilities"] = "Capacités"
	L["Add Triggers"] = "Ajouter des déclencheurs"
	L["Always Active"] = "Toujours actif"
	L["Always Show"] = "Toujours afficher"
	L["Always show the aura, highlight it if debuffed."] = "Toujours afficher l'aura, surbrillance si absente."
	L["Always show the aura, turns grey if on cooldown."] = "Toujours afficher l'aura, devient grise si en recharge."
	L["Always show the aura, turns grey if the debuff not active."] = "Toujours afficher l'aura, devient gris si l'affaiblissement n'est pas actif."
	L["Always shows highlights if enchant missing."] = "Toujours afficher des reflets si l'enchantement est absent."
	L["Always shows the aura, grey if buff not active."] = "Toujours afficher l'aura, devient gris si l'amélioration n'est pas active."
	L["Always shows the aura, highlight it if buffed."] = "Toujours afficher l'aura, surbrillance si présente."
	L["Always shows the aura, highlight when active, turns blue on insufficient resources."] = "Toujours afficher l'aura, surbrillance si active, bleue si ressources insuffisantes."
	L["Always shows the aura, highlight while proc is active, blue on insufficient resources."] = "Toujours afficher l'aura, surbrillance tant que le proc est actif, bleue si ressources insuffisantes."
	L["Always shows the aura, highlight while proc is active, blue when not usable."] = "Toujours afficher l'aura, surbrillance tant que le proc est actif, bleue si non utilisable."
	L["Always shows the aura, highlight while proc is active, turns red when out of range, blue on insufficient resources."] = "Toujours afficher l'aura, surbrillance tant que le proc est actif, rouge si pas à portée, bleue si ressources insuffisantes."
	L["Always shows the aura, turns blue on insufficient resources."] = "Toujours afficher l'aura, bleue si ressources insuffisantes."
	L["Always shows the aura, turns blue when not usable."] = "Toujours afficher l'aura, bleue si non utilisable."
	L["Always shows the aura, turns grey if on cooldown."] = "Toujours afficher l'aura, devient grise si en recharge."
	L["Always shows the aura, turns grey if the ability is not usable and red when out of range."] = "Toujours afficher l'aura, grise si la technique n'est pas utilisable et rouge si hors de portée."
	L["Always shows the aura, turns grey if the ability is not usable."] = "Toujours afficher l'aura, griser si la technique n'est pas utilisable."
	L["Always shows the aura, turns red when out of range, blue on insufficient resources."] = "Toujours afficher l'aura, rouge si hors de portée, bleue si ressources insuffisantes."
	L["Always shows the aura, turns red when out of range."] = "Toujours afficher l'aura, rouge si hors de portée."
	L["Always shows the aura."] = "Toujours afficher l'aura."
	L["Back"] = "Retour"
	L["Basic Show On Cooldown"] = "Affichage de base en temps de recharge"
	--[[Translation missing --]]
	L["Basic Show On Ready"] = "Basic Show On Ready"
	L["Bloodlust/Heroism"] = "Furie sanguinaire/Héroïsme"
	L["buff"] = "amélioration"
	L["Buffs"] = "Améliorations"
	L["Charge and Buff Tracking"] = "Suivis des Charges et Amélioration"
	L["Charge and Debuff Tracking"] = "Suivis des Charges et Affaiblissement"
	L["Charge and Duration Tracking"] = "Suivi des Charges et Durée"
	L["Charge Tracking"] = "Suivis des Charges"
	L["cooldown"] = "temps de recharge"
	L["Cooldown Tracking"] = "Suivi du temps de recharge"
	--[[Translation missing --]]
	L["Cooldowns"] = "Cooldowns"
	L["Create Auras"] = "Créer Auras"
	L["debuff"] = "affaiblissement"
	L["Debuffs"] = "Affaiblissements"
	--[[Translation missing --]]
	L["dps buff"] = "dps buff"
	--[[Translation missing --]]
	L["Highlight while action is queued."] = "Highlight while action is queued."
	L["Highlight while active, red when out of range."] = "Mettre en surbrillance pendant qu'il est actif, rouge quand hors de portée."
	L["Highlight while active."] = "Mettez en surbrillance pendant qu 'il est actif."
	L["Highlight while buffed, red when out of range."] = "En surbrillance quand amélioré, rouge quand hors de portée"
	L["Highlight while buffed."] = "Mettez en surbrillance quand amélioré"
	L["Highlight while debuffed, red when out of range."] = "En surbrillance quand non-amélioré, rouge quand hors de portée"
	L["Highlight while debuffed."] = "Mettez en surbrillance quand non-amélioré."
	L["Highlight while spell is active."] = "Mettez en surbrillance quand le sort est actif."
	L["Hold CTRL to create multiple auras at once"] = "Maintenir CTRL pour créer plusieurs auras simultanément"
	L["Keeps existing triggers intact"] = "Garder intact les déclencheurs existants"
	--[[Translation missing --]]
	L["Master Channeler Rune"] = "Master Channeler Rune"
	L["Next"] = "Suivant"
	L["Only show the aura if the target has the debuff."] = "Montre l'aura que si la cible a l'affaiblissement."
	L["Only show the aura when the item is on cooldown."] = "Afficher uniquement l'aura quand l'objet est en recharge."
	L["Only shows if the weapon is enchanted."] = "N'afficher que si l'arme est enchanté"
	L["Only shows if the weapon is not enchanted."] = "N'afficher que si l'arme n'est pas enchanté."
	L["Only shows the aura if the target has the buff."] = "Montre l'aura que si la cible a l'amélioration."
	L["Only shows the aura when the ability is on cooldown."] = "Afficher uniquement l'aura quand la technique est en recharge."
	L["Only shows the aura when the ability is ready to use."] = "Afficher uniquement l'aura quand la technique est prête à être utilisée."
	L["Other cooldown"] = "Autre temps de recharge"
	L["Pet alive"] = "Familier vivant"
	--[[Translation missing --]]
	L["regen buff"] = "regen buff"
	L["Replace all existing triggers"] = "Remplacer tous les déclencheurs existant"
	L["Replace Triggers"] = "Remplacer les déclencheurs"
	L["Resources"] = "Ressources"
	L["Resources and Shapeshift Form"] = "Ressources et Forme de Changeforme"
	--[[Translation missing --]]
	L["Rogue cooldown"] = "Rogue cooldown"
	L["Runes"] = "Runes"
	L["Shapeshift Form"] = "Forme de Changeforme"
	L["Show Always, Glow on Missing"] = "Toujours afficher, lorsque la brillance est manquante"
	L["Show Charges and Check Usable"] = "Afficher les Charges et Vérifier si Utilisable"
	L["Show Charges with Proc Tracking"] = "Afficher les Charges avec le Suivi des Procs"
	L["Show Charges with Range Tracking"] = "Afficher les Charges avec Vérification de la Portée"
	L["Show Charges with Usable Check"] = "Afficher les Charges avec Vérification si Utilisable"
	--[[Translation missing --]]
	L["Show Cooldown and Action Queued"] = "Show Cooldown and Action Queued"
	L["Show Cooldown and Buff"] = "Afficher les Temps de Recharges et Améliorations"
	L["Show Cooldown and Buff and Check for Target"] = "Afficher le Temps de Recharge et l'Amélioration et Vérifier si il y a une Cible"
	L["Show Cooldown and Buff and Check Usable"] = "Afficher le Temps de Recharge et l'Amélioration et Vérifier si c'est Utilisable"
	L["Show Cooldown and Check for Target"] = "Afficher le Temps de Recharge et Vérifier si il y a une Cible"
	L["Show Cooldown and Check for Target & Proc Tracking"] = "Afficher le temps de recharge et Vérifier le Suivi des Cibles et des Procs"
	L["Show Cooldown and Check Usable"] = "Afficher le Temps de Recharge et Vérifier si c'est Utilisable"
	L["Show Cooldown and Check Usable & Target"] = "Afficher le Temps de Recharge et Vérifier si c'est Utilisable et si il y a une Cible"
	--[[Translation missing --]]
	L["Show Cooldown and Check Usable, Proc Tracking"] = "Show Cooldown and Check Usable, Proc Tracking"
	--[[Translation missing --]]
	L["Show Cooldown and Check Usable, Target & Proc Tracking"] = "Show Cooldown and Check Usable, Target & Proc Tracking"
	L["Show Cooldown and Debuff"] = "Afficher le Temps de Recharge et L'Affaiblissement"
	L["Show Cooldown and Debuff and Check for Target"] = "Afficher les Temps de Recharge et l'Affaiblissement et Vérifier si il y a une Cible"
	--[[Translation missing --]]
	L["Show Cooldown and Duration"] = "Show Cooldown and Duration"
	--[[Translation missing --]]
	L["Show Cooldown and Duration and Check for Target"] = "Show Cooldown and Duration and Check for Target"
	--[[Translation missing --]]
	L["Show Cooldown and Duration and Check Usable"] = "Show Cooldown and Duration and Check Usable"
	--[[Translation missing --]]
	L["Show Cooldown and Proc Tracking"] = "Show Cooldown and Proc Tracking"
	L["Show Cooldown and Totem Information"] = "Afficher le Temps de Rechargement et l'Information du Totem"
	--[[Translation missing --]]
	L["Show if Enchant Missing"] = "Show if Enchant Missing"
	--[[Translation missing --]]
	L["Show on Ready"] = "Show on Ready"
	--[[Translation missing --]]
	L["Show Only if Buffed"] = "Show Only if Buffed"
	--[[Translation missing --]]
	L["Show Only if Debuffed"] = "Show Only if Debuffed"
	--[[Translation missing --]]
	L["Show Only if Enchanted"] = "Show Only if Enchanted"
	L["Show Only if on Cooldown"] = "Afficher Seulement si en Recharge"
	L["Show Totem and Charge Information"] = "Afficher les Informations du Totem et de Charge"
	L["Stance"] = "Posture"
	L["Track the charge and proc, highlight while proc is active, turns red when out of range, blue on insufficient resources."] = "Suivre la charge et le proc, mettre en surbrillance pendant que le proc est actif, devient rouge lorsque vous êtes hors de portée, bleu lorsque les ressources sont insuffisantes"
	L["Tracks the charge and the buff, highlight while the buff is active, blue on insufficient resources."] = "Suit la charge et le buff, surligne pendant que le buff est actif, bleu sur les ressources insuffisantes."
	L["Tracks the charge and the debuff, highlight while the debuff is active, blue on insufficient resources."] = [=[
Suit la charge et le debuff, met en surbrillance pendant que le debuff est actif, bleu en cas de ressources insuffisantes.]=]
	L["Tracks the charge and the duration of spell, highlight while the spell is active, blue on insufficient resources."] = "Suit la charge et la durée du sort, mettez en surbrillance pendant que le sort est actif, bleu en cas de ressources insuffisantes."
	L["Unknown Item"] = "Objet inconnu"
	--[[Translation missing --]]
	L["Warrior cooldown"] = "Warrior cooldown"