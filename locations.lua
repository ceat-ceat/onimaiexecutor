local BASE_URL = "https://raw.githubusercontent.com/ceat-ceat/onimaiexecutor/main"
local CLIENT_BASE = BASE_URL .. "/client"

return {
    Main = CLIENT_BASE .. "/main.lua",
    Modules = {
        AntideathedRemote = {
            Main = CLIENT_BASE .. "/AntideathedRemote/BindableEvent.lua",
            BindableEvent = CLIENT_BASE .. "AntideathedRemote/BindableEvent.lua"
        },
        Highligher = {
            Main = CLIENT_BASE .. "/Highlighter/main.lua",
            Lexer = CLIENT_BASE .. "Highlighter/lexer.lua",
            Language = CLIENT_BASE .. "Highlighter/language.lua",
        },
        EncryptedNetClient = {
            Main = "/EncryptedNetClient/main.lua",
            EllipticCurveCryptography = {
                Main = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/main.lua",
                Arith = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/modules/arith.lua",
                ChaCha20 = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/modules/chacha20.lua",
                Curve = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/modules/curve.lua",
                ModP = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/modules/modp.lua",
                ModQ = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/modules/modq.lua",
                Random = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/modules/random.lua",
                Sha256 = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/modules/sha256.lua",
                TwoPower = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/modules/twoPower.lua",
                Util = CLIENT_BASE .. "/EncryptedNetClient/EllipticCurveCryptography/modules/util.lua",
            }
        },
    }
    ClientAssets = "https://www.roblox.com/library/12910385605/",
    ServerModule = "https://www.roblox.com/library/12910374025/"
}