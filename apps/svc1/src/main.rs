extern crate pretty_env_logger;

mod helpers;

use warp::{reject::Rejection, reply::Reply, Filter};

#[tokio::main(flavor = "current_thread")]
async fn main() {
    pretty_env_logger::init();

    let log = warp::log("wasi::api");

    let health = warp::path!("health")
        .and(warp::path::end())
        .and_then(health_handler)
        .with(log);
    let catch_404 = warp::any()
        .map(|| warp::reply::with_status("Not found", warp::http::StatusCode::NOT_FOUND))
        .with(log);
    
    let routes = health.or(catch_404);

    helpers::run(routes).await;
}

async fn health_handler() -> std::result::Result<impl Reply, Rejection> {
    Ok("Hello world!")
}
