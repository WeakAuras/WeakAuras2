#!/usr/bin/env python3

import patreon
from patreon.schemas import pledge
import unicodedata
import os

def has_cj(text):
    for char in text:
        for name in ('CJK','CHINESE','KATAKANA',):
            if name in unicodedata.name(char):
                return True
    return False

def has_k(text):
    for char in text:
        if "HANGUL" in unicodedata.name(char):
            return True
    return False

def get_names(pledges_response, all_pledges, names):
    """Function to add names from all_pledges to names list"""
    for pledge in all_pledges:
        if pledge.attributes()["declined_since"] == None:
          patron_id = pledge.relationship('patron').id()
          patron = pledges_response.find_resource_by_type_and_id('user', patron_id)
          names.append(patron.attribute('full_name'))


api_client = patreon.API(os.environ['PATREON_CREATOR_ACCESS_TOKEN'])

campaign_id = api_client.fetch_campaign().data()[0].id()
pledges_response = api_client.fetch_page_of_pledges(
    campaign_id,
    25)

cursor = None
names = []
while True:
    pledges_response = api_client.fetch_page_of_pledges(
        campaign_id,
        25,
        cursor=cursor,
    )
    get_names(pledges_response, pledges_response.data(), names)
    cursor = api_client.extract_cursor(pledges_response)
    if not cursor:
        break


names.sort(key=lambda y: y.lower())


cjnames = filter(has_cj, names)
knames = filter(lambda n: not has_cj(n) and has_k(n), names)
latinnames = filter(lambda n: not has_cj(n) and not has_k(n), names)

file = open("WeakAuras/PatreonList.lua", "w")
file.write("if not WeakAuras.IsLibsOK() then return end\n")
file.write("---@type string\n")
file.write("local AddonName = ...\n")
file.write("---@class Private\n")
file.write("local Private = select(2, ...)\n")

file.write("Private.PatreonsList = {\n")
for name in latinnames:
    file.write("  [=[" + name.strip() + "]=],\n")
file.write("}\n")

file.write("Private.PatreonsListCJ = {\n")
for name in cjnames:
    file.write("  [=[" + name.strip() + "]=],\n")
file.write("}\n")

file.write("Private.PatreonsListK = {\n")
for name in knames:
    file.write("  [=[" + name.strip() + "]=],\n")
file.write("}\n")

file.close()
