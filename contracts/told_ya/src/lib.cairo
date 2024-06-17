use starknet::{ContractAddress};

#[starknet::interface]
pub trait IToldYa<TContractState> {
    fn create_event(ref self: TContractState, name: ByteArray, predictionsDeadline: ByteArray, eventDatetime: ByteArray, type_: ByteArray) -> Event;
    fn create_prediction(ref self: TContractState, event_identifier: ByteArray, value: ByteArray) -> Prediction;
    fn get_events(self: @TContractState) -> Array<Event>;
    fn get_predictions(self: @TContractState) -> Array<Prediction>;
    fn get_user_predictions(self: @TContractState, user: ContractAddress) -> Array<Prediction>;
}

pub struct Event {
    identifier: ByteArray,
    name: ByteArray,
    predictionsDeadline: ByteArray,
    eventDatetime: ByteArray,
    type_: ByteArray,
}

pub struct Prediction {
    identifier: ByteArray,
    event_identifier: ByteArray,
    value: ByteArray,
    creator: ContractAddress,
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
