
class UDataAssetPhysicsProp : UDataAsset
{
    UPROPERTY()
    UStaticMesh Mesh;

    UPROPERTY()
    bool Breakable = false;

    UPROPERTY()
    UNiagaraSystem BreakParticle;

    UPROPERTY()
    int Health = 2;
}

class APhysicsProp : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {

    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {

    }
}