import { redirect } from 'next/navigation';
import { createServerClient } from '@/lib/supabase/server';

export default async function DashboardPage() {
  const supabase = createServerClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect('/auth/login');
  }

  const displayName =
    user.user_metadata?.display_name || user.email || 'Adventurer';

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
          <h1 className="text-xl font-bold text-indigo-600">TabletopConnect</h1>
          <form action="/auth/logout" method="POST">
            <button
              type="submit"
              className="text-sm text-gray-600 hover:text-gray-900 font-medium px-4 py-2 rounded-md border border-gray-300 hover:bg-gray-50 transition-colors"
            >
              Sign Out
            </button>
          </form>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="bg-white rounded-xl shadow-sm p-8">
          <div className="mb-6">
            <h2 className="text-2xl font-bold text-gray-900 mb-2">
              Welcome back, {displayName}! 🎲
            </h2>
            <p className="text-gray-600">
              Signed in as{' '}
              <span className="font-medium text-gray-800">{user.email}</span>
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-8">
            <div className="bg-indigo-50 rounded-lg p-6">
              <h3 className="font-semibold text-indigo-900 mb-2">
                🗺️ Find Players
              </h3>
              <p className="text-sm text-indigo-700">
                Discover local tabletop enthusiasts near you.
              </p>
            </div>
            <div className="bg-purple-50 rounded-lg p-6">
              <h3 className="font-semibold text-purple-900 mb-2">
                🎯 Join Groups
              </h3>
              <p className="text-sm text-purple-700">
                Connect with gaming groups that match your style.
              </p>
            </div>
            <div className="bg-green-50 rounded-lg p-6">
              <h3 className="font-semibold text-green-900 mb-2">
                📅 Schedule Games
              </h3>
              <p className="text-sm text-green-700">
                Organize and join game sessions in your area.
              </p>
            </div>
          </div>

          <p className="mt-8 text-sm text-gray-500 text-center">
            More features coming soon. Your adventure is just beginning!
          </p>
        </div>
      </main>
    </div>
  );
}
