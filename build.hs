import System.Directory
import System.FilePath
import System.Process
-- import qualified Data.Text.IO as IO
import Text.Printf


type Template = (String, String)

getTemplate :: FilePath -> IO Template
getTemplate path = do 
    txt <- readFile path
    return (takeFileName . dropExtension $ path, txt)

getTemplates :: IO [Template]
getTemplates = do
    files <- getDirectoryContents "templates"
    let tplFiles = ["templates\\" ++ f | f <- files, takeExtension f == ".htm"]
    mapM getTemplate tplFiles

getTemplatesMarkup :: Template -> String
getTemplatesMarkup (tplId, tplData) = printf "<script type=\"text/x-handlebars\" data-template-name=\"%s\">%s</script>\n" tplId tplData


getJSFiles :: IO [String]
getJSFiles = do
    files <- getDirectoryContents "js"
    return ["js\\" ++ f | f <- files, takeExtension f == ".js"]

getJSMarkup :: String -> String
getJSMarkup = printf "<script src=\"%s\"></script>"

---

compileTemplates = do
    putStrLn "Compile templates..."
    tpls <- getTemplates
    
    index <- readFile "index_tpl.html"

    let templatesMarkup = unlines $ map getTemplatesMarkup tpls
    writeFile "index.html" $ printf index templatesMarkup
    
compileCoffee = do
    putStrLn "Compile coffee scripts..."
    system "coffee js/core.coffee js/brushes.coffee js/main.coffee js/test/test.coffee"

main = do
    compileTemplates
    compileCoffee
