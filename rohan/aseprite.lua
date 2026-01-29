-- Native Aseprite binary file parser (.ase/.aseprite)
-- Adapted from https://github.com/elloramir/love-ase

local BYTE  = { "B",  1 }
local WORD  = { "H",  2 }
local SHORT = { "h",  2 }
local DWORD = { "I4", 4 }
local LONG  = { "i4", 4 }
local FIXED = { "i4", 4 }

local function read_num(file, fmt, amount)
  amount = amount or 1
  return love.data.unpack(fmt[1], file:read(fmt[2] * amount), 1)
end

local function read_string(file)
  return file:read(read_num(file, WORD))
end

local function grab_header(file)
  local header = {}
  header.file_size = read_num(file, DWORD)
  header.magic_number = read_num(file, WORD)

  if header.magic_number ~= 0xA5E0 then
    error("Not a valid aseprite file")
  end

  header.frames_number = read_num(file, WORD)
  header.width = read_num(file, WORD)
  header.height = read_num(file, WORD)
  header.color_depth = read_num(file, WORD)
  header.opacity = read_num(file, DWORD)
  header.speed = read_num(file, WORD)
  read_num(file, DWORD, 2)
  header.palette_entry = read_num(file, BYTE)
  read_num(file, BYTE, 3)
  header.number_color = read_num(file, WORD)
  header.pixel_width = read_num(file, BYTE)
  header.pixel_height = read_num(file, BYTE)
  header.grid_x = read_num(file, SHORT)
  header.grid_y = read_num(file, SHORT)
  header.grid_width = read_num(file, WORD)
  header.grid_height = read_num(file, WORD)
  read_num(file, BYTE, 84)
  header.frames = {}
  return header
end

local function grab_frame_header(file)
  local frame_header = {}
  frame_header.bytes_size = read_num(file, DWORD)
  frame_header.magic_number = read_num(file, WORD)

  if frame_header.magic_number ~= 0xF1FA then
    error("Corrupted aseprite file")
  end

  local old_chunks = read_num(file, WORD)
  frame_header.frame_duration = read_num(file, WORD)
  read_num(file, BYTE, 2)
  local new_chunks = read_num(file, DWORD)

  if new_chunks == 0 then
    frame_header.chunks_number = old_chunks
  else
    frame_header.chunks_number = new_chunks
  end

  frame_header.chunks = {}
  return frame_header
end

local function grab_color_profile(file)
  local color_profile = {}
  color_profile.type = read_num(file, WORD)
  color_profile.uses_fixed_gama = read_num(file, WORD)
  color_profile.fixed_game = read_num(file, FIXED)
  read_num(file, BYTE, 8)
  return color_profile
end

local function grab_palette(file)
  local palette = {}
  palette.entry_size = read_num(file, DWORD)
  palette.first_color = read_num(file, DWORD)
  palette.last_color = read_num(file, DWORD)
  palette.colors = {}
  read_num(file, BYTE, 8)

  for i = 1, palette.entry_size do
    local has_name = read_num(file, WORD)
    palette.colors[i] = {
      color = {
        read_num(file, BYTE),
        read_num(file, BYTE),
        read_num(file, BYTE),
        read_num(file, BYTE)
      }
    }
    if has_name == 1 then
      palette.colors[i].name = read_string(file)
    end
  end
  return palette
end

local function grab_old_palette(file)
  local palette = {}
  palette.packets = read_num(file, WORD)
  palette.colors_packet = {}

  for i = 1, palette.packets do
    palette.colors_packet[i] = {
      entries = read_num(file, BYTE),
      number = read_num(file, BYTE),
      colors = {}
    }
    if palette.colors_packet[i].number == 0 then
      palette.colors_packet[i].number = 256
    end
    for j = 1, palette.colors_packet[i].number do
      palette.colors_packet[i][j] = {
        read_num(file, BYTE),
        read_num(file, BYTE),
        read_num(file, BYTE)
      }
    end
  end
  return palette
end

local function grab_layer(file)
  local layer = {}
  layer.flags = read_num(file, WORD)
  layer.type = read_num(file, WORD)
  layer.child_level = read_num(file, WORD)
  layer.width = read_num(file, WORD)
  layer.height = read_num(file, WORD)
  layer.blend = read_num(file, WORD)
  layer.opacity = read_num(file, BYTE)
  read_num(file, BYTE, 3)
  layer.name = read_string(file)
  return layer
end

local function grab_cel(file, size)
  local cel = {}
  cel.layer_index = read_num(file, WORD)
  cel.x = read_num(file, WORD)
  cel.y = read_num(file, WORD)
  cel.opacity_level = read_num(file, BYTE)
  cel.type = read_num(file, WORD)
  read_num(file, BYTE, 7)

  if cel.type == 0 then
    cel.width = read_num(file, WORD)
    cel.height = read_num(file, WORD)
    cel.data = {}
    for i = 1, cel.width * cel.height do
      cel.data[i] = {
        read_num(file, BYTE),
        read_num(file, BYTE),
        read_num(file, BYTE),
        read_num(file, BYTE)
      }
    end
  elseif cel.type == 1 then
    cel.frame_pos_link = read_num(file, WORD)
  elseif cel.type == 2 then
    cel.width = read_num(file, WORD)
    cel.height = read_num(file, WORD)
    cel.data = file:read(size - 26)
  elseif cel.type == 3 then
    cel.width = read_num(file, WORD)
    cel.height = read_num(file, WORD)
    cel.bits_per_tile = read_num(file, WORD)
    cel.bitmask_tile_id = read_num(file, DWORD)
    cel.bitmask_x_flip = read_num(file, DWORD)
    cel.bitmask_y_flip = read_num(file, DWORD)
    cel.bitmask_rotation = read_num(file, DWORD)
    read_num(file, BYTE, 10)
    cel.data = {}
    for i = 1, cel.width * cel.height do
      cel.data[i] = { read_num(file, DWORD) }
    end
  end
  return cel
