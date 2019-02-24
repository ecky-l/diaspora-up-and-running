#!/bin/bash
curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -

curl -L https://s.diaspora.software/1t | bash

source /var/local/diaspora/.rvm/scripts/rvm
rvm autolibs read-fail
rvm install 2.4

git clone -b master https://github.com/diaspora/diaspora.git /var/local/diaspora/diaspora

cd /var/local/diaspora/diaspora
VERSION=$(git tag | tail -n1)
if [[ -n "${git_tag+set}" ]]; then
	VERSION=${git_tag}
fi
git checkout ${VERSION}

cp -f /var/local/diaspora/script/server /var/local/diaspora/diaspora/script/

# create the tar archive before we create our configs
tar -czf source.tar.gz *
mv source.tar.gz /var/local/diaspora/diaspora/public/

# copy our changes
cp -f /var/local/diaspora/config/{diaspora.yml,database.yml,routes.rb} /var/local/diaspora/diaspora/config/

gem install bundler
/var/local/diaspora/diaspora/script/configure_bundler
/var/local/diaspora/diaspora/bin/bundle install --full-index

if [[ -n "${create_database+set}" && ${create_database} = 1 ]]; then
	RAILS_ENV=production /var/local/diaspora/diaspora/bin/rake db:create
fi

RAILS_ENV=production /var/local/diaspora/diaspora/bin/rake db:migrate
RAILS_ENV=production /var/local/diaspora/diaspora/bin/rake assets:precompile

cd /var/local/diaspora
rm -rf /var/local/diaspora/diaspora/.git
tar -cvz --preserve-permissions --same-owner -f diaspora-${VERSION}.tar.gz \
	.bashrc .bash_profile .bundle .gem .gnupg .mkshrc .pki .profile .rvm diaspora
rm -rf /var/local/diaspora/{diaspora,.bash_profile,.bashrc,.bundle,.gem,.gnupg,.mkshrc,.pki,.profile,.rvm,.zlogin,.zshrc}
