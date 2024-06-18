use starknet::ContractAddress;
use openzeppelin::access::ownable::OwnableComponent;
use core::hash::{Hash, HashStateTrait, HashStateExTrait};

#[starknet::interface]
pub trait IToldYa<TContractState> {
    fn create_event(ref self: TContractState, name: felt252, predictions_deadline: felt252, event_datetime: felt252, type_: felt252) -> Event_;
    // fn create_prediction(ref self: TContractState, event_identifier: ByteArray, value: ByteArray) -> Prediction;
    fn get_events(self: @TContractState) -> Array<Event_>;
    // fn get_predictions(self: @TContractState) -> Array<Prediction>;
    // fn get_user_predictions(self: @TContractState, user: ContractAddress) -> Array<Prediction>;
}

#[derive(Serde, Drop, Copy, starknet::Store)]
pub struct Event_ {
    identifier: felt252,
    name: felt252,
    predictions_deadline: felt252,
    event_datetime: felt252,
    type_: felt252,
}

#[derive(Serde, Drop, starknet::Store)]
pub struct Prediction {
    identifier: ByteArray,
    event_identifier: ByteArray,
    value: ByteArray,
    creator: ContractAddress,
}

#[starknet::contract]
mod Toldya {    

    use core::poseidon::PoseidonTrait;
    use core::hash::{Hash, HashStateTrait, HashStateExTrait};
    use super::Event_;
    use super::StoreFelt252Array;

    component!(path: super::OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = super::OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = super::OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        events: LegacyMap::<felt252, Event_>,
        events_id: Array<felt252>,
        #[substorage(v0)]
        ownable: super::OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: super::OwnableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_owner: super::ContractAddress){
        self.ownable.initializer(initial_owner);
    }

    #[abi(embed_v0)]
    impl ToldYaImpl of super::IToldYa<ContractState> {

        fn create_event(ref self: ContractState, name: felt252, predictions_deadline: felt252, event_datetime: felt252, type_: felt252) -> Event_ {
            // 1) Verifying caller is owner
            self.ownable.assert_only_owner();

            // 2) Hashing the new event
            let hash_state = PoseidonTrait::new();
            let hash_result: felt252 = hash_state.update(name).update(predictions_deadline).update(event_datetime).update(type_).finalize();            

            // 3) Creating the instance of the new event
            let new_event: Event_ = Event_ {
                identifier: hash_result, 
                name: name,
                predictions_deadline: predictions_deadline,
                event_datetime: event_datetime,
                type_: type_
            };

            // 4) Storing the new event in Storage
            self.events.write(new_event.identifier, new_event);

            // 5) Adding the id to events_id
            let mut events_id: Array<felt252> = self.events_id.read();
            events_id.append(new_event.identifier);
            self.events_id.write(events_id);

            //6) Returning the new event
            new_event
        }

        fn get_events(self: @ContractState) -> Array<Event_> {
            let mut events_id: Array<felt252> = self.events_id.read();
            let mut events = ArrayTrait::<Event_>::new();
            while !events_id.is_empty(){
                let event_id = events_id.pop_front().unwrap();
                let event = self.events.read(event_id);
                events.append(event);
            };
            events
        }
    }
}



// This block of code is used to store Array<felt252> in the Storage. 
// TODO: Move this block in another file and import it in this file.
impl StoreFelt252Array of starknet::Store<Array<felt252>> {
    fn read(address_domain: u32, base: starknet::storage_access::StorageBaseAddress) -> starknet::SyscallResult<Array<felt252>> {
        StoreFelt252Array::read_at_offset(address_domain, base, 0)
    }

    fn write(
        address_domain: u32, base: starknet::storage_access::StorageBaseAddress, value: Array<felt252>
    ) -> starknet::SyscallResult<()> {
        StoreFelt252Array::write_at_offset(address_domain, base, 0, value)
    }

    fn read_at_offset(
        address_domain: u32, base: starknet::storage_access::StorageBaseAddress, mut offset: u8
    ) -> starknet::SyscallResult<Array<felt252>> {
        let mut arr: Array<felt252> = array![];

        // Read the stored array's length. If the length is greater than 255, the read will fail.
        let len: u8 = starknet::Store::<u8>::read_at_offset(address_domain, base, offset)
            .expect('Storage Span too large');
        offset += 1;

        // Sequentially read all stored elements and append them to the array.
        let exit = len + offset;
        loop {
            if offset >= exit {
                break;
            }

            let value = starknet::Store::<felt252>::read_at_offset(address_domain, base, offset).unwrap();
            arr.append(value);
            offset += starknet::Store::<felt252>::size();
        };

        // Return the array.
        Result::Ok(arr)
    }

    fn write_at_offset(
        address_domain: u32, base: starknet::storage_access::StorageBaseAddress, mut offset: u8, mut value: Array<felt252>
    ) -> starknet::SyscallResult<()> {
        // Store the length of the array in the first storage slot.
        let len: u8 = value.len().try_into().expect('Storage - Span too large');
        starknet::Store::<u8>::write_at_offset(address_domain, base, offset, len).unwrap();
        offset += 1;

        // Store the array elements sequentially
        while let Option::Some(element) = value
            .pop_front() {
                starknet::Store::<felt252>::write_at_offset(address_domain, base, offset, element).unwrap();
                offset += starknet::Store::<felt252>::size();
            };

        Result::Ok(())
    }

    fn size() -> u8 {
        255 * starknet::Store::<felt252>::size()
    }
}
