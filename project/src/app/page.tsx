import Link from 'next/link';

export default function Home() {
  return (
    <main>
      {/* Hero Section */}
      <section className="bg-indigo-700 text-white py-24 px-4 text-center">
        <div className="max-w-3xl mx-auto">
          <h1 className="text-4xl font-bold leading-tight sm:text-5xl">
            Connect with Tabletop Gamers Near You
          </h1>
          <p className="text-xl mt-4 text-indigo-100 max-w-xl mx-auto">
            Find local players, organize game sessions, and build your gaming community — all in one place.
          </p>
          <div className="mt-8 flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              href="/players"
              className="inline-block px-8 py-3 bg-white text-indigo-700 font-semibold rounded-xl hover:bg-indigo-50 transition-colors text-lg shadow-md"
            >
              Find Players
            </Link>
            <Link
              href="/auth/signup"
              className="inline-block px-8 py-3 border-2 border-white text-white font-semibold rounded-xl hover:bg-indigo-600 transition-colors text-lg"
            >
              Sign Up Free
            </Link>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 px-4 bg-gray-50">
        <div className="max-w-6xl mx-auto">
          <h2 className="text-3xl font-bold text-gray-900 text-center mb-4">
            Everything You Need to Play
          </h2>
          <p className="text-center text-gray-500 mb-12 max-w-xl mx-auto">
            TableTop Connect brings the gaming community together with powerful tools for discovery, organization, and communication.
          </p>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {/* Find Players */}
            <Link
              href="/players"
              className="group bg-white rounded-2xl shadow-md hover:shadow-lg transition-shadow p-8 flex flex-col items-center text-center"
            >
              <div className="w-16 h-16 bg-indigo-100 rounded-2xl flex items-center justify-center mb-4 group-hover:bg-indigo-200 transition-colors">
                <svg
                  className="w-8 h-8 text-indigo-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                  />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Find Players</h3>
              <p className="text-gray-500 text-sm">
                Search for local gamers by location, experience, favorite games, and availability. Connect with your perfect gaming partners.
              </p>
              <span className="mt-4 text-indigo-600 font-medium text-sm group-hover:underline">
                Browse players →
              </span>
            </Link>

            {/* Join Groups */}
            <Link
              href="/groups"
              className="group bg-white rounded-2xl shadow-md hover:shadow-lg transition-shadow p-8 flex flex-col items-center text-center"
            >
              <div className="w-16 h-16 bg-purple-100 rounded-2xl flex items-center justify-center mb-4 group-hover:bg-purple-200 transition-colors">
                <svg
                  className="w-8 h-8 text-purple-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
                  />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Join Groups</h3>
              <p className="text-gray-500 text-sm">
                Find and join local gaming groups. Organize recurring sessions, share game collections, and build your gaming circle.
              </p>
              <span className="mt-4 text-purple-600 font-medium text-sm group-hover:underline">
                Explore groups →
              </span>
            </Link>

            {/* Attend Events */}
            <Link
              href="/events"
              className="group bg-white rounded-2xl shadow-md hover:shadow-lg transition-shadow p-8 flex flex-col items-center text-center"
            >
              <div className="w-16 h-16 bg-green-100 rounded-2xl flex items-center justify-center mb-4 group-hover:bg-green-200 transition-colors">
                <svg
                  className="w-8 h-8 text-green-600"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Attend Events</h3>
              <p className="text-gray-500 text-sm">
                Discover local game nights, tournaments, and casual sessions. RSVP and manage your gaming calendar with ease.
              </p>
              <span className="mt-4 text-green-600 font-medium text-sm group-hover:underline">
                View events →
              </span>
            </Link>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="bg-white py-20 px-4 text-center">
        <div className="max-w-2xl mx-auto">
          <h2 className="text-3xl font-bold text-gray-900 mb-4">
            Ready to Find Your Next Game?
          </h2>
          <p className="text-gray-500 mb-8">
            Join thousands of tabletop enthusiasts already connecting through TableTop Connect.
          </p>
          <Link
            href="/players"
            className="inline-block px-10 py-4 bg-indigo-600 text-white font-semibold rounded-xl hover:bg-indigo-700 transition-colors text-lg shadow-md"
          >
            Find Players Near You
          </Link>
        </div>
      </section>
    </main>
  );
}
