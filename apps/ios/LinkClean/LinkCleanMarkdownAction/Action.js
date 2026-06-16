var ExtensionPreprocessingJS = new Object();

ExtensionPreprocessingJS.run = function(arguments) {
    arguments.completionFunction({
        "pageTitle": document.title,
        "pageURL": document.URL
    });
};
