module agent::registry;

use std::string::String;
use sui::clock::{timestamp_ms, Clock};
use sui::display;
use sui::event;
use sui::object_table;
use sui::package;

public struct Agent has key, store {
    id: UID,
    name: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    docker_image: String,
    docker_sha256: Option<String>,
    min_memory_gb: u16,
    min_cpu_cores: u16,
    supports_tee: bool,
    chains: vector<String>,
    created_at: u64,
    updated_at: u64,
    version: u64,
}

public struct AgentCreatedEvent has copy, drop {
    id: address,
    name: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    docker_image: String,
    docker_sha256: Option<String>,
    min_memory_gb: u16,
    min_cpu_cores: u16,
    supports_tee: bool,
    chains: vector<String>,
    created_at: u64,
}

public struct AgentUpdatedEvent has copy, drop {
    id: address,
    name: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    docker_image: String,
    docker_sha256: Option<String>,
    min_memory_gb: u16,
    min_cpu_cores: u16,
    supports_tee: bool,
    chains: vector<String>,
    updated_at: u64,
    version: u64,
}

public struct AgentDeletedEvent has copy, drop {
    id: address,
    name: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    docker_image: String,
    docker_sha256: Option<String>,
    min_memory_gb: u16,
    min_cpu_cores: u16,
    supports_tee: bool,
    chains: vector<String>,
    version: u64,
    deleted_at: u64,
}

public struct Developer has key, store {
    id: UID,
    name: String,
    github: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    agents: object_table::ObjectTable<String, Agent>,
    owner: address,
    created_at: u64,
    updated_at: u64,
    version: u64,
}

public struct DeveloperCreatedEvent has copy, drop {
    id: address,
    name: String,
    github: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    owner: address,
    created_at: u64,
}

public struct DeveloperUpdatedEvent has copy, drop {
    id: address,
    name: String,
    github: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    owner: address,
    updated_at: u64,
    version: u64,
}

public struct DeveloperDeletedEvent has copy, drop {
    id: address,
    name: String,
    github: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    version: u64,
    deleted_at: u64,
}

public struct DeveloperNames has key, store {
    id: UID,
    developer: address,
    names: vector<String>,
    version: u64,
}

public struct DeveloperNamesCreatedEvent has copy, drop {
    id: address,
    developer: address,
    names: vector<String>,
    version: u64,
}

public struct DeveloperNamesUpdatedEvent has copy, drop {
    id: address,
    developer: address,
    names: vector<String>,
    version: u64,
}

public struct AgentRegistry has key, store {
    id: UID,
    name: String,
    version: u32,
    admin: address,
    developers: object_table::ObjectTable<String, Developer>,
    developers_index: object_table::ObjectTable<address, DeveloperNames>,
}

public struct RegistryCreatedEvent has copy, drop {
    id: address,
    name: String,
    admin: address,
}

public struct REGISTRY has drop {}

fun init(otw: REGISTRY, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);

    let developer_keys = vector[
        b"name".to_string(),
        b"description".to_string(),
        b"image_url".to_string(),
        b"thumbnail_url".to_string(),
        b"link".to_string(),
        b"project_url".to_string(),
    ];

    let developer_values = vector[
        b"{name}".to_string(),
        b"{description}".to_string(),
        b"{image}".to_string(),
        b"{image}".to_string(),
        b"https://github.com/{github}".to_string(),
        b"{site}".to_string(),
    ];
    let mut display_developers = display::new_with_fields<Developer>(
        &publisher,
        developer_keys,
        developer_values,
        ctx,
    );

    let agent_keys = vector[
        b"name".to_string(),
        b"description".to_string(),
        b"image_url".to_string(),
        b"thumbnail_url".to_string(),
        b"project_url".to_string(),
    ];

    let agent_values = vector[
        b"{name}".to_string(),
        b"{description}".to_string(),
        b"{image}".to_string(),
        b"{image}".to_string(),
        b"{site}".to_string(),
    ];
    let mut display_agents = display::new_with_fields<Agent>(
        &publisher,
        agent_keys,
        agent_values,
        ctx,
    );

    let registry_keys = vector[
        b"name".to_string(),
        b"description".to_string(),
        b"image_url".to_string(),
        b"thumbnail_url".to_string(),
        b"project_url".to_string(),
    ];

    let registry_values = vector[
        b"{name}".to_string(),
        b"Registry for Silvana agents and developers".to_string(),
        b"https://silvana.one/_next/static/media/logo.b97230ea.svg".to_string(),
        b"https://silvana.one/_next/static/media/logo.b97230ea.svg".to_string(),
        b"https://silvana.one".to_string(),
    ];
    let mut display_registry = display::new_with_fields<Agent>(
        &publisher,
        registry_keys,
        registry_values,
        ctx,
    );

    display_developers.update_version();
    display_agents.update_version();
    display_registry.update_version();
    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display_developers, ctx.sender());
    transfer::public_transfer(display_agents, ctx.sender());
    transfer::public_transfer(display_registry, ctx.sender());
}

