page 72405 "ZST Update SAS Token"
{
    PageType = StandardDialog;
    Caption = 'Update SAS Token';

    layout
    {
        area(Content)
        {
            field(SASTokenInput; SASTokenInput)
            {
                ApplicationArea = All;
                Caption = 'New Access Key / SAS Token';
                ExtendedDatatype = Masked;
                ToolTip = 'Enter the new Azure Shared Key or SAS token. The value will be stored securely and cannot be retrieved once saved.';
            }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ZSTSecretMgt: Codeunit "ZST Secret Mgt.";
        SecretToken: SecretText;
        EmptyTokenErr: Label 'Token cannot be empty.';
        TokenUpdatedMsg: Label 'SAS Token updated successfully.';
        TokenNotChangedMsg: Label 'SAS Token was not changed.';
    begin
        if CloseAction <> Action::OK then begin
            Message(TokenNotChangedMsg);
            exit(true);
        end;
        if SASTokenInput = '' then begin
            Message(EmptyTokenErr);
            exit(false);
        end;
        SecretToken := SASTokenInput;
        ZSTSecretMgt.SetSASToken(SecretToken);
        Message(TokenUpdatedMsg);
        exit(true);
    end;

    var
        SASTokenInput: Text;
}
