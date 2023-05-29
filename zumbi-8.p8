pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
function _init()
	stage = 1

	cursor_pos_x = 1
	cursor_pos_y = 1
	info_box_y = 1;

	types_of_tiles = {"drug\nstore","police\ndepartament","grocery\nstore","clothing\nstore","bar","gun store","house","gas\nstation","restaurant","flower\nshop","lake","farm","ranch","forest","constr.\nstore"}

	types_of_jobs = {"dOCTOR", "cOP", "cOOK", "hANDYMAN", "fARMER", "lUMBERJACK"}

	types_of_perks = {
		{"sMALL STOMACH", "consumes less food daily"},
		{"sTRONG", "increased melee damage"},
		{"20/20 VISION", "greater accuracy"},
		{"sKILLED", "does stuff faster"},
		{"rESOURCEFUL", "uses less materials"},
	}

	types_of_flaws = {
		{"gLUTTON", "eats a lot"},
		{"wEAK", "less melee damage"},
		{"nEAR SIGHTED", "less accurate"},
		{"iNEPT", "takes more time to do something"},
		{"wASTEFUL", "actions consumes more materials"}
	}

	names = { "tHOMAS", "bRUCE", "dOUG", "aNNA", "mARY", "cLAIRE" }

	party_members = {}

	party_menu_option_selector = 1
	showing_party_members = false
	showing_party_inventory = false
	party_menu_inner_option = false
	party_members_showing_member_stats_idx = 0
	block_btns = true

	party_inventory = {}

	city_size_selector = 1
	board_sizes = {5, 7, 8}
	board_starting_x_by_size = {16, 8, -4}
	z_spawner_limit_by_size = {2, 4, 6}
	z_spawner_limit = 1
	board = {}
	current_selected_tile = {}

	tiles_to_check = {}
	can_explore_current_selected_tile = false
	current_tile_allowed_actions = {}

	showing_current_tile_options = true
	showing_party_options = false
end

function _draw()
	cls()

	if stage == 1 then
		print("choose city size", 28, 60)

		spr(064, 24, 65 + (city_size_selector * 6))
		print("small", 32, 72)
		print("medium")
		print("big")
	end

	if stage == 2 then
		for i=1, count(board) do
			for k=1, count(board[i]) do
				spr(000, board[i][k].px, board[i][k].py, 2, 2)
				spr(board[i][k].spr, board[i][k].px, board[i][k].py, 2, 2)
			end
		end

		rect(1, 1, 50, 39, 11)

		if showing_current_tile_options then
			print(current_selected_tile.type, 3, 3, 7)
			size = (current_selected_tile.size == 1) and "small" or "big"
			print("sIZE: " .. size, 3, 17, 7)

			print((current_selected_tile.is_known) and "kNOWN" or "uNKNOWN", 3, 24, 7)
			if not current_selected_tile.is_known then
				can_explore = (can_explore_current_selected_tile) and "cAN EXPLORE" or "tOO FAR"
				can_explore_color = (can_explore_current_selected_tile) and 11 or 8
				print(can_explore, 3, 32, can_explore_color)
			end
		else
			if not showing_party_members and not showing_party_inventory then
				print("your group", 3, 3, 7)
				spr(064, 1, 10 + (party_menu_option_selector * 6))
				print("mEMBERS", 10, 17, 7)
				print("iNVENTORY")
				print("sTATS")
			elseif showing_party_members then
				print("members", 3, 3, 7)
				spr(064, 1, 10 + (party_menu_option_selector * 6))
				for i=1, count(party_members) do
					print(party_members[i].name, 10, 17, 7)
				end
				if party_members_showing_member_stats_idx > 0 then
					rectfill(14, 10, 64, 50, 0)
					rect(14, 10, 64, 50, 11)
					print(party_members[party_members_showing_member_stats_idx].job .. " " .. party_members[party_members_showing_member_stats_idx].name, 16, 12, 7)
					print("perks", 11)
					print(party_members[party_members_showing_member_stats_idx].perk1[1], 7)
					print(party_members[party_members_showing_member_stats_idx].perk2[1])
					print("flaw", 8)
					print(party_members[party_members_showing_member_stats_idx].flaw[1], 7)
				end
				

			elseif showing_party_inventory then
				print("inventory", 3, 3, 7)
				spr(064, 1, 10 + (party_menu_option_selector * 6))
			end
		end

		if (info_box_y <= 40) rectfill(1, info_box_y, 50, 42, 0)

		select_tile_spr = (current_selected_tile.size == 1) and 008 or 006
		spr(010, current_selected_tile.px, current_selected_tile.py, 2, 2)
		spr(select_tile_spr, current_selected_tile.px, current_selected_tile.py, 2, 2)

	end
