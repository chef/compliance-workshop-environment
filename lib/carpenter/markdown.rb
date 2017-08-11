module Carpenter
  module Markdown
    def self.print(tfstate)
      deck_colors(tfstate).each do |color|
        puts "# #{color} deck\n\n"

        puts '| Hearts | IP Address |   | Spades | IP Address |   | Diamonds | IP Address |   | Clubs | IP Address |'
        puts '| ------ | ---------- | - | ------ | ---------- | - | -------- | ---------- | - | ----- | ---------- |'

        %w(02 03 04 05 06 07 08 09 10 jack queen king ace).each do |val|
          row = []
          %w(hearts spades diamonds clubs).each do |suit|
            row << "#{val} #{suit_to_char(suit)} | #{ip_for_workstation(tfstate, color, suit, val)}"
          end

          puts "| #{row.join(' | - | ')} |"
        end
      
        puts "\n\n"
      end
    end

    private

    def self.suit_to_char(suit)
      case suit
      when 'hearts'
        '❤️'
      when 'spades'
        '♠️'
      when 'diamonds'
        '♦️'
      when 'clubs'
        '♣️'
      end
    end

    def self.ip_for_workstation(tfstate, color, suit, num)
      deck_cards = all_workstations(tfstate)[color]
      return unless deck_cards.key?(suit)
      
      deck_cards[suit][num]
    end

    def self.deck_colors(tfstate)
      all_workstations(tfstate).keys
    end

    def self.all_workstations(tfstate)
      return @workstations unless @workstations.nil?

      puts "***** PARSING WORKSTATIONS *****"

      @workstations = {}

      tfstate['modules'].each do |mod|
        mod['resources'].values.each do |resource|
          attrs = resource['primary']['attributes']
          next unless attrs.key?('tags.Name') && attrs['tags.Name'].include?('-workshop-station-')
          next if attrs['public_ip'].nil?

          color, suit, number = parse_workstation_name(attrs['tags.Name'])
          @workstations[color] ||= {}
          @workstations[color][suit] ||= {}
          @workstations[color][suit][number] = attrs['public_ip']
        end
      end

      @workstations
    end

    def self.parse_workstation_name(name)
      parsed = name.match(/\w+-workshop-station-(\w+)-(\w+)-(\w+)/)
      color  = parsed[1]
      suit   = parsed[2]
      number = parsed[3]

      [color, suit, number]
    end
  end
end
