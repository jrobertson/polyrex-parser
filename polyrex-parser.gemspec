Gem::Specification.new do |s|
  s.name = 'polyrex-parser'
  s.version = '0.3.4'
  s.summary = 'polyrex-parser'
  s.authors = ['James Robertson']
  s.files = Dir['lib/**/*.rb']
  s.add_dependency('recordx-parser') 
  s.signing_key = '../privatekeys/polyrex-parser.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/polyrex-parser'
end
