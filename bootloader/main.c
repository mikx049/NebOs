#include <efi.h>
#include <efilib.h>

void ClearStdout(void) {
  uefi_call_wrapper(gST->ConOut->ClearScreen, 1, gST->ConOut);
}

void SetCursorPosition(UINTN Colom, UINTN Row) {
  uefi_call_wrapper(gST->ConOut->SetCursorPosition, 3, gST->ConOut, Colom, Row);
}

void Sleep(UINTN Miliseconds) {
  uefi_call_wrapper(gBS->Stall, 1, Miliseconds * 1000);
}

EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
  InitializeLib(ImageHandle, SystemTable);
  
  ClearStdout();

  CHAR16 *Sequence[] = {
    L"A ",
    L"AA",
    L"EE",
    L"A ",
    L"AE"
  };

  UINTN SequenceLength = sizeof(Sequence) / sizeof(Sequence[0]);

  while (TRUE) {
    for (UINTN i = 0; i < SequenceLength; i++) {
      SetCursorPosition(0, 0);

      Print(L"%s", Sequence[i]);

      Sleep(200);
    }
  }

  return EFI_SUCCESS;
}
