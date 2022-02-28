class UDataAssetTiler : UDataAsset
{
    UPROPERTY()
    UTexture2D T1;

    UPROPERTY()
    UTexture2D T2;

    UPROPERTY()
    UTexture2D T3;

    UPROPERTY()
    float RoughnessOffset = 0.0;

	UPROPERTY()
    float Fuzz = 0;
	
	UPROPERTY()
    FLinearColor Subsurface = FLinearColor(0, 0, 0, 1);
}

