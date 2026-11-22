#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <string>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Una sola copia de la app por sesión de Windows. Dos copias a la vez abrirían
// la misma base local (y la primera vez, la trasladarían a la vez).
constexpr const wchar_t kSingleInstanceMutex[] =
    L"Local\\com.baudity.baudex_desktop.single_instance";

std::wstring ExePathOf(DWORD process_id) {
  std::wstring path;
  HANDLE process =
      ::OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, process_id);
  if (process == nullptr) return path;
  wchar_t buffer[MAX_PATH * 2];
  DWORD size = static_cast<DWORD>(sizeof(buffer) / sizeof(buffer[0]));
  if (::QueryFullProcessImageNameW(process, 0, buffer, &size)) {
    path.assign(buffer, size);
  }
  ::CloseHandle(process);
  return path;
}

struct FindArgs {
  std::wstring exe_path;
  HWND found = nullptr;
};

BOOL CALLBACK FindOurWindow(HWND hwnd, LPARAM lparam) {
  auto* args = reinterpret_cast<FindArgs*>(lparam);
  wchar_t class_name[64];
  if (::GetClassNameW(hwnd, class_name, 64) == 0 ||
      std::wstring(class_name) != L"FLUTTER_RUNNER_WIN32_WINDOW") {
    return TRUE;
  }
  DWORD process_id = 0;
  ::GetWindowThreadProcessId(hwnd, &process_id);
  if (process_id == ::GetCurrentProcessId()) return TRUE;
  // La clase es la misma en toda app Flutter: se compara el ejecutable.
  if (_wcsicmp(ExePathOf(process_id).c_str(), args->exe_path.c_str()) != 0) {
    return TRUE;
  }
  args->found = hwnd;
  return FALSE;
}

// Trae al frente la ventana de la copia que ya está abierta.
void BringExistingToFront() {
  FindArgs args;
  args.exe_path = ExePathOf(::GetCurrentProcessId());
  if (args.exe_path.empty()) return;
  // La otra copia puede estar arrancando y aún sin ventana: se espera un poco.
  for (int i = 0; i < 20 && args.found == nullptr; i++) {
    ::EnumWindows(FindOurWindow, reinterpret_cast<LPARAM>(&args));
    if (args.found == nullptr) ::Sleep(250);
  }
  if (args.found == nullptr) return;
  if (::IsIconic(args.found)) ::ShowWindow(args.found, SW_RESTORE);
  ::SetForegroundWindow(args.found);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Si ya hay una copia abierta, se le pasa el foco y esta sale sin abrir
  // la base. El mutex lo libera Windows al cerrarse el proceso.
  HANDLE single_instance =
      ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutex);
  if (single_instance != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    BringExistingToFront();
    ::CloseHandle(single_instance);
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"baudex_desktop", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (single_instance != nullptr) {
    ::ReleaseMutex(single_instance);
    ::CloseHandle(single_instance);
  }
  return EXIT_SUCCESS;
}
