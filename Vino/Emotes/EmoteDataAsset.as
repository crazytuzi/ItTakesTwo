class UEmoteDataAsset : UDataAsset
{
    UPROPERTY()
    FText Name;

    UPROPERTY()
    FText Description;

    UPROPERTY()
    UTexture2D Icon;

    UPROPERTY(Category = "Animations")
    UAnimSequence MaysAnimation;

    UPROPERTY(Category = "Animations")
    UAnimSequence CodysAnimation;

    UPROPERTY()
    TSubclassOf<UHazeCapability> OptionalCapability;
}