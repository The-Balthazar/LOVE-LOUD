-- Starts SupremeCommander.exe with the 3 GB allocator fix applied in memory (the exe file is not changed).
--
-- The exe is Large Address Aware (4 GB on 64-bit Windows), but its page allocator keeps a page table with one
-- 4-byte entry per 4 KB page that is allocated with a fixed size of 3 MB (0xC0000 entries = 0..3 GB). A memory
-- block reserved above 0xC0000000 makes it read/write past the end of that table (crash or memory corruption).
-- Two constants fix it: table size 3 MB -> 4 MB, and the matching bounds check 0xC0000 -> 0x100000 pages.
--
-- The process is started suspended, so no exe code has run yet; both places are checked for the expected
-- original bytes first. If anything does not match or fails, the game starts (or is restarted) unpatched.

local ffi = require'ffi'

ffi.cdef[[
typedef struct {
    uint32_t cb; char *lpReserved; char *lpDesktop; char *lpTitle;
    uint32_t dwX, dwY, dwXSize, dwYSize, dwXCountChars, dwYCountChars, dwFillAttribute, dwFlags;
    uint16_t wShowWindow, cbReserved2; uint8_t *lpReserved2;
    void *hStdInput, *hStdOutput, *hStdError;
} LL_STARTUPINFOA;
typedef struct { void *hProcess, *hThread; uint32_t dwProcessId, dwThreadId; } LL_PROCESS_INFORMATION;
int CreateProcessA(const char *app, char *cmd, void *pa, void *ta, int inherit, uint32_t flags, void *env,
                   const char *cwd, LL_STARTUPINFOA *si, LL_PROCESS_INFORMATION *pi);
int ReadProcessMemory(void *h, const void *addr, void *buf, size_t n, size_t *done);
int WriteProcessMemory(void *h, void *addr, const void *buf, size_t n, size_t *done);
int VirtualProtectEx(void *h, void *addr, size_t n, uint32_t prot, uint32_t *old);
int FlushInstructionCache(void *h, const void *addr, size_t n);
int TerminateProcess(void *h, uint32_t code);
uint32_t ResumeThread(void *h);
int CloseHandle(void *h);
]]

local k32 = ffi.C

local CREATE_SUSPENDED = 0x4
local PAGE_EXECUTE_READWRITE = 0x40

-- SupremeCommander.exe (Steam, image base 0x400000, no relocations)
local PATCHES = {
    { addr = 0x916B16, old = '\0\0\48\0', new = '\0\0\64\0' }, -- push 300000h -> 400000h: page table 3 MB -> 4 MB
    { addr = 0x916DE8, old = '\0\0\12\0', new = '\0\0\16\0' }, -- cmp eax,0C0000h -> 100000h: bounds check
}

local function start(exe, args, cwd, flags)
    local si = ffi.new('LL_STARTUPINFOA')
    si.cb = ffi.sizeof(si)
    local pi = ffi.new('LL_PROCESS_INFORMATION')
    local line = ('"%s" %s'):format(exe, args or '')
    local cmd = ffi.new('char[?]', #line + 1, line)
    if k32.CreateProcessA(nil, cmd, nil, nil, 0, flags, nil, cwd, si, pi) == 0 then
        return nil
    end
    return pi
end

local function close(pi)
    k32.CloseHandle(pi.hThread)
    k32.CloseHandle(pi.hProcess)
end

local function applyPatches(h)
    local buf = ffi.new('uint8_t[4]')
    for _, p in ipairs(PATCHES) do
        if k32.ReadProcessMemory(h, ffi.cast('const void *', p.addr), buf, 4, nil) == 0
        or ffi.string(buf, 4) ~= p.old then
            return false, 'unknown exe build or already patched'
        end
    end
    for _, p in ipairs(PATCHES) do
        local addr = ffi.cast('void *', p.addr)
        local old = ffi.new('uint32_t[1]')
        if k32.VirtualProtectEx(h, addr, 4, PAGE_EXECUTE_READWRITE, old) == 0 then
            return nil, 'VirtualProtectEx failed'
        end
        local ok = k32.WriteProcessMemory(h, addr, p.new, 4, nil) ~= 0
        k32.VirtualProtectEx(h, addr, 4, old[0], old)
        if not ok then
            return nil, 'WriteProcessMemory failed'
        end
    end
    k32.FlushInstructionCache(h, nil, 0)
    return true, 'patched'
end

-- returns patched (true/false), message, process id (nil if the game could not be started)
local function launch(exe, args, cwd)
    exe = exe:gsub('/', '\\')
    local pi = start(exe, args, cwd, CREATE_SUSPENDED)
    if not pi then
        return false, 'CreateProcess failed'
    end
    local ok, msg = applyPatches(pi.hProcess)
    if ok == nil then
        -- a write failed half way: never run a half-patched exe, start it again unpatched
        k32.TerminateProcess(pi.hProcess, 1)
        close(pi)
        pi = start(exe, args, cwd, 0)
        if not pi then
            return false, msg..', restart failed'
        end
        local pid = pi.dwProcessId
        close(pi)
        return false, msg..', started unpatched', pid
    end
    k32.ResumeThread(pi.hThread)
    local pid = pi.dwProcessId
    close(pi)
    return ok, ok and msg or (msg..', started unpatched'), pid
end

return { launch = launch }
