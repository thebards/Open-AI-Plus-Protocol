// Needed for truffle flattener
module.exports = {
    contracts_directory: "./contracts",
    compilers: {
        solc: {
            version: '0.8.12',
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200,
                },
            },
        },
    },
    plugins: ["truffle-contract-size"]
}