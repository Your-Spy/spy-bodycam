Webhook = Webhook or {}

Webhook.DefaultHook = 'https://discord.com/api/webhooks/1257683370037477447/0YPA1M5yzoNZsIqKA-BRputLYH03dn-fi9hiNvFygy3LfiymMujhyNOIDO3pRbpzjwvS' -- Default hook for uploads

Webhook.Username = 'Spy Bodycam Records'     -- Bot Username
Webhook.Title = 'Bodycam Records'            -- Message Title

Webhook.DefaultAuthor = {   -- Default author 
    name = "Spy Bodycam",
    icon_url = "https://i.imgur.com/tMyAdkz.png"
}

Webhook.JobUploads = {  -- Job Speific author
    ['police'] = {
        webhook = 'https://discord.com/api/webhooks/1257923313519427704/mdKHatLx_fD-a1ennTeGZrFfox9wJqZaIReo0d4-U7zu9rzIJ-A2HWof49CCeiorc269',
        author = {
            name = "Police Department",
            icon_url = "https://i.imgur.com/tMyAdkz.png"
        }
    },
}
