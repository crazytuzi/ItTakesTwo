
class UDataAssetDistantLights : UDataAsset
{
    
}

class ADistantLights : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {

    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {

    }

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {

    }
}