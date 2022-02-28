import Vino.Emotes.EmoteDataAsset;

class UEmoteComponent : UActorComponent
{
    UPROPERTY()
    TArray<UEmoteDataAsset> Emotes;

    UFUNCTION()
    void AddEmote(UEmoteDataAsset Emote)
    {
        Emotes.AddUnique(Emote);
    }

    UFUNCTION()
    void RemoveEmote(UEmoteDataAsset Emote)
    {
        Emotes.Remove(Emote);
    }
}