PHONY: under-setup--asdf under-setup--katana setup-unix contract-full contract-artifacts declare-contract deploy-contract get-contract-class run-network

# config-account: \
# 	starkli account fetch \
# 	$ACCOUNT \
# 	--rpc $NETWORK_RPC_URL \
# 	--output ~/.starkli-wallets/devnet/deployer/account.json

SHELL=/bin/bash

setup-unix:
	make under-setup--asdf && \
	make under-setup--katana

under-setup--asdf:
	git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0 && \
	echo '. "$HOME/.asdf/asdf.sh" >> .bashrc && \
	source .bashrc && \
	asdf plugin add scarb && \
	asdf install scarb 2.6.3 && \
	asdf global scarb 2.6.3 &&

under-setup--katana:
	asdf plugin add dojo https://github.com/dojoengine/asdf-dojo && \
	asdf install dojo 0.7.2 && \
	asdf global dojo 0.7.2

contract-full:
	make contract-artifacts && \
	make declare-contract &&\
	make get-class &&\
	make deploy

contract-artifacts:
	cd contracts/told_ya && \
	scarb build && \
	cd -

declare-contract:
	starkli declare \
	--account katana \
	--rpc=$NETWORK_RPC_URL \
	--compiler-version=2.6.2 \
	target/dev/told_ya_ToldYa.contract_class.json

deploy-contract:
	make get-class &&\
	starkli deploy \
	--account katana \
	--rpc $NETWORK_RPC_URL
	$CONTRACT_HASH_CLASS

get-contract-class:
	CONTRACT_HASH_CLASS=$(starkli class-hash \
	contracts/told_ya/target/dev/told_ya_ToldYa.contract_class.json)

run-network: \
	katana
