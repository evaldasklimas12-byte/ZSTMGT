codeunit 72400 "ZST Import Mgt."
{
    procedure ImportPackageFromRegistry(Registry: Record "ZST Setup Package"): Text
    var
        ZSTManagementSetup: Record "ZST Setup Management Setup";
        ConfigPackage: Record "Config. Package";
        TempConfigSetup: Record "Config. Setup" temporary;
        DataCompression: Codeunit "Data Compression";
        ABSBlobClient: Codeunit "ABS Blob Client";
        ABSResponse: Codeunit "ABS Operation Response";
        AuthHelper: Codeunit "Storage Service Authorization";
        TempBlob: Codeunit "Temp Blob";
        ConfigPackageImport: Codeunit "Config. Package - Import";
        ZSTSecretMgt: Codeunit "ZST Secret Mgt.";
        StorageServiceAuth: Interface "Storage Service Authorization";
        InS: InStream;
        OutS: OutStream;
        SecretKey: SecretText;
        SetupErr: Label 'ERROR: Setup table not initialized';
        SecretNotSetErr: Label 'ERROR: Access Key / SAS Token not configured';
        SkipMsg: Label 'SKIP: %1 (Already installed)', Comment = '%1 = Configuration Package Code';
        DownloadErr: Label 'ERROR: %1 (Download failed)', Comment = '%1 = Configuration Package Code';
        FormatErr: Label 'ERROR: %1 (Not a valid RapidStart/GZip file)', Comment = '%1 = Configuration Package Code';
        SuccessMsg: Label 'SUCCESS: %1', Comment = '%1 = Configuration Package Code';
    begin
        if not ZSTManagementSetup.Get() then
            exit(SetupErr);

        if ConfigPackage.Get(Registry.Code) then
            exit(StrSubstNo(SkipMsg, Registry.Code));

        if not ZSTSecretMgt.GetSASToken(SecretKey) then
            exit(SecretNotSetErr);

        StorageServiceAuth := AuthHelper.UseReadySAS(SecretKey);
        ABSBlobClient.Initialize(ZSTManagementSetup."Storage Account Name", ZSTManagementSetup."Container Name", StorageServiceAuth);

        ABSResponse := ABSBlobClient.GetBlobAsStream(Registry."Path", InS);
        if not ABSResponse.IsSuccessful() then
            exit(StrSubstNo(DownloadErr, Registry.Code));

        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, InS);

        TempBlob.CreateInStream(InS);
        if not DataCompression.IsGZip(InS) then
            exit(StrSubstNo(FormatErr, Registry.Code));

        ConfigPackageImport.ImportRapidStartPackageStream(TempBlob, TempConfigSetup);

        exit(StrSubstNo(SuccessMsg, Registry.Code));
    end;

    procedure GetSuccessPrefix(): Text
    var
        SuccessMsg: Label 'SUCCESS: ', Locked = true;
    begin
        exit(SuccessMsg);
    end;

    procedure ApplyPackagesFromFilter(PackageFilter: Text): Text
    var
        ConfigPackage: Record "Config. Package";
        Results: Text;
    begin
        if PackageFilter = '' then
            exit('');

        ConfigPackage.SetFilter(Code, PackageFilter);
        if ConfigPackage.FindSet() then
            repeat
                Results += ApplyPackageData(ConfigPackage.Code) + '\';
            until ConfigPackage.Next() = 0;

        exit(Results);
    end;

    procedure ApplyPackageData(PackageCode: Code[20]): Text
    var
        ConfigPackage: Record "Config. Package";
        SuccessMsg: Label 'APPLIED: %1', Locked = true;
        ErrorMsg: Label 'FAILED: %1 (%2)', Locked = true;
        AlreadyAppliedMsg: Label 'SKIPPED: %1 (Already applied during review)', Locked = true;
        PackageNotFoundLbl: Label 'Package not found';
    begin
        if not ConfigPackage.Get(PackageCode) then
            exit(StrSubstNo(ErrorMsg, PackageCode, PackageNotFoundLbl));

        if ConfigPackage."Apply Status" = ConfigPackage."Apply Status"::Completed then
            exit(StrSubstNo(AlreadyAppliedMsg, PackageCode));

        TryApplyPackage(PackageCode);

        exit(StrSubstNo(SuccessMsg, PackageCode));
    end;

    local procedure TryApplyPackage(PackageCode: Code[20])
    var
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageMgt: Codeunit "Config. Package Management";
    begin
        ConfigPackage.Get(PackageCode);
        ConfigPackageTable.SetRange("Package Code", PackageCode);
        if ConfigPackageTable.FindSet() then
            repeat
                ConfigPackageMgt.ApplyPackage(ConfigPackage, ConfigPackageTable, true);
            until ConfigPackageTable.Next() = 0;
    end;

    
}
