export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <div className="z-10 max-w-5xl w-full items-center justify-between font-mono text-sm">
        <h1 className="text-4xl font-bold text-center mb-8">
          Flight Delay Insurance Protocol
        </h1>
        <p className="text-center text-lg mb-8">
          Decentralized flight delay insurance powered by blockchain technology
        </p>
        <div className="text-center">
          <p className="mb-4">
            Get 200 USDC payout for just 50 USDC premium when your flight is delayed 6+ hours
          </p>
          <div className="space-x-4">
            <button className="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
              Buy Insurance
            </button>
            <button className="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
              Invest
            </button>
          </div>
        </div>
      </div>
    </main>
  )
} 