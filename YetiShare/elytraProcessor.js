var MyExtensionJavaScriptClass = function() {};

const ANDROID_PREFIX = "android-app:";

MyExtensionJavaScriptClass.prototype = {
    
    run: function(arguments) {
        
        const origin = window.location.origin;
        let result = [];
        
        if (origin.includes("medium.com")) {
            
            let elements = document.querySelectorAll("link[rel='alternate']");
            
            // we dont want the android universal links
            elements = [...elements].filter(i => i.href.includes(ANDROID_PREFIX) == false);
            
            if (elements.length == 0) {
                
                let authorLink = document.querySelectorAll("link[rel='author']");
                
                if (authorLink.length) {
                    authorLink = authorLink[0].href;
                    let url = new URL(authorLink);
                    
                    // format is provided here: https://help.medium.com/hc/en-us/articles/214874118-RSS-feeds
                    let required = `https://medium.com/feed${url.pathname}`;
                    
                    // now fetch the author's name
                    let authorName = document.querySelector(`meta[property="author"]`).content;
                    
                    result.push({
                                url: required,
                                title: authorName
                                });
                }
                
            }
            else {
                
                for (let elem of elements) {
                    
                    const url = new URL(elem.href, origin);
                    
                    result.push({
                                url: url.href,
                                title: elem.title || ""
                                });
                }
                
            }
            
        }
        else if (origin.includes("micro.blog")) {
            
            // documentation for feeds: http://help.micro.blog/2017/api-feeds/
            
            let title = document.title;
            let username = window.location.pathname.replace("/", "");
            let xmlFeed = `https://${username}.micro.blog/feed.xml`;
            let jsonFeed = `https://${username}.micro.blog/feed.json`;
            
            result.push({
                        title,
                        url: xmlFeed
                        });
            
            result.push({
                        title,
                        url: jsonFeed
                        });
            
        }
        else if (origin.includes("youtube.com")) {
            
            let {pathname} = window.location;
            
            if (pathname.includes("c/") == true || pathname.includes("u/") || pathname.includes("user/")) {
                
                let elements = document.querySelectorAll("link[rel='canonical']");
                
                for (let elem of elements) {
                    
                    const url = new URL(elem.href, origin);
                    
                    let title = elem.title || document.title || "";
                    
                    title = title.replace(" - YouTube", "");
                    
                    result.push({
                                url: url.href,
                                title
                                });
                }

                
            }
            else if (pathname.includes("channel/")) {
                
                let title = document.title || "";
                
                title = title.replace(" - YouTube", "");
                
                let url = window.location.href;
                
                result.push({
                    title,
                    url
                });
                
            }
            else {
                // non-supported youtube URL (inner or public pages).
            }
            
        }
        else {
            // standard processing
            
            let elements = document.querySelectorAll("link[rel='alternate']");
            
            for (let elem of elements) {
                const url = new URL(elem.href, origin);
                result.push({
                            url: url.href,
                            title: elem.title || ""
                            });
            }

        }
        
        // remove the comment feed since we dont support it
        result = result.filter(i => i.url.includes("/comment") == false);
        
        // remove android-app:// urls since, well, we're not on Android, YET!
        result = result.filter(i => i.url.includes(ANDROID_PREFIX) == false);

        // Pass the baseURI of the webpage to the extension.
        arguments.completionFunction({"baseURI": document.baseURI, "items": result});
    }
};

// The JavaScript file must contain a global object named "ExtensionPreprocessingJS".
var ExtensionPreprocessingJS = new MyExtensionJavaScriptClass;