end

function _update()
	if stage == 1 then
		if (btnp(4) or btnp(5)) stage = 2 board_size = board_sizes[city_size_selector] z_spawner_limit = z_spawner_limit_by_size[city_size_selector] cursor_pos_x = ceil(board_size/2) cursor_pos_y = ceil(board_size/2)

		if (btnp(2) and city_size_selector > 1) city_size_selector -= 1
		if (btnp(3) and city_size_selector < 3) city_size_selector += 1 
	end

	if stage == 2 then
		if count(board) == 0 then
			lim_y = 0
			lim_x = 0
			left_position = 0
			z_spawner_created = 0
			z_spawner = false
			board_line = {}
			tile_counter = 1

			for i=1, board_size^2 do
				size = rnd({1,2})
				z_spawner = false
				rnd_factor = (z_spawner_created == 0) and 0 or 0.5
				if (i % board_size == 0 and rnd() > rnd_factor and z_spawner_created < z_spawner_limit) z_spawner = true z_spawner_created += 1

				local tile = {}
				tile.px = board_starting_x_by_size[city_size_selector] + (lim_x * 16) + left_position
				tile.py = 44 + (lim_y * 9)
				tile.type = rnd(types_of_tiles)
				tile.size = size
				tile.spr = (size == 1) and 004 or 002
				tile.is_known = false
				if z_spawner then
					tile.spr = (size == 1) and 036 or 034
				end
				tile.is_z_spawner = z_spawner
				tile.border_check = false
				add(board_line, tile)

				lim_x += 1
				if i % board_size == 0 then
					add(board, board_line)
					board_line = {}
					lim_y += 1
					lim_x = 0
					left_position = (left_position == 0) and 8 or 0 
				end
			end

			board[cursor_pos_y][cursor_pos_x].is_known = true
			board[cursor_pos_y][cursor_pos_x].spr = (board[cursor_pos_y][cursor_pos_x].size == 1) and 040 or 038
		end

		if count(party_members) == 0 then
			local new_guy = {}

			local types_of_perks_local = types_of_perks
			local types_of_flaws_local = types_of_flaws

			perk1_idx = flr(rnd(count(types_of_perks_local))) + 1
			perk1 = types_of_perks_local[perk1_idx]
			del(types_of_perks_local, perk1)
			del(types_of_flaws_local, types_of_flaws_local[perk1_idx])


			perk2_idx = flr(rnd(count(types_of_perks_local))) + 1
			perk2 = types_of_perks_local[perk2_idx]
			del(types_of_perks_local, perk2)
			del(types_of_flaws_local, types_of_flaws_local[perk2_idx])


			new_guy.name = rnd(names)
			new_guy.job = rnd(types_of_jobs)
			new_guy.perk1 = perk1
			new_guy.perk2 = perk2
			new_guy.flaw = rnd(types_of_flaws_local)

			add(party_members, new_guy)
		end


		if (info_box_y <= 40) info_box_y += 4

		if showing_current_tile_options then
			if (btnp(0) and cursor_pos_x > 1) cursor_pos_x -= 1 info_box_y = 1 
			if (btnp(1) and cursor_pos_x < board_size) cursor_pos_x += 1 info_box_y = 1
			if (btnp(2) and cursor_pos_y > 1) cursor_pos_y -= 1 info_box_y = 1
			if (btnp(3) and cursor_pos_y < board_size) cursor_pos_y += 1 info_box_y = 1
		else
			if btnp(1) then
				if (showing_party_members) party_members_showing_member_stats_idx = 1

				if not party_menu_inner_option then
					if (party_menu_option_selector == 1 and not party_menu_inner_option) showing_party_members = true showing_party_inventory = false party_menu_inner_option = true
					if (party_menu_option_selector == 2 and not party_menu_inner_option) showing_party_inventory = true showing_party_members = false party_menu_inner_option = true
				end
			end

			if btnp(0) then
				if showing_party_members then
					if party_members_showing_member_stats_idx > 0 then
						party_members_showing_member_stats_idx = 0
					else
						showing_party_members = false party_menu_inner_option = false
					end
				end
				if (showing_party_inventory) showing_party_inventory = false  party_menu_inner_option = false
			end 

			if (btnp(2) and party_menu_option_selector > 1) party_menu_option_selector -= 1
			if (btnp(3) and party_menu_option_selector < 2) party_menu_option_selector += 1
		end

		current_selected_tile = board[cursor_pos_y][cursor_pos_x]

		get_tiles_to_check(cursor_pos_x, cursor_pos_y)

		check_can_explore_current_tile()

		if (btnp(4) and can_explore_current_selected_tile) current_selected_tile.is_known = true -- todo: trigger some action
		if (btnp(5)) showing_current_tile_options = not showing_current_tile_options showing_party_options = not showing_party_options info_box_y = 1 party_menu_option_selector = 1 party_menu_inner_option = false showing_party_inventory  = false showing_party_members = false
	end
