#!/usr/bin/env python3
import discord
import unicodedata
import os
import sys

API_TOKEN = os.environ['DISCORD_ACCESS_TOKEN']
CHANNEL_ID = 1259514390000963594
MSG_ID = 1260693417336504482
VALID_ROLES = {
  1102916915653001258, # Premium Members
  1103105933971836958, # Platinum Support
  1103105132239007824, # Gold Support
  1102916921004937286, # Silver Support
  689250157799407890, # Twitch Subscriber: Tier 3
  689250157799407798, # Twitch Subscriber: Tier 2
  689250157799407691, # Twitch Subscriber: Tier 1
  563427483555201024, # Twitch Subscriber,
  507633262445723668, # Patron Bronze
  507260546119368714, # Patron Silver
  506449385543041034, # Patron Gold
  512016261631442945, # Patreon Goldish
  635471797583872020, # Patreon Platinum
  635471886134018049, # Patreon Diamond
  512014685088907265, # Patreon
  402021459440173056, # Regular
  172440752045948928, # Moderator,
  294497613565263872, # Super Moderator
}

MSG = """React to this message to have your name included in the Thanks list inside the WeakAuras GUI.
The bot runs every monday, and you have to be a member of the discord for the bot to verify your status.

Note, that most symbols are filtered. Pure Latin, Chinese or Korean should be fine.
And the names are reviewed by a human.

The bot is experimental and will probably break a few times.
"""

commitBodyFile = open("commit-body.txt", "w", encoding="utf-8")
def commitMsgPrint(*text):
  string = ' '.join(text)
  commitBodyFile.write(string + "\n")
  print(string)

def has_cj(text):
  for char in text:
    for name in ('CJK','CHINESE','KATAKANA',):
      if unicodedata.name(char).startswith(name):
        return True
  return False

def has_k(text):
  for char in text:
    if unicodedata.name(char).startswith("HANGUL"):
      return True
  return False

def checkChar(char):
  for name in ('CJK','CHINESE','KATAKANA', 'LATIN', 'DIGIT', 'SPACE', 'HANGUL'):
    if unicodedata.name(char).startswith(name):
      return True
  return False

def cleanName(name):
  newName = "".join([c for c in name if checkChar(c)]).strip()
  newName = newName.replace("[=[", "")
  newName = newName.replace("]=]", "")
  newName = newName.replace("|", "")
  newName = newName[:25]
  if newName != name:
    commitMsgPrint("* Changing \"" + name + "\" to \"" + newName + "\"")
  return newName


class DiscordNameGather(discord.Client):
  mode = ""
  messagePerAuthor = {}

  def hasRightRole(self, roles):
    for r in roles:
      if r.id in VALID_ROLES:
        return True
    return False

  async def on_ready(self):
    for guild in self.guilds:
      for channel in guild.channels:
        if channel.id == CHANNEL_ID:
          if self.mode == "msg":
            await self.sendMessage(channel)
          elif self.mode == "edit":
            await self.editMessage(channel)
          elif self.mode == "history":
            await self.parseHistory(channel)
          else:
            await self.parseReactions(channel, MSG_ID)

    await client.close()

  async def sendMessage(self, channel):
    message = channel.send(MSG)
    commitMsgPrint("Send message with id:", (await message).id)

  async def editMessage(self, channel):
    message = await channel.fetch_message(MSG_ID)
    await message.edit(content = MSG)


  # Old method of enumerating messages in a channel
  async def parseHistory(self, channel):
    messages = [message async for message in channel.history(limit=2000)]
    for message in messages:
      self.handleHistoryMessage(message)
    self.writeFile()

  def handleHistoryMessage(self, message):
    if isinstance(message.author, discord.member.Member):
      if self.hasRightRole(message.author.roles):
        if message.author.id not in self.messagePerAuthor:
          self.messagePerAuthor[message.author.id] = message.content
          commitMsgPrint(message.author.name, ":", message.content)
      else:
        commitMsgPrint("Ignoring user, because they don't have the right role:", message.author.name)

  # New method of parsing reactions to a singular message
  async def parseReactions(self, channel, msgId):
    message = await channel.fetch_message(msgId)
    for reaction in message.reactions:
      async for user in reaction.users():
        if isinstance(user, discord.member.Member):
          if self.hasRightRole(user.roles):
            self.messagePerAuthor[user.id] = user.display_name
          else:
            commitMsgPrint("Ignoring User (missing role): ", user.display_name)
    self.writeFile()


  def writeFile(self):
    names = list(self.messagePerAuthor.values())

    commitMsgPrint("")
    commitMsgPrint("Cleaning names")
    names = [cleanName(name) for name in names]
    names = [name for name in names if name != ""]

    names.sort(key=lambda y: y.lower())

    cjnames = filter(has_cj, names)
    knames = filter(lambda n: not has_cj(n) and has_k(n), names)
    latinnames = filter(lambda n: not has_cj(n) and not has_k(n), names)

    discordListFile = open("WeakAuras/DiscordList.lua", "w", encoding="utf-8")
    discordListFile.write("if not WeakAuras.IsLibsOK() then return end\n")
    discordListFile.write("---@type string\n")
    discordListFile.write("local AddonName = ...\n")
    discordListFile.write("---@class Private\n")
    discordListFile.write("local Private = select(2, ...)\n")

    discordListFile.write("Private.DiscordList = {\n")
    commitMsgPrint("")
    commitMsgPrint("Final Latin Names List")
    for name in latinnames:
      discordListFile.write("  [=[" + name + "]=],\n")
      commitMsgPrint("*", name)
    discordListFile.write("}\n")

    commitMsgPrint("")
    commitMsgPrint("Final China/Japan List")
    discordListFile.write("Private.DiscordListCJ = {\n")
    for name in cjnames:
      discordListFile.write("  [=[" + name + "]=],\n")
      commitMsgPrint("*", name)
    discordListFile.write("}\n")

    commitMsgPrint("")
    commitMsgPrint("Final Korea List")
    discordListFile.write("Private.DiscordListK = {\n")
    for name in knames:
      discordListFile.write("  [=[" + name + "]=],\n")
      commitMsgPrint("*", name)
    discordListFile.write("}\n")

    discordListFile.close()


intents = discord.Intents.default()
intents.message_content = True
intents.members = True

client = DiscordNameGather(intents=intents)

if __name__ == "__main__":
  if len(sys.argv) > 1:
    client.mode = sys.argv[1]
    print("Running in mode", client.mode)

  client.run(API_TOKEN)


