FROM ruby:2.1-onbuild
EXPOSE ["8080"]
CMD ["./leaderboard.rb"]
