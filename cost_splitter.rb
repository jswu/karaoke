require 'csv'

# Try to use pre taxs and tips in internal computations.
TAX_AND_TIPS_MULTIPLIER = 1 + 0.0875 + 0.18

DRINKS = {
    b: 5,
    t: 6,
    pd: 12,
}

cost_file_name = ARGV[0]
total_cost_pre_tt = ARGV[1].to_f
room_cost_pre_tt = ARGV[2].to_f
drinks_cost_pre_tt = total_cost_pre_tt - room_cost_pre_tt

people = {}
actual_total_room_time = 0
actual_total_room_cost = 0
actual_total_drinks_cost = 0

File.open(cost_file_name, 'r') do |cost_file|
  cost_file.each_line do |line|
    tokens = line.split(' ')

    begin
      room_time = Float(tokens[-1])
      tokens = tokens[0...-1]
    rescue
      room_time = 1
    end
    actual_total_room_time += room_time

    name = tokens[0]
    tokens = tokens.drop(1)

    drinks_cost = tokens.inject(0){|memo, token| memo + DRINKS[token.to_sym]}
    actual_total_drinks_cost += drinks_cost

    people[name] = {
      room_time: room_time,
      drinks_cost: drinks_cost,
    }
  end
end

room_cost_per_full_person = room_cost_pre_tt / actual_total_room_time

people.keys.each do |name|
  person = people[name]
  room_cost = room_cost_per_full_person * person[:room_time]
  person[:room_cost] = room_cost
  actual_total_room_cost += room_cost
end

people['Total'] = {
  room_time: actual_total_room_time,
  room_cost: actual_total_room_cost,
  drinks_cost: actual_total_drinks_cost,
}

def dollarfy(amount)
  "$#{amount.round(2)}"
end

CSV.open("#{cost_file_name}_output.csv", "wb") do |csv|
  csv << ['Name', 'Room time', 'Room $', 'Drinks $', 'Total $']
  people.each do |name, person|
    room_time = person[:room_time]
    room_cost = person[:room_cost] * TAX_AND_TIPS_MULTIPLIER
    drinks_cost = person[:drinks_cost] * TAX_AND_TIPS_MULTIPLIER
    total_cost = room_cost + drinks_cost
    csv << [name, room_time, dollarfy(room_cost), dollarfy(drinks_cost), dollarfy(total_cost)]
  end
end