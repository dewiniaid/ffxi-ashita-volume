addon.name      = 'Volume'
addon.author    = 'Dewin'
addon.version   = '1.0'
addon.desc      = 'Toggle or adjust sound and music volume through chat commands'
addon.link      = 'https://github.com/dewiniaid/ffxi-ashita-volume'

require('common')
local chat = require('chat')
local settings = require('settings')
local ffi = require('ffi')

-- FFI Prototypes (lifted from the Config addon)
ffi.cdef[[
    typedef int32_t (__cdecl* get_config_value_t)(int32_t);
    typedef int32_t (__cdecl* set_config_value_t)(int32_t, int32_t);
    typedef int32_t (__fastcall* get_config_entry_t)(int32_t, int32_t, int32_t);

    // Configuration Value Entry Definition
    typedef struct FsConfigSubject {
        uintptr_t   VTable;         /* The configuration entry VTable pointer. */
        uint32_t    m_configKey;    /* The configuration entry key. */
        int32_t     m_configValue;  /* The configuration entry value. */
        uint32_t    m_configType;   /* The configuration entry type. */
        char        m_polName[8];   /* The configuration entry PlayOnline name. */
        int32_t     m_minVal;       /* The configuration entry minimum value.  */
        int32_t     m_maxVal;       /* The configuration entry maximum value. (-1 if not used.) */
        int32_t     m_defVal;       /* The configuration entry default value. (Used when not able to clamp a value within min/max.) */
        uintptr_t   m_callbackList; /* The configuration entry callback linked list object. */
        int32_t     m_configProc;   /* The configuration entry flags. (0x01 means the value will force-update even if the value already matches.) */
    } FsConfigSubject;
]];

-- Config Variables
local config = T{
    get     = nil,
    set     = nil,
    this    = nil,
    info    = nil,
};

local CONFIG_SOUND = 9
local CONFIG_MUSIC = 10
local MAX_VOLME = 100
local volume = {
    settings = {
        sound_volume = nil,
        music_volume=nil
    }
}

ashita.events.register('load', 'load_cb', function ()
    -- Obtain the needed function pointers..
    local ptr = ashita.memory.find('FFXiMain.dll', 0, '8B0D????????85C974??8B44240450E8????????C383C8FFC3', 0, 0)
    config.get = ffi.cast('get_config_value_t', ptr)
    config.set = ffi.cast('set_config_value_t', ashita.memory.find('FFXiMain.dll', 0, '85C974??8B4424088B5424045052E8????????C383C8FFC3', -6, 0))
    config.info = ffi.cast('get_config_entry_t', ashita.memory.find('FFXiMain.dll', 0, '8B490485C974108B4424048D14808D04508D0481C2040033C0C20400', 0, 0))

    -- Obtain the 'this' pointer for the configuration data..
    config.this = ffi.cast('uint32_t**', ptr + 2)[0][0]

    -- Ensure all pointers are valid..
    assert(config.get ~= nil, chat.header('volume'):append(chat.error('Error: Failed to locate required \'get\' function pointer.')))
    assert(config.set ~= nil, chat.header('volume'):append(chat.error('Error: Failed to locate required \'set\' function pointer.')))
    assert(config.info ~= nil, chat.header('volume'):append(chat.error('Error: Failed to locate required \'info\' function pointer.')))
    assert(config.this ~= 0, chat.header('volume'):append(chat.error('Error: Failed to locate required \'this\' object pointer.')))

    local sound_volume = config.get(CONFIG_SOUND)
    local music_volume = config.get(CONFIG_MUSIC)
    local default_settings = T{
        sound_volume = (sound_volume == 0 or sound_volume == nil) and 50 or sound_volume,
        music_volume = (music_volume == 0 or music_volume == nil) and 50 or music_volume,
    }

    volume.settings = settings.load(default_settings)
    -- print(chat.header('volume')
    --     :append(chat.message('Current sound volume: '))
    --     :append(chat.success(tostring(sound_volume)))
    -- )
    -- print(chat.header('volume')
    --     :append(chat.message('Current music volume: '))
    --     :append(chat.success(tostring(music_volume)))
    -- )
end)

ashita.events.register('unload', 'unload_cb', function ()
    settings.save()
end)

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args()
    if (#args == 0) then
        return
    end
    local lower = string.lower(args[1])
    local setting
    local what
    local key
    if lower == '/music' then
        setting = CONFIG_MUSIC
        what = "music"
        key = 'music_volume'
    elseif (lower == '/sound') or (lower == 'sfx') then
        setting = CONFIG_SOUND
        what = "sound effects"
        key = 'sound_volume'
    else
        return
    end

    local current_volume = config.get(setting)
    local unmuted_volume = volume.settings[key]
    if (#args == 1) then
        if current_volume == 0 then
            print(chat.header('volume')
                :append(chat.message('Current ' .. what .. ' volume: '))
                :append(chat:error("muted"))
                :append(chat.message(' (Previous volume: '))
                :append(chat.success(tostring(unmuted_volume)))
                :append(chat.message(')'))
            )
        else
            print(chat.header('volume')
                :append(chat.message('Current ' .. what .. ' volume: '))
                :append(chat.success(tostring(unmuted_volume)))
            )
        end
        return
    end
    lower = string.lower(args[2])
    local new_volume
    if lower == 'mute' then
        new_volume = 0
    elseif lower == 'toggle' then
        if current_volume == 0 then
            new_volume = unmuted_volume
        else
            new_volume = 0
        end
    else
        new_volume = tonumber(args[2])
        if new_volume == nil or (new_volume < 0) or (new_volume > 100) then
            print(chat.header('volume')
                :append(chat.error('Expected a new volume level of "toggle", "mute", or a number between 0 and 100.'))
            )
            return
        end
    end
    if new_volume == 0 then
        if current_volume ~= 0 then
            volume.settings[key] = current_volume
        end
        print(chat.header('volume'):append(chat.message('Muting ' .. what .. '.')))
    elseif lower == 'toggle' then
        print(chat.header('volume'):append(chat.message('Unmuting ' .. what .. '.')))
    else
        print(chat.header('volume'):append(chat.message('Changing ' .. what .. ' volume to '):append(chat.success(tostring(new_volume)))))
    end
    config.set(setting, new_volume)
end)
