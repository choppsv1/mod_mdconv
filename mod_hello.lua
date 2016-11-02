-- mod_hello.lua
local st = require "util.stanza"; -- Import Prosody's stanza API into 'st'

function dosub (tag)
    module:log("info", "Maptag: text: %s %s %s #%s '%s'",
               tag.name, tag.attr, tag.tags, #tag, tag);
    for i = 1, #tag do
        module:log("info", "    '%s'", tag[i])
        if tag[i] == "hi" then
            tag[i] = "bye"
        end
    end
    return tag
end

function on_message(event)
    module:log("info", "Received a message! Look: %s", tostring(event.stanza));
    -- Check the type of the incoming stanza to avoid loops:
    --[[
    if event.stanza.attr.type == "error" then
        return; -- We do not want to reply to these, so leave.
    end

    -- Create a clone of the received stanza to use for our reply:
    local reply_stanza = st.clone(event.stanza);
    -- This is a neat trick in Lua to swap two variables, without needing a third:
    reply_stanza.attr.to, reply_stanza.attr.from = reply_stanza.attr.from, reply_stanza.attr.to;

    -- Now send!
    module:send(reply_stanza);

    -- We're done! Now, let's halt event propagation
    return true
    ]]
    event.stanza:maptags(dosub)
    return
end

module:hook("pre-message/bare", on_message);
module:log("info", "Hello world!");
