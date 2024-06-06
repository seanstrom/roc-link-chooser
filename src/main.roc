app [main] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br",
    rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.0.1/x_XwrgehcQI4KukXligrAkWTavqDAdE5jGamURpaX-M.tar.br",
}

import rand.Random
import pf.Stdout
import pf.Task
import pf.Arg
import pf.Path
import pf.File

chooseRandomLink = \items, randomSeed ->
    length = List.len items |> Num.toI32
    generator = Random.int 0 (length - 1)
    List.range { start: At 0, end: Before 10 }
    |> List.walk { seed: Random.seed randomSeed, indexes: [] } \state, _ ->
        random = generator state.seed
        seed = random.state
        indexes = List.append state.indexes random.value
        { seed, indexes }
    |> \stuff -> List.last stuff.indexes
    |> Result.map Num.toU64
    |> \index -> Result.withDefault index 0
    |> \index -> List.get items index

main =
    readArgsTask =
        cliArgs = Arg.list!
        args = List.dropFirst cliArgs 1
        fileNameArg = List.get args 0
        randomSeedArg = List.get args 1 |> Result.try Str.toU32

        when fileNameArg is
            Ok fileName ->
                File.readUtf8 (Path.fromStr fileName)
                |> Task.mapErr \_ -> ReadFileErr
                |> Task.await \fileContent ->
                    when randomSeedArg is
                        Ok randomSeed ->
                            Task.ok (randomSeed, fileContent)
                        Err _ ->
                            Task.err RandomSeedErr
            Err _ ->
                Task.err FileNameErr

    finalResult <- Task.attempt readArgsTask
    when finalResult is
        Err FileNameErr ->
            Task.err (Exit 1 "Sorry, I don't think I received a file name.")

        Err RandomSeedErr ->
            Task.err (Exit 1 "Sorry, I don't think I received a random seed.")

        Err ReadFileErr ->
            Task.err (Exit 1 "Sorry, I was not able to read the text file.")

        Ok (randomSeed, fileContent) ->
            fileContent
                |> Str.split "\n\n"
                |> List.map \item -> Str.split item "\n"
                |> List.map \pair -> List.last pair
                |> List.map \url -> Result.withDefault url "Oops"
                |> List.dropFirst 1
                |> chooseRandomLink randomSeed
                |> Result.withDefault "Ouch"
                |> Stdout.line!
