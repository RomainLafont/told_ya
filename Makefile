PHONY: contract-full contract-artifacts declare-contract deploy-contract get-contract-class run-network

contract-full: \
	make contract-artifacts && \
	make declare-contract &&\
	make get-class &&\
	make deploy

contract-artifacts: \
	cd contracts/told_ya && \
	scarb build && \
	cd -

declare-contract: \
	starkli declare \
	--account katana \
	--rpc=$NETWORK_RPC_URL \
    --compiler-version=2.6.2 \
	target/dev/told_ya_ToldYa.contract_class.json

deploy-contract: \
	make get-class &&\
	starkli deploy \
	--account katana \
	--rpc $NETWORK_RPC_URL
	$CONTRACT_HASH_CLASS

get-contract-class: \
	CONTRACT_HASH_CLASS=$(starkli class-hash \
	contracts/told_ya/target/dev/told_ya_ToldYa.contract_class.json)

run-network: \
	katana
