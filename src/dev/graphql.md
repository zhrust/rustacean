# tokio


## background
> 无奈背景

## goal

上手用 tokio 完成实用微服务的开发和检验...

## trace

TBD

### prototype

> Q: 

在 rust 中如何构建一个简单的 graphQL 服务?

> A:

可以使用以下步骤来构建一个简单的 GraphQL 服务：

 1. 添加 juniper 和 hyper 依赖：

────────────────────

    [dependencies]
    juniper = "0.15.2"
    juniper_hyper = "0.16.1"
    hyper = "0.14.3"

────────────────────

 2. 定义一个 schema：

────────────────────
```rust
use juniper::{graphql_object, EmptyMutation, EmptySubscription, FieldResult, RootNode};

struct QueryRoot;

#[graphql_object]
impl QueryRoot {
    fn hello() -> FieldResult<String> {
        Ok("Hello, world!".to_string())
    }
}

type Schema = RootNode<'static, QueryRoot, EmptyMutation, EmptySubscription>;

```


在这个例子中，我们定义了一个 QueryRoot 类型，并添加了一个 hello 方法来返回一个字符串。

 3. 定义一个请求处理器：

────────────────────

```rust
use hyper::{Body, Request, Response, Server};
use juniper_hyper::{graphiql_handler, graphql_handler};

async fn handle_request(req: Request<Body>) -> Result<Response<Body>, hyper::Error> {
    match (req.method(), req.uri().path()) {
        (&hyper::Method::GET, "/graphql") => graphiql_handler("/graphql")(req).await,
        (&hyper::Method::POST, "/graphql") => graphql_handler(&Schema, &QueryRoot, req).await,
        _ => Ok(Response::builder()
            .status(hyper::StatusCode::NOT_FOUND)
            .body(Body::empty())
            .unwrap()),
    }
}

```


这个例子中使用了 hyper 库来处理请求。我们检查了请求的方法和路径，如果请求是 GET /graphql，我们会使用 graphiql_handler 函数返回 GraphQL IDE 页面；如果请求是 POST /graphql，我们 会使用 graphql_handler 函数来处理 GraphQL 查询。

 4. 启动服务器：

────────────────────
```rust

#[tokio::main]
async fn main() {
    let addr = ([127, 0, 0, 1], 8080).into();
    let server = Server::bind(&addr).serve(make_service_fn(|_conn| async {
        Ok::<_, hyper::Error>(service_fn(handle_request))
    }));

    println!("Listening on http://{}", addr);

    if let Err(e) = server.await {
        eprintln!("server error: {}", e);
    }
}

```


在这个例子中，我们使用 hyper 库来创建一个服务器，并把请求处理器传给服务器。在 main 函数中启动服务器，监听在 127.0.0.1:8080 上。

 5. 使用 GraphQL 查询：

现在你可以在 http://127.0.0.1:8080/graphql 上访问 GraphQL IDE 页面，输入以下查询：

────────────────────
    query {
    hello
    }
────────────────────

然后点击 "Play" 按钮发送查询。服务器会返回以下结果：

────────────────────
    {
    "data": {
        "hello": "Hello, world!"
    }
    }
────────────────────

这就是一个简单的 Rust GraphQL 服务的基本结构。你可以根据自己的需求添加更多的查询、变异和订阅。

## refer.
> 关键参考

[Tutorial | Tokio - An asynchronous Rust runtime](https://tokio.rs/tokio/tutorial)


- [介绍 - Tokio Internals](https://tony612.github.io/tokio-internals/01_intro_async.html)
- ...





```
        _~^|^~_
    \) /  ♡ ←  \ ()
      '_   ▽   _'
      / '--∽--' \

...act by ferris-actor v0.2.4 (built on 23.0303.201916)
```

