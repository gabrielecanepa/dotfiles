require "io/console"
require "json"
require "open-uri"

begin
  require "colored"
  require "octokit"
rescue LoadError
  puts "Could not find all needed gems. Please run `bundle install` and retry"
  exit
end

MINIMUM_AVATAR_SIZE = 2 * 1024
GITHUB_AUTHORIZATION_NOTE = 'Setup check'.freeze

$all_good = true

def check(label, &block)
  puts "Checking #{label}..."
  result, message = yield
  $all_good = $all_good && result
  puts result ? "[OK] #{message}".green : "[KO] #{message}".red
end

def check_all
  check("shell") do
    if ENV["SHELL"].match(/zsh/)
      [ true, "Your default shell is zsh"]
    else
      [ false, "Your default shell is #{ENV["SHELL"]}, but should be zsh"]
    end
  end
  check("GitHub setup") do
    begin
      groups = `ssh -T git@github.com 2>&1`.match(/Hi (?<nickname>.*)! You've successfully authenticated/)
      git_email = (`git config --global user.email`).chomp
      nickname = groups["nickname"]

      client = Octokit::Client.new
      client.login = nickname
      puts "Please type in your GitHub password (login: '#{nickname}'):"
      print "> "
      client.password = STDIN.noecho { |stdin| stdin.gets.chomp }
      puts "\nThanks. Asking some infos to GitHub..."
      # TODO(ssaunier): https://github.com/octokit/octokit.rb#two-factor-authentication

      authorization =
        client.authorizations.find { |a| a[:note] == GITHUB_AUTHORIZATION_NOTE } ||
        client.create_authorization(
          scopes: ["user:email"],
          note: GITHUB_AUTHORIZATION_NOTE)
      client.access_token = authorization["token"]

      avatar_url = client.user[:avatar_url]
      emails = client.emails.map { |email| email[:email] }
      client.delete_authorization(authorization[:id])

      if emails.include?(git_email)
        content_length = `curl -s -I #{avatar_url} | grep 'Content-Length:'`.strip.gsub("Content-Length: ", "").to_i
        if content_length >= MINIMUM_AVATAR_SIZE
          [ true, "GitHub email config is OK. And you have a profile picture 📸"]
        else
          [ false, "You don't have any profile picture set.\nIt's important, go to github.com/settings/profile and upload a picture right now."]
        end
      else
        [ false,
          "Your git email is '#{git_email}' and is not listed in https://github.com/settings/emails\n" +
          "Run `git config --global user.email george@abitbol.com` to set your git email address. With your own!"]
      end
    rescue Octokit::Unauthorized => e
      puts "Wrong GitHub password, please try again 🙏     Details: #{e.message}"
      exit 1
    end
  end
  check("git editor setup") do
    editor = `git config --global core.editor`
    if editor.match(/atom/i)
      [ true, "Atom is your default git editor"]
    else
      [ false, "Check your ~/.gitconfig editor setup. Right now, it's `#{editor.chomp}`"]
    end
  end
  check("ruby gems") do
    if (`which rspec`) != "" && (`which rubocop`) != ""
      [ true, "Everything's fine"]
    else
      [ false, "Rspec and Rubocop gems aren't there. Did you run the `gem install ...` command?"]
    end
  end
end

def outro
  if $all_good
    puts ""
    puts "🚀  Awesome! Everything is setup correctly.".green
  else
    puts ""
    puts "😥  Bummer! Something's wrong.".red
  end
end

check_all
outro
