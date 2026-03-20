import Link from 'next/link';

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Nav */}
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
          <span className="text-xl font-bold text-indigo-600">
            TabletopConnect
          </span>
          <nav className="flex items-center gap-4">
            <Link
              href="/auth/login"
              className="text-sm font-medium text-gray-600 hover:text-gray-900"
            >
              Sign In
            </Link>
            <Link
              href="/auth/signup"
              className="text-sm font-medium bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md transition-colors"
            >
              Get Started
            </Link>
          </nav>
        </div>
      </header>

      {/* Hero */}
      <main className="flex-1 flex items-center justify-center px-4">
        <div className="max-w-2xl mx-auto text-center py-20">
          {/* Badge */}
          <span className="inline-block bg-indigo-100 text-indigo-700 text-sm font-medium px-3 py-1 rounded-full mb-6">
            🎲 Built for tabletop enthusiasts
          </span>

          {/* Headline */}
          <h1 className="text-5xl font-bold text-gray-900 mb-4 leading-tight">
            Find your perfect{' '}
            <span className="text-indigo-600">gaming group</span>
          </h1>

          {/* Subheadline */}
          <p className="text-xl text-gray-600 mb-10 max-w-lg mx-auto">
            TabletopConnect helps you discover local players, organize game
            sessions, and build lasting gaming communities — all in one place.
          </p>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/auth/signup"
              className="inline-flex items-center justify-center bg-indigo-600 hover:bg-indigo-700 text-white font-semibold px-8 py-3 rounded-lg text-base transition-colors shadow-sm"
            >
              Get Started — it&apos;s free
            </Link>
            <Link
              href="/auth/login"
              className="inline-flex items-center justify-center border-2 border-indigo-600 text-indigo-600 hover:bg-indigo-50 font-semibold px-8 py-3 rounded-lg text-base transition-colors"
            >
              Sign In
            </Link>
          </div>

          {/* Social proof / features */}
          <div className="mt-16 grid grid-cols-1 sm:grid-cols-3 gap-8 text-left">
            <div className="bg-white rounded-xl p-6 shadow-sm">
              <div className="text-2xl mb-2">🗺️</div>
              <h3 className="font-semibold text-gray-900 mb-1">
                Find Local Players
              </h3>
              <p className="text-sm text-gray-600">
                Browse players and groups near you, filtered by game, experience,
                and availability.
              </p>
            </div>
            <div className="bg-white rounded-xl p-6 shadow-sm">
              <div className="text-2xl mb-2">📅</div>
              <h3 className="font-semibold text-gray-900 mb-1">
                Organize Sessions
              </h3>
              <p className="text-sm text-gray-600">
                Create game events, manage RSVPs, and keep everyone on the same
                page.
              </p>
            </div>
            <div className="bg-white rounded-xl p-6 shadow-sm">
              <div className="text-2xl mb-2">💬</div>
              <h3 className="font-semibold text-gray-900 mb-1">
                Stay Connected
              </h3>
              <p className="text-sm text-gray-600">
                Message players, join group chats, and never miss a game night
                again.
              </p>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="py-6 text-center text-sm text-gray-500">
        © {new Date().getFullYear()} TabletopConnect. Roll for initiative.
      </footer>
    </div>
  );
}
