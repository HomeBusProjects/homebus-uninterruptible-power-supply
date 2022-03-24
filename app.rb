require 'homebus'
require 'dotenv/load'

require 'snmp'

class UPSHomebusApp < Homebus::App
  DDC_UPS = 'org.homebus.experimental.uninterruptible-power-supply'
  DDC_SYSTEM = 'org.homesbus.experimental.system'

  def initialize(options)
    @options = options

    @agent_hostname = @options[:agent] || ENV['SNMP_AGENT_NAME']
    @community_string = @options[:community] || ENV['SNMP_COMMUNITY_STRING']

    super
  end

  def setup!
    @manager = SNMP::Manager.new(host: @agent_hostname, community: @community_string, version: :SNMPv1)

    response = @manager.get(['sysDescr.0', 
                             'sysName.0',
                             'sysLocation.0',
                             'sysUpTime.0',
                             '1.3.6.1.2.1.33.1.1.1.0',
                             '1.3.6.1.2.1.33.1.1.3.0', # upsIdentUPSSoftwareVersion
                             '1.3.6.1.2.1.33.1.1.2.0' # upsIdentModel
                            ])

    response.each_varbind do |vb|
      @sysName = vb.value.to_s if  vb.name.to_s == 'SNMPv2-MIB::sysName.0'
      @sysUptime = vb.value.to_i if vb.name.to_s == 'SNMPv2-MIB::sysUptime.0'
      @sysDescr = vb.value.to_s if  vb.name.to_s == 'SNMPv2-MIB::sysDescr.0'
      @sysLocation = vb.value.to_s if  vb.name.to_s == 'SNMPv2-MIB::sysLocation.0'
      @sysUptime = vb.value.to_i if  vb.name.to_s == 'SNMPv2-MIB::sysUptime.0'
#      @manufacturer = vb.value.to_s if  vb.name.to_s == 'UPS-MIB::upsIdentManufacturer.0' #
      @manufacturer = vb.value.to_s if  vb.name.to_s == 'SNMPv2-SMI::mib-2.33.1.1.1.0'
#      @model = vb.value.to_s if  vb.name.to_s == 'UPS-MIB::upsIdentModel.0' # '1.3.6.1.2.1.33.1.1.1.0'
      @model = vb.value.to_s if  vb.name.to_s == 'SNMPv2-SMI::mib-2.33.1.1.2.0'
      @firmware_version = vb.value.to_s if vb.name.to_s == 'SNMPv2-SMI::mib-2.33.1.1.4.0'
    end

    puts
    puts 'sysThings'
    puts @sysName, @sysDescr, @sysLocation, @manufacturer, @model, @sysUptime
  end

  def _get_data
    # currently unused
    #   estimated_minutes_remaining: '1.3.6.1.2.1.33.1.2.3.0',
    #   battery_current: '1.3.6.1.2.1.33.1.2.6.0',
    #   battery_temperature: '1.3.6.1.2.1.33.1.2.7.0'

    oids = {
      uptime: SNMP::ObjectId.new('1.3.6.1.2.1.1.3.0'),
      input_frequency: SNMP::ObjectId.new('1.3.6.1.2.1.33.1.3.3.1.2.1'),
      input_voltage: SNMP::ObjectId.new('1.3.6.1.2.1.33.1.3.3.1.3.1'),
      seconds_on_battery: SNMP::ObjectId.new('1.3.6.1.2.1.33.1.2.2.0'),
      estimated_charge_remaining: SNMP::ObjectId.new('1.3.6.1.2.1.33.1.2.4.0'),
      battery_voltage: SNMP::ObjectId.new('1.3.6.1.2.1.33.1.2.5.0'),
      firmware_version: SNMP::ObjectId.new('1.3.6.1.2.1.33.1.1.4.0')
    }

    oid_map = oids.invert
    results = {}

    response = @manager.get(oids.values)
    response.each_varbind do |vb|
      key = oid_map[vb.name.to_oid]

      if vb.value.asn1_type == 'INTEGER'
        results[key] = vb.value.to_i
      elsif vb.value.asn1_type == 'TimeTicks'
        results[key] = vb.value.to_i / 100
      else
        results[key] = vb.value.to_s
      end
    end

    return results
  end

  def work!
    results = _get_data

    if false && results[:firmware_version] != @firmware_version
      system = {
        name: @sysName,
        platform: @sysDescr,
        build: @firmware_version,
        ip: @ip_address,
        mac_addr: nil
      }

      @device.publish! DDC_SYSTEM, system
    end

    results.delete(:firmware_version)

    if results
      if @options[:verbose]
        pp results
      end

#      @device.publish! DDC_UPS, results
    end

    sleep update_interval
  end

  def update_interval
    60
  end

  def name
    'Homebus Uninterruptible Power Supply publisher'
  end

  def publishes
    [ DDC_UPS, DDC_SYSTEM ]
  end

  def devices
    [
      { name: 'Uninterruptible Power Supply',
        identity: {
          manufacturer: @manufacturer,
          model: @model,
          serial_number: @serial_number
        }
      }
    ]
  end
end
