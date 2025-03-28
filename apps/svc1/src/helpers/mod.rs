use std::net::SocketAddr;

use warp::{reply::Reply, Filter};
use tokio::{io::AsyncWriteExt, net::TcpListener, sync::oneshot};

pub async fn run<F>(filter: F)
where
    F: Filter + Clone + Send + Sync + 'static,
    F::Extract: Reply,
{    
    let (tx, rx) = oneshot::channel();
    
    let (_addr, server) = warp::serve(filter)
        .bind_with_graceful_shutdown(SocketAddr::from(([0, 0, 0, 0], 8080)), async {
             rx.await.ok();
        });
    
    // Spawn the server into a runtime
    tokio::spawn(server);
    
    println!("Listening on http://{}", _addr);

    shutdown_signal().await;

    println!("stopping...");

    // Later, start the shutdown...
    let _ = tx.send(());
}

async fn shutdown_signal() {
    let addr = SocketAddr::from(([0, 0, 0, 0], 8081));
    let listener = match TcpListener::bind(addr).await {
        Ok(listener) => listener,
        Err(err) => {
            println!("Failed to bind kill signal listener: {:?}", err);
            return;
        }
    };

    println!("Listening for kill signal on http://{}", addr);

    let mut stream = match listener.accept().await {
        Ok((stream, _)) => stream,
        Err(err) => {
            println!("Failed to respond to kill signal: {:?}", err);
            return;
        }
    };

    // Respond to the HTTP get request with a 200 response and break out of the loop
    let response = "Shutting down";
    let response = format!(
        "HTTP/1.1 200 OK\r\nContent-Length: {}\r\n\r\n{}",
        response.len(),
        response
    );

    if let Err(err) = stream.write_all(response.as_bytes()).await {
        println!("Failed to response to kill signal response: {:?}", err);
    }
}
