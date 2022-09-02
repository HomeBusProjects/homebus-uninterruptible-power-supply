require 'homebus/options'

require 'homebus-uninterruptible-power-supply/version'

class HomebusUninterruptiblePowerSupply::Options < Homebus::Options
  def app_options(op)
    agent_help     = 'the SNMP agent IP address or name'
    community_help = 'the SNMP community string'

    op.separator 'SNMP options:'
    op.on('-a', '--agent SNMP_AGENT', agent_help) { |value| options[:agent] = value }
    op.on('-c', '--community SNMP_COMMUNITY_STRING', community_help) { |value| options[:community] = value }
    op.separator ''
  end

  def banner
    'HomeBus UPS (Uninterruptible Power Supply) publisher'
  end

  def version
    HomebusUninterruptiblePowerSupply::VERSION
  end

  def name
    'homebus-uninterruptible-power-supply'
  end
end
