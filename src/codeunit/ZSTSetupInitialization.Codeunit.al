codeunit 72403 "ZST Setup Initialization"
{
    trigger OnRun()
    begin
        RunFullSetup();
    end;

    procedure InitializeSetup()
    var
        ZSTConfigMgtSetup: Record "ZST Setup Management Setup";
        ZSTSecretMgt: Codeunit "ZST Secret Mgt.";
        TokenText: Text;
        Token: SecretText;
    begin
        if not ZSTConfigMgtSetup.Get() then begin
            ZSTConfigMgtSetup.Init();
            ZSTConfigMgtSetup."Primary Key" := '';
            ZSTConfigMgtSetup."Storage Account Name" := 'hiperzeststorage';
            ZSTConfigMgtSetup."Container Name" := 'configuration';
            ZSTConfigMgtSetup.Insert();
        end;

        if not ZSTSecretMgt.HasSASToken() then begin
            TokenText := 'sv=2024-11-04&ss=bfqt&srt=sco&sp=rwdlacupiytfx&se=2027-01-21T22:31:23Z&st=2026-01-21T14:16:23Z&spr=https&sig=7%2FD1j6yUYdgct%2B8vliCk3tb4y2hkNoO1%2BuoYFYEKaI8%3D';
            Token := TokenText;
            ZSTSecretMgt.SetSASToken(Token);
        end;
    end;

    procedure RunFullSetup()
    var
        ZSTPackageRegistry: Record "ZST Setup Package";
        ZSTPackageRegistryMgt: Codeunit "ZST Package Registry Mgt.";
        ZSTImportMgt: Codeunit "ZST Import Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        ZSTSetupScenario: Enum "ZST Setup Scenario";
        PackageFilter: Text;
    begin
        InitializeSetup();

        case true of
            EnvironmentInfo.IsProduction():
                ZSTSetupScenario := ZSTSetupScenario::New;
            CompanyInformationMgt.IsDemoCompany():
                ZSTSetupScenario := ZSTSetupScenario::Demo;
            EnvironmentInfo.IsSandbox():
                ZSTSetupScenario := ZSTSetupScenario::Test;
        end;

        ZSTPackageRegistryMgt.FillPackageRegistryFromAzureFile();

        ZSTPackageRegistry.SetRange(Scenario, ZSTSetupScenario);
        ZSTPackageRegistry.SetRange(Active, true);
        if ZSTPackageRegistry.FindSet() then
            repeat
                ZSTImportMgt.ImportPackageFromRegistry(ZSTPackageRegistry);
                if PackageFilter <> '' then
                    PackageFilter += '|';
                PackageFilter += ZSTPackageRegistry.Code;
            until ZSTPackageRegistry.Next() = 0;

        ZSTImportMgt.ApplyPackagesFromFilter(PackageFilter);
    end;
}
