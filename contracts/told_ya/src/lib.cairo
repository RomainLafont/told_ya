use starknet::{ContractAddress};

#[starknet::interface]
pub trait IToldYa<TContractState> {
    fn create_event(ref self: TContractState, name: ByteArray, deadline: ByteArray, tags: Array<ByteArray>) -> ByteArray;
    fn create_prediction(ref self: TContractState, event_id: ByteArray, value: Felt252Dict<ByteArray>) -> ByteArray;
    fn get_past_user_predictions(self: @TContractState, user_address: ContractAddress) -> Span<Prediction>;
    fn get_future_user_predictions(self: @TContractState, user_address: ContractAddress) -> Span<Prediction>;
    fn get_future_events(self: @TContractState) -> Span<RealEvent>;
}

#[starknet::contract]
mod HelloStarknet {
    #[storage]
    struct Storage {
        balance: felt252,
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert(amount != 0, 'Amount cannot be 0');
            self.balance.write(self.balance.read() + amount);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            self.balance.read()
        }
    }
}
