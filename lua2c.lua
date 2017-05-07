local description = [=[
Usage: lua lua2c.lua [+]lua_filename modul_name

Write a C source file to standard output.  When this C source file is
included in another C source file, it has the effect of loading and
running the specified file at that point in the program.

The file named by 'lua_filename' contains either Lua byte code or Lua source.
Its contents are used to generate the C output.  If + is used, then the
contents of 'lua_filename' are first compiled before being used to generate
the C output.

This program is slightly modified for LuaDist static builds needs.

http://lua-users.org/wiki/BinTwoCee
]=]

if not arg or not arg[1] or not arg[2] then
  io.stderr:write(description)
  return
end

local compile_flag, path = arg[1]:match"^(+?)(.*)"
local file = path:match"([^\\/]-%.?([^%.\\/]*)())$"
local modul = arg[2]

-- string.dump() returns a binary representation of sting
local content = compile_flag=="+"
  and string.dump(assert(loadfile(path)))
  or assert(io.open(path,"rb")):read"*a"

local function firstplate(fmt)
  return string.format(fmt,
    modul,
    file,
    modul,
    (string.len(content)+1))
end

local function secondplate(fmt)
    return string.format(fmt,
    modul,
    (string.len(content)+1),
    modul,
    modul,
    modul,
    file)
end

local dump do
  local numtab={} 
  for i=0,255 do 
    numtab[string.char(i)]=("0x%02x, "):format(i) 
  end
  function dump(str)
    return (str:gsub(".", numtab):gsub(("."):rep(66), "%0\n\t"))
  end
end

io.write(firstplate[=[
/* code automatically generated by bin2c -- DO NOT EDIT */
/* %s.%s */
#include "lua.h"
#include "lauxlib.h"

static const unsigned char %s_slua[%d] = {
        ]=],
dump(content), secondplate[=[0x00
};

const unsigned int %s_slua_length = %s;

int luaopen_%s (lua_State *L)
{
  luaL_loadbuffer(L, (const char *) %s_slua, %s_slua_length, %q);
  lua_pcall(L, 0, LUA_MULTRET, 0);

  return 0;
}

]=])

