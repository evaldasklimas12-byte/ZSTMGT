codeunit 72401 "ZST Package Registry Mgt."
{

    procedure FillPackageRegistryFromAzureFile()
    var
        ZSTManagementSetup: Record "ZST Setup Management Setup";
        ZSTPackageRegistry: Record "ZST Setup Package";
        TempRegistry: Record "ZST Setup Package" temporary;
        TempBlobInfo: Record "ABS Container Content" temporary;
        ABSBlobClient: Codeunit "ABS Blob Client";
        AuthHelper: Codeunit "Storage Service Authorization";
        ZSTSecretMgt: Codeunit "ZST Secret Mgt.";
        ABSResponse: Codeunit "ABS Operation Response";
        TempBlob: Codeunit "Temp Blob";
        StorageServiceAuth: Interface "Storage Service Authorization";
        InS: InStream;
        OutS: OutStream;
        SecretKey: SecretText;
    begin
        if not ZSTManagementSetup.Get() then
            exit;

        if not ZSTSecretMgt.GetSASToken(SecretKey) then
            exit;
        StorageServiceAuth := AuthHelper.UseReadySAS(SecretKey);
        ABSBlobClient.Initialize(ZSTManagementSetup."Storage Account Name", ZSTManagementSetup."Container Name", StorageServiceAuth);
        ABSBlobClient.ListBlobs(TempBlobInfo);

        if TempBlobInfo.FindSet() then
            repeat
                if TempBlobInfo."Full Name".ToLower().EndsWith('.rapidstart') then begin
                    ABSResponse := ABSBlobClient.GetBlobAsStream(TempBlobInfo."Full Name", InS);

                    if ABSResponse.IsSuccessful() then begin
                        Clear(TempBlob);
                        TempBlob.CreateOutStream(OutS);
                        CopyStream(OutS, InS);

                        Clear(TempRegistry);
                        if GetPackageData(TempBlob, TempRegistry) then begin
                            ParseScenario(TempBlobInfo."Full Name", TempRegistry);

                            if not ZSTPackageRegistry.Get(TempRegistry.Code, TempRegistry.Scenario) then begin
                                ZSTPackageRegistry.Init();
                                ZSTPackageRegistry.Code := TempRegistry.Code;
                                ZSTPackageRegistry.Scenario := TempRegistry.Scenario;
                                ZSTPackageRegistry.Insert();
                            end;

                            ZSTPackageRegistry."Path" := TempBlobInfo."Full Name";
                            ZSTPackageRegistry."Processing Order" := TempRegistry."Processing Order";
                            ZSTPackageRegistry.Version := TempRegistry.Version;
                            ZSTPackageRegistry.Active := true;
                            ZSTPackageRegistry.Modify();
                        end;
                    end;
                end;
            until TempBlobInfo.Next() = 0;
    end;

    procedure GetPackageData(var TempBlob: Codeunit "Temp Blob"; var TempRegistry: Record "ZST Setup Package"): Boolean
    var
        DataCompression: Codeunit "Data Compression";
        DecompressedBlob: Codeunit "Temp Blob";
        XmlInS: InStream;
        GZipInS: InStream;
        DecompressedOutS: OutStream;
        PackageXml: XmlDocument;
        PackageNode: XmlNode;
    begin
        if not TempBlob.HasValue() then
            exit(false);

        TempBlob.CreateInStream(GZipInS);
        if not DataCompression.IsGZip(GZipInS) then
            exit(false);

        DecompressedBlob.CreateOutStream(DecompressedOutS);
        DataCompression.GZipDecompress(GZipInS, DecompressedOutS);

        DecompressedBlob.CreateInStream(XmlInS);
        if XmlDocument.ReadFrom(XmlInS, PackageXml) then
            if PackageXml.SelectSingleNode('/*/@Code', PackageNode) then begin
                TempRegistry.Code := CopyStr(PackageNode.AsXmlAttribute().Value(), 1, 20);

                if PackageXml.SelectSingleNode('/*/@ProductVersion', PackageNode) then
                    TempRegistry.Version := CopyStr(PackageNode.AsXmlAttribute().Value(), 1, 20);

                if PackageXml.SelectSingleNode('/*/@ProcessingOrder', PackageNode) then
                    Evaluate(TempRegistry."Processing Order", PackageNode.AsXmlAttribute().Value());

                exit(true);
            end;

        exit(false);
    end;

    procedure ParseScenario(FullName: Text; var Registry: Record "ZST Setup Package")
    var
        NameParts: List of [Text];
        CleanName: Text;
        ScenarioText: Text;
    begin
        CleanName := FullName.Replace('.rapidstart', '');
        NameParts := CleanName.Split('_');
        if NameParts.Count < 1 then
            exit;

        ScenarioText := NameParts.Get(1).ToLower();
        case ScenarioText of
            'demo':
                Registry.Scenario := Registry.Scenario::Demo;
            'new':
                Registry.Scenario := Registry.Scenario::New;
            'test':
                Registry.Scenario := Registry.Scenario::Test;
        end;
    end;
}
