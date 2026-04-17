codeunit 72402 "ZST Install Setup"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        ZSTSetupInitialization: Codeunit "ZST Setup Initialization";
    begin
        ZSTSetupInitialization.InitializeSetup();
    end;
    
}
