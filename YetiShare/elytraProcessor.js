var MyExtensionJavaScriptClass = function() {};

MyExtensionJavaScriptClass.prototype = {
    run: function(arguments) {
        const origin = window.location.origin;
        let result = [];
        const elements = document.querySelectorAll("link[rel='alternate']");

        for (let elem of elements) {
            const url = new URL(elem.href, origin);
            result.push({
                url: url.href,
                title: elem.title || ""
            });
        }

        result = result.filter(i => i.url.includes("/comment") == false);

        // Pass the baseURI of the webpage to the extension.
        arguments.completionFunction({"baseURI": document.baseURI, "items": result});
    }
};

// The JavaScript file must contain a global object named "ExtensionPreprocessingJS".
var ExtensionPreprocessingJS = new MyExtensionJavaScriptClass;
