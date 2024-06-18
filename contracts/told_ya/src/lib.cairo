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
mod Toldya {

    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        balance: felt252
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_owner: ContractAddress){
        self.ownable.initializer(initial_owner);
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