public fun create_registry(name: String, ctx: &mut TxContext) {
    let registry = AgentRegistry {
        id: object::new(ctx),
        name,
        version: 1,
        admin: ctx.sender(),
        developers: object_table::new(ctx),
        developers_index: object_table::new(ctx),
    };
    event::emit(RegistryCreatedEvent {
        id: registry.id.to_address(),
        name,
        admin: ctx.sender(),
    });
    transfer::share_object(registry);
}

public fun add_developer(
    registry: &mut AgentRegistry,
    name: String,
    github: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let developer_id = object::new(ctx);
    let address = developer_id.to_address();
    let timestamp = clock.timestamp_ms();
    let developer = Developer {
        id: developer_id,
        name,
        github,
        image,
        description,
        site,
        agents: object_table::new(ctx),
        owner: ctx.sender(),
        created_at: timestamp,
        updated_at: timestamp,
        version: 1,
    };
    event::emit(DeveloperCreatedEvent {
        id: address,
        name,
        github,
        image,
        description,
        site,
        owner: ctx.sender(),
        created_at: timestamp,
    });
    object_table::add(
        &mut registry.developers,
        name,
        developer,
    );
    if (object_table::contains(&registry.developers_index, ctx.sender())) {
        let developer_names = object_table::borrow_mut(
            &mut registry.developers_index,
            ctx.sender(),
        );
        vector::push_back(&mut developer_names.names, name);
        developer_names.version = developer_names.version + 1;
        event::emit(DeveloperNamesUpdatedEvent {
            id: developer_names.id.to_address(),
            developer: ctx.sender(),
            names: developer_names.names,
            version: developer_names.version,
        });
    } else {
        let developer_names = DeveloperNames {
            id: object::new(ctx),
            developer: ctx.sender(),
            names: vector[name],
            version: 1,
        };
        event::emit(DeveloperNamesCreatedEvent {
            id: developer_names.id.to_address(),
            developer: ctx.sender(),
            names: developer_names.names,
            version: developer_names.version,
        });
        object_table::add(
            &mut registry.developers_index,
            address,
            developer_names,
        );
    }
}

#[error]
const EInvalidOwner: vector<u8> = b"Invalid owner";

public fun update_developer(
    registry: &mut AgentRegistry,
    name: String,
    github: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let developer = object_table::borrow_mut(
        &mut registry.developers,
        name,
    );
    assert!(developer.owner == ctx.sender(), EInvalidOwner);
    developer.github = github;
    developer.image = image;
    developer.description = description;
    developer.site = site;
    developer.updated_at = clock.timestamp_ms();
    developer.version = developer.version + 1;

    event::emit(DeveloperUpdatedEvent {
        id: developer.id.to_address(),
        name,
        github,
        image,
        description,
        site,
        owner: ctx.sender(),
        updated_at: developer.updated_at,
        version: developer.version,
    });
}

#[error]
const ENotAdmin: vector<u8> = b"Not admin";

#[allow(unused_variable)]
public fun remove_developer(
    registry: &mut AgentRegistry,
    name: String,
    clock: &Clock,
    ctx: &mut TxContext,
): (Developer, Option<DeveloperNames>) {
    assert!(registry.admin == ctx.sender(), ENotAdmin);
    let developer = object_table::remove(&mut registry.developers, name);
    event::emit(DeveloperDeletedEvent {
        id: developer.owner,
        name,
        github: developer.github,
        image: developer.image,
        description: developer.description,
        site: developer.site,
        version: developer.version,
        deleted_at: clock.timestamp_ms(),
    });
    if (object_table::contains(&registry.developers_index, developer.owner)) {
        let developer_names = object_table::borrow_mut(
            &mut registry.developers_index,
            developer.owner,
        );
        let (found, index) = vector::index_of(&developer_names.names, &name);
        if (found) {
            vector::remove(&mut developer_names.names, index);
        };
        developer_names.version = developer_names.version + 1;
        event::emit(DeveloperNamesUpdatedEvent {
            id: developer_names.id.to_address(),
            developer: ctx.sender(),
            names: developer_names.names,
            version: developer_names.version,
        });
        if (vector::is_empty(&developer_names.names)) {
            let developer_names = object_table::remove(
                &mut registry.developers_index,
                developer.owner,
            );
            return (developer, option::some(developer_names))
        };
    };

    (developer, option::none())
}