end

function get_tiles_to_check(cpx, cpy)
	tiles_to_check = {}
	if cpy % 2 != 0 then
		if (cpx - 1 > 0 and cpy - 1 > 0) add(tiles_to_check, { cpx - 1, cpy - 1 })
		if (cpy - 1 > 0) add(tiles_to_check, { cpx, cpy - 1 })
		if (cpx - 1 > 0) add(tiles_to_check, { cpx - 1, cpy })
		if (cpx + 1 <= board_size) add(tiles_to_check, { cpx + 1, cpy })
		if (cpx - 1 > 0 and cpy + 1 <= board_size) add(tiles_to_check, { cpx - 1, cpy + 1 })
		if (cpy + 1 <= board_size) add(tiles_to_check, { cpx, cpy + 1 })
	else
		if (cpy - 1 > 0) add(tiles_to_check, { cpx, cpy - 1 })
		if (cpy - 1 > 0 and cpx + 1 <= board_size)  add(tiles_to_check, { cpx + 1, cpy - 1 })
		if (cpx - 1 > 0) add(tiles_to_check, { cpx - 1, cpy })
		if (cpx + 1 <= board_size) add(tiles_to_check, { cpx + 1, cpy })
		if (cpy + 1 <= board_size) add(tiles_to_check, { cpx, cpy + 1 })
		if (cpx + 1 <= board_size and cpy + 1 <= board_size) add(tiles_to_check, { cpx + 1, cpy + 1 })
	end
end

function check_can_explore_current_tile()

	if not current_selected_tile.is_known then
		for tile in all(tiles_to_check) do
			if board[tile[2]][tile[1]].is_known then 
				can_explore_current_selected_tile = true
				goto exit_fn
			else
				can_explore_current_selected_tile = false
			end
		end
	end

	::exit_fn::

end