end

local function grab_tags(file)
  local tags = {}
  tags.number = read_num(file, WORD)
  tags.tags = {}
  read_num(file, BYTE, 8)

  for i = 1, tags.number do
    tags.tags[i] = {
      from = read_num(file, WORD),
      to = read_num(file, WORD),
      direction = read_num(file, BYTE),
      extra_byte = read_num(file, BYTE),
      color = { read_num(file, BYTE, 3) },
      name = (function()
        read_num(file, BYTE, 8)
        return read_string(file)
      end)()
    }
  end
  return tags
end

local function grab_slice(file)
  local slice = {}
  slice.key_numbers = read_num(file, DWORD)
  slice.keys = {}
  slice.flags = read_num(file, DWORD)
  read_num(file, DWORD)
  slice.name = read_string(file)

  for i = 1, slice.key_numbers do
    slice.keys[i] = {
      frame = read_num(file, DWORD),
      x = read_num(file, DWORD),
      y = read_num(file, DWORD),
      width = read_num(file, DWORD),
      height = read_num(file, DWORD)
    }
    if slice.flags == 1 then
      slice.keys[i].center_x = read_num(file, DWORD)
      slice.keys[i].center_y = read_num(file, DWORD)
      slice.keys[i].center_width = read_num(file, DWORD)
      slice.keys[i].center_height = read_num(file, DWORD)
    elseif slice.flags == 2 then
      slice.keys[i].pivot_x = read_num(file, DWORD)
      slice.keys[i].pivot_y = read_num(file, DWORD)
    end
  end
  return slice
end

local function grab_user_data(file)
  local user_data = {}
  user_data.flags = read_num(file, DWORD)
  if user_data.flags == 1 then
    user_data.text = read_string(file)
  elseif user_data.flags == 2 then
    user_data.colors = { read_num(file, BYTE, 4) }
  end
  return user_data
end

local function grab_tileset(file)
  local tileset = {}
  tileset.id = read_num(file, DWORD)
  tileset.flags = read_num(file, DWORD)
  tileset.num_tiles = read_num(file, DWORD)
  tileset.tile_width = read_num(file, WORD)
  tileset.tile_height = read_num(file, WORD)
  tileset.base_index = read_num(file, SHORT)
  read_num(file, BYTE, 14)
  tileset.name = read_string(file)

  if tileset.flags == 1 then
    tileset.external_id = read_num(file, DWORD)
    tileset.tileset_id_in_external_file = read_num(file, DWORD)
  end
  return tileset
end

local function grab_chunk(file)
  local chunk = {}
  chunk.size = read_num(file, DWORD)
  chunk.type = read_num(file, WORD)

  if chunk.type == 0x2007 then
    chunk.data = grab_color_profile(file)
  elseif chunk.type == 0x2019 then
    chunk.data = grab_palette(file)
  elseif chunk.type == 0x0004 then
    chunk.data = grab_old_palette(file)
  elseif chunk.type == 0x2004 then
    chunk.data = grab_layer(file)
  elseif chunk.type == 0x2005 then
    chunk.data = grab_cel(file, chunk.size)
  elseif chunk.type == 0x2018 then
    chunk.data = grab_tags(file)
  elseif chunk.type == 0x2022 then
    chunk.data = grab_slice(file)
  elseif chunk.type == 0x2020 then
    chunk.data = grab_user_data(file)
  elseif chunk.type == 0x2023 then
    chunk.data = grab_tileset(file)
  end

  return chunk
end

local Aseprite = {}

function Aseprite.load(path)
  local file = love.filesystem.newFile(path)
  if not file:open("r") then
    error("File not found: " .. path)
  end

  local ase = {}
  ase.header = grab_header(file)

  for i = 1, ase.header.frames_number do
    ase.header.frames[i] = grab_frame_header(file)
    for j = 1, ase.header.frames[i].chunks_number do
      ase.header.frames[i].chunks[j] = grab_chunk(file)
    end
  end

  file:close()

  -- Extract useful data
  local result = {
    width = ase.header.width,
    height = ase.header.height,
    frameCount = ase.header.frames_number,
    frames = {},
    tags = {},
    layers = {},
    slices = {},
  }

  -- Process frames and extract durations
  for i, frame in ipairs(ase.header.frames) do
    result.frames[i] = {
      duration = frame.frame_duration / 1000, -- ms to seconds
    }

    -- Extract tags, layers, slices from chunks
    for _, chunk in ipairs(frame.chunks) do
      if chunk.type == 0x2018 and chunk.data then -- Tags
        for _, tag in ipairs(chunk.data.tags) do
          result.tags[tag.name] = {
            from = tag.from + 1, -- 1-indexed
            to = tag.to + 1,
            direction = tag.direction, -- 0=forward, 1=reverse, 2=pingpong
          }
        end
      elseif chunk.type == 0x2004 and chunk.data then -- Layer
        result.layers[#result.layers + 1] = {
          name = chunk.data.name,
          visible = (chunk.data.flags % 2) == 1,
        }
      elseif chunk.type == 0x2022 and chunk.data then -- Slice
        result.slices[chunk.data.name] = chunk.data
      end
    end
  end

  result._raw = ase
  return result
end

return Aseprite

