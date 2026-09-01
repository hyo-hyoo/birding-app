namespace :maintenance do
  desc "Delete expired sessions and retained email-verification records"
  task cleanup: :environment do
    result = MaintenanceCleanup.call
    puts "Cleanup complete: sessions=#{result.sessions}, tokens=#{result.tokens}, attempts=#{result.attempts}, keys=#{result.keys}"
  end
end