__gfx__
0000000000000000000000066000000000000000000000000000000ff00000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000066666600000000000000000000000000ffffff000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000066666666660000000000000000000000ffffffffff0000000000000000000000000000000000000000000000000000000000000000000
000000000000000007766666666666600000000000000000077ffffffffffff00000000000000000000000000000000000000000000000000000000000000000
00000000000000000dd776666666611000000006600000000aa77ffffffff9900000000ff0000000000000000000000000000000000000000000000000000000
00000000000000000dddd7766661111000000666666000000aaaa77ffff9999000000ffffff00000000000000000000000000000000000000000000000000000
00000000000000000dddddd77111111000066666666660000aaaaaa779999990000ffffffffff000000000000000000000000000000000000000000000000000
00000005500000000ddddddd1111111007766666666667700aaaaaaa99999990077ffffffffff770000000077000000000000000000000000000000000000000
00000550055000000ddddddd111111100dd77666666771100aaaaaaa999999900aa77ffffff77990000007700770000000000000000000000000000000000000
00055000000550000ddddddd111111100dddd776677111100aaaaaaa999999900aaaa77ff7799990000770000007700000000000000000000000000000000000
05500000000005500ddddddd111111100dddddd7711111100aaaaaaa999999900aaaaaa779999990077000000000077000000000000000000000000000000000
50000000000000050ddddddd111111100ddddddd111111100aaaaaaa999999900aaaaaaa99999990700000000000000700000000000000000000000000000000
0550000000000550000ddddd11111000000ddddd11111000000aaaaa99999000000aaaaa99999000077000000000077000000000000000000000000000000000
000550000005500000000ddd1110000000000ddd1110000000000aaa9990000000000aaa99900000000770000007700000000000000000000000000000000000
00000550055000000000000d100000000000000d100000000000000a900000000000000a90000000000007700770000000000000000000000000000000000000
00000005500000000000000000000000000000000000000000000000000000000000000000000000000000077000000000000000000000000000000000000000
00000000000000000000000ee000000000000000000000000000000bb00000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000eeeeee00000000000000000000000000bbbbbb000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000eeeeeeeeee0000000000000000000000bbbbbbbbbb0000000000000000000000000000000000000007b00000000000000000000000000
0000000000000000077eeeeeeeeeeee00000000000000000077bbbbbbbbbbbb0000000000000000000000000000000000007b3300007b0000000000000000000
000000000000000008877eeeeeeee2200000000ee000000003377bbbbbbbb1100000000bb00000000000000000000000000bbbb0bb0b3b000000000000000000
00000000000000000888877eeee2222000000eeeeee000000333377bbbb1111000000bbbbbb000000000000000000000000b3b3b3bbbbb000000000000000000
00000000000000000888888772222220000eeeeeeeeee0000333333771111110000bbbbbbbbbb000000000000000000000003307b3b3b3000000000000000000
00000007700000000888888822222220077eeeeeeeeee7700333333311111110077bbbbbbbbbb77000000000000000000000420b3bbb30000000000000000000
0000077007700000088888882222222008877eeeeee77220033333331111111003377bbbbbb77110000000033000000000004203b30420000000000330000000
000770000007700008888888222222200888877ee772222003333333111111100333377bb771111000000b33bb300000000042334234200000000b3444c00000
07700000000007700888888822222220088888877222222003333333111111100333333771111110000333bb33b33000000342bb42b420000003334c7c7c4000
7000000000000007088888882222222008888888222222200333333311111110033333331111111003b3bb3bb33b3b3003b3423b42342b3003b344c7ccc43b30
0770000000000770000888882222200000088888222220000003333311111000000333331111100000033bb3b3bb300000033bb342bb30000004c7cc744b3000
000770000007700000000888222000000000088822200000000003331110000000000333111000000000033b333000000000033b3330000000000c7443300000
00000770077000000000000820000000000000082000000000000003100000000000000310000000000000033000000000000003300000000000000330000000
00000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aa900009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aaa90009aaa900099999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009aa900009999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
009a9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
