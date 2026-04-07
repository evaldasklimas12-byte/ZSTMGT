codeunit 72405 "ZST Secret Mgt."
{
    procedure SetSASToken(Token: SecretText)
    begin
        IsolatedStorage.Set('ZST_SASToken', Token, DataScope::Company);
    end;

    procedure GetSASToken(var Token: SecretText): Boolean
    begin
        if not IsolatedStorage.Contains('ZST_SASToken', DataScope::Company) then
            exit(false);
        IsolatedStorage.Get('ZST_SASToken', DataScope::Company, Token);
        exit(true);
    end;

    procedure HasSASToken(): Boolean
    begin
        exit(IsolatedStorage.Contains('ZST_SASToken', DataScope::Company));
    end;
}
