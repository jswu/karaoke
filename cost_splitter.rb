# For computing karaoke receipts.
# Usage:
#   ruby cost_splitter.rb COST_FILE_NAME TOTAL_COST_PRE_TAX_TIP ROOM_COST_PRE_TAX_TIP
# Example:
#   ruby cost_splitter.rb 2016_02_26.txt 460 324
# Import .csv into Google Spreadsheets, then share the spreadsheet!
require 'csv'

VENMO_USERNAME = 'Sandy-Wu'
SQUARE_CASH_USERNAME = '$SandyWu'

# Try to not use pre taxs and tips in internal computations.
TAX_AND_TIPS_MULTIPLIER = 1 + 0.0875 + 0.18

DRINKS = {
    # Beer
    b: 5,
    # Tequila
    t: 6,
    # Peach delight
    pd: 12,
    # Coke (estimate, unsure)
    ck: 5,
}

cost_file_name = ARGV[0]
event_name = cost_file_name.split('.')[0]

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
    name = tokens[0]
    raise "Duplicate name exists: #{name}" if people.has_key?(name)

    begin
      # Expect the last number to be the room time fraction
      room_time = Float(tokens[-1])
      tokens = tokens[0...-1]
    rescue
      room_time = 1
    end
    actual_total_room_time += room_time

    tokens = tokens.drop(1)

    # TODO(sandy): Instead of computing absolute total drinks cost, should
    # perhaps instead split the sum of the drink costs by each person,
    # proportionally. This will help account for stray items that were
    # unaccounted for.
    drinks_cost = tokens.inject(0) do |memo, token|
      memo + DRINKS.fetch(token.to_sym)
    end
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


def make_venmo_link(amount, event_name)
  "https://venmo.com/?txn=pay&share=private&recipients=#{VENMO_USERNAME}&amount=#{amount}&note=#{event_name}%20karaoke"
end

def make_square_cash_link(amount)
  "https://cash.me/#{SQUARE_CASH_USERNAME}/#{amount}"
end

CSV.open("#{event_name}_output.csv", "wb") do |csv|
  csv << ['Name', 'Room time', 'Room $', 'Drinks $', '*** Total $ (PAY THIS AMOUNT) *** (use links for convenience --->)', 'Pay with Venmo', 'Pay with Square Cash', 'I paid! (y/n)']
  people.each do |name, person|
    room_time = person[:room_time]
    room_cost = person[:room_cost] * TAX_AND_TIPS_MULTIPLIER
    drinks_cost = person[:drinks_cost] * TAX_AND_TIPS_MULTIPLIER
    total_cost = room_cost + drinks_cost
    venmo_link = make_venmo_link(total_cost.round(2), event_name)
    square_cash_link = make_square_cash_link(total_cost.round(2))
    csv << [name, room_time, dollarfy(room_cost), dollarfy(drinks_cost), dollarfy(total_cost), venmo_link, square_cash_link]
  end
end
