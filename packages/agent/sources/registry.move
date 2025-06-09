module agent::registry;

use std::string::String;
use sui::clock::{timestamp_ms, Clock};
use sui::display;
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
    created_at: u64,
    updated_at: u64,
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
}

public struct AgentRegistry has key, store {
    id: UID,
    name: String,
    version: u32,
    admin: address,
    developers: object_table::ObjectTable<String, Developer>,
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
    };
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
    };
    object_table::add(
        &mut registry.developers,
        name,
        developer,
    );
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
}

#[error]
const ENotAdmin: vector<u8> = b"Not admin";

#[allow(unused_variable)]
public fun remove_developer(
    registry: &mut AgentRegistry,
    name: String,
    ctx: &mut TxContext,
): Developer {
    assert!(registry.admin == ctx.sender(), ENotAdmin);
    let developer = object_table::remove(&mut registry.developers, name);
    developer
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
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let developer_object = object_table::borrow_mut(
        &mut registry.developers,
        developer,
    );
    assert!(developer_object.owner == ctx.sender(), EInvalidOwner);
    let agent_id = object::new(ctx);
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
        created_at: timestamp,
        updated_at: timestamp,
    };

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
    agent.updated_at = timestamp;
}

public fun remove_agent(
    registry: &mut AgentRegistry,
    developer: String,
    name: String,
    ctx: &mut TxContext,
): Agent {
    let developer_object = object_table::borrow_mut(
        &mut registry.developers,
        developer,
    );
    assert!(developer_object.owner == ctx.sender(), EInvalidOwner);
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
