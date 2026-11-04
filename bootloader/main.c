#include <efi.h>
#include <efilib.h>

void ClearStdout(void) {
  uefi_call_wrapper(gST->ConOut->ClearScreen, 1, gST->ConOut);
}

void SetCursorPosition(UINTN Column, UINTN Row) {
  uefi_call_wrapper(gST->ConOut->SetCursorPosition, 3, gST->ConOut, Column, Row);
}

void Sleep(UINTN Miliseconds) {
  uefi_call_wrapper(gBS->Stall, 1, Miliseconds * 1000);
}

void HideCursor(void) {
  uefi_call_wrapper(gST->ConOut->EnableCursor, 2, gST->ConOut, FALSE);
}

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
  InitializeLib(ImageHandle, SystemTable);

  HideCursor();
  ClearStdout();

  while (TRUE) {
    __asm__ volatile ("hlt");
  }

  return EFI_SUCCESS;
}
