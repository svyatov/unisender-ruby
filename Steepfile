# frozen_string_literal: true

target :unisender do
  check "lib"
  signature "sig"

  library "net-http", "json", "uri", "openssl", "time"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.strict)
end

target :consumer do
  check "test/consumer", "examples"
  signature "sig"
  signature "test/consumer"

  library "net-http", "json", "uri", "openssl", "time"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.strict)
end
