import re
import json


def parse_lua_to_dict(lua_file):
    pattern = r'\["(.*?)"\] = {p = (.*?), a = (.*?), s = "(.*?)", r = (.*?), k = (.*?)},'
    players = {}
    try:
        with open(lua_file, 'r', encoding='utf-8') as infile:
            lua_content = infile.read()
            matches = re.findall(pattern, lua_content)
            for name, p, a, s, r, k in matches:
                players[name] = {
                    'p': 'nil' if p == 'nil' else round(float(p), 2),
                    'a': round(float(a), 2),
                    's': s,
                    'r': round(float(r), 2),
                    'k': int(k)
                }
    except FileNotFoundError:
        pass  # If the file doesn't exist, start with an empty dictionary.
    return players


def update_or_insert_player(players, player_data, stats):
    name = player_data['name']
    new_data = {
        'p': round(player_data.get('bestPerformanceAverage', 0) if player_data.get(
            'bestPerformanceAverage') is not None else 0, 2),
        'a': round(player_data['allStarPoints'], 2),
        's': player_data['spec'],
        'r': round(player_data['rankPercent'], 2),
        'k': int(player_data['rank'])
    }
    # Check for existence and update if different
    if name in players and players[name] != new_data:
        stats['updated'] += 1
    elif name not in players:
        stats['added'] += 1
    players[name] = new_data


def write_dict_to_lua(players, lua_file):
    with open(lua_file, 'w', encoding='utf-8') as outfile:
        outfile.write("playerData = {\n")
        for name, data in sorted(players.items(), key=lambda x: x[0]):
            p_value = data['p'] if data['p'] != 'nil' else 'nil'
            outfile.write(f'  ["{name}"] = {{p = {p_value}, a = {data["a"]}, s = "{data["s"]}", r = {data["r"]}, k = {data["k"]}}},\n')
        outfile.write("}\n")


def preprocess_data_file(data_file):
    latest_entries = {}
    with open(data_file, 'r', encoding='utf-8') as infile:
        for line in infile:
            player_data = json.loads(line.strip())
            # Always keep the latest entry for each player
            latest_entries[player_data['name']] = player_data
    return latest_entries.values()


def main(data_file, lua_file):
    players = parse_lua_to_dict(lua_file)
    stats = {'added': 0, 'updated': 0}

    latest_player_data = preprocess_data_file(data_file)
    for player_data in latest_player_data:
        update_or_insert_player(players, player_data, stats)

    write_dict_to_lua(players, lua_file)
    print(f"Players added: {stats['added']}")
    print(f"Players updated: {stats['updated']}")


# Adjust 'data_file.txt' and 'output.lua' with your actual file paths
main('../datafile.txt', '../../PlayerDB/DB.lua')
