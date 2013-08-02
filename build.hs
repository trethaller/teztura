import System.Directory
import System.FilePath
import System.Process
import Text.Printf
    
compileCoffee = do
    putStrLn "Compile coffee scripts..."
    system "coffee -c -b js/app.coffee js/core.coffee js/tools.coffee js/test/test.coffee"

main = do
    -- compileTemplates
    compileCoffee
