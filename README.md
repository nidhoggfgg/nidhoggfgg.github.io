this is just my blog :)

I use the [moefox](https://github.com/nidhoggfgg/hugo-moefox) theme, which requires a very high version of hugo.  
It can't work with the hugo in the default Ubuntu/Debain repository.  
so, I use docker to run the hugo.

just use `docker-compose up`, it will act same as normal `hugo server --buildDrafts`.

NOTE: `docker-compose up` will build the image first, and it will pull the hugo from github.
if building the image fail just beacause the network, try `docker-compose build --build-arg "https_proxy=https://<your_proxy_ip>:<your_proxy_port>"` then `docker-compose up`

btw, I'm not provide a way to run `hugo build`. It is useless. The build, publish and binding domain are all automate.  
Github Action -> Vercel -> [blog.nidhoggfgg.fun](blog.nidhoggfgg.fun)

and there is no "public" in *main* branch, all the build output is in the *gh-page* branch
