codeunit 72410 "ZST Setup API"
{
    [ServiceEnabled]
    procedure RunSetup()
    var
        ZSTSetupInitialization: Codeunit "ZST Setup Initialization";
    begin
        ZSTSetupInitialization.RunFullSetup();
    end;
}
