require('luaex')

local childprocess = require('childprocess')
local fs = require('fs')
local path = require('path')
local package = require('./package.lua')

local date_format = '%Y-%m-%d-%H-%M-%S'
local mode = process.argv[2]
local exarg = process.argv[3]

if not string.match(process.argv[1], 'main.lua') then
  mode = process.argv[1]
  exarg = process.argv[2]
end

function fs.readdir_recursive(dir)
	local results = {}
	local dir_list = path.join(table.unpack(dir))
	local files = fs.load_dir(dir_list)

	table.foreach(files, function(_, name)
		local small_dir = path.join(dir_list, name)
		local dir_locate_status, err = fs.lstatSync(small_dir)
		if err then
			error(err)
		end
		if dir_locate_status.type ~= 'directory' then
			table.insert(results, small_dir)
		else
			local another_time = fs.readdir_recursive({ dir_list, name })
			table.foreach(another_time, function(_, value)
				table.insert(results, value)
			end)
		end
	end)

	return results
end

function fs.load_dir(dir)
	local files, err = fs.readdirSync(dir)
	if err then
		error(err)
	end
	return files
end

print("")
print("Rainy's android development tool: geta")
print("--------------------------------------")
print("Version     | " .. package.version)
print("Description | " .. package.description)
print("License     | " .. package.license)
print("--------------------------------------")
print("")

local accept = { 'dmesg', 'logcat', 'ramoops', 'clear', 'clearall' }
local clear_arg_accept = { 'dmesg', 'logcat', 'ramoops' }

local function print_manual()
  print '------------------------------------------------------------------------------------'
  print 'dmesg                            | get dmesg log (live)'
  print 'logcat                           | get logcat log (live)'
  print 'ramoops                          | get ramoops log (last dmesg log before crash)'
  print 'clear [dmesg / ramoops / logcat] | clear specific log folder (folder name like mode)'
  print 'clearall                         | clear every folder that exist'
  print '------------------------------------------------------------------------------------'
  print ''
end

if (not mode) or (not table.includes(accept, mode)) then
  print 'You should provide one one of these mode'
  print_manual()
  os.exit()
end

local function log(msg)
  local date = os.date(date_format)
  print(string.format('%s | %s', date, msg))
end

local function run_clean(need_arg)
  if not need_arg or not table.includes(clear_arg_accept, need_arg) then
    print 'clear command arg missing or mismatch, only accept: dmesg / ramoops / logcat'
    print_manual()
    os.exit()
  end
  local clean_folder_name = string.format('%s_log', need_arg)
  if not fs.existsSync('./' .. clean_folder_name) then return end
  log('Clearing folder name: ' .. clean_folder_name)
  local all_file = fs.readdir_recursive({ clean_folder_name })
  for _, file_dir in pairs(all_file) do
    fs.unlinkSync(file_dir)
  end
  fs.rmdirSync('./' .. clean_folder_name)
  log('(FINISHED) Clear folder: ' .. clean_folder_name)
end

local function run_clean_all()
  log('Clearing all folders...')
  run_clean('dmesg')
  run_clean('logcat')
  run_clean('ramoops')
  log('(FINISHED) Clear all folder!')
end

if mode == 'clear' then
  return run_clean(exarg)
end

if mode == 'clearall' then
  return run_clean_all()
end

log('Checking folders...')

local date = os.date(date_format)
local folder_name = string.format('%s_log', mode)
local file_name = string.format('%s-%s.log', mode, date)
local full_path = './' .. folder_name .. '/' .. file_name

if not fs.existsSync(folder_name) then
  log('Folder ' .. folder_name .. ' not exists, creating...')
  fs.mkdirSync(folder_name)
  log('Created folder: ' .. folder_name)
end

log('Checking adb ...')

childprocess.exec('adb --version', function (data)
  if data then
    log("Your pc doesn't have adb binary, please install it from here: https://developer.android.com/tools/releases/platform-tools")
    os.exit()
  end
end)

log('adb command exists! Now checking if have any device avaliable')

childprocess.exec('adb devices', function (_, res)
  local filtered_break = string.split(res, 'device')
  if #filtered_break == 1 then
    log("No device avaliable, Exit binary")
    os.exit()
  end
end)

log(string.format('Device avaliable, now running log recorder... [%s]', mode))

local function run_dmesg_recorder(file)
  local childProcess = require('childprocess')
  local child = childProcess.spawn('adb', {'shell', 'su', '-c', 'dmesg', '-w'}, {})
  child.stdout:on('data', function (data)
    fs.writeSync(file, -1, data)
  end)
end

local function run_logcat_recorder(file)
  local childProcess = require('childprocess')
  local child = childProcess.spawn('adb', {'shell', 'su', '-c', 'logcat'}, {})
  child.stdout:on('data', function (data)
    fs.writeSync(file, -1, data)
  end)
end

local function run_ramoops_recorder(file)
  local childProcess = require('childprocess')
  local child = childProcess.spawn('adb', {'shell', 'su', '-c', "'cat /sys/fs/pstore/console-ramoops-0'"}, {})
  child.stdout:on('data', function (data)
    fs.writeSync(file, -1, data)
  end)
  child.stdout:on('close', function ()
    log(string.format('(FINISHED) File avaliable in: %s', full_path))
  end)
end

local file = fs.openSync(full_path, 'a')

if mode == 'dmesg' then
  return run_dmesg_recorder(file)
end

if mode == 'logcat' then
  return run_logcat_recorder(file)
end

if mode == 'ramoops' then
  return run_ramoops_recorder(file)
end