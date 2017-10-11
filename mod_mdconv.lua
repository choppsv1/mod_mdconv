-- -*- lua -*-

-- mod_mdconv.lua
local stanza = require "util.stanza"; -- Import Prosody's stanza API into 'stanza'
local pacakge = require("package"); -- import dumper
local debug = require("debug"); -- import dumper
local info = debug.getinfo(1,'S');
local rex = require 'rex_pcre'

module:log("info", "packages.path: %s", package.path);
module:log("info", "findme: %s", info.source)
local mpath = info.source:sub(2, -1)
package.path = package.path .. ";" .. mpath:gsub("/mod_hello.lua", "/?.lua")
module:log("info", "findme: %s", package.path)

-- local inspect = require('inspect')


local an_href = "\\[([^]]+)\\]\\(([^)]+)\\)"
local an_href_rex = rex.new(an_href)

function dosub (stanza)
    local body = stanza:get_child("body")
    if #body ~= 1 then
        module:log("info", "skipping body with more than 1 tag #tag: %d", #body)
        return
    end
    -- we replace the verbose text with just the "a href" names
    local orig = body[1]
    body[1] = string.gsub(orig, '%[([^%]]*)%]%(([^%)]*)%)', "%1")

    stanza:tag("html", {xmlns = "http://jabber.org/protocol/xhtml-im"})
    stanza:tag("body", {xmlns = "http://www.w3.org/1999/xhtml"})

    local re_end = 0
    local first = 1
    local atag, old_end, re_start, name, hrefval, text
    while true do
        old_end = re_end + 1
        re_start, re_end, name, hrefval = an_href_rex:find(orig, old_end)
        if not re_start then break end

        -- Add pre-text and tag data
        text = orig:sub(old_end, re_start - 1)
        if first > 0 then
            first = 0
            atag = stanza:tag("p"):text(text)
            -- module:log("info", "adding tag: %s", inspect(atag))
        else
            stanza:text(text)
            -- module:log("info", "adding text: %s", text)
        end

        atag = stanza:tag("a", { href = hrefval }):text(name):up()
        -- module:log("info", "adding tag: %s", inspect(atag))
    end

    text = orig:sub(old_end, -1)
    if first > 0 then
        atag = stanza:tag("p"):text(text)
        -- module:log("info", "adding last tag: %s", inspect(atag))
    else
        -- stanza:tag(""):text(text)
        stanza:text(text)
        -- module:log("info", "adding text: %s", text)
    end

    stanza:up() -- p
    stanza:up() -- body
    stanza:up() -- html
end

function on_message(event)
    module:log("info", "Received a message! Look: %s", tostring(event.stanza));

    -- Check for HTML tag, if present we aren't going to do any conversion
    if not event.stanza:get_child("html", "http://jabber.org/protocol/xhtml-im") then
        module:log("info", "Mapping message: %s", event.stanza:pretty_print(event.stanza))
        dosub(event.stanza)
    else
        module:log("info", "Skipping message with HTML markup pp: %s\n%s",
                   event.stanza:pretty_print(event.stanza),
                   tostring(event.stanza))
                   -- inspect(event.stanza))
    end
    -- -- module:log("info", "stanza module: %s", inspect(stanza))
    -- -- module:log("info", "serialize: %s", tostring(event.stanza))
    return
end

module:hook("pre-message/bare", on_message);
module:log("info", "mod_mdconv intiialized");
