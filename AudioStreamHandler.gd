extends Control

var effect
var recording
var token = 'SOPPIEVD7ED7KXA7PPMC623LNPAU7TZO'

func _ready():
	var idx = AudioServer.get_bus_index('Record')
	effect = AudioServer.get_bus_effect(idx, 0)
	print(effect)
	
func _process(_delta):
	if Input.is_action_just_pressed('record'): # R key
		record()
	if Input.is_action_just_pressed('play_recording'): # P key
		print('running play function')
		play_rec()
	if Input.is_action_just_pressed('send_req'): # S key
		send_req(recording.data)
	if Input.is_action_just_pressed('save_and_send'): # B key
		save_file_and_send()

func record():
	if effect.is_recording_active():
		print('Stopped')
		recording = effect.get_recording()
		effect.set_recording_active(false)
		
		recording.set_stereo(false)
		var mono = convert_to_mono(recording.get_data())
		recording.set_data(mono)
	else:
		print('Recording')
		effect.set_recording_active(true)

func play_rec():
	print(recording)
	print(recording.format)
	print(recording.mix_rate)
	print(recording.stereo)
	var data = recording.get_data()
	print(data.size())

	$AudioStreamPlayer.stream = recording
	$AudioStreamPlayer.play()

func convert_to_mono(data):
	var new_data = PoolByteArray()
	var count = 0
	for i in range(len(data)):
		if (i+1) % 3 == 0 or (i+1) % 4 == 0:
			continue
		else:
			new_data.append(int(data[i]))
	return new_data

func save_file_and_send():
	var save_path = './sound.wav'
	recording.save_to_wav(save_path)
	print('Saved to ' + save_path)
	
	var file = File.new()
	file.open('./sound.wav', File.READ)
	var data = file.get_buffer(file.get_len())
	
	print('Sending data')
	var headers = ['Authorization: Bearer ' + token, 'Content-Type: audio/wav']
	$HTTPRequest.request_raw('https://api.wit.ai/dictation', headers, true, HTTPClient.METHOD_POST, data)

func send_req(data):
	print('Sending data')
	var headers = ['Authorization: Bearer ' + token, 'Content-Type: audio/raw;encoding=unsigned-integer;bits=16;rate=44100;endian=little']
	$HTTPRequest.request_raw('https://api.wit.ai/speech/', headers, true, HTTPClient.METHOD_POST, data)
	
func _on_request_completed(result, response_code, _headers, body):
	print(response_code, result)
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