public fun add_agent(
    registry: &mut AgentRegistry,
    developer: String,
    name: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    docker_image: String,
    docker_sha256: Option<String>,
    min_memory_gb: u16,
    min_cpu_cores: u16,
    supports_tee: bool,
    chains: vector<String>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let developer_object = object_table::borrow_mut(
        &mut registry.developers,
        developer,
    );
    assert!(developer_object.owner == ctx.sender(), EInvalidOwner);
    let agent_id = object::new(ctx);
    let address = agent_id.to_address();
    let timestamp = clock.timestamp_ms();
    let agent = Agent {
        id: agent_id,
        name,
        image,
        description,
        site,
        docker_image,
        docker_sha256,
        min_memory_gb,
        min_cpu_cores,
        supports_tee,
        chains,
        created_at: timestamp,
        updated_at: timestamp,
        version: 1,
    };
    event::emit(AgentCreatedEvent {
        id: address,
        name,
        image,
        description,
        site,
        docker_image,
        docker_sha256,
        min_memory_gb,
        min_cpu_cores,
        supports_tee,
        chains,
        created_at: timestamp,
    });
    object_table::add(&mut developer_object.agents, name, agent);
}

public fun update_agent(
    registry: &mut AgentRegistry,
    developer: String,
    name: String,
    image: Option<String>,
    description: Option<String>,
    site: Option<String>,
    docker_image: String,
    docker_sha256: Option<String>,
    min_memory_gb: u16,
    min_cpu_cores: u16,
    supports_tee: bool,
    chains: vector<String>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let developer_object = object_table::borrow_mut(
        &mut registry.developers,
        developer,
    );
    assert!(developer_object.owner == ctx.sender(), EInvalidOwner);
    let agent: &mut Agent = object_table::borrow_mut(
        &mut developer_object.agents,
        name,
    );
    let timestamp = clock.timestamp_ms();
    agent.image = image;
    agent.description = description;
    agent.site = site;
    agent.docker_image = docker_image;
    agent.docker_sha256 = docker_sha256;
    agent.min_memory_gb = min_memory_gb;
    agent.min_cpu_cores = min_cpu_cores;
    agent.supports_tee = supports_tee;
    agent.chains = chains;
    agent.updated_at = timestamp;
    agent.version = agent.version + 1;
    let address = agent.id.to_address();
    event::emit(AgentUpdatedEvent {
        id: address,
        name,
        image,
        description,
        site,
        docker_image,
        docker_sha256,
        min_memory_gb,
        min_cpu_cores,
        supports_tee,
        chains,
        updated_at: timestamp,
        version: agent.version,
    });
}

public fun remove_agent(
    registry: &mut AgentRegistry,
    developer: String,
    name: String,
    clock: &Clock,
    ctx: &mut TxContext,
): Agent {
    let developer_object = object_table::borrow_mut(
        &mut registry.developers,
        developer,
    );
    assert!(developer_object.owner == ctx.sender(), EInvalidOwner);
    let agent = object_table::borrow(
        &developer_object.agents,
        name,
    );
    let timestamp = clock.timestamp_ms();
    event::emit(AgentDeletedEvent {
        id: agent.id.to_address(),
        name,
        image: agent.image,
        description: agent.description,
        site: agent.site,
        docker_image: agent.docker_image,
        docker_sha256: agent.docker_sha256,
        min_memory_gb: agent.min_memory_gb,
        min_cpu_cores: agent.min_cpu_cores,
        supports_tee: agent.supports_tee,
        chains: agent.chains,
        version: agent.version,
        deleted_at: timestamp,
    });
    let agent = object_table::remove(
        &mut developer_object.agents,
        name,
    );
    agent
}

public fun get_agent(
    registry: &AgentRegistry,
    developer: String,
    agent: String,
): (&Developer, &Agent) {
    let developer_object = object_table::borrow(
        &registry.developers,
        developer,
    );
    (developer_object, object_table::borrow(&developer_object.agents, agent))
}
