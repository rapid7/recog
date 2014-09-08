module Recog
class Nizer

  # Default certainty ratings where none are specified in the fingerprint itself
  DEFAULT_OS_CERTAINTY      = 0.85      # Most frequent weights are 0.9, 1.0, and 0.5
  DEFAULT_SERVICE_CERTAINTY = 0.85      # Most frequent weight is 0.85

  # Non-weighted host attributes that can be extracted from fingerprint matches
  HOST_ATTRIBUTES = %W{
    host.domain
    host.id
    host.ip
    host.mac
    host.name
    host.time
    hw.device
    hw.family
    hw.product
    hw.vendor
  }

  @@db_manager = nil

  #
  # Locate a database that corresponds with the `match_key` and attempt to
  # find a matching {Fingerprint fingerprint}, stopping at the first hit. Returns `nil`
  # when no matching database or fingerprint is found.
  #
  # @param match_key [String] Fingerprint DB name, e.g. 'smb.native_os'
  # @return (see Fingerprint#match)
  def self.match(match_key, match_string)
    match_string = match_string.to_s.unpack("C*").pack("C*")
    @@db_manager ||= Recog::DBManager.new
    @@db_manager.databases.each do |db|
      next unless db.match_key == match_key
      db.fingerprints.each do |fprint|
        m = fprint.match(match_string)
        return m if m
      end
    end
    nil
  end

  #
  # Consider an array of match outputs, choose the best result, taking into
  # account the granularity of OS vs Version vs SP vs Language. Only consider
  # fields relevant to the host (OS, name, mac address, etc).
  #
  def self.best_os_match(matches)

    # The result hash we return to the caller
    result = {}

    # Certain attributes should be evaluated separately
    host_attrs  = {}

    # Bucket matches into matched OS product names
    os_products = {}

    matches.each do |m|
      # Count how many times each host attribute value is asserted
      (HOST_ATTRIBUTES & m.keys).each do |ha|
        host_attrs[ha]        ||= {}
        host_attrs[ha][m[ha]] ||= 0
        host_attrs[ha][m[ha]]  += 1
      end

      next unless m.has_key?('os.product')

      # Group matches by OS product and normalize certainty
      cm = m.dup
      cm['os.certainty'] = ( m['os.certainty'] || DEFAULT_OS_CERTAINTY ).to_f
      os_products[ cm['os.product'] ] ||= []
      os_products[ cm['os.product'] ]  << cm
    end

    #
    # Select the best host attribute value by highest frequency
    #
    host_attrs.keys.each do |hk|
      ranked_attr = host_attrs[hk].keys.sort do |a,b|
        host_attrs[hk][b] <=> host_attrs[hk][a]
      end
      result[hk] = ranked_attr.first
    end

    # Unable to guess the OS without OS matches
    unless os_products.keys.length > 0
      return result
    end

    #
    # Select the best operating system name by combined certainty of all
    # matches within an os.product group. Multiple weak matches can
    # outweigh a single strong match by design.
    #
    ranked_os = os_products.keys.sort do |a,b|
      os_products[b].map{ |r| r['os.certainty'] }.inject(:+) <=>
      os_products[a].map{ |r| r['os.certainty'] }.inject(:+)
    end

    # Within the best match group, try to fill in missing attributes
    os_name = ranked_os.first

    # Find the best match within the winning group
    ranked_os_matches = os_products[os_name].sort do |a,b|
      b['os.certainty'] <=> a['os.certainty']
    end

    # Fill in missing result values in descending order of best match
    ranked_os_matches.each do |rm|
      rm.each_pair do |k,v|
        result[k] ||= v
      end
    end

    result
  end

  #
  # Consider an array of match outputs, choose the best result, taking into
  # account the granularity of service. Only consider fields relevant to the
  # service.
  #
  def self.best_service_match(matches)

    # The result hash we return to the caller
    result = {}

    # Bucket matches into matched service product names
    service_products = {}

    matches.select{ |m| m.has_key?('service.product') }.each do |m|
      # Group matches by product and normalize certainty
      cm = m.dup
      cm['service.certainty'] = ( m['service.certainty'] || DEFAULT_SERVICE_CERTAINTY ).to_f
      service_products[ cm['service.product'] ] ||= []
      service_products[ cm['service.product'] ]  << cm
    end

    # Unable to guess the service without service matches
    unless service_products.keys.length > 0
      return result
    end

    #
    # Select the best service name by combined certainty of all matches
    # within an service.product group. Multiple weak matches can
    # outweigh a single strong match by design.
    #
    ranked_service = service_products.keys.sort do |a,b|
      service_products[b].map{ |r| r['service.certainty'] }.inject(:+) <=>
      service_products[a].map{ |r| r['service.certainty'] }.inject(:+)
    end

    # Within the best match group, try to fill in missing attributes
    service_name = ranked_service.first

    # Find the best match within the winning group
    ranked_service_matches = service_products[service_name].sort do |a,b|
      b['service.certainty'] <=> a['service.certainty']
    end

    # Fill in missing service values in descending order of best match
    ranked_service_matches.each do |rm|
      rm.keys.select{ |k| k.index('service.') == 0 }.each do |k|
        result[k] ||= rm[k]
      end
    end

    result
  end

end
end

=begin

Current key names:

  apache.info
  apache.variant
  apache.variant.version
  cookie
  host.domain
  host.id
  host.ip
  host.mac
  host.name
  host.time
  hw.device
  hw.family
  hw.product
  hw.vendor
  imail.eval
  jetty.info
  junction.cookie
  junction.name
  linux.kernel.version
  loadbalancer.poolname
  mdaemon.unregistered
  mercur.os.info
  metainfo.version
  metainfo.version.version
  ms.nttp.version
  notes.build.version
  notes.intl
  ntmail.id
  openssh.comment
  openssh.cvepatch
  os.arch
  os.build
  os.certainty
  os.device
  os.edition
  os.family
  os.product
  os.vendor
  os.version
  os.version.version
  os.version.version.version
  postfix.os.info
  postoffice.build
  postoffice.id
  proftpd.server.name
  pureftpd.config
  qpopper.version
  sendmail.config.version
  sendmail.hpux.phne.version
  sendmail.vendor.version
  service.certainty
  service.component.family
  service.component.product
  service.component.vendor
  service.component.version
  service.family
  service.product
  service.vendor
  service.version
  service.version.version
  service.version.version.version
  service.version.version.version.version
  service.version.version.version.version.version
  siemens.model
  snmp.fpmib.oid.1
  snmp.fpmib.oid.2
  system.time
  system.time.format
  system.time.micros
  system.time.millis
  thttpd.mx-patch
  timeout
  tomcat.info
  zmailer.ident

=end
