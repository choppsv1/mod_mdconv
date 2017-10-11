-- mod_hello.lua
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

local inspect = require('inspect')


local an_href = "\\[([^]]+)\\]\\(([^)]+)\\)"
local an_href_rex = rex.new(an_href)

function olddosub (child)
    -- module:log("info", "Maptag: tag.name: %s tag.attr %s tag.tags %s #tag #%s tag '%s'", tag.name, tag.attr, tag.tags, #tag, tag);
    module:log("info", "Maptag-inspect: tag.name: %s\ntag.attr: %s\nchildren: %s",
               tag.name,
               inspect(child.attr),
               inspect(child.tags))

    -- for i = 1, #child do
    --     module:log("info", "    '%s'", child[i])
    --     child[i] = child[i]:gsub('%[([^%]]*)%]%(([^%)]*)%)', "<a href='%2'>%1</a>")
    --     --if child[i] == "hi" then
    --     --    child[i] = "bye"
    --     --end
    -- end

    return child
end

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
            module:log("info", "adding tag: %s", inspect(atag))
        else
            -- stanza:tag(""):text(text)
            stanza:text(text)
            module:log("info", "adding text: %s", text)
        end

        atag = stanza:tag("a", { href = hrefval }):text(name):up()
        module:log("info", "adding tag: %s", inspect(atag))
    end

    text = orig:sub(old_end, -1)
    if first > 0 then
        atag = stanza:tag("p"):text(text)
        module:log("info", "adding last tag: %s", inspect(atag))
    else
        -- stanza:tag(""):text(text)
        stanza:text(text)
        module:log("info", "adding text: %s", text)
    end

    stanza:up() -- p
    stanza:up() -- body
    stanza:up() -- html
end

function on_message(event)
    module:log("info", "Received a message! Look: %s", tostring(event.stanza));

    -- Check the type of the incoming stanza to avoid loops:
    --[[
    if event.stanza.attr.type == "error" then
        return; -- We do not want to reply to these, so leave.
    end

    -- Create a clone of the received stanza to use for our reply:
    local reply_stanza = stanza.clone(event.stanza);
    -- This is a neat trick in Lua to swap two variables, without needing a third:
    reply_stanza.attr.to, reply_stanza.attr.from = reply_stanza.attr.from, reply_stanza.attr.to;

    -- Now send!
    module:send(reply_stanza);

    -- We're done! Now, let's halt event propagation
    return true
    ]]

    -- Check for HTML tag, if present we aren't going to do any conversion

    if not event.stanza:get_child("html", "http://jabber.org/protocol/xhtml-im") then
        module:log("info", "Mapping message: %s", event.stanza:pretty_print(event.stanza))
        dosub(event.stanza)
    else
        module:log("info", "Skipping message with HTML markup pp: %s\n%s",
                   event.stanza:pretty_print(event.stanza),
                   inspect(event.stanza))
    end
    -- module:log("info", "stanza module: %s", inspect(stanza))
    -- module:log("info", "serialize: %s", tostring(event.stanza))
    return
end

module:hook("pre-message/bare", on_message);
module:log("info", "Hello world!");

--[[
local indent, first, short_close = 0, true, nil;
for tagline, text in data:gmatch("<([^>]+)>([^<]*)") do
	if tagline:sub(-1,-1) == "/" then
		tagline = tagline:sub(1, -2);
		short_close = true;
	end
	if tagline:sub(1,1) == "/" then
		io.write(":up()");
		indent = indent - indent_step;
	else
		local name, attr = tagline:match("^(%S*)%s*(.*)$");
		local attr_str = {};
		for k, _, v in attr:gmatch("(%S+)=([\"'])([^%2]-)%2") do
			if #attr_str == 0 then
				table.insert(attr_str, ", { ");
			else
				table.insert(attr_str, ", ");
			end
			if k:match("^%a%w*$") then
				table.insert(attr_str, string.format("%s = %q", k, v));
			else
				table.insert(attr_str, string.format("[%q] = %q", k, v));
			end
		end
		if #attr_str > 0 then
			table.insert(attr_str, " }");
		end
		if first and name == "iq" or name == "presence" or name == "message" then
			io.write(string.format("stanza.%s(%s)", name, table.concat(attr_str):gsub("^, ", "")));
			first = nil;
		else
			io.write(string.format("\n%s:tag(%q%s)", indent_char:rep(indent), name, table.concat(attr_str)));
		end
		if not short_close then
			indent = indent + indent_step;
		end
	end
	if text and text:match("%S") then
		io.write(string.format(":text(%q)", text));
	elseif short_close then
		short_close = nil;
		io.write(":up()");
	end
end

example html message

    Oct 10 12:23:04 tops.int.dev.terastrm.net:hello info    Maptag-inspect: tag.name: "html"
    tag.attr: {
    xmlns = "http://jabber.org/protocol/xhtml-im"
    }
    tag: '<html xmlns='http://jabber.org/protocol/xhtml-im'><body xmlns='http://www.w3.org/1999/xhtml'><p>Test <strong>bold</strong> <span style='color: #e83333;'>color</span>\</p></body></html>'

tags: { { -- <body xmlns='http://www.w3.org/1999/xhtml'><p>Test <strong>bold</strong> <span style='color: #e83333;'>color</span>\\</p></body>
     <1>{ -- <p xmlns='http://www.w3.org/1999/xhtml'>Test <strong>bold</strong> <span style='color: #e83333;'>color</span>\\</p>
       "Test ", <2>{ -- <strong xmlns='http://www.w3.org/1999/xhtml'>bold</strong>
         "bold",
        attr = {
          xmlns = "http://www.w3.org/1999/xhtml"
        },
        name = "strong",
        tags = {},
        <metatable> = <3>{
          __index = <table 3>,
          __tostring = <function 1>,
          __type = "stanza",
          add_child = <function 2>,
          add_direct_child = <function 3>,
          body = <function 4>,
          child_with_name = <function 5>,
          child_with_ns = <function 6>,
          children = <function 7>,
          childtags = <function 8>,
          find = <function 9>,
          get_child = <function 10>,
          get_child_text = <function 11>,
          get_error = <function 12>,
          get_text = <function 13>,
          maptags = <function 14>,
          pretty_print = <function 15>,
          pretty_top_tag = <function 16>,
          query = <function 17>,
          reset = <function 18>,
          tag = <function 19>,
          text = <function 20>,
          top_tag = <function 21>,
          up = <function 22>
        }
      }, " ", <4>{ -- <span style='color: #e83333;' xmlns='http://www.w3.org/1999/xhtml'>color</span>
         "color",
        attr = {
          style = "color: #e83333;",
          xmlns = "http://www.w3.org/1999/xhtml"
        },
        name = "span",
        tags = {},
        <metatable> = <table 3>
      }, "\\",
      attr = {
        xmlns = "http://www.w3.org/1999/xhtml"
      },
      name = "p",
      tags = { <table 2>, <table 4> },
      <metatable> = <table 3>
    },
    attr = {
      xmlns = "http://www.w3.org/1999/xhtml"
    },
    name = "body",
    tags = { <table 1> },
    <metatable> = <table 3>
  } }
#1


    a = "<gitlab> Ciaran Cain pushed to branch [master](https://gitlab.dev.terastrm.net/TeraStream/redhostapps/commits/master) of [TeraStream/redhostapps](https://gitlab.dev.terastrm.net/TeraStream/redhostapps) ([Compare changes](https://gitlab.dev.terastrm.net/TeraStream/redhostapps/compare/36160d875dbeaf847a6c7384323776d894127109...0e4c0f0b869719e1d140bf9719255526c0d88cac))"
--]]
