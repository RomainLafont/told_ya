use starknet::ContractAddress;
use openzeppelin::access::ownable::OwnableComponent;
use core::hash::{Hash, HashStateTrait, HashStateExTrait};

#[starknet::interface]
pub trait IToldYa<TContractState> {
    fn create_event(ref self: TContractState, name: felt252, predictions_deadline: felt252, event_datetime: felt252, type_: felt252) -> Event_;
    fn create_prediction(ref self: TContractState, event_identifier: felt252, value: felt252) -> Prediction;
    fn get_events(self: @TContractState) -> Array<Event_>;
    fn get_predictions(self: @TContractState) -> Array<Prediction>;
    fn get_user_predictions(self: @TContractState, user: ContractAddress) -> Array<Prediction>;
}

#[derive(Serde, Drop, Copy, starknet::Store)]
pub struct Event_ {
    pub identifier: felt252,
    pub name: felt252,
    pub predictions_deadline: felt252,
    pub event_datetime: felt252,
    pub type_: felt252,
}

#[derive(Serde, Drop, Copy, starknet::Store)]
pub struct Prediction {
    pub identifier: felt252,
    pub event_identifier: felt252,
    pub value: felt252,
    pub creator: ContractAddress,
}

#[starknet::contract]
mod ToldYa {    

    use core::poseidon::PoseidonTrait;
    use core::hash::{Hash, HashStateTrait, HashStateExTrait};
    use starknet::ContractAddress;
    use super::Event_;
    use super::Prediction;
    use super::StoreFelt252Array;

    component!(path: super::OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = super::OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = super::OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        events: LegacyMap::<felt252, Event_>,
        events_id: Array<felt252>,
        predictions: LegacyMap::<felt252, Prediction>,
        predictions_id: Array<felt252>,
        user_predictions_id: LegacyMap::<ContractAddress, Array<felt252>>,
        #[substorage(v0)]
        ownable: super::OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: super::OwnableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState){
        let caller_address = starknet::get_caller_address();
        self.ownable.initializer(caller_address);
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

        fn create_prediction(ref self: ContractState, event_identifier: felt252, value: felt252) -> Prediction {

            //TODO: [PERF] Use the storage var `events_id` to check if the event_identifier is valid.
            // 1) Checking if event_identifier is valid
            let mut events_id: Array<felt252> = self.events_id.read();
            let mut event_id_is_valid: bool = false;
            while !events_id.is_empty(){
                let event_id = events_id.pop_front().unwrap();
                if event_identifier == event_id {
                    event_id_is_valid = true;
                }
            };
            assert!(event_id_is_valid == true, "event_identifier is not valid.");

            // 2) Checking if the user has already made a prediction on the event
            let caller_address = starknet::get_caller_address();
            let mut user_predictions_id: Array<felt252> = self.user_predictions_id.read(caller_address);
            while !user_predictions_id.is_empty(){
                let user_prediction_id = user_predictions_id.pop_front().unwrap();
                let user_prediction = self.predictions.read(user_prediction_id);
                assert!(user_prediction.event_identifier != event_identifier, "A prediction has already been created with for this event." )
            };

            // 3) Hashing the new prediction
            let caller_address = starknet::get_caller_address();
            let hash_state = PoseidonTrait::new();
            let hash_result: felt252 = hash_state.update(event_identifier).update(value).update(caller_address.into()).finalize();    

            // 4) Creating the instance of the new prediction
            let new_prediction: Prediction = Prediction {
                identifier: hash_result, 
                event_identifier: event_identifier,
                value: value,
                creator: caller_address
            };

            // 5) Storing the new event in Storage
            self.predictions.write(new_prediction.identifier, new_prediction);  

            // 6) Adding the id to predictions_id
            let mut predictions_id: Array<felt252> = self.predictions_id.read();
            predictions_id.append(new_prediction.identifier);
            self.predictions_id.write(predictions_id);

            // 7) Adding the id to user_predictions_id
            let mut user_predictions_id: Array<felt252> = self.user_predictions_id.read(caller_address);
            user_predictions_id.append(new_prediction.identifier);
            self.user_predictions_id.write(caller_address, user_predictions_id);

            // 8) Returning the new event
            new_prediction
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

        fn get_predictions(self: @ContractState) -> Array<Prediction> {
            let mut predictions_id: Array<felt252> = self.predictions_id.read();
            let mut predictions = ArrayTrait::<Prediction>::new();
            while !predictions_id.is_empty(){
                let prediction_id = predictions_id.pop_front().unwrap();
                let prediction = self.predictions.read(prediction_id);
                predictions.append(prediction);
            };
            predictions
        }

        fn get_user_predictions(self: @ContractState, user: ContractAddress) -> Array<Prediction> {
            let caller_address = starknet::get_caller_address();
            let mut user_predictions_id: Array<felt252> = self.user_predictions_id.read(caller_address);
            let mut user_predictions = ArrayTrait::<Prediction>::new();
            while !user_predictions_id.is_empty(){
                let user_prediction_id = user_predictions_id.pop_front().unwrap();
                let user_prediction = self.predictions.read(user_prediction_id);
                user_predictions.append(user_prediction);
            };
            user_predictions
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
